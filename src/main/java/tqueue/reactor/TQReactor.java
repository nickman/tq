/**
 * Helios, OpenSource Monitoring
 * Brought to you by the Helios Development Group
 *
 * Copyright 2007, Helios Development Group and individual contributors
 * as indicated by the @author tags. See the copyright.txt file in the
 * distribution for a full listing of individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org. 
 *
 */
package tqueue.reactor;

import java.lang.management.ManagementFactory;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.sql.ORADataFactory;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Logger;

import reactor.Environment;
import reactor.core.Dispatcher;
import reactor.core.dispatch.wait.ParkWaitStrategy;
import reactor.core.processor.RingBufferWorkProcessor;
import reactor.fn.Consumer;
import reactor.fn.Function;
import reactor.rx.Streams;
import reactor.rx.action.Action;
import reactor.rx.action.Control;
import reactor.rx.broadcast.Broadcaster;
import reactor.rx.stream.GroupedStream;
import tqueue.db.types.DBType;
import tqueue.db.types.TQBATCH;
import tqueue.db.types.TQTRADE;
import tqueue.db.types.TQTRADE_ARR;
//import tqueue.db.localtypes.*;
import tqueue.pools.ConnectionPool;

import com.codahale.metrics.Gauge;
import com.codahale.metrics.Histogram;
import com.codahale.metrics.Meter;
import com.codahale.metrics.MetricRegistry;

/**
 * <p>Title: TQReactor</p>
 * <p>Description: Trade processor</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.TQReactor</code></p>
 */

public class TQReactor implements Iterator<TQBATCH>, Runnable, ThreadFactory {
	/** The TQReactor singleton instance */
	private static volatile TQReactor instance = null;
	/** The TQReactor singleton instance ctor lock */
	private static final Object lock = new Object();
	
	/** The number of available cpus */
	public static final int CORES = ManagementFactory.getOperatingSystemMXBean().getAvailableProcessors();
	
	/** The batch polling SQL */
	public static final String POLL_BATCH_SQL = 
			"SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) " +
			"FROM TABLE(TQV.QUERYTBATCHES(?, ?, ?, ?)) " +
			"ORDER BY FIRST_T ";
	
	/** The initial lock batch SQL */	
	public static final String LOCK_BATCH_SQL =
			"BEGIN ? := TQV.LOCKBATCHREF(?, ?, ?); END;";
	
	/** The processing started lock batch SQL */
	public static final String RELOCK_BATCH_SQL = 
			"BEGIN TQV.RELOCKBATCH(?); END;";
	
	/** The SQL to dereference a BatchRoutingKey */
	public static final String DEREF_BATCH_KEY_SQL = 
			"DELETE FROM TQBATCHES T WHERE ROWID = CHARTOROWID(?) RETURNING VALUE(T) INTO ?";
	

	/** The SQL to start a batch process and return the trades for the batch */
	public static final String START_BATCH_SQL = 
			"BEGIN ? := TQV.STARTBATCH(?); END;";

	/** The SQL to save the processed trades */
	public static final String SAVE_TRADES_SQL = 
			"BEGIN TQV.SAVETRADES(?, ?); END;";
	
	/** The SQL to finish the batch and delete the processed trade stubs */
	public static final String FINISH_BATCH_SQL = 
			"BEGIN TQV.FINISHBATCH(?); END;";

	
	/** Static class logger */
	private final Logger log = Logger.getLogger(getClass());
	
	/** The connection pool */
	private final ConnectionPool connPool;
	/** The trade broadscaster */
	private Broadcaster<TQBATCH> sink;
	/** The trade poller's active wrapped connection */
	private Connection wrappedConnection = null;
	
	/** The trade poller's active connection */
	private OracleConnection pollerConnection = null;
	/** The trade poller's active prepared statement */
	private OraclePreparedStatement pollerPs = null;
	/** The trade poller's active batch locker */
	private OracleCallableStatement pollerCs = null;
	/** The trade poller's active result set */
	private OracleResultSet pollerRset = null;	
	/** The trade poller's TQBATCH OraDataFactory */
	private final ORADataFactory tqBatchOraDataFactory;
	/** The trade poller's TQTRADE OraDataFactory */
	private final ORADataFactory tradeOraDataFactory;
	/** The trade poller's TQTRADE_ARR OraDataFactory */
	private final ORADataFactory tradeArrBatchOraDataFactory;
	
