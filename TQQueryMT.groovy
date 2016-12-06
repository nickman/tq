import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

String DRIVER = "oracle.jdbc.OracleDriver";
//String URL = "jdbc:oracle:oci8:@";
//String URL = "jdbc:oracle:thin:@//localhost:1521/XE";
//String URL = "jdbc:oracle:thin:@//192.168.1.35:1521/ORCL";
String URL = "jdbc:oracle:thin:@//localhost:1521/ORCL";
String USER = "tqreactor";
String PASS = "tq";

ds = new OracleDataSource();
ds.setDriverType(DRIVER);
ds.setURL(URL);
ds.setUser(USER);
ds.setPassword(PASS);

println "OracleConnection.END_TO_END_STATE_INDEX_MAX: ${OracleConnection.END_TO_END_STATE_INDEX_MAX}";
println "OracleConnection.END_TO_END_ACTION_INDEX: ${OracleConnection.END_TO_END_ACTION_INDEX}";
println "OracleConnection.END_TO_END_MODULE_INDEX: ${OracleConnection.END_TO_END_MODULE_INDEX}";
println "OracleConnection.END_TO_END_CLIENTID_INDEX: ${OracleConnection.END_TO_END_CLIENTID_INDEX}";


//  FIXME:  Statistics data is not available because statistics aggregation is not enabled for the selected action

final int THREADS = 4;
final int ROW_LIMIT = 1024;
final int FETCH_SIZE = 1;
final int CPU_MULTI = 2;

final Connection[] connections = new Connection[THREADS];
addShutdownHook {
	connections.each() {
		if(it!=null) try { it.close(); } catch (x) {}
	}
	println "All Connections Closed In Shutdown Hook";		
}

try {
	for(i in 0..THREADS-1) {    	
		connections[i] = ds.getConnection();
		def Properties clientInfo = new Properties();		
		// clientInfo.setProperty(OracleConnection.OCSID_ACTION_KEY, "BatchReader");
  // 		clientInfo.setProperty(OracleConnection.OCSID_MODULE_KEY, "TQProcessor");
  // 		clientInfo.setProperty(OracleConnection.OCSID_CLIENTID_KEY,"Thread#${i+1}");	
		// clientInfo.setProperty("OCSID.ACTION", "BatchReader");
  // 		clientInfo.setProperty("OSCID.MODULE", "TQProcessor");
  // 		clientInfo.setProperty("OSCID.CLIENTID","Thread#${i+1}");	
		//String[] e2e = new String[OracleConnection.END_TO_END_STATE_INDEX_MAX];
		String[] e2e = [
			"BatchReader",
			"Thread#${i+1}",
			null,
			"TQProcessor"
		] as String[];
  		connections[i].setEndToEndMetrics(e2e, (short) 0);
		println "Acquired Connection #${i+1}";
	}
	println "All Connections Acquired";
} catch (ex) {
	ex.printStackTrace(System.err);
	connections.each() {
		if(it!=null) try { it.close(); } catch (x) {}
	}
	println "All Connections Closed After Error";	
	throw new Exception();
}

for(q in 0..1000) {
	final CountDownLatch latch = new CountDownLatch(THREADS);
	for(i in 0..THREADS-1) {    
	   final int x = i;
	   Thread.startDaemon({    
	       def ps = null;
	       def rset = null;
	       def msg = null;
	       int rowCount = 0;
	       try {
	       		//ps = connections[i].prepareStatement("SELECT VALUE(T).TOV() B FROM TABLE(TQ.GROUP_BATCH_STUBS(?, ?, ?)) T ORDER BY T.FIRST_T");
	       		ps = connections[x].prepareStatement("SELECT VALUE(T).TOV() B FROM TABLE(TQ.GROUP_BATCH_STUBS(TQ.MAKE_SPEC(?, ?, ?, ?))) T ORDER BY T.FIRST_T"); // 1, 1024, 16
	       		
	       		ps.setInt(1, x);
	       		ps.setInt(2, ROW_LIMIT);
	       		ps.setInt(3, THREADS);
	       		ps.setInt(4, CPU_MULTI);
		       	final long start = System.currentTimeMillis();
	       		rset = ps.executeQuery();
	       		rset.setFetchSize(100);
	       		while(rset.next()) {
	       			if(rowCount==0) {
	       				msg = rset.getString(1);
	       			}
	       			rowCount++;
	       		}
	       		if(rowCount==0) {
					msg = "NO ROWS";
				}
		       	final long elapsed = System.currentTimeMillis() - start;
		       	final String[] e2eMetrics = connections[x].getEndToEndMetrics();		       	
		       	println "MOD: $x, BATCH: $msg,  rows: $rowCount  elapsed: $elapsed ms.\n\tE2E: ${e2eMetrics}";
		   } finally {
		   		try { rset.close(); } catch (ex) {}
		   		try { ps.close(); } catch (ex) {}
		   		latch.countDown();
		   }
	       
	   });
	}


	println "Waiting On Latch";
	latch.await();
	println "\nTest Complete";

}

connections.each() {
	if(it!=null) try { it.close(); } catch (x) {}
}
println "All Connections Closed";



// for(i in 0..15) {    
//     final int x = i;
//     final Sql sql = Sql.newInstance(ds);
//     def batch = sql.firstRow("SELECT VALUE(T).TOV() B FROM TABLE(TQ.GROUP_BATCH_STUBS($x)) T ORDER BY T.FIRST_T").B;
//     //def batch = sql.firstRow("SELECT T.FIRST_T B FROM TABLE(TQ.GROUP_BATCH_STUBS($x, 8096)) T ORDER BY T.FIRST_T").B;
//     println "MOD: $x, BATCH: $batch";
// }
