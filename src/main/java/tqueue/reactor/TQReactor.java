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
import java.util.Iterator;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.sql.ORADataFactory;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Logger;

import reactor.Environment;
import reactor.fn.Consumer;
import reactor.fn.Function;
import reactor.rx.broadcast.Broadcaster;
import reactor.rx.stream.GroupedStream;
import tqueue.db.types.TQBATCH;
import tqueue.pools.ConnectionPool;

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
			"BEGIN TQV.LOCKBATCH(?, ?); END;";
	

	
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
	private final ORADataFactory tqBatchOraDataFactory = TQBATCH.getORADataFactory();
	
	/** The ID of the last trade batched and retrieved */
	private int lastTradeQueueId = 0;
	/** The poller's maximum number of trades to retrieve in one loop */
	private int maxRows = 1000;
	/** The poller's maximum batch size */
	private int maxBatchSize = 10;
	/** The poller's wait period in seconds when waiting for the next rows to become available */
	private int pollWaitTime = 10;
	/** The poller's maximum wait loops when waiting for the next rows to become available */
	private int pollWaitLoops = 10;
	
	/** Poller thread serial */
	private final AtomicInteger threadSerial = new AtomicInteger(0);
	/** The starting TQUEUE_ID to poll for */
	private final AtomicInteger startId = new AtomicInteger(0);
	/** The numnber of pending tasks in the current loop */
	private final AtomicInteger pending = new AtomicInteger(0);
	

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
	
	/**
	 * Initializes the TQBatch broadcaster
	 */
	protected void initSink() {
		sink = Broadcaster.create(Environment.get(), Environment.cachedDispatcher());
		sink			
			
			.groupBy(new Function<TQBATCH, Integer>() {
				@Override
				public Integer apply(final TQBATCH t) {
					try {
						return t.getAccount()%CORES;
					} catch (Exception ex) {
						throw new RuntimeException(ex);
					} 
				}
			})
			.consume(new Consumer<GroupedStream<Integer, TQBATCH>>(){
				@Override
				public void accept(final GroupedStream<Integer, TQBATCH> t) {
					final Integer key = t.key();
					t.consume(new Consumer<TQBATCH>() {
						@Override
						public void accept(final TQBATCH batch) {					
							try {
								log.info("Consumed Batch [" + key + "]: stubs:" + batch.getTcount() + ", last:" + batch.getLastT());
								Thread.currentThread().join(500);
								
							} catch (Exception ex) {
								throw new RuntimeException(ex);
							}
						}
					});
				}
			});
		
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
				while(pending.get()!=0) {
					Thread.yield();
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
					TQBATCH preBatch = (TQBATCH)pollerRset.getORAData(1, TQBATCH.getORADataFactory());
					if(preBatch.getAccount()==-1) {
						//log.info("Timed out waiting for results");
						break;
					}
					pollerCs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					
					pollerCs.setORAData(1, preBatch);
					pollerCs.setInt(2, 0);
					
					pollerCs.execute();
					TQBATCH postBatch = (TQBATCH)pollerCs.getORAData(1, TQBATCH.getORADataFactory());
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
					sink.onNext(postBatch);
				}
				if(batchCount>0 | dropCount>0) {
				log.info(new StringBuilder("Polling loop: batches:")
					.append(batchCount)
					.append(", stubs:")
					.append(stubCount)
					.append(", drops:")
					.append(dropCount)					
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