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

import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.driver.OracleConnection;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Logger;

import tqueue.db.types.TQBATCH;
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
	private final Logger log = Logger.getLogger(getClass());
	
	public static final String POLL_BATCH_SQL = 
			"SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) " +
			"FROM TABLE(TQV.QUERYTBATCHES(?, ?, ?, ?)) " +
			"ORDER BY FIRST_T ";
	
	public static final String LOCK_BATCH_SQL =
			"BEGIN TQV.LOCKBATCH(?, ?); END;";
//			"BEGIN ? := TQV.LOCKBATCHR(?); END;";
			
	
	public static void main(String[] args) {
		BasicConfigurator.configure();		
		OracleAdapter oa = new OracleAdapter();
		oa.getTQBatches(0, 5000, 10, 5);
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
		int startId = startAt;
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
			
			ps.setInt(2, maxRows);
			ps.setInt(3, maxBatchSize);
			ps.setInt(4, maxWait);			
			for(int i = 0; i < 1000; i++) {
				log.info("Fetching Batches starting at [" + startId + "]");
				ps.setInt(1, startId);
				rs = ps.executeQuery();
				rs.setFetchSize(maxRows * maxBatchSize);
				int batchCount = 0;
				int stubCount = 0;
				while(rs.next()) {				
					TQBATCH batch = (TQBATCH)((OracleResultSet)rs).getORAData(1, TQBATCH.getORADataFactory());
					if(batch.getAccount()==-1) {
						log.info("Timed out waiting for results");
						break;
					}
					csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);
					
					csRelock.setORAData(1, batch);
					csRelock.setInt(2, 0);
					//csRelock.setOracleObject(1, batch.toDatum(oraConn));
					//csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE);
					
					csRelock.execute();
					batch = (TQBATCH)csRelock.getORAData(1, TQBATCH.getORADataFactory());
					log.info("Batch Size:" + batch.getTcount() + ":" + batch);
					startId = batch.getLastT();
					batchCount++;
					stubCount += batch.getTcount();
					conn.commit();
				}
				rs.close();
				log.info("Total Batches:" + batchCount + " Total Trades:" + stubCount);
			}
			return null; // ((TQSTUB_ARR)((OracleCallableStatement)cs).getORAData(2, TQSTUB_ARR.getORADataFactory())).getArray();
		} catch (Exception ex) {
			log.error("getTQStubs failed", ex);
			throw new RuntimeException("getTQStubs failed", ex);
		} finally {
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(csRelock!=null) try { csRelock.close(); } catch (Exception x) {/* No Op */}
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
		}		
	}
	
	public void processBatch(TQBATCH batch) {
		Connection conn = null;
		OracleConnection oraConn = null;
		PreparedStatement ps = null;
		OracleCallableStatement csRelock = null;
		ResultSet rs = null;
		try {
			conn = ConnectionPool.getInstance().getConnection();
			oraConn = ConnectionPool.unwrap(conn, OracleConnection.class);
			//ps = oraConn.prepareStatement(POLL_BATCH_SQL);
			csRelock = (OracleCallableStatement)oraConn.prepareCall("BEGIN TQV.RELOCKBATCH(?); END;");
			csRelock.registerOutParameter(1, TQBATCH._SQL_TYPECODE, TQBATCH._SQL_NAME);			
			csRelock.setORAData(1, batch);
			csRelock.execute();
			batch = (TQBATCH)csRelock.getORAData(1, TQBATCH.getORADataFactory());
			
			
		} catch (Exception ex) {
			
		} finally {
			if(rs!=null) try { rs.close(); } catch (Exception x) {/* No Op */}
			if(ps!=null) try { ps.close(); } catch (Exception x) {/* No Op */}
			if(csRelock!=null) try { csRelock.close(); } catch (Exception x) {/* No Op */}
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