	/** The ID of the last trade batched and retrieved */
	private int lastTradeQueueId = 0;
	/** The poller's maximum number of trades to retrieve in one loop */
	private int maxRows = 10000;
	/** The poller's maximum batch size */
	private int maxBatchSize = 1000;
	/** The poller's wait period in seconds when waiting for the next rows to become available */
	private int pollWaitTime = 3;
	/** The poller's maximum wait loops when waiting for the next rows to become available */
	private int pollWaitLoops = 10;
	/** The number of parallel streams to run per core */
	private int streamsPerCore = 1;
	
	
	Control ctx = null;
	
	/** The thread factory for the ring buffer's executor service */
	protected final ThreadFactory tf = new ThreadFactory() {
		final AtomicInteger serial = new AtomicInteger(0);
		public Thread newThread(final Runnable r) {
			Thread t = new Thread(r, "TQReactorThread#" + serial.incrementAndGet());
			t.setDaemon(true);
			return t;
		}
	};
	/** The thread pool for the ring buffer */
	protected ThreadPoolExecutor tpe = null;
	
	/** The ring buffer */
	protected RingBufferWorkProcessor<BatchRoutingKey> ringBuffer = null;
	
	protected final AtomicInteger pollerBarrier = new AtomicInteger(0);
	
	
	
	
	/** Poller thread serial */
	private final AtomicInteger threadSerial = new AtomicInteger(0);
	/** The starting TQUEUE_ID to poll for */
	private final AtomicInteger startId = new AtomicInteger(0);
	
	/** The metric registry */
	private final MetricRegistry registry;
	
	/** The inflight gauge */
	private final AtomicInteger inFlight = new AtomicInteger(0);
	/** A meter of trades per/s */
	private final Meter tradesPerSec;
	/** A meter of batches per/s */
	private final Meter batchesPerSec;
	/** A histogram of batch sizes (trades per batch) */
	private final Histogram avgBatchSize;
	/** A histogram of batch processing times */
	private final Histogram avgBatchProcessingTime;
	/** A histogram of trade processing times */
	private final Histogram avgTradeProcessingTime;
	/** A histogram of event publishing back-pressure */
	private final Histogram avgBackPressureTime;
	/** A histogram of ring buffer available capacity */
	private final Histogram avgRingBufferCap;
	
	/** A histogram of concurrent inflight batches */
	private final Histogram inFlightMetric;
	

	/** The started flag */
	private final AtomicBoolean started = new AtomicBoolean(false);
	
	/** The poller thread */
	private Thread pollerThread = null;
	
	
	/**
	 * Acquires the TQReactor singleton instance
	 * @return the TQReactor singleton instance
	 */
	public static TQReactor getInstance() {
		if(instance==null) {
			synchronized(lock) {
				if(instance==null) {
					instance = new TQReactor();
				}
			}
		}
		return instance;
	}
	
	public static void main(String[] args) {
		BasicConfigurator.configure();
		TQReactor tqr = TQReactor.getInstance();
		tqr.log.info("TQReactor Test");
		try {
			tqr.start();
			tqr.pollerThread.join();
		} catch (Exception ex) {
			ex.printStackTrace(System.err);
		}
	}
	
