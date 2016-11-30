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
package tqueue.db;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.jdbc.OracleConnection;
import tqueue.db.types.TQBATCH;
import tqueue.db.types.TQUEUE_OBJ;
import tqueue.pools.ConnectionPool;

/**
 * <p>Title: OracleAdapter</p>
 * <p>Description: </p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.db.OracleAdapter</code></p>
 * TODO:  type repo, plsql call, returns, arr binding
 */

public class OracleAdapter {
	/** Instance logger */
	private final Logger log = LoggerFactory.getLogger(getClass());
	
	/** The number of TQ threads to run */
	public static final int CORE_POOL_SIZE = 1; //Runtime.getRuntime().availableProcessors() * 2;
	
	public static final int MAX_BATCH_ROWS = 1024;
	public static final int ORA_HASH_BUCKETS = 999999;
	public static final int BATCH_FETCH_SIZE = 1024;
	
	
	
	public static final String POLL_BATCH_SQL = "SELECT VALUE(X) FROM TABLE(TQ.GROUP_TQBATCHES(?,?,?,?)) X";
	public static final String RESOLVE_BATCH_SQL = "SELECT VALUE(T) FROM TABLE(TQ.PIPE_TRADE_BATCH(?)) T";
	
	protected final ThreadFactory tf = new ThreadFactory() {
		final AtomicInteger serial = new AtomicInteger(0);
		public Thread newThread(final Runnable r) {
			Thread t = new Thread(r, "TQReactorThread#" + serial.incrementAndGet());
			t.setDaemon(true);
			return t;
		}
	};
	/** The TQ thread pool */
	protected final ThreadPoolExecutor tpe = new ThreadPoolExecutor(CORE_POOL_SIZE, 24, 60, TimeUnit.SECONDS, new ArrayBlockingQueue<Runnable>(10240, false ), tf);
	/* The run indicator */
	protected final AtomicBoolean tqProcessorActive = new AtomicBoolean(true);
	
