
import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;

String DRIVER = "oracle.jdbc.OracleDriver";
//String URL = "jdbc:oracle:thin:@//leopard:1521/XE";
//String URL = "jdbc:oracle:thin:@//tporacle:1521/ORCL";
String URL = "jdbc:oracle:thin:@//localhost:1521/ORCL";
//String URL = "jdbc:oracle:thin:@//localhost:1521/XE";
//String URL = "jdbc:oracle:thin:@//horacle:1521/cdb1";
String USER = "tqreactor";
String PASS = "tq";

ds = new OracleDataSource();
ds.setDriverType(DRIVER);
ds.setURL(URL);
ds.setUser(USER);
ds.setPassword(PASS);
def R = new Random(System.currentTimeMillis());
def SPECIE_TYPES = ["A", "B", "C", "D", "E", "V", "W", "X", "Y", "Z", "P"] as String[];
def STL = SPECIE_TYPES.length;
def ACCTSIZE = 0;
def SECSIZE = 0;
def securities = [];
def accounts = [];

randomType = {
    return SPECIE_TYPES[Math.abs(R.nextInt(STL))];
}

randomSecurity = {
    return securities.get(Math.abs(R.nextInt(SECSIZE)));
}

randomAccount = {
    return accounts.get(Math.abs(R.nextInt(ACCTSIZE)));
}


sql = Sql.newInstance(ds);

SECSIZE = sql.firstRow("SELECT COUNT(*) C FROM SECURITY").C.intValue();
if(SECSIZE<1) {
    sql.withTransaction {
        sql.withBatch { st ->
            for(i in 0..10000) {
                String s = UUID.randomUUID().toString();
                st.execute("INSERT INTO SECURITY VALUES(SEQ_SECURITY_ID.NEXTVAL, '$s', '${randomType()}')");
            }
        }    
    }
    SECSIZE = sql.firstRow("SELECT COUNT(*) C FROM SECURITY").C.intValue();
    println "Species Inserted: $SECSIZE";
} else {
    println "Species Already Loaded";
}    


ACCTSIZE = sql.firstRow("SELECT COUNT(*) C FROM ACCOUNT").C.intValue();
if(ACCTSIZE<1) {
    sql.withTransaction {
        sql.withBatch { st ->
            for(i in 0..1000) {
                String s = UUID.randomUUID().toString();
                st.execute("INSERT INTO ACCOUNT VALUES(SEQ_ACCOUNT_ID.NEXTVAL, '$s')");
            }
        }    
    }
    ACCTSIZE = sql.firstRow("SELECT COUNT(*) C FROM ACCOUNT").C.intValue();
    println "Accounts Inserted: $ACCTSIZE";
} else {
    println "Accounts Already Loaded";
}    



sql.eachRow("SELECT SECURITY_DISPLAY_NAME FROM SECURITY", { securities.add(it.SECURITY_DISPLAY_NAME); });
sql.eachRow("SELECT ACCOUNT_DISPLAY_NAME FROM ACCOUNT", { accounts.add(it.ACCOUNT_DISPLAY_NAME); });
println "Caches Loaded";

for(x in 0..10) {
    sql.withTransaction {
        sql.withBatch { st ->
            batchId = sql.firstRow("SELECT SEQ_TQBATCH_ID.NEXTVAL BATCH_ID FROM DUAL").BATCH_ID.toInteger();
            long start = System.currentTimeMillis();
            for(i in 0..10000) {
                s = randomSecurity();
                a = randomAccount();
                //  TQUEUE_ID,XID,STATUS_CODE,
                // SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,
                // SECURITY_ID,SECURITY_TYPE,
                // ACCOUNT_ID,
                // BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                st.execute("""INSERT INTO TQUEUE VALUES(
                    SEQ_TQUEUE_ID.NEXTVAL, tq.CURRENTXID, 'PENDING',       --TQUEUE_ID,XID,STATUS_CODE,
                    '$s', '$a',                                             --SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,
                    NULL, NULL,                                             --SECURITY_ID,SECURITY_TYPE,
                    NULL, $batchId,                                         --ACCOUNT_ID, BATCH_ID
                    SYSDATE, NULL, NULL                                     --CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                    )""");
            }
            long elapsed = System.currentTimeMillis() - start;
            println "Inserted 10000 rows in $elapsed ms.";
        }    
    }
    println "Completed Batch #$x";

// TQROWID       NOT NULL ROWID        
// TQUEUE_ID     NOT NULL NUMBER(38)   
// XID           NOT NULL RAW(8 BYTE)  
// SECURITY_ID   NOT NULL NUMBER(38)   
// SECURITY_TYPE NOT NULL CHAR(1)      
// ACCOUNT_ID    NOT NULL NUMBER(38)   
// BATCH_ID      NOT NULL NUMBER(38)   
// BATCH_TS               TIMESTAMP(6) 

//=====================================================================
//=====================================================================
// TQUEUE_ID             NOT NULL NUMBER(38)    
// XID                   NOT NULL RAW(8 BYTE)   
// STATUS_CODE           NOT NULL VARCHAR2(15)  
// SECURITY_DISPLAY_NAME NOT NULL VARCHAR2(64)  
// ACCOUNT_DISPLAY_NAME  NOT NULL VARCHAR2(36)  
// SECURITY_ID                    NUMBER(38)    
// SECURITY_TYPE                  CHAR(1)       
// ACCOUNT_ID                     NUMBER(38)    
// BATCH_ID                       NUMBER(38)    
// CREATE_TS             NOT NULL DATE          
// UPDATE_TS                      DATE          
// ERROR_MESSAGE                  VARCHAR2(512) 

}

println "Trades Inserted";

println "Gathering Stats for TQUEUE";
sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100); end;");
println "Gathering Stats for ACCOUNT";
sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100); end;");
println "Gathering Stats for SECURITY";
sql.execute("begin DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100); end;");

println "Stats Gathered";










tqTypes = [
'XROWID'  :               'VARCHAR2(18)',
'TQUEUE_ID'  :            'INT',
'STATUS_CODE'  :          'VARCHAR2(15)',
'SECURITY_DISPLAY_NAME'  :'VARCHAR2(64)',
'ACCOUNT_DISPLAY_NAME'  : 'VARCHAR2(36)',
'SECURITY_ID'  :          'INT',
'SECURITY_TYPE'  :        'CHAR(1)',
'ACCOUNT_ID'  :           'INT',
'CREATE_TS'  :            'DATE',
'UPDATE_TS'  :            'DATE',
'ERROR_MESSAGE'  :        'VARCHAR2(512)'
];
