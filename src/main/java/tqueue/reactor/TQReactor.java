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

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLTimeoutException;
import java.sql.Timestamp;
import java.util.Random;
import java.util.concurrent.SynchronousQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.sql.ORADataFactory;
import reactor.Environment;
import reactor.core.config.DispatcherType;
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
import tqueue.helpers.JMXHelper;
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
 * TODO:
 * Delete batch refs on start 
 */

public class TQReactor implements TQReactorMBean, Runnable, ThreadFactory {
	/** The TQReactor singleton instance */
	private static volatile TQReactor instance = null;
	/** The TQReactor singleton instance ctor lock */
	private static final Object lock = new Object();
	
	public static final boolean ISWIN = System.getProperty("os.name").toLowerCase().contains("windows");
	
	/** The number of available cpus */
	public static final int CORES = ManagementFactory.getOperatingSystemMXBean().getAvailableProcessors();
	
	/** The batch polling SQL */
	public static final String POLL_BATCH_SQL = 
			"SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) " +
			"FROM TABLE(TQV.QUERYTBATCHES(?, ?, ?, ?)) " +
			"ORDER BY FIRST_T ";
	
	/** The initial lock batch SQL */	
	public static final String LOCK_BATCH_SQL =
			"BEGIN TQV.LOCKBATCHREF(?, ?, ?, ?, ?); END;";
	
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
	/** The trade poller's TQBATCH OraDataFactory */
	private final ORADataFactory tqBatchOraDataFactory;
	/** The trade poller's TQTRADE OraDataFactory */
	private final ORADataFactory tradeOraDataFactory;
	/** The trade poller's TQTRADE_ARR OraDataFactory */
	private final ORADataFactory tradeArrBatchOraDataFactory;
	
	/** The ID of the last trade batched and retrieved */
	private int lastTradeQueueId = 0;
	/** The poller's maximum number of trades to retrieve in one loop */
	private int maxRows = 5000;
	/** The poller's maximum batch size */
	private int maxBatchSize = 50;
	/** The poller's wait period in seconds when waiting for the next rows to become available */
	private int pollWaitTime = 0;
	/** The poller's maximum wait loops when waiting for the next rows to become available */
	private int pollWaitLoops = 10;
	/** The number of parallel streams to run per core */
	private int streamsPerCore = 4;
	
	
	private int loopCount = 0;
	private int lastBatchcount = 0;
	private int batchCount = 0;
	private int stubCount = 0;
	private int dropCount = 0;
	
	
	/** Indicates if the poller config changed */
	private final AtomicBoolean pollerConfigChanged = new AtomicBoolean(false);
	
	
	Control ctx = null;
	
	/** The thread factory for the ring buffer's executor service */
	protected final ThreadFactory tf = new ThreadFactory() {
		final AtomicInteger serial = new AtomicInteger(0);
		@Override
		public Thread newThread(final Runnable r) {
			Thread t = new Thread(r, "TQReactorThread#" + serial.incrementAndGet());
			t.setDaemon(true);
			return t;
		}
	};
	/** The thread pool for the ring buffer */
	protected ThreadPoolExecutor tpe = null;
	
	/** The ring buffer processor */
	//protected Broadcaster<BatchRoutingKey> ringBuffer = null;
	protected RingBufferWorkProcessor<BatchRoutingKey> ringBuffer = null;
	
	/** Flag indicating the poller has been reset */
	protected final AtomicBoolean resetFlag = new AtomicBoolean(false);
	
	
	
	/** Random generator to throw exceptions */
	protected final Random random = new Random(System.currentTimeMillis());
	
	
	
	
	
	/** Poller thread serial */
	private final AtomicInteger threadSerial = new AtomicInteger(0);
	/** The starting TQUEUE_ID to poll for */
	private final HighwaterNextId nextPollId = new HighwaterNextId();
	
	/** The metric registry */
	private final MetricRegistry registry;
	
	/** The inflight gauge */
	private final AtomicInteger inFlight = new AtomicInteger(0);
	/** Recoverable exception count */
	private final AtomicInteger recovErrs = new AtomicInteger(0);
	/** Unrecoverable exception count */
	private final AtomicInteger unrecovErrs = new AtomicInteger(0);
	/** Batch in process concurrency */
	private final AtomicInteger batchProcessingConcurrency = new AtomicInteger(0);
	