	private TQReactor() {
		Environment.initializeIfEmpty().assignErrorJournal(new Consumer<Throwable>(){
			@Override
			public void accept(final Throwable t) {
				log.error("Untrapped exception", t);				
			}
		});
		connPool = ConnectionPool.getInstance();
		tqBatchOraDataFactory = TQBATCH.getORADataFactory();
		tradeArrBatchOraDataFactory = TQTRADE_ARR.getORADataFactory();
		tradeOraDataFactory = TQTRADE.getORADataFactory();
		registry = connPool.getMetricRegistry();
		//inFlight = connPool.getInflightGauge();
		final Gauge<Integer> inFlightGauge = new Gauge<Integer>() {
			@Override
			public Integer getValue() {			
				final int i = inFlight.get();
				inFlightMetric.update(i);
				return i;
			}
		};
		final Gauge<Integer> startIdGauge = new Gauge<Integer>() {
			@Override
			public Integer getValue() {				
				return startId.get();
			}
		};
		
		registry.register("InFlightBatchGauge", inFlightGauge);
		registry.register("StartingId", startIdGauge);
		tradesPerSec = registry.meter("tradesPerSec");
		batchesPerSec = registry.meter("batchesPerSec");
		avgBatchSize = registry.histogram("avgBatchSize");
		avgBatchProcessingTime = registry.histogram("avgBatchProcessingTime");
		avgTradeProcessingTime = registry.histogram("avgTradeProcessingTime");
		avgBackPressureTime = registry.histogram("avgBackPressureTime");
		inFlightMetric = registry.histogram("inFlightBatches");
		avgRingBufferCap = registry.histogram("avgRingBufferCap");
		
		
		
		
		
		
	}
	
	@Override
	public Thread newThread(final Runnable r) {
		Thread t = new Thread(r, "TQPollerThread#" + threadSerial.incrementAndGet());
		t.setDaemon(true);
		return t;
	}
	
	/**
	 * Starts the TQReactor::TQPoller service
	 * @throws Exception thrown if the poller cannot be started
	 */
	public void start() throws Exception {
		if(started.compareAndSet(false, true)) {
			log.info("Starting TQReactor::TQPoller....");
			try {
				initSink();
				initPoller();
				pollerThread = newThread(this);
				pollerThread.start();
				log.info("TQReactor::TQPoller Started");
//				pollerRset = null;	
				
			} catch (Exception ex) {
				started.set(false);
				cleanupPoller();
				log.error("Failed to start TQReactor::TQPoller", ex);				
				throw ex;
			} 
		}		
	}
	
	/**
	 * Stops the TQReactor::TQPoller service
	 */
	public void stop() {
		if(started.compareAndSet(true, false)) {
			
		}
	}
	
	Function<BatchRoutingKey, Integer> groupFunction(final int mod) {
		return new Function<BatchRoutingKey, Integer>() {
			@Override
			public Integer apply(final BatchRoutingKey t) {
				try {
					return t.getAccountId()%mod;
				} catch (Exception ex) {
					throw new RuntimeException(ex);
				} 
			}
		};
	}
	
	Consumer<Throwable> errorConsumer(final Integer key) {
		return new Consumer<Throwable>() {
			@Override
			public void accept(final Throwable t) {				
				log.error("TQBATCH exception [" + key + "]", t);
			}
		};
	}
	
	Consumer<Void> completionConsumer(final Integer key) {
//		return new Consumer<Void>() {
//			@Override
//			public void accept(final Void t) {				
//				log.info("TQBATCH complete [" + t + "]");
//			}
//		};
		return new Action<Void, Void>() {

			@Override
			protected void doNext(final Void ev) {
				this.onComplete();
				
			}
			
		};
	}
	
	
	Consumer<BatchRoutingKey> batchConsumer(final Integer key) {
		return new Consumer<BatchRoutingKey>() {
			@Override
			public void accept(final BatchRoutingKey batch) {					
				try {					
//					if(key==3) {
//						log.info("Consumed Batch(" + key + ")  [" + id + "]: stubs:" + batch.getTcount() + ", first:" + batch.getFirstT() + ", last:" + batch.getLastT());
//					}
					final int tcount = batch.getTcount();
					tradesPerSec.mark(tcount);
					batchesPerSec.mark();
					avgBatchSize.update(tcount);

					processBatch(batch);
					inFlight.decrementAndGet();
				} catch (Exception ex) {
					throw new RuntimeException(ex);
				}
			}		
		};
	}
		

	
	
	
	
	Consumer<GroupedStream<Integer, BatchRoutingKey>> batchConsumerGrouped() {
		return new Consumer<GroupedStream<Integer, BatchRoutingKey>>() {		
		
			@Override
			public void accept(final GroupedStream<Integer, BatchRoutingKey> t) {
				final Integer key = t.key();
				t.consume(batchConsumer(key));
			}		
		};
	}
	
