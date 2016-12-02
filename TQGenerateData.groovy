import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

String DRIVER = "oracle.jdbc.OracleDriver";
//String URL = "jdbc:oracle:oci8:@";
String URL = "jdbc:oracle:thin:@//localhost:1521/XE";
String USER = "tqreactor";
String PASS = "tq";

ds = new OracleDataSource();
ds.setDriverType(DRIVER);
ds.setURL(URL);
ds.setUser(USER);
ds.setPassword(PASS);

THREADS = 4;
BATCHSIZE = 100;
LOOPS = 2000;


sql = Sql.newInstance(ds);

SECSIZE = sql.firstRow("SELECT COUNT(*) C FROM SECURITY").C.intValue();
if(SECSIZE<1) {
    sql.call("BEGIN TESTDATA.GENSECS(); END;");
    SECSIZE = sql.firstRow("SELECT COUNT(*) C FROM SECURITY").C.intValue();
    println "Species Inserted: $SECSIZE";
} else {
    println "Species Already Loaded";
}    

ACCTSIZE = sql.firstRow("SELECT COUNT(*) C FROM ACCOUNT").C.intValue();
if(ACCTSIZE<1) {
    sql.call("BEGIN TESTDATA.GENACCTS(); END;");
    ACCTSIZE = sql.firstRow("SELECT COUNT(*) C FROM ACCOUNT").C.intValue();
    println "Accounts Inserted: $ACCTSIZE";
} else {
    println "Accounts Already Loaded";
}    

totalTrades = new AtomicLong();
latch = new CountDownLatch(THREADS);
allThreads = [];
for(threads in 1..THREADS) {
    tx = Thread.startDaemon("TQDataLoader#${threads}", {
        
        def conn = null;
        def ps = null;
        def me = Thread.currentThread().getName();
        println "Thread [$me] started";
        try {           
            conn = ds.getConnection();             
            ps = conn.prepareCall("BEGIN TESTDATA.GENTRADES($BATCHSIZE); END;");
            for(x in 1..LOOPS) {
                if(Thread.interrupted()) {
                    println "[$me] Interrupted. Exiting...";
                    return;
                }
                final long start = System.currentTimeMillis();
                ps.execute();
                final long elapsed = System.currentTimeMillis() - start;
                long gtotal = totalTrades.addAndGet(BATCHSIZE);
                println "[$me] Generated $BATCHSIZE. Rolling Total: $gtotal, elapsed: $elapsed ms.";
            }
            println "[$me] Thread Completed";
         } finally {
            latch.countDown();
            try { ps.close(); } catch (x) {}
            try { conn.close(); } catch (x) {}
         }
    }); // end of Thread def
    allThreads.add(tx);
} // end of for loop

println "Awaiting Worker Thread Completion...";
try {
    latch.await();
    println "Completed Generation of ${totalTrades} Trades";
    println "Gathering Stats for TQSTUBS";
    sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQSTUBS', estimate_percent => 100); end;");
    println "Gathering Stats for TQUEUE";
    sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100); end;");
    println "Gathering Stats for ACCOUNT";
    sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100); end;");
    println "Gathering Stats for SECURITY";
    sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100); end;");
        
} catch(q) {
    println "Task Interrupted. Stopping  Worker Threads";
    allThreads.each() { it.interrupt(); }
    println "Worker Threads Signalled";
}    