	/** A meter of trades per/s */
	private final Meter tradesPerSec;
	/** A meter of batches per/s */
	private final Meter batchesPerSec;
	/** A meter of loop read batches */
	private final Meter readBatchesPerSec;
	
	/** A histogram of batch sizes (trades per batch) */
	private final Histogram avgBatchSize;
	/** A histogram of batch processing times */
	private final Histogram avgBatchProcessingTime;
	/** A histogram of trade processing times */
	private final Histogram avgTradeProcessingTime;
	/** A histogram of event publishing back-pressure */
	private final Histogram avgBackPressureTime;
	/** A meter of polling stored proc invocation time in ms */
	private final Histogram pollingExecTimeMs;
	/** A histogram of times to first result in the poller query in ms */
	private final Histogram timeToFirstResultSetMs;
	/** A histogram of times to the next result in the poller query in ms */
	private final Histogram timeToNextResultSetMs;
	/** A histogram of the number of rows retrieved in each poller query */
	private final Histogram resultSetCount;
	/** A histogram of the amount of time a BatchRoutingKey spends in the stream */
	private final Histogram batchRouteKeyStreamTime;
	
	/** The number of rows retrieved during the current result set iteration */
	private int rowCount = 0;
	
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
	
	protected static final String HAWT_WAR = "/home/nwhitehead/.m2/repository/io/hawt/hawtio-web/1.4.19/hawtio-web-1.4.19.war";
	protected static final String WIN_HAWT_WAR = "c:\\users\\nwhitehe\\.m2\\repository\\io\\hawt\\hawtio-web\\1.4.19\\hawtio-web-1.4.19.war";

	
	public static void main(String[] args) {
		
		final Logger logx = LoggerFactory.getLogger(TQReactor.class);
		
		final io.hawt.embedded.Main main = new io.hawt.embedded.Main();
		main.setWar(ISWIN ? WIN_HAWT_WAR : HAWT_WAR);
		main.setPort(9090);
		//main.setContextPath("/");
		System.setProperty("hawtio.authenticationEnabled", "false");
		Thread bootThread = new Thread("HeliosJMXBootStrap") {
			public void run() {
				try {
					main.run();
				} catch (Exception ex) {
					//log.error("Failed to boot hawt", ex);
				}
			}
		};
		bootThread.start();
		
//		BasicConfigurator.configure();
		TQReactor tqr = TQReactor.getInstance();
		tqr.log.info("TQReactor Test");
		try {
			tqr.start();
			//tqr.pollerThread.join();
			tqr.clHandler();
		} catch (Exception ex) {
			ex.printStackTrace(System.err);
		}
	}
	
	private void clHandler() {			
		try {
			final BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
			String line = null;
			while(true) {
				line = br.readLine();
				if(line!=null) {
					
					if("r".equalsIgnoreCase(line)) {
						reset();
					} else if("rr".equalsIgnoreCase(line)) {
						reset(0);
					} else if("exit".equalsIgnoreCase(line)) {						
						log.info("\n\t===========================================\n\tReactor Environment Shutting Down ......\n\t===========================================");
						Environment.get().shutdown();
						log.info("Shutdown Complete. Exiting....");
						System.exit(0);
					}
				}
			}
		} catch (Exception ex) {
			System.err.println("CL Command Handler Failed");
			ex.printStackTrace(System.err);
		}
	}
	
