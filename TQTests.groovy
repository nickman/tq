import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;

String DRIVER = "oracle.jdbc.OracleDriver";
String URL = "jdbc:oracle:thin:@//localhost:1521/ORCL";
String USER = "tqreactor";
String PASS = "tq";

def ds = new OracleDataSource();
ds.setDriverType(DRIVER);
ds.setURL(URL);
ds.setUser(USER);
ds.setPassword(PASS);
def sql = Sql.newInstance(ds);



conn = null;
ps = null;
ps2 = null;
csStubs = null;
csTrades = null;
csLock = null;
rset = null;
rset2 = null;

// threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999
threadMod = -1;
rowLimit = 10;
threadCount = 16;
bucketSize = 999999;
fetchSize = 100;
sql.call("BEGIN TQ.SET_TCPLOG_ENABLED(1); END;");
sql.call("BEGIN LOGGING.tcplogx('Hello From Remote'); END;");
try {
    conn = ds.getConnection();
    conn.setAutoCommit(false);
    println "Connected to ${conn.getMetaData().getURL()}";
    //ps = conn.prepareStatement("select VALUE(X).TOV() from TABLE(TQ.GROUP_TQBATCHES(?,?,?,?)) X");
    ps = conn.prepareStatement("select * from TABLE(TQ.GROUP_TQBATCHES(?,?,?,?)) X");
    ps2 = conn.prepareStatement("select VALUE(T) from TABLE(TQ.PIPE_TRADE_BATCH(?)) T");
    csStubs = conn.prepareCall("BEGIN ? := TQ.DELETE_STUB_BATCH(?); END;");
    csLock = conn.prepareCall("BEGIN ? := TQ.LOCKTRADES(?); END;");
    //csTrades = conn.callStatement("BEGIN TQ.UPDATE_TRADES(?); END;");
    long start  = System.currentTimeMillis();
    ps.setInt(1, threadMod);
    ps.setInt(2, rowLimit);
    ps.setInt(3, threadCount);
    ps.setInt(4, bucketSize);
    rset = ps.executeQuery();
    rset.setFetchSize(fetchSize);
    int cnt = 0;
    int trades = 0;
    int maxTrades = -1;
    int t = 0;
    int TCOUNT = 0;
    xrowids = null;
    stubxrowids = null;
    tqueueObj = null;
    boolean printedObj = false;
    while(rset.next()) {
        cnt++;
        xrowids = rset.getObject('TQROWIDS');        
        stubxrowids = rset.getObject('ROWIDS');
        TCOUNT = rset.getInt('TCOUNT');
        ps2.setObject(1, xrowids);
        rset2 = ps2.executeQuery();
        t = 0;
        while(rset2.next()) {
            t++;
            tqueueObj = rset2.getObject(1);
            Struct st = (Struct)tqueueObj;
            println "Trade #$t ATTRS: ${st.getAttributes()}";
        
/*            
            if(!printedObj) {
                printedObj = true;
                tqueueObj = rset2.getObject(1);
                println "TQUEUE_OBJ: ${tqueueObj}";
                println "TQUEUE_OBJ TYPE: ${tqueueObj.getClass().getName()}";
                Struct st = (Struct)tqueueObj;
                println "ATTRS: ${st.getAttributes()}";
            }
*/            
        }
        println "-----> T: $t, TCOUNT: $TCOUNT";
        csLock.setObject(2, xrowids);
        csLock.registerOutParameter(1, Types.NUMERIC);
        csLock.execute();        
        int rowsLocked = csLock.getInt(1);
        println "Xrowids: ${xrowids.getArray().length}, Rows Selected: $t, Rows Locked: $rowsLocked";
        rset2.close();
        trades += t;
        if(t > maxTrades) maxTrades = t;
//        csStubs.registerOutParameter(1, Types.NUMERIC);
//        csStubs.setObject(2, stubxrowids);
//        csStubs.execute();
        conn.commit();
    }
    
    long elapsed = System.currentTimeMillis() - start;
    println "Fetched $cnt batches and $trades Trades. Max Batch Size: $maxTrades, Elapsed: $elapsed ms.";
    println "Last XROWIDS: $xrowids";
    println "XROWID ARR: ${xrowids.getArray()}\n\t---> TYPE: ${xrowids.getArray().getClass().getName()}";
} finally {
    try { rset.close(); println "RSET Closed"; } catch (x) {}
    try { rset2.close(); println "RSET2 Closed"; } catch (x) {}
    try { ps.close(); println "PS Closed"; } catch (x) {}
    try { ps2.close(); println "PS2 Closed"; } catch (x) {}
    try { csStubs.close(); println "CSStubs Closed"; } catch (x) {}
    try { csTrades.close(); println "CSTrades Closed"; } catch (x) {}
    try { csLock.close(); println "CSLock Closed"; } catch (x) {}
    try { conn.close(); println "CONN Closed"; } catch (x) {}
}