	public static void main(String[] args) {		
		OracleAdapter oa = new OracleAdapter();
		oa.tpe.prestartAllCoreThreads();
		oa.tpe.execute(oa.newTQRunnable(0));
		try { Thread.currentThread().join(); } catch (Exception x) {/* No Op */}
//		oa.getTQBatches(0, 20000, 50, 5);		
//		final int warmups = 1000;
//		final int loops = 1000;
//		for(int i = 0; i < warmups; i++) {
//			TQSTUB[] stubs = oa.getTQStubsA(1000);
//			Object[] jstubs = oa.getTQStubsJ(1000);
//		}
//		oa.log.info("WARMUP COMPLETE");
//		long start = System.currentTimeMillis();
//		for(int i = 0; i < loops; i++) {
//			TQSTUB[] stubs = oa.getTQStubsA(1000);
//		}
//		long elapsed = System.currentTimeMillis() - start;
//		oa.log.info("Local:" + elapsed);
//		start = System.currentTimeMillis();
//		for(int i = 0; i < loops; i++) {
//			Object[] stubs = oa.getTQStubsJ(1000);
//		}
//		elapsed = System.currentTimeMillis() - start;
//		oa.log.info("Local:" + elapsed);
//		
//		//oa.log.info("Acquired [" + stubs.length + "] TQSTUBs");
//		
//		//oa.log.info("Acquired [" + jstubs.length + "] TQSTUBs");
		
		
		/*
  	EXECUTE IMMEDIATE 'truncate table event';
    SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) 
      BULK COLLECT INTO batches
      FROM TABLE(TQV.QUERYTBATCHES(lastProcessed, 5000, 100))    -- STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10
      ORDER BY FIRST_T;
    TQV.LOCKBATCHES(batches);
    FOR i in 1..batches.COUNT LOOP
      TQV.RELOCKBATCH(batches(i));
      trades := TQV.STARTBATCH(batches(i));
      now := SYSDATE;
      // =======
      // PROCESS
      // =======
      FOR x in 1..trades.COUNT LOOP
        trades(x).STATUS_CODE := 'CLEARED';
        trades(x).UPDATE_TS :=  now;
      END LOOP;
      // =======
      TQV.SAVETRADES(trades, batches(i).BATCH_ID);  
      TQV.FINISHBATCH(batches(i).ROWIDS);
      COMMIT;
      
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
			ps = oraConn.prepareStatement(POLL_BATCH_SQL);			
			csRelock = (OracleCallableStatement)oraConn.prepareCall(LOCK_BATCH_SQL);
			/*
			 * Need to catch this and continue
			 * Caused by: java.sql.SQLException: ORA-04068: existing state of packages has been discarded
			 * ORA-04061: existing state of package body "TQREACTOR.TQV" has been invalidated
			 * ORA-04065: not executed, altered or dropped package body "TQREACTOR.TQV"
			 * ORA-06508: PL/SQL: could not find program unit being called: "TQREACTOR.TQV"
			 * ORA-06512: at line 1
			 */
			
//		TQBATCH preBatch = (TQBATCH)((OracleResultSet)rs).getORAData(1, TQBATCH.getORADataFactory());
//		csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
//		
//		csRelock.setORAData(1, preBatch);
//		csRelock.setInt(2, 0);
      
//		conn = ConnectionPool.getInstance().getConnection();
//		oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);

//		 */
		
	}
	
//	public static final int MAX_BATCH_ROWS = 1024;
//	public static final int ORA_HASH_BUCKETS = 999999;
//	public static final int BATCH_FETCH_SIZE = 1024;
	
	
	/**
	 * Creates a TQ processor runnable
	 * @param processorId The processor id
	 * @return the TQ processor runnable
	 */
	public Runnable newTQRunnable(final int processorId) {
		return new Runnable() {
			public void run() {
				Connection conn = null;
				OracleConnection oraConn = null;
				PreparedStatement batchPs = null;
				ResultSet batchRset = null;
				PreparedStatement resolvePs = null;
				ResultSet resolveRset = null;
				try {
					conn = ConnectionPool.getInstance().getConnection();
					oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
					long batches = 0L;
					long trades = 0L;
					while(tqProcessorActive.get()) {
						try {
							resolvePs = conn.prepareStatement(RESOLVE_BATCH_SQL);
							batchPs = conn.prepareStatement(POLL_BATCH_SQL);
							batchPs.setInt(1, processorId);
							batchPs.setInt(2, MAX_BATCH_ROWS);
							batchPs.setInt(3, CORE_POOL_SIZE);
							batchPs.setInt(4, ORA_HASH_BUCKETS);
							batchRset = batchPs.executeQuery();
							batchRset.setFetchSize(BATCH_FETCH_SIZE);
							while(batchRset.next()) {
								final TQBATCH batch = batchRset.getObject(1, TQBATCH.class);
								batches++;
								//log.info("BATCH: {}", batch);
								resolvePs.setObject(1, batch.getTqrowids());
								resolveRset = resolvePs.executeQuery();
								while(resolveRset.next()) {
									final TQUEUE_OBJ trade = resolveRset.getObject(1, TQUEUE_OBJ.class);
									trades++;
									//log.info("\nTRADE: {}", trade);
									trade.release();
								}
								batch.release();
							}
						} catch (Exception ex) {
							log.error("TQProcessor#{} Loop Error", processorId, ex);
						} finally {
							if(batchRset!=null) try { batchRset.close(); } catch (Exception x) {/* No Op */}
							if(resolveRset!=null) try { resolveRset.close(); } catch (Exception x) {/* No Op */}
							if(batchPs!=null) try { batchPs.close(); } catch (Exception x) {/* No Op */}							
							if(resolvePs!=null) try { resolvePs.close(); } catch (Exception x) {/* No Op */}
						}
					}
				} finally {
					if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
				}
				log.info("TQProcessor#{} Terminated", processorId);
			}
		};
	}
	

	
	public <T> T[] toArray(final Class<T> type, final Object...arr) {
		T[] rarr = null;
		if(arr==null || arr.length==0) {
			rarr = (T[])java.lang.reflect.Array.newInstance(type, 0);
		} else {
			rarr = (T[])java.lang.reflect.Array.newInstance(type, arr.length);
			System.arraycopy(arr, 0, rarr, 0, arr.length);
		}
		
		return rarr;
	}
	
}


/*
 DECLARE
      CURSOR xQ IS
      SELECT TQSTUB(ROWIDTOCHAR(ROWID), TRADE_QUEUE_ID, TRADE_QUEUE_STATUS_CODE, SPECIE_DISPLAY_NAME, POSITIONACCOUNT_ACCT_NBR, SPECIE_ID, POSITIONACCOUNT_ACCT_ID, CREATE_TS, UPDATE_TS, ERROR_MESSAGE)  
      FROM TQUEUE  
      WHERE TRADE_QUEUE_STATUS_CODE IN ('PENDING','ENRICH','RETRY')
      ORDER BY TRADE_QUEUE_ID;      
      LIM NUMBER := 5000;
 BEGIN
  OPEN xQ;
  FETCH xQ BULK COLLECT INTO ? LIMIT LIM;
  CLOSE xQ;     
 END;

         ps = conn.prepareStatement("SELECT TQ.TQSTUBS(5000) FROM DUAL");
         cs = conn.prepareCall("{? = call TQ.TQSTUBS(5000)");





*/