	/*
	 * Error when cancelling waiting query:
java.sql.SQLTimeoutException: ORA-01013: user requested cancel of current operation
ORA-06512: at "SYS.DBMS_ALERT", line 118
ORA-06512: at "TQREACTOR.TQV", line 270
ORA-20000: ORU-10015: error:3 waiting for pipe message.
ORA-06512: at "TQREACTOR.TQV", line 314
ORA-06512: at line 1

	at oracle.jdbc.driver.T4CTTIoer.processError(T4CTTIoer.java:440)
	at oracle.jdbc.driver.T4CTTIoer.processError(T4CTTIoer.java:396)
	at oracle.jdbc.driver.T4C8Oall.processError(T4C8Oall.java:837)
	at oracle.jdbc.driver.T4CTTIfun.receive(T4CTTIfun.java:445)
	at oracle.jdbc.driver.T4CTTIfun.doRPC(T4CTTIfun.java:191)
	at oracle.jdbc.driver.T4C8Oall.doOALL(T4C8Oall.java:523)
	at oracle.jdbc.driver.T4CPreparedStatement.doOall8(T4CPreparedStatement.java:207)
	at oracle.jdbc.driver.T4CPreparedStatement.executeForDescribe(T4CPreparedStatement.java:863)
	at oracle.jdbc.driver.OracleStatement.executeMaybeDescribe(OracleStatement.java:1153)
	at oracle.jdbc.driver.OracleStatement.doExecuteWithTimeout(OracleStatement.java:1275)
	at oracle.jdbc.driver.OraclePreparedStatement.executeInternal(OraclePreparedStatement.java:3576)
	at oracle.jdbc.driver.OraclePreparedStatement.executeQuery(OraclePreparedStatement.java:3620)
	at oracle.jdbc.driver.OraclePreparedStatementWrapper.executeQuery(OraclePreparedStatementWrapper.java:1491)
	at tqueue.reactor.TQReactor.run(TQReactor.java:552)
	at java.lang.Thread.run(Thread.java:745)
	 */
	