    public static int findNextPositivePowerOfTwo(final int value) {
       	return  1 << (32 - Integer.numberOfLeadingZeros((int)value - 1));    		
	}    

	
	/**
	 * Initializes the TQBatch broadcaster
	 */
	protected void initSink() {
		final int totalStreams = CORES * streamsPerCore;
		final int ringBufferSize = findNextPositivePowerOfTwo(totalStreams);
		log.info("\n\t=====================================\n\tRingBuffer Slots:" + ringBufferSize + "\n\t=====================================");
		tpe = new ThreadPoolExecutor(CORES * 4, CORES * 4, 60, TimeUnit.SECONDS, new SynchronousQueue<Runnable>(), tf);
		tpe.prestartAllCoreThreads();
		ringBuffer = RingBufferWorkProcessor.create(tpe, ringBufferSize, new ParkWaitStrategy());		
		
	final Map<Integer, Consumer<BatchRoutingKey>> groupConsumers = new HashMap<Integer, Consumer<BatchRoutingKey>>(totalStreams);
	for(int i = 0; i < totalStreams; i++) {
		final int k = i;
		groupConsumers.put(i, new Consumer<BatchRoutingKey>(){
			final Dispatcher dispatcher = Environment.cachedDispatcher();
			@Override
			public void accept(final BatchRoutingKey batch) {							
				dispatcher.dispatch(batch, batchConsumer(k), errorConsumer(k));					
			}
		});			
	}
		ctx = Streams.wrap(ringBuffer)
//			.observe(t -> {				
//				inFlight.incrementAndGet();
//				try {
//					log.info("Batch [" + t.getAccount() + " / " + t.getBatchId() + "] is in flight");
//				} catch (Exception ex) {
//					log.error("Infligh Observer Exception", ex);
//					throw new RuntimeException(ex);
//				}								
//			})
//			.observeComplete(x -> 
//				inFlight.decrementAndGet()
//			)
			.groupBy(groupFunction(totalStreams))
			.consume(new Consumer<GroupedStream<Integer, BatchRoutingKey>>() {
				@Override
				public void accept(final GroupedStream<Integer, BatchRoutingKey> t) {
					t.capacity(1).consume(groupConsumers.get(t.key()));					
				}
			});
				
		
//		ringBuffer.subscribe(sink);
		log.info("Control:\n" + ctx.debug().toString());
		log.info("Sink created");		
	}
	
