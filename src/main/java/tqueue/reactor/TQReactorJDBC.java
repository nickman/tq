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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.management.ManagementFactory;
import java.lang.reflect.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.HashMap;
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
import oracle.sql.ARRAY;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import reactor.Environment;
import reactor.core.Dispatcher;
import reactor.core.dispatch.wait.ParkWaitStrategy;
import reactor.core.processor.RingBufferWorkProcessor;
import reactor.fn.Consumer;
import reactor.fn.Function;
import reactor.fn.Predicate;
import reactor.rx.Streams;
import reactor.rx.action.Control;
import reactor.rx.broadcast.Broadcaster;
import reactor.rx.stream.GroupedStream;
//import tqueue.db.types.*;
import tqueue.db.localtypes.TQBATCH;
import tqueue.db.localtypes.TQTRADE;
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

public class TQReactorJDBC implements Runnable, ThreadFactory {
	/** The TQReactor singleton instance */
	private static volatile TQReactorJDBC instance = null;
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
			"BEGIN TQV.LOCKBATCH(?, ?); END;";
	
	/** The processing started lock batch SQL */
	public static final String RELOCK_BATCH_SQL = 
			"BEGIN TQV.RELOCKBATCH(?); END;";

	/** The SQL to start a batch process and return the trades for the batch */
	public static final String START_BATCH_SQL = 
			"BEGIN ? := TQV.STARTBATCH(?); END;";

	/** The SQL to save the processed trades */
	public static final String SAVE_TRADES_SQL = 
			"BEGIN TQV.SAVETRADES(?, ?); END;";
	
	/** The SQL to finish the batch and delete the processed trade stubs */
	public static final String FINISH_BATCH_SQL = 
			"BEGIN TQV.FINISHBATCH(?); END;";

	
	/** Instance logger */
	private final Logger log = LoggerFactory.getLogger(getClass());

	
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
	
	/** The ID of the last trade batched and retrieved */
	private int lastTradeQueueId = 0;
	/** The poller's maximum number of trades to retrieve in one loop */
	private int maxRows = 10000;
	/** The poller's maximum batch size */
	private int maxBatchSize = 1000;
	/** The poller's wait period in seconds when waiting for the next rows to become available */
	private int pollWaitTime = 1;
	/** The poller's maximum wait loops when waiting for the next rows to become available */
	private int pollWaitLoops = 10;
	/** The number of parallel streams to run per core */
	private int streamsPerCore = 1;
	protected final AtomicLong gBatchCounter = new AtomicLong(0);
	
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
	protected RingBufferWorkProcessor<TQBATCH> ringBuffer = null;
	
	
	
	
	/** Poller thread serial */
	private final AtomicInteger threadSerial = new AtomicInteger(0);
	/** The starting TQUEUE_ID to poll for */
	private final AtomicInteger startId = new AtomicInteger(0);
	/** The numnber of pending tasks in the current loop */
	private final AtomicInteger pending = new AtomicInteger(0);
	
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
	/** A histogram of serialized TQBATCH sizes */
	private final Histogram avgTQBatchByteSize;
	/** A histogram of TQBATCH ser/deser times in ms. */
	private final Histogram avgSerDeserTime;
	

	/** The started flag */
	private final AtomicBoolean started = new AtomicBoolean(false);
	
	/** The poller thread */
	private Thread pollerThread = null;
	
	
	/**
	 * Acquires the TQReactor singleton instance
	 * @return the TQReactor singleton instance
	 */
	public static TQReactorJDBC getInstance() {
		if(instance==null) {
			synchronized(lock) {
				if(instance==null) {
					instance = new TQReactorJDBC();
				}
			}
		}
		return instance;
	}
	
	public static void main(String[] args) {
		TQReactorJDBC tqr = TQReactorJDBC.getInstance();
		tqr.log.info("TQReactor Test");
		try {
			tqr.start();
			tqr.pollerThread.join();
		} catch (Exception ex) {
			ex.printStackTrace(System.err);
		}
	}
	
