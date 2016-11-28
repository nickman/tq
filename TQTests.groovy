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
rset = null;
rset2 = null;
// threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999
threadMod = -1;
rowLimit = 60000;
threadCount = 16;
bucketSize = 999999;
fetchSize = 100;
try {
    conn = ds.getConnection();
    println "Connected to ${conn.getMetaData().getURL()}";
    //ps = conn.prepareStatement("select VALUE(X).TOV() from TABLE(TQ.GROUP_TQBATCHES(?,?,?,?)) X");
    ps = conn.prepareStatement("select * from TABLE(TQ.GROUP_TQBATCHES(?,?,?,?)) X");
    ps2 = conn.prepareStatement("select VALUE(T).TOV() from TABLE(TQ.PIPE_TRADE_BATCH(?)) T");
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
    xrowids = null;
    while(rset.next()) {
        cnt++;
        t = rset.getInt('TCOUNT');
        xrowids = rset.getObject('TQROWIDS');
        ps2.setObject(1, xrowids);
        rset2 = ps2.executeQuery();
        while(rset2.next()) {
            //println rset2.getString(1);
        }
        rset2.close();
        trades += t;
        if(t > maxTrades) maxTrades = t;
    }
    long elapsed = System.currentTimeMillis() - start;
    println "Fetched $cnt batches and $trades Trades. Max Batch Size: $maxTrades, Elapsed: $elapsed ms.";
    //println "Last XROWIDS: $xrowids";
/*
    for(i in 1..100) {
        rset.next();        
        println "${rset.getString(1)}";
        Thread.sleep(500);
    }
*/    
} finally {
    try { rset.close(); println "RSET Closed"; } catch (x) {}
    try { rset2.close(); println "RSET2 Closed"; } catch (x) {}
    try { ps.close(); println "PS Closed"; } catch (x) {}
    try { ps2.close(); println "PS2 Closed"; } catch (x) {}
    try { conn.close(); println "CONN Closed"; } catch (x) {}
}