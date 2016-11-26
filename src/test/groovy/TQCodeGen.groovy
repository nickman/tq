import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;

String DRIVER = "oracle.jdbc.OracleDriver";
String URL = "jdbc:oracle:thin:@//localhost:1521/XE";
String USER = "tqreactor";
String PASS = "tq";

NO_LEN_TYPES = new HashSet<String>(["DATE", "TIMESTAMP"]);

TABLE_META_SQL = "SELECT * FROM USER_TAB_COLUMNS WHERE TABLE_NAME = ? ORDER BY COLUMN_ID"

def ds = new OracleDataSource();
ds.setDriverType(DRIVER);
ds.setURL(URL);
ds.setUser(USER);
ds.setPassword(PASS);
def sql = Sql.newInstance(ds);
//======================================
//   Meta Cache
//======================================
def metaCache = [:];

getTabMeta = { tableName ->
	def meta = metaCache.get(tableName);
	if(meta!=null) return meta;
	meta = new LinkedHashMap();
	sql.eachRow(TABLE_META_SQL, [tableName], {
		colName = it.COLUMN_NAME;
		colAttrs = [:];
		colAttrs.tname = it.TABLE_NAME;
		colAttrs.cname = it.COLUMN_NAME;
		colAttrs.dtype = it.DATA_TYPE;
		colAttrs.length = it.DATA_LENGTH.intValue();
		colAttrs.nul = "Y".equals(it.NULLABLE);
		colAttrs.nulspec = colAttrs.nul ? "" : "NOT NULL";
		colAttrs.id = it.COLUMN_ID;
		def lenSpec = NO_LEN_TYPES.contains(it.DATA_TYPE) ? "" : "(${it.DATA_LENGTH})";
		colAttrs.ddl = "${it.DATA_TYPE}$lenSpec";
		meta.put(colName, colAttrs);
	});	
	metaCache.put(tableName, meta);
	return meta;
}

genObject = { rowid, arr, record, tableName ->
	meta = getTabMeta(tableName);
	b = new StringBuilder();
	if(record) {
		b.append("TYPE ${tableName}_REC IS RECORD (");		
	} else {
		b.append("CREATE OR REPLACE TYPE ${tableName}_OBJ FORCE AS OBJECT (");		
	}
	if(rowid) {
		b.append("\n\tXROWID VARCHAR2(18),");
	}
	meta.values().each() { m ->
		if(record) {
			// TQUEUEO.TQUEUE_ID%TYPE,
			b.append("\n\t${m.cname} ${tableName}.${m.cname}%TYPE,");
		} else {
			b.append("\n\t${m.cname} ${m.ddl},");
		}		
	}
	b.deleteCharAt(b.length()-1);
	b.append("\n);");
	if(!record) {
		b.append("\n/");
	}
	if(arr) {
		if(record) {
			b.append("\nTYPE ${tableName}_REC_ARR IS TABLE OF ${tableName}_REC;");			
			b.append("\nTYPE ${tableName}_REC_CUR IS REF CURSOR RETURN ${tableName}_REC;");
		} else {
			b.append("\nCREATE OR REPLACE TYPE ${tableName}_OBJ_ARR FORCE AS TABLE OF ${tableName}_OBJ;\n/")
		}
		
	}
	return b.toString();
}


genPipeRecsIntoObjects = { rowid, tableName ->
	meta = getTabMeta(tableName);
	b = new StringBuilder("FUNCTION ${tableName}_RECS_TO_OBJS(p IN ${tableName}_REC_CUR) RETURN ${tableName}_OBJ_ARR PIPELINED PARALLEL_ENABLE IS ");
	b.append("\n\tobj ${tableName}_OBJ;")
	b.append("\nBEGIN\n\t\tLOOP\n\t\t\tFETCH p into obj;\n\t\t\tEXIT WHEN p%NOTFOUND;");
	b.append("\n\t\t\tPIPE ROW(${tableName}_OBJ(");
	b.append("obj.XROWID,")
	meta.values().each() { m ->
		b.append("obj.${m.cname},")
	}
	b.deleteCharAt(b.length()-1);
	b.append("));\n\t\tEND LOOP;\n\t\tRETURN;\n\t\tEXCEPTION\n\t\t\tWHEN NO_DATA_NEEDED THEN RAISE;\nEND ${tableName}_RECS_TO_OBJS;");
	return b.toString();
}



println genObject(true, true, false, "TQUEUE");
println genPipeRecsIntoObjects(true, "TQUEUE");