	private TQReactorJDBC() {
		Environment.initializeIfEmpty().assignErrorJournal(new Consumer<Throwable>(){
			@Override
			public void accept(final Throwable t) {
				log.error("Untrapped exception", t);				
			}
		});
		connPool = ConnectionPool.getInstance();
		registry = connPool.getMetricRegistry();
		//inFlight = connPool.getInflightGauge();
		final Gauge<Integer> inFlightGauge = new Gauge<Integer>() {
			@Override
			public Integer getValue() {				
				return inFlight.get();
			}
		};
		final Gauge<Integer> startIdGauge = new Gauge<Integer>() {
			@Override
			public Integer getValue() {				
				return startId.get();
			}
		};
		
		registry.register("InFlightBatches", inFlightGauge);
		registry.register("StartingId", startIdGauge);
//		/** A meter of trades per/s */
//		private final Meter tradesPerSec;
//		/** A meter of batches per/s */
//		private final Meter batchesPerSec;
//		/** A histogram of batch sizes (trades per batch) */
//		private final Histogram avgBatchSize;
		tradesPerSec = registry.meter("tradesPerSec");
		batchesPerSec = registry.meter("batchesPerSec");
		avgBatchSize = registry.histogram("avgBatchSize");
		
//		/** A histogram of serialized TQBATCH sizes */
//		private final Histogram avgTQBatchByteSize;
//		/** A histogram of TQBATCH ser/deser times in ms. */
//		private final Histogram avgSerDeserTime;
		
		avgTQBatchByteSize = registry.histogram("avgTQBatchByteSize");
		avgSerDeserTime = registry.histogram("avgSerDeserTime");
		
		
		
		
		
		
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
	
	Function<TQBATCH, Integer> groupFunction(final int mod) {
		return new Function<TQBATCH, Integer>() {
			@Override
			public Integer apply(final TQBATCH t) {
				try {
					return t.getAccount()%mod;
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
	
	Consumer<TQBATCH> batchConsumer(final Integer key) {
		return new Consumer<TQBATCH>() {
			@Override
			public void accept(final TQBATCH batch) {					
				try {
					final long id = gBatchCounter.incrementAndGet();		
//					if(key==3) {
//						log.info("Consumed Batch(" + key + ")  [" + id + "]: stubs:" + batch.getTcount() + ", first:" + batch.getFirstT() + ", last:" + batch.getLastT());
//					}
					final int tcount = batch.getTcount();
					tradesPerSec.mark(tcount);
					batchesPerSec.mark();
					avgBatchSize.update(tcount);

					processBatch(ser(batch));
					pending.decrementAndGet();
					inFlight.decrementAndGet();
					
					
				} catch (Exception ex) {
					throw new RuntimeException(ex);
				}
			}		
		};
	}
		

	
	Consumer<GroupedStream<Integer, TQBATCH>> batchConsumerGrouped() {
		return new Consumer<GroupedStream<Integer, TQBATCH>>() {		
		
			@Override
			public void accept(final GroupedStream<Integer, TQBATCH> t) {
				final Integer key = t.key();
				t.consume(batchConsumer(key));
			}		
		};
	}
	
	final Predicate<TQBATCH> acctPred(final int key) {
		return new Predicate<TQBATCH>() {
			/**
			 * {@inheritDoc}
			 * @see reactor.fn.Predicate#test(java.lang.Object)
			 */
			@Override
			public boolean test(TQBATCH t) {
				try {
					return t.getAccount()%CORES==key;
				} catch (Exception ex) {
					log.error("AcctPred:", ex);
					throw new RuntimeException(ex);
				}
			}
		};
	}
	
	/**
	 * Initializes the TQBatch broadcaster
	 */
	protected void initSink() {
		final int totalStreams = CORES * streamsPerCore;
		tpe = new ThreadPoolExecutor(12, 24, 60, TimeUnit.SECONDS, new SynchronousQueue<Runnable>(), tf);
		tpe.prestartAllCoreThreads();
		ringBuffer = RingBufferWorkProcessor.create(tpe, 128, new ParkWaitStrategy());		
		
		final Map<Integer, Consumer<TQBATCH>> groupConsumers = new HashMap<Integer, Consumer<TQBATCH>>(totalStreams);
		for(int i = 0; i < totalStreams; i++) {
			final int k = i;
			groupConsumers.put(i, new Consumer<TQBATCH>(){
				final Dispatcher dispatcher = Environment.cachedDispatcher();
				@Override
				public void accept(final TQBATCH batch) {							
					dispatcher.dispatch(batch, batchConsumer(k), errorConsumer(k));
				}
			});
			
		}
		ctx = Streams.wrap(ringBuffer)
			.observe(t -> {
				inFlight.incrementAndGet();
//				try {
//					log.info("Batch [" + t.getAccount() + " / " + t.getBatchId() + "] is in flight");
//				} catch (Exception ex) {
//					log.error("Infligh Observer Exception", ex);
//					throw new RuntimeException(ex);
//				}								
			})
			.observeComplete(x -> inFlight.decrementAndGet())
			.groupBy(groupFunction(totalStreams))
			.capacity(1)			
			.consume(new Consumer<GroupedStream<Integer, TQBATCH>>() {
				@Override
				public void accept(final GroupedStream<Integer, TQBATCH> t) {
					t.consume(groupConsumers.get(t.key()));					
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
			try {
				if(pending.get()!=0) {
//					log.info("Waiting on pending");
//					while(pending.get()!=0) {
//						Thread.yield();
//					}
//					log.info("Pending complete");
				}
				pollerPs.setInt(1, this.startId.get());
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
					//TQBATCH preBatch = (TQBATCH)pollerRset.getORAData(1, tqBatchOraDataFactory);
					TQBATCH preBatch = (TQBATCH)pollerRset.getObject(1);
					if(preBatch.getAccount()==-1) {
						//log.info("Timed out waiting for results");
						break;
					}
					pollerCs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					
					//pollerCs.setORAData(1, preBatch);
					pollerCs.setObject(1, preBatch);
					pollerCs.setInt(2, 0);
					
					pollerCs.execute();
					//TQBATCH postBatch = (TQBATCH)pollerCs.getORAData(1, tqBatchOraDataFactory);
					TQBATCH postBatch = (TQBATCH)pollerCs.getObject(1);
					if(postBatch.getTcount()==0) {
						continue;
					}
					startId.set(postBatch.getLastT());
					if(postBatch.getTcount() != preBatch.getTcount()) {
						dropCount += (preBatch.getTcount() - postBatch.getTcount());
					}
					batchCount++;
					stubCount += postBatch.getTcount();
					pollerConnection.commit();
					pending.incrementAndGet();
					ringBuffer.onNext(postBatch);
					
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
					.append(", inFlight:")
					.append(inFlight.get())					
					.toString()
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
	
	protected byte[] ser(final TQBATCH batch) {
		ByteArrayOutputStream baos = null;
		ObjectOutputStream oos = null;
		try {
			baos = new ByteArrayOutputStream(2048);
			oos = new ObjectOutputStream(baos);
			oos.writeObject(batch);
			oos.flush();
			baos.flush();
			final byte[] bytes = baos.toByteArray();
			avgTQBatchByteSize.update(bytes.length);
			return bytes;
		} catch (Exception ex) {
			throw new RuntimeException(ex);
		} finally {
			if(baos!=null) try { baos.close(); } catch (Exception ex) {/* No Op */}
			if(oos!=null) try { oos.close(); } catch (Exception ex) {/* No Op */}
		}
	}
	
	protected TQBATCH deser(final byte[] bytes, final Connection conn) {
		ByteArrayInputStream baos = null;
		ObjectInputStream oos = null;
		try {			
			baos = new ByteArrayInputStream(bytes);
			oos = new ObjectInputStream(baos);
			TQBATCH batch = (TQBATCH)oos.readObject();
//			batch.restoreConnection(conn);
			return batch;			
		} catch (Exception ex) {
			throw new RuntimeException(ex);
		} finally {
			if(baos!=null) try { baos.close(); } catch (Exception ex) {/* No Op */}
			if(oos!=null) try { oos.close(); } catch (Exception ex) {/* No Op */}
		}		
	}
	
	protected TQBATCH serdeser(final TQBATCH batch, final Connection conn) {
		final long start = System.currentTimeMillis();
		try {
			return deser(ser(batch), conn);
		} finally {
			avgSerDeserTime.update(System.currentTimeMillis() - start);
		}
	}
	
	/**
	 * Processes a batch
	 * @param batchToProcess The batch to process
	 */
	public void processBatch(final byte[] batchToProcess) {   // final TQBATCH batchToProcess
		Connection conn = null;
		OracleConnection oraConn = null;
		PreparedStatement ps = null;
		OracleCallableStatement cs = null;
		ResultSet rs = null;
		TQBATCH preBatch = null;
		TQBATCH postBatch = null;
		try {
			
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
			preBatch = deser(batchToProcess, conn); //serdeser(batchToProcess, conn);
			//preBatch.restoreConnection(oraConn);
			//===========================================================================================
			// 	 PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH);
			//===========================================================================================
			cs = (OracleCallableStatement)oraConn.prepareCall(RELOCK_BATCH_SQL);
			cs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
			cs.setObject(1, preBatch, TQBATCH._SQL_TYPECODE);
//			cs.setORAData(1, preBatch);
			cs.execute();
			//postBatch = (TQBATCH)cs.getORAData(1, tqBatchOraDataFactory);
			postBatch = (TQBATCH)cs.getObject(1);
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
			
			//cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
			cs.setObject(2, postBatch);
//			cs.setORAData(2, postBatch);
			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
			//cs.registerOutParameter(1, TQTRADE_ARR._SQL_TYPECODE, TQTRADE_ARR._SQL_NAME);
			cs.registerOutParameter(1, connPool.ad(TQTRADE.class).getTypeCode(), "TQREACTOR.TQTRADE_ARR");
			cs.execute();
			//return ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
			//trades = ((TQTRADE_ARR)cs.getORAData(1, TQTRADE_ARR.getORADataFactory())).getArray();
			Object[] trs = (Object[])cs.getArray(1).getArray();
			trades = new TQTRADE[trs.length];
			System.arraycopy(trs, 0, trades, 0, trs.length);
			postBatch = (TQBATCH)cs.getObject(2);
			cs.close();
			if(trades.length != Array.getLength(postBatch.getRowids().getArray())) {
//				log.error("Mismatch between trade count [" + trades.length + "] and postBatch stub count [" + postBatch.getRowids().length() + "]. (PreBatch:[" + preBatch.getRowids().length() + "])");
				throw new RuntimeException("Mismatch between trade count [" + trades.length + "], postBatch ROWID count [" + Array.getLength(postBatch.getRowids().getArray()) + "] and postBatch Stub count [" + Array.getLength(postBatch.getStubs().getArray()) + "]");
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
			//cs.setORAData(1, new TQTRADE_ARR(trades));
			cs.setObject(1, new ARRAY(connPool.ad(TQTRADE.class), oraConn, trades));
			cs.setInt(2, postBatch.getBatchId());
			cs.execute();
			cs.close();
			
			
			//===========================================================================================
			//		PROCEDURE FINISHBATCH(batchRowids IN XROWIDS);
			//===========================================================================================						
			cs = (OracleCallableStatement)oraConn.prepareCall(FINISH_BATCH_SQL);
			//cs.setORAData(1, postBatch.getRowids());
			cs.setArray(1, postBatch.getRowids());
			cs.execute();
			cs.close();
			conn.commit();
			//log.info("Batch Complete");
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