	/**
	 * Runs the TQReactor::TQPoller polling loop in the polling thread.
	 * {@inheritDoc}
	 * @see java.lang.Runnable#run()
	 */
	@Override
	public void run() {
		
		while(started.get()) {
			if(pollerBarrier.get() > 0) {
				log.info("Waiting on poller barrier...");
				final long start = System.nanoTime(); 
				while(pollerBarrier.get() > 0) {
					Thread.yield();
				}
				final long elapsed = System.nanoTime()-start;
				log.info("Waited on poller barrier for [" + elapsed + "] ns. / [" + TimeUnit.MILLISECONDS.convert(elapsed, TimeUnit.NANOSECONDS) + "] ms.");
			}
			try {
				/*
				 * ===========================================================================
				 * SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) 
				 * FROM TABLE(TQV.QUERYTBATCHES(?, ?, ?, ?)) 
				 * ORDER BY FIRST_T 
				 * FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, 
				 * 		MAX_BATCH_SIZE IN INT DEFAULT 10, WAIT_TIME IN INT DEFAULT 0) RETURN TQBATCH_ARR
				 * ===========================================================================
				 */
				
				pollerPs.setInt(1, this.startId.get());
//				pollerPs.setInt(1, 0);
				pollerPs.setInt(2, maxRows);
				pollerPs.setInt(3, maxBatchSize);
				pollerPs.setInt(4, pollWaitTime);			
				
				pollerRset = (OracleResultSet)pollerPs.executeQuery();
				
				pollerRset.setFetchSize(maxBatchSize);
				int batchCount = 0;
				int stubCount = 0;
				int dropCount = 0;
				while(pollerRset.next()) {
					if(!started.get()) {
						break;
					}
					TQBATCH preBatch = (TQBATCH)pollerRset.getORAData(1, tqBatchOraDataFactory);
					if(preBatch.getAccount()==-1) {
						//log.info("Timed out waiting for results");
						break;
					}
					
					// ===========================================================================
					//   FUNCTION LOCKBATCHREF(batch IN OUT TQBATCH, accountId OUT INT, tcount OUT INT) RETURN VARCHAR2 IS 
					// 	 BEGIN ? := TQV.LOCKBATCHREF(?, ?, ?); END;
					// ===========================================================================
					pollerCs.registerOutParameter(1, DBType.VARCHAR.typeCode);
					pollerCs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					pollerCs.registerOutParameter(3, DBType.INTEGER.typeCode);
					pollerCs.registerOutParameter(4, DBType.INTEGER.typeCode);
				
					pollerCs.setORAData(2, preBatch);
					
					pollerCs.execute();
					final String rowid = pollerCs.getString(1);
					final int accountId = pollerCs.getInt(3);
					final int tcount = pollerCs.getInt(4);
					if(rowid==null) {
						continue;
					}
					stubCount += tcount;
					TQBATCH postBatch = (TQBATCH)pollerCs.getORAData(2, tqBatchOraDataFactory);
					this.startId.set(postBatch.getFirstT());
					batchCount++;
					pollerConnection.commit();
					avgRingBufferCap.update(ringBuffer.getAvailableCapacity());
					final long start = System.currentTimeMillis();
					ringBuffer.onNext(new BatchRoutingKey(rowid, accountId, tcount));					
					final long elapsed = System.currentTimeMillis() - start;
					pollerBarrier.incrementAndGet();
					avgBackPressureTime.update(elapsed);
					inFlight.incrementAndGet();
					
					//sink.onNext(postBatch);
				}
				pollerRset.close();
				if(batchCount>0 | dropCount>0) {
				log.info(new StringBuilder("Polling loop: batches:")
					.append(batchCount)
					.append(", stubs:")
					.append(stubCount)
					.append(", drops:")
					.append(dropCount)
					.append(", cap:")
					.append(ringBuffer.getAvailableCapacity())					
					.append(", inFlight:")
					.append(inFlight.get())					
					
				);
				}
				batchCount = 0;
				stubCount = 0;
				dropCount = 0;				
				if(!started.get()) {
					break;
				}				
			} catch (SQLException sex) {
				if(pollerRset!=null) try { pollerRset.close(); } catch (Exception x) {/* No Op */}
				if(sex.getErrorCode()==4068) {
					log.warn("Package State Changed. Re-initializing....");
					continue;
				}
				log.error("getTQStubs failed", sex);				
			} catch (Exception ex) {
				log.error("getTQStubs failed", ex);
			}			
		}
		log.info("TQReactor::TQPoller Polling Thread Ended");
		pollerThread = null;
	}
	
	/**
	 * Cleans up the polling JDBC resources and then re-initializes.
	 */
	protected void reInitPoller() {
		cleanupPoller();
		initPoller();
	}
	