	private TQReactor() {
		Environment.initializeIfEmpty().assignErrorJournal(new Consumer<Throwable>(){
			@Override
			public void accept(final Throwable t) {
				//log.error("Untrapped exception", t);				
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
				return nextPollId.get();
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
		batchRouteKeyStreamTime = registry.histogram("batchRouteKeyStreamTime");
		pollingExecTimeMs = registry.histogram("pollingExecTimeMs");
		readBatchesPerSec = registry.meter("readBatchesPerSec"); 
		timeToFirstResultSetMs = registry.histogram("timeToFirstResultSetMs");
		timeToNextResultSetMs = registry.histogram("timeToNextResultSetMs");
		resultSetCount = registry.histogram("resultSetCount");
		
		JMXHelper.registerMBean(this, OBJECT_NAME);
		
		
		
		
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
			System.err.println("\n\t===================\n\tTQReactor SHUTTING DOWN !!\n\t===================");
			try { pollerThread.interrupt(); } catch (Exception x) {/* No Op */}
			Environment.get().shutdown();
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
		

	public void process(final BatchRoutingKey batch) {
		final int tcount = batch.getTcount();
//		log.info("[" + Thread.currentThread().getName() + "] Processing [" + tcount + "] Trades for [" + batch.getAccountId() + "]");
		tradesPerSec.mark(tcount);
		batchesPerSec.mark();
		avgBatchSize.update(tcount);

		processBatch(batch);
		
		inFlight.decrementAndGet();
		nextPollId.update(batch.getFirstTrade());
		batchProcessingConcurrency.decrementAndGet();
	}
	
	public void onException(final Throwable err) {
			TQException tqe = null;
			if(err instanceof TQException) {
				tqe = (TQException)err;			
			} else if(err.getCause() != null && (err.getCause() instanceof TQException)) {
					tqe = (TQException)err.getCause();			
			} else {
				log.error("Unknown TQ processing exception", err);
				return;
			}
			final BatchRoutingKey brk = tqe.getBatch();
			nextPollId.fail(brk.getFirstTrade());
			if(tqe.isRecoverable()) {
				recovErrs.incrementAndGet();
				try {
					reset();
				} catch (Exception ex) {
					log.error("Failed to reset ps", ex);
				}
	
				// reset the poller. trades will be re-processed.
			} else {
				unrecovErrs.incrementAndGet();
				// trades are not recoverable. Save them in a FAILED state
				failBatch(brk, tqe);
			}
			batchProcessingConcurrency.decrementAndGet();
		//err.printStackTrace(System.err);
		// FIXME:  Need to reset the poller
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
//		final int totalStreams = CORES * streamsPerCore;
		final int totalStreams = CORES;
//		final int totalStreams = 4;
//		final int totalStreams = 6;
		final int ringBufferSize = findNextPositivePowerOfTwo(totalStreams);
		log.info("\n\t=====================================\n\tRingBuffer Slots:" + ringBufferSize + "\n\t=====================================");
		tpe = new ThreadPoolExecutor(1, 1, 60, TimeUnit.SECONDS, new SynchronousQueue<Runnable>(), tf);
//		tpe.prestartAllCoreThreads();
		ringBuffer = RingBufferWorkProcessor.create("ringbuff", CORES*2); 
				// Broadcaster.create(Environment.newDispatcher("tqdispatcher", 32*totalStreams, totalStreams, DispatcherType.RING_BUFFER));
				//RingBufferWorkProcessor.create(tpe, ringBufferSize, new ParkWaitStrategy());
		
		ctx = Streams.wrap(ringBuffer)
			.groupBy(brk -> brk.getAccountId() % totalStreams)			
			.observe(sg -> sg.observe(brk -> inFlight.incrementAndGet()))
			.consume(groupedStream -> 
				groupedStream
					.dispatchOn(Environment.get(), Environment.newDispatcher("tqprocessor", 32, 1, DispatcherType.RING_BUFFER))
					.consume(						
						brk -> {
							batchProcessingConcurrency.incrementAndGet();
							process(brk);
						},
						t -> onException(t)						
				)
			);
		
//	final Map<Integer, Consumer<BatchRoutingKey>> groupConsumers = new HashMap<Integer, Consumer<BatchRoutingKey>>(totalStreams);
//	for(int i = 0; i < totalStreams; i++) {
//		final int k = i;
//		groupConsumers.put(i, new Consumer<BatchRoutingKey>(){
//			final Dispatcher dispatcher = Environment.newDispatcher(1, 1, DispatcherType.RING_BUFFER);
//			@Override
//			public void accept(final BatchRoutingKey batch) {							
//				dispatcher.dispatch(batch, batchConsumer(k), errorConsumer(k));					
//			}
//		});			
//	}
//		ctx = Streams.wrap(ringBuffer)
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
//			.groupBy(groupFunction(totalStreams))
//			.consume(new Consumer<GroupedStream<Integer, BatchRoutingKey>>() {
//				@Override
//				public void accept(final GroupedStream<Integer, BatchRoutingKey> t) {
//					t.capacity(1).consume(groupConsumers.get(t.key()));					
//				}
//			});
				
		
//		ringBuffer.subscribe(sink);
		log.info("Control:\n" + ctx.debug().toString());
		log.info("Sink created");		
	}
	
	/**
	 * Resets the polling loop and the starting id
	 */
	public void reset(final int nextId) {
		if(resetFlag.compareAndSet(false, true)) {
			try {
				nextPollId.reset(nextId);
				try { pollerPs.cancel(); } catch (Exception x) {/* No Op */}
				log.info("\n\tPOLLER RESET. Next ID:" + nextPollId.get() + "\n");
			} catch (Exception ex) {
				log.error("Failed to cancel poller Cs:", ex);
			}
		}
	}
	
	
	
	/**
	 * Resets the polling loop
	 */
	public void reset() {
		if(resetFlag.compareAndSet(false, true)) {
			try {
				nextPollId.reset();
				try { pollerPs.cancel(); } catch (Exception x) {/* No Op */}
				log.info("\n\tPOLLER RESET. Next ID:" + nextPollId.get() + "\n");
			} catch (Exception ex) {
				log.error("Failed to cancel poller Cs:", ex);
			}
		}
	}
	
	/**
	 * Runs the TQReactor::TQPoller polling loop in the polling thread.
	 * {@inheritDoc}
	 * @see java.lang.Runnable#run()
	 */
	@Override
	public void run() {
		
		while(started.get()) {
			if(inFlight.get() > 0) {				
				final long start = System.currentTimeMillis();
				long wt = start;
//				while(inFlight.get() > 0) {
//					if(resetFlag.get()) break;
//					if(System.currentTimeMillis() > (wt + 10000)) {
//						log.warn("Polling Barrier Wait has waited for 10s.");
//						wt = System.currentTimeMillis();
//					}
//					Thread.yield();
//				}
				resetFlag.set(false);
//				final long elapsed = System.currentTimeMillis()-start;
//				pollingWaitTimeMs.update(elapsed);				
//				log.info("Waited on poller barrier. Wait: [{}] ms. Conc: [{}], Start ID: [{}]", new Object[]{ elapsed, batchProcessingConcurrency.get(), nextPollId.get()});
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
				if(pollerPs==null) try { pollerPs = (OraclePreparedStatement)pollerConnection.prepareStatement(POLL_BATCH_SQL); } catch (Exception x) {/* No Op */}
			
//				if(resetFlag.get()) break;
				pollerPs.setInt(1, nextPollId.get());
				pollerPs.setInt(1, 0);
				pollerPs.setInt(2, maxRows);
				pollerPs.setInt(3, maxBatchSize);
				pollerPs.setInt(4, pollWaitTime);			
				
				final long execStart = System.currentTimeMillis();
				try {
					pollerRset = (OracleResultSet)pollerPs.executeQuery();
					rowCount = 0;
					pollingExecTimeMs.update(System.currentTimeMillis() - execStart);
				} catch (SQLTimeoutException sto) {
					reInitPoller();
					continue;
				}

				
				pollerRset.setFetchSize(maxBatchSize);
				int batchCount = 0;
				int stubCount = 0;
				int dropCount = 0;
				int rsetLoops = 0;
				final long rsetStart = System.currentTimeMillis();
				while(pollerRset!=null && pollerRset.next()) {
					readBatchesPerSec.mark();
					if(rowCount==0) {
						timeToFirstResultSetMs.update(System.currentTimeMillis() - rsetStart);
					} else {
						timeToNextResultSetMs.update(System.currentTimeMillis() - rsetStart);
					}
					rowCount++;
					if(!started.get() || resetFlag.get()) {
						break;
					}
					TQBATCH preBatch = (TQBATCH)pollerRset.getORAData(1, tqBatchOraDataFactory);
					if(preBatch.getAccount()==-1) {
						//log.info("Timed out waiting for results");
						break;
					}
					rsetLoops++;
					
					// ===========================================================================
					//   PROCEDURE LOCKBATCHREF(batch IN TQBATCH, accountId OUT INT, tcount OUT INT, firstTrade OUT INT, xrowid OUT VARCHAR2) IS 
					// 	 BEGIN TQV.LOCKBATCHREF(?, ?, ?, ?, ?); END;
					// ===========================================================================
					
//					pollerCs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					pollerCs.registerOutParameter(2, DBType.INTEGER.typeCode);
					pollerCs.registerOutParameter(3, DBType.INTEGER.typeCode);
					pollerCs.registerOutParameter(4, DBType.INTEGER.typeCode);
					pollerCs.registerOutParameter(5, DBType.VARCHAR.typeCode);
				
					pollerCs.setORAData(1, preBatch);
					try {
						pollerCs.execute();
					}  catch (SQLTimeoutException sto) {
						reInitPoller();
						continue;
					}
					if(resetFlag.get()) break;
					final String rowid = pollerCs.getString(5);
					final int accountId = pollerCs.getInt(2);
					final int tcount = pollerCs.getInt(3);
					final int firstTrade = pollerCs.getInt(4);
					 
					if(rowid==null) {
						continue;
					}
					stubCount += tcount;
					//TQBATCH postBatch = (TQBATCH)pollerCs.getORAData(2, tqBatchOraDataFactory);
//					final int firstTrade = postBatch.getFirstT();					
					batchCount++;
					pollerConnection.commit();
//					avgRingBufferCap.update(ringBuffer.getAvailableCapacity());
					final long start = System.currentTimeMillis();
					if(resetFlag.get()) break;
					final BatchRoutingKey brk = new BatchRoutingKey(rowid, accountId, tcount, firstTrade); 
					ringBuffer.onNext(brk);	
					//log.info("Dispatched {}", brk);
					final long elapsed = System.currentTimeMillis() - start;
					inFlight.incrementAndGet();
					avgBackPressureTime.update(elapsed);
					inFlight.incrementAndGet();
									
				}  //  end of result set loop
				
				if(loopCount>0 && rsetLoops > 0) {
					resultSetCount.update(rowCount);
					log.info("========================================== Loop:" + loopCount + ", Batches:" + rsetLoops + " rowCount:" + rowCount);
				}
				rowCount = 0;

				loopCount++;
				pollerRset.close();
				if(batchCount>0 | dropCount>0) {
					log.info(new StringBuilder("Polling loop: batches:")
						.append(batchCount)
						.append(", stubs:")
						.append(stubCount)
						.append(", drops:")
						.append(dropCount)
//						.append(", cap:")
//						.append(ringBuffer.getAvailableCapacity())					
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
			}	finally {
				loopCount = 0;
				lastBatchcount = 0;
				
			}
		}  // end of polling loop
		log.info("TQReactor::TQPoller Polling Thread Ended", new Throwable());
		pollerThread = null;
	}
	
	/**
	 * Cleans up the polling JDBC resources and then re-initializes.
	 */
	protected void reInitPoller() {
		cleanupPoller();
		initPoller();
		resetFlag.set(false);
		
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
	 * Fails a batch
	 * @param batchKey The batch to fail
	 * @param err The underlying exception. Used to derive error message
	 * FIXME: failBatch and processBatch have a lot of overlap
	 */
	public void failBatch(final BatchRoutingKey batchKey, final TQException err) {
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
		        tqt.setStatusCode("FAILED");
		        tqt.setErrorMessage(trimMsg(err));
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
			//avgBatchProcessingTime.update(elapsedTime);
			try {
				//avgTradeProcessingTime.update(elapsedTime/batchKey.getTcount());
			} catch (Exception x) {/* No Op */}
		} catch (Exception ex) {
//			log.error("Failed to process batch", ex);
			//throw new RuntimeException("Failed to process batch [" + postBatch + "]", ex);
			log.error("\n\t=====================================================================\n\t!!!!!!!!!!!!!!!!\n\tFAILED TO SAVE FAILED BATCH\n\t!!!!!!!!!!!!!!!\n\t=====================================================================\n", ex);
		} finally {
			inFlight.decrementAndGet();
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(cs!=null) try { cs.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.rollback(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}			
		}
	}
	
	/** The maximum number of bytes in an error message */
	protected int maxErrMsgSize = 512;
	
	protected String trimMsg(final Throwable t) {
		if(t==null) return "Unknown Error";
		String msg = t.getMessage();
		if(msg==null || msg.trim().isEmpty()) {
			msg = t.toString();
		}
		if(msg.length() > maxErrMsgSize) {
			msg = msg.substring(0, maxErrMsgSize);
		}
		return msg;
	}
	
	
	
	/**
	 * Processes a batch
	 * @param batchKey The batch to process
	 */
	public void processBatch(final BatchRoutingKey batchKey) {   // --   58 to 60 ms. per execution
		//if(1==1) return;
		Connection conn = null;
		OracleConnection oraConn = null;
		OraclePreparedStatement ps = null;
		OracleCallableStatement cs = null;
		OracleResultSet rs = null;
		TQBATCH preBatch = null;
		TQBATCH postBatch = null;
		try {
			//log.info("Processing {}", batchKey);
			batchRouteKeyStreamTime.update(batchKey.getElapsedSinceCreate());
			final long startTime = System.currentTimeMillis();
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
//			final int errCond = Math.abs(random.nextInt(100));
			// This means reset the poller and reprocess
//			if(errCond == 7) throw new RecoverableTQException(batchKey, "Yikes. A recoverable error.");
			// This means mark the trades as failed
//			if(errCond == 9) throw new UnrecoverableTQException(batchKey, "Yikes!! An unrecoverable error.");
			// "DELETE FROM TQBATCHES T WHERE ROWID = CHARTOROWID(?) RETURNING VALUE(T) INTO ?";
//			ps = (OraclePreparedStatement)oraConn.prepareStatement(DEREF_BATCH_KEY_SQL);
//			ps.setString(1, batchKey.getRowid());
//			ps.registerReturnParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);			
//			ps.execute();
//			rs = (OracleResultSet)ps.getReturnResultSet();
//			rs.next();
//			preBatch = (TQBATCH)rs.getORAData(1, tqBatchOraDataFactory);
//			rs.close();
//			ps.close();
//			rs = null;
//			ps = null;
//			
//			
//			//preBatch.restoreConnection(oraConn);
//			//===========================================================================================
//			// 	 PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH);
//			//===========================================================================================
//			cs = (OracleCallableStatement)oraConn.prepareCall(RELOCK_BATCH_SQL);
//			cs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
//			cs.setObject(1, preBatch, TQBATCH._SQL_TYPECODE);
////			cs.setORAData(1, preBatch);
//			cs.execute();			
//			postBatch = (TQBATCH)cs.getORAData(1, tqBatchOraDataFactory);
//			cs.close();
//			if(postBatch.getTcount() != preBatch.getTcount()) {
//				int dropCount = (preBatch.getTcount() - postBatch.getTcount());
//				//System.err.println("RE-Lock Drops:" + dropCount);
//			}
//			cs = null;
//			//===========================================================================================
//			//		FUNCTION STARTBATCH(tqbatch IN OUT TQBATCH) RETURN TQTRADE_ARR;
//			//===========================================================================================
//			TQTRADE[] trades = null;
//			cs = (OracleCallableStatement)oraConn.prepareCall(START_BATCH_SQL);
//			
//			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
//			cs.setObject(2, postBatch, TQBATCH._SQL_TYPECODE);
////			cs.setORAData(2, postBatch);
//			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
//			cs.registerOutParameter(1, TQTRADE_ARR._SQL_TYPECODE, TQTRADE_ARR._SQL_NAME);
//			cs.execute();
//			//return ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
//			trades = ((TQTRADE_ARR)cs.getORAData(1, TQTRADE_ARR.getORADataFactory())).getArray();
//			postBatch = (TQBATCH)cs.getORAData(2, tqBatchOraDataFactory);
//			cs.close();
//			if(trades.length != postBatch.getRowids().length()) {
//				log.error("Mismatch between trade count [" + trades.length + "] and postBatch stub count [" + postBatch.getRowids().length() + "]. (PreBatch:[" + preBatch.getRowids().length() + "])");
//				throw new RuntimeException("Mismatch between trade count [" + trades.length + "], postBatch ROWID count [" + postBatch.getRowids().length() + "] and postBatch Stub count [" + postBatch.getStubs().length() + "]");
//			}
//			cs = null;

			
			//===========================================================================================
			//		FUNCTION STARTBATCH(tqBatchRowId IN VARCHAR2, batchId OUT INT) RETURN TQTRADE_ARR 
			//===========================================================================================

			cs = (OracleCallableStatement)oraConn.prepareCall("BEGIN ? := TQV.STARTBATCH(?, ?); END;");
			cs.registerOutParameter(1, TQTRADE_ARR._SQL_TYPECODE, TQTRADE_ARR._SQL_NAME);
			cs.registerOutParameter(3, DBType.INTEGER.typeCode); 
			cs.setString(2, batchKey.getRowid());
			cs.execute();
			final TQTRADE[] trades = ((TQTRADE_ARR)cs.getORAData(1, TQTRADE_ARR.getORADataFactory())).getArray();
			final int batchId = cs.getInt(3);
			cs.close();
			
			
			
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
			cs.setInt(2, batchId);
			cs.execute();
			cs.close();
			cs = null;
			
			
			//===========================================================================================
			//		PROCEDURE FINISHBATCH(batchRowids IN XROWIDS);
			//===========================================================================================						
//			cs = (OracleCallableStatement)oraConn.prepareCall(FINISH_BATCH_SQL);
//			cs.setORAData(1, postBatch.getRowids());
//			cs.execute();
//			cs.close();
			
			
			conn.commit();
			conn.close();
			
			cs = null;
			conn = null;
			inFlight.decrementAndGet();
			//log.info("Batch Complete");
			final long elapsedTime = System.currentTimeMillis() - startTime;
			avgBatchProcessingTime.update(elapsedTime);
			try {
				avgTradeProcessingTime.update(elapsedTime/batchKey.getTcount());
			} catch (Exception x) {/* No Op */}
		} catch (Exception ex) {
//			log.error("Failed to process batch", ex);
			throw new RuntimeException("Failed to process batch [" + postBatch + "]", ex);
		} finally {
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(cs!=null) try { cs.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.rollback(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}			
		}
	}
	

	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getActiveCount()
	 */
	@Override
	public int getActiveCount() {		
		return tpe.getActiveCount();
	}	
	
	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getCompletedTaskCount()
	 */
	@Override
	public long getCompletedTaskCount() {
		return tpe.getCompletedTaskCount();
	}
	
	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getCorePoolSize()
	 */
	@Override
	public int getCorePoolSize() {
		return tpe.getCorePoolSize();
	}

	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getLargestPoolSize()
	 */
	@Override
	public int getLargestPoolSize() {
		return tpe.getLargestPoolSize();
	}
	
	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getMaximumPoolSize()
	 */
	@Override
	public int getMaximumPoolSize() {		
		return tpe.getMaximumPoolSize();
	}
	
	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getPoolSize()
	 */
	@Override
	public int getPoolSize() {		
		return tpe.getPoolSize();
	}
	
	/**
	 * {@inheritDoc}
	 * @see tqueue.reactor.TQReactorMBean#getTaskCount()
	 */
	@Override
	public long getTaskCount() {
		return tpe.getTaskCount();
	}

	/**
	 * Returns the max number of rows to poll from the DB
	 * @return the maxRows
	 */
	@Override
	public int getMaxRows() {
		return maxRows;
	}

	/**
	 * Sets the max number of rows to poll from the DB
	 * @param maxRows the maxRows to set
	 */
	@Override
	public void setMaxRows(final int maxRows) {
		if(maxRows < 1) throw new IllegalArgumentException("Invalid max Rows count:" + maxRows);
		pollerConfigChanged.set(maxRows != this.maxRows);		
		this.maxRows = maxRows;
	}

	/**
	 * Returns the maximum batch size to retrieve from the DB
	 * @return the maxBatchSize
	 */
	@Override
	public int getMaxBatchSize() {
		return maxBatchSize;
	}

	/**
	 * Sets the maximum batch size to poll from the DB 
	 * @param maxBatchSize the maxBatchSize to set
	 */
	@Override
	public void setMaxBatchSize(final int maxBatchSize) {
		if(maxBatchSize < 1) throw new IllegalArgumentException("Invalid max batch size:" + maxBatchSize);
		pollerConfigChanged.set(maxBatchSize != this.maxBatchSize);
		this.maxBatchSize = maxBatchSize;
		this.maxBatchSize = maxBatchSize;
	}

	/**
	 * Returns the poller wait time on the DB side in seconds
	 * @return the pollWaitTime
	 */
	@Override
	public int getPollWaitTime() {
		return pollWaitTime;
	}

	/**
	 * Sets the poller wait time on the DB side in seconds
	 * @param pollWaitTime the pollWaitTime to set in seconds
	 */
	@Override
	public void setPollWaitTime(final int pollWaitTime) {
		if(pollWaitTime < 0) throw new IllegalArgumentException("Invalid wait time:" + pollWaitTime);
		pollerConfigChanged.set(pollWaitTime != this.pollWaitTime);
		this.pollWaitTime = pollWaitTime;
	}

	@Override
	public int getInflightBatchCount() {		
		return inFlight.get();
	}

	/**
	 * Returns 
	 * @return the loopCount
	 */
	public int getLoopCount() {
		return loopCount;
	}

	/**
	 * Returns 
	 * @return the lastBatchcount
	 */
	public int getLastBatchcount() {
		return lastBatchcount;
	}

	/**
	 * Returns 
	 * @return the batchCount
	 */
	public int getBatchCount() {
		return batchCount;
	}

	/**
	 * Returns 
	 * @return the stubCount
	 */
	public int getStubCount() {
		return stubCount;
	}

	/**
	 * Returns 
	 * @return the dropCount
	 */
	public int getDropCount() {
		return dropCount;
	}
	
	
	/**
	 * Returns the total number of recoverable TQ exceptions
	 * @return the total number of recoverable TQ exceptions
	 */
	public int getRecovErrs() {
		return recovErrs.get();
	}

	/**
	 * Returns the total number of unrecoverable TQ exceptions
	 * @return the unrecovErrs the total number of unrecoverable TQ exceptions
	 */
	public int getUnrecovErrs() {
		return unrecovErrs.get();
	}
	
	/**
	 * Returns the starting range of the next poll
	 * @return the starting range of the next poll
	 */
	public int getNextPollerStart() {
		return nextPollId.get();
	}

	/**
	 * Returns the current total number of threads processing batches
	 * @return the current total number of threads processing batches
	 */
	public int getBatchProcessingConcurrency() {
		return batchProcessingConcurrency.get();
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