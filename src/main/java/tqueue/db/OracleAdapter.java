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
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.driver.OracleConnection;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import tqueue.db.types.TQBATCH;
import tqueue.db.types.TQTRADE;
import tqueue.db.types.TQTRADE_ARR;
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
	
	public static final String POLL_BATCH_SQL = 
			"SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) " +
			"FROM TABLE(TQV.QUERYTBATCHES(?, ?, ?, ?)) " +
			"ORDER BY FIRST_T ";
	
	public static final String LOCK_BATCH_SQL =
			"BEGIN TQV.LOCKBATCH(?, ?); END;";

	public static final String RELOCK_BATCH_SQL = 
			"BEGIN TQV.RELOCKBATCH(?); END;";

	public static final String START_BATCH_SQL = 
			"BEGIN ? := TQV.STARTBATCH(?); END;";

	public static final String SAVE_TRADES_SQL = 
			"BEGIN TQV.SAVETRADES(?, ?); END;";
	
	public static final String FINISH_BATCH_SQL = 
			"BEGIN TQV.FINISHBATCH(?); END;";
	
	protected final ThreadFactory tf = new ThreadFactory() {
		final AtomicInteger serial = new AtomicInteger(0);
		public Thread newThread(final Runnable r) {
			Thread t = new Thread(r, "TQReactorThread#" + serial.incrementAndGet());
			t.setDaemon(true);
			return t;
		}
	};
	protected final ThreadPoolExecutor tpe = new ThreadPoolExecutor(12, 24, 60, TimeUnit.SECONDS, new ArrayBlockingQueue<Runnable>(10240, false ), tf); 
	
	public static void main(String[] args) {		
		OracleAdapter oa = new OracleAdapter();
		oa.tpe.prestartAllCoreThreads();
		oa.getTQBatches(0, 20000, 50, 5);		
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

		 */
		
	}
	
	// POLL_BATCH_SQL
	
	public TQBATCH[] getTQBatches(final int startAt, final int maxRows, final int maxBatchSize, final int maxWait) {
		Connection conn = null;
		OracleConnection oraConn = null;
		PreparedStatement ps = null;
		OracleCallableStatement csRelock = null;
		ResultSet rs = null;
		final AtomicInteger startId = new AtomicInteger(startAt);
		final AtomicInteger pending = new AtomicInteger(0);
		try {
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
			
			ps.setInt(1, 0);
			ps.setInt(2, maxRows);
			ps.setInt(3, maxBatchSize);
			ps.setInt(4, maxWait);			
			for(int i = 0; i < Integer.MAX_VALUE; i++) {
				//log.info("Fetching Batches starting at [" + startId + "]");
				//ps.setInt(1, startId.get());
				while(pending.get()!=0) {
					Thread.yield();
				}
				rs = ps.executeQuery();
				rs.setFetchSize(maxRows * maxBatchSize);
				int batchCount = 0;
				int stubCount = 0;
				int dropCount = 0;
				while(rs.next()) {				
					TQBATCH preBatch = (TQBATCH)((OracleResultSet)rs).getORAData(1, TQBATCH.getORADataFactory());
					if(preBatch.getAccount()==-1) {
						//log.info("Timed out waiting for results");
						break;
					}
					csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					
					csRelock.setORAData(1, preBatch);
					csRelock.setInt(2, 0);
					//csRelock.setOracleObject(1, batch.toDatum(oraConn));
					//csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE);
					
					csRelock.execute();
					TQBATCH postBatch = (TQBATCH)csRelock.getORAData(1, TQBATCH.getORADataFactory());
//					log.info("Batch Size:" + batch.getTcount() + ":" + batch);
					startId.set(postBatch.getLastT());
					if(postBatch.getTcount() != preBatch.getTcount()) {
						dropCount = (preBatch.getTcount() - postBatch.getTcount());
					}
					batchCount++;
					stubCount += postBatch.getTcount();
					conn.commit();
					final TQBATCH b = postBatch;
					final int bc = batchCount;
					final int sc = stubCount;
					final int dc = dropCount;
					pending.incrementAndGet();
					tpe.submit(new Runnable(){
						public void run() {
							try {
								processBatch(b);
								if(bc>0) {
									if(dc>0) {
										//System.err.println("Lock Drops:" + dc);
									}
									//log.info("Total Batches:" + bc + " Total Trades:" + sc);
								}
							} catch (Exception ex) {
								System.err.println(ex);
								startId.set(0);
							} finally {
								pending.decrementAndGet();
							}
						}						
					});					
				}
				rs.close();
				log.info("BatchSet Complete\n\tBatch Count:" + batchCount + "\n\tStub Count:" + stubCount + "\n\tDrop Count:" + dropCount);
				batchCount = 0;
				stubCount = 0;
				dropCount = 0;

			}
			return null; // ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
		} catch (SQLException sex) {
//			log.info("SQLException:", sex);
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(csRelock!=null) try { csRelock.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.rollback(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
			if(sex.getErrorCode()==4068) {
				log.warn("Package State Changed. Re-initializing....");
				throw new RuntimeException(sex);
				//return getTQBatches(startAt, maxRows, maxBatchSize, maxWait);
			}
			log.error("getTQStubs failed", sex);
			throw new RuntimeException("getTQStubs failed", sex);
			
		} catch (Exception ex) {
			log.error("getTQStubs failed", ex);
			throw new RuntimeException("getTQStubs failed", ex);
		} finally {
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(csRelock!=null) try { csRelock.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.rollback(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
		}		
	}
	
	public void processBatch(final TQBATCH batchToProcess) {
		Connection conn = null;
		OracleConnection oraConn = null;
		PreparedStatement ps = null;
		OracleCallableStatement cs = null;
		ResultSet rs = null;
		TQBATCH preBatch = batchToProcess;
		
		// RelockBatch
//		"BEGIN TQV.RELOCKBATCH(?); END;";

		//START_BATCH_SQL = 
//		"BEGIN ? := TQV.STARTBATCH(?); END;";
		
//		public static final String SAVE_TRADES_SQL = 
//				"BEGIN TQV.SAVETRADES(?, ?); END;";
//		
//		public static final String FINISH_BATCH_SQL = 
//				"BEGIN TQV.FINISHBATCH(?); END;";
		

		TQBATCH postBatch = null;
		try {
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);

			//===========================================================================================
			// 	 PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH);
			//===========================================================================================
			cs = (OracleCallableStatement)oraConn.prepareCall(RELOCK_BATCH_SQL);
			cs.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);			
			cs.setORAData(1, preBatch);
			cs.execute();
			postBatch = (TQBATCH)cs.getORAData(1, TQBATCH.getORADataFactory());
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
			cs.setORAData(2, postBatch);
			cs.registerOutParameter(2, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);	
			cs.registerOutParameter(1, TQTRADE_ARR._SQL_TYPECODE, TQTRADE_ARR._SQL_NAME);
			cs.execute();
			//return ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
			trades = ((TQTRADE_ARR)cs.getORAData(1, TQTRADE_ARR.getORADataFactory())).getArray();
			postBatch = (TQBATCH)cs.getORAData(2, TQBATCH.getORADataFactory());
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

//	public TQSTUB[] getTQStubsA(final int limit) {
//		Connection conn = null;
//		OracleConnection oraConn = null;
//		CallableStatement cs = null;
//		try {
//			conn = ConnectionPool.getInstance().getConnection();
//			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
//			cs = oraConn.prepareCall(LOCAL_TQSTUB_FETCH_SQL);
//			cs.setInt(1, limit);
//			cs.registerOutParameter(2, TQSTUB_ARR._SQL_TYPECODE, TQSTUB_ARR._SQL_NAME);
//			cs.execute();
//			return ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
//		} catch (Exception ex) {
//			log.error("getTQStubs failed", ex);
//			throw new RuntimeException("getTQStubs failed", ex);
//		} finally {
//			if(cs!=null) try { cs.close(); } catch (Exception x) {/* No Op */}
//			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
//		}
//	}
//	
//	public Object[] getTQStubsJ(final int limit) {
//		Connection conn = null;
//		PreparedStatement ps = null;
//		ResultSet rset = null;
//		try {
//			conn = ConnectionPool.getInstance().getConnection();
//			ps = conn.prepareCall("SELECT TQ.TQSTUBS(?) FROM DUAL");
//			ps.setInt(1, limit);
//			rset = ps.executeQuery();
//			rset.next();
//			//return toArray(TQSTUB.class, (Object[])rset.getArray(1).getArray());
//			return (Object[])rset.getArray(1).getArray();
//		} catch (Exception ex) {
//			log.error("getTQStubs failed", ex);
//			throw new RuntimeException("getTQStubs failed", ex);
//		} finally {
//			if(rset!=null) try { rset.close(); } catch (Exception x) {/* No Op */}
//			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
//			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
//		}
//	}
	
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