	/**
	 * Initializes all the poller's allocated JDBC resources
	 */
	protected void initPoller() {
		try {
			wrappedConnection = connPool.getConnection();				
			pollerConnection = ConnectionPool.unwrap(wrappedConnection, OracleConnection.class);
			pollerPs = (OraclePreparedStatement)pollerConnection.prepareStatement(POLL_BATCH_SQL);			
			pollerCs = (OracleCallableStatement)pollerConnection.prepareCall(LOCK_BATCH_SQL);			
		} catch (Exception ex) {
			log.error("Failed to initialize poller JDBC resources", ex);
			cleanupPoller();
		}
	}
	
	
	/**
	 * Closes all the poller's allocated JDBC resources
	 */
	protected void cleanupPoller() {
		if(pollerRset!=null) try { pollerRset.close(); } catch (Exception x) {/* No Op */}
		pollerRset = null;
		if(pollerPs!=null) try { pollerPs.close(); } catch (Exception x) {/* No Op */}
		pollerPs = null;
		if(pollerCs!=null) try { pollerCs.close(); } catch (Exception x) {/* No Op */}
		pollerCs = null;
		if(wrappedConnection!=null) try { wrappedConnection.rollback(); } catch (Exception x) {/* No Op */}
		if(wrappedConnection!=null) try { wrappedConnection.close(); } catch (Exception x) {/* No Op */}
		wrappedConnection = null;
		pollerConnection = null;		
	}
	
	
	/**
	 * Processes a batch
	 * @param batchKey The batch to process
	 */
	public void processBatch(final BatchRoutingKey batchKey) {
		Connection conn = null;
		OracleConnection oraConn = null;
		OraclePreparedStatement ps = null;
		OracleCallableStatement cs = null;
		OracleResultSet rs = null;
		TQBATCH preBatch = null;
		TQBATCH postBatch = null;
		try {
			final long startTime = System.currentTimeMillis();
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);

			// "DELETE FROM TQBATCHES T WHERE ROWID = CHARTOROWID(?) RETURNING VALUE(T) INTO ?";
			ps = (OraclePreparedStatement)oraConn.prepareStatement(DEREF_BATCH_KEY_SQL);
			ps.setString(1, batchKey.getRowid());
			ps.registerReturnParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);			
			ps.execute();
			rs = (OracleResultSet)ps.getReturnResultSet();
			rs.next();
			preBatch = (TQBATCH)rs.getORAData(1, tqBatchOraDataFactory);
			rs.close();
			ps.close();
			
			
			//preBatch.restoreConnection(oraConn);
			//===========================================================================================
			// 	 PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH);
			//===========================================================================================
			cs = (OracleCallableStatement)oraConn.prepareCall(RELOCK_BATCH_SQL);
			cs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
			cs.setObject(1, preBatch, TQBATCH._SQL_TYPECODE);
//			cs.setORAData(1, preBatch);
			cs.execute();
			pollerBarrier.decrementAndGet();
			postBatch = (TQBATCH)cs.getORAData(1, tqBatchOraDataFactory);
			cs.close();
			if(postBatch.getTcount() != preBatch.getTcount()) {
				int dropCount = (preBatch.getTcount() - postBatch.getTcount());
				//System.err.println("RE-Lock Drops:" + dropCount);
			}
			
			//===========================================================================================
			//		FUNCTION STARTBATCH(tqbatch IN OUT TQBATCH) RETURN TQTRADE_ARR;
			//===========================================================================================
			TQTRADE[] trades = null;
			cs = (OracleCallableStatement)oraConn.prepareCall(START_BATCH_SQL);
			
			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
			cs.setObject(2, postBatch, TQBATCH._SQL_TYPECODE);
//			cs.setORAData(2, postBatch);
			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
			cs.registerOutParameter(1, TQTRADE_ARR._SQL_TYPECODE, TQTRADE_ARR._SQL_NAME);
			cs.execute();
			//return ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
			trades = ((TQTRADE_ARR)cs.getORAData(1, TQTRADE_ARR.getORADataFactory())).getArray();
			postBatch = (TQBATCH)cs.getORAData(2, tqBatchOraDataFactory);
			cs.close();
			if(trades.length != postBatch.getRowids().length()) {
				log.error("Mismatch between trade count [" + trades.length + "] and postBatch stub count [" + postBatch.getRowids().length() + "]. (PreBatch:[" + preBatch.getRowids().length() + "])");
				throw new RuntimeException("Mismatch between trade count [" + trades.length + "], postBatch ROWID count [" + postBatch.getRowids().length() + "] and postBatch Stub count [" + postBatch.getStubs().length() + "]");
			}
			
			
			//===========================================================================================
			//		PROCEDURE SAVETRADES(trades IN TQTRADE_ARR, batchId IN INT);
			//===========================================================================================			
			final Timestamp ts = new Timestamp(System.currentTimeMillis());
			for(TQTRADE tqt: trades) {
		        tqt.setStatusCode("CLEARED");
		        tqt.setUpdateTs(ts);				
			}
			cs = (OracleCallableStatement)oraConn.prepareCall(SAVE_TRADES_SQL);
			cs.setORAData(1, new TQTRADE_ARR(trades));
			cs.setInt(2, postBatch.getBatchId());
			cs.execute();
			cs.close();
			
			
			//===========================================================================================
			//		PROCEDURE FINISHBATCH(batchRowids IN XROWIDS);
			//===========================================================================================						
			cs = (OracleCallableStatement)oraConn.prepareCall(FINISH_BATCH_SQL);
			cs.setORAData(1, postBatch.getRowids());
			cs.execute();
			cs.close();
			conn.commit();
			//log.info("Batch Complete");
			final long elapsedTime = System.currentTimeMillis() - startTime;
			avgBatchProcessingTime.update(elapsedTime);
			try {
				avgTradeProcessingTime.update(elapsedTime/batchKey.getTcount());
			} catch (Exception x) {/* No Op */}
		} catch (Exception ex) {
			log.error("Failed to process batch", ex);
			throw new RuntimeException("Failed to process batch [" + postBatch + "]", ex);
		} finally {
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(cs!=null) try { cs.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.rollback(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}			
		}
	}
	

	@Override
	public boolean hasNext() {
		return started.get();
	}

	@Override
	public TQBATCH next() {
		try {
			if(!pollerRset.next()) {
				pollerRset.close();
				pollerPs.setInt(1, lastTradeQueueId);
				pollerPs.setInt(2, maxRows);
				pollerPs.setInt(3, maxBatchSize);
				pollerRset = (OracleResultSet)pollerPs.executeQuery();
				return next();
			} else {
				TQBATCH batch = (TQBATCH)((OracleResultSet)pollerRset).getORAData(1, tqBatchOraDataFactory);
				pollerCs.setORAData(1, batch);
				pollerCs.setInt(2, 0);
				pollerCs.execute();
				batch = (TQBATCH)pollerCs.getORAData(1, TQBATCH.getORADataFactory());
				lastTradeQueueId = batch.getLastT();
				return batch;
			}
			
		} catch (Exception ex) {
			throw new RuntimeException("next() exception", ex);
		}
		
		
	}

	@Override
	public void remove() {
		/* No Op */		
	}
	

}

/*
import reactor.Environment;
import reactor.rx.Streams;
import reactor.rx.stream.Broadcaster;

public class ReactorHelloWorld {
  public static void main(String... args) throws InterruptedException {
    Environment.initialize(); 

    Broadcaster<String> sink = Streams.broadcast(Environment.get()); 

    sink.dispatchOn(Environment.cachedDispatcher()) 
        .map(String::toUpperCase) 
        .consume(s -> System.out.printf("s=%s%n", s)); 

    sink.onNext("Hello World!"); 

    Thread.sleep(500); 
  }
}

// ============= filter
Stream<String> st;

st.filter(s -> s.startsWith("Hello")) 
  .consume(s -> service.doWork(s)); 
  
============= observe consumer
Stream<String> st;

st.observe(s -> LOG.info("Got input [{}] on thread [{}}]", s, Thread.currentThread())) 
  .observeComplete(v -> LOG.info("Stream is complete")) 
  .observeError(Throwable.class, (o, t) -> LOG.error("{} caused an error: {}", o, t)) 
  .consume(s -> service.doWork(s)); 

============= broadcast  
  
Broadcaster<String> sink = Broadcaster.create(Environment.get()); 

sink.map(String::toUpperCase) 
    .consume(s -> System.out.printf("%s greeting = %s%n", Thread.currentThread(), s)); 

sink.onNext("Hello World!");   
 
============= RingBuffer Processor
Processor<Buffer> processor = new ProcessorSpec<Buffer>()
                .singleThreadedProducer() 
                .dataBufferSize(4 * 1024) 
                .dataSupplier(() -> new Buffer()) 
                .consume(buff -> service.readInput(buff)) 
                .get();

============= Zero GC
Using the Processor, it’s possible to create an application that produces zero garbage and need never halt for GC.

Operation<Buffer> op = processor.prepare(); 
op.get().append("Hello World!").flip(); 
op.commit(); 
 
============= 

=============  
 
 
 
*/