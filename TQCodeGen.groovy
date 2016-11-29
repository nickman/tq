import oracle.jdbc.pool.OracleDataSource;
import groovy.sql.*;
import java.sql.*;
import oracle.jdbc.*;
import oracle.jdbc.aq.*;

String DRIVER = "oracle.jdbc.OracleDriver";
String URL = "jdbc:oracle:thin:@//localhost:1521/ORCL";
String USER = "tqreactor";
String PASS = "tq";

int US = '_';

NO_LEN_TYPES = new HashSet<String>(["DATE", "TIMESTAMP(6)", "ROWID"]);

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

//======================================
//   Formatting Ops
//======================================

uinds = { name ->
    int index = 1;
    int offset = 0;
    int loops = 0;
    uids = [];
    while(index!=-1) {
        index = name.indexOf(US, offset);
        if(index!=-1) {
            uids.add(index-loops);
            offset += index+1;
        }
        loops++;
    }
    return uids as int[];
}

pc = { name ->
    int[] u = uinds(name);
    s = name.toLowerCase().replace("_", "");
    if(u.length > 0) {
        StringBuilder b = new StringBuilder(s);
        u.each() { index ->
            int nextChar = index+1;
            if(nextChar <= b.length()) {
                upchar = b.substring(index, nextChar).toUpperCase();
                b.replace(index, index+1, upchar);
            }
        }
        s = b.toString();
    }
    return s;
}

//======================================
//   Code Gen Ops
//======================================
// FIXME:   ROWID for OBJECTs must be VARCHAR2(18)
getTabMeta = { tableName ->
	def meta = metaCache.get(tableName);
	if(meta!=null) return meta;
	meta = new LinkedHashMap();
	sql.eachRow(TABLE_META_SQL, [tableName], {
		colName = it.COLUMN_NAME;
		colAttrs = [:];
		colAttrs.tname = it.TABLE_NAME;
		colAttrs.cname = it.COLUMN_NAME;
		colAttrs.pname = pc(it.COLUMN_NAME);
		colAttrs.lcpname = pc(it.COLUMN_NAME).toLowerCase();
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


// FIXME: Add TOV for ARR types
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
	if(!record) {
		b.append("\nMEMBER FUNCTION TOV RETURN VARCHAR2");
	} else {
		b.deleteCharAt(b.length()-1);
	}
	b.append("\n);");
	int trimLen = " || ',' || ".length();
	if(!record) {
		b.append("\n/");
		b.append("\nCREATE OR REPLACE TYPE BODY ${tableName}_OBJ AS\nMEMBER FUNCTION TOV RETURN VARCHAR2 AS\nBEGIN\nRETURN ");
		if(rowid) {
			b.append("SELF.XROWID || ',' || ");
		}
		meta.values().each() { m ->
			b.append("SELF.${m.cname} || ',' || ");
		}
		for(i in 1..trimLen) b.deleteCharAt(b.length()-1);
		b.append(";\nEND TOV;\nEND;\n/\n")
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
	b.append("\n\trec ${tableName}_REC;")
	b.append("\nBEGIN\n\t\tLOOP\n\t\t\tFETCH p into rec;\n\t\t\tEXIT WHEN p%NOTFOUND;");
	b.append("\n\t\t\tPIPE ROW(${tableName}_OBJ(");
	b.append("rec.XROWID,")
	meta.values().each() { m ->
		b.append("rec.${m.cname},")
	}
	b.deleteCharAt(b.length()-1);
	b.append("));\n\t\tEND LOOP;\n\t\tRETURN;\n\t\tEXCEPTION\n\t\t\tWHEN NO_DATA_NEEDED THEN RAISE;\nEND ${tableName}_RECS_TO_OBJS;");
	return b.toString();
}

genTableParams = { rowid, xrowid, inout, prefix, tableName ->
	meta = getTabMeta(tableName);
	b = new StringBuilder("(");
	if(rowid) {
		if(xrowid) {
			b.append(prefix).append("XROWID ").append(inout).append(" VARCHAR2, ");
		} else {
			b.append(prefix).append("${pc('rowid')} ").append(inout).append(" ROWID, ");
		}
	}
	meta.values().each() { m ->
		b.append(prefix).append(m.pname).append(" ").append(inout).append(" ").append(m.dtype).append(", ");
	}
	b.deleteCharAt(b.length()-1);b.deleteCharAt(b.length()-1);
	return b.append(")").toString();
}

genTableSelect = { rowid, xrowid, prefix, tableName ->
	meta = getTabMeta(tableName);
	b = new StringBuilder();
	if(rowid) {
		if(xrowid) {
			b.append("ROWIDTOCHAR(").append(prefix).append("ROWID),");
		} else {
			b.append(prefix).append("ROWID,");
		}
	}
	meta.values().each() { m ->
		b.append(prefix).append(m.cname).append(",");
	}
	b.deleteCharAt(b.length()-1);
	return b.toString();
}

genObjToTabUpdate = { prefix, tableName ->
	meta = getTabMeta(tableName);
	b = new StringBuilder("UPDATE ").append(tableName).append(" SET ");
	meta.values().each() { m ->
		b.append("\n").append(m.cname).append("=").append(prefix).append(m.cname).append(",");
	}
	b.deleteCharAt(b.length()-1);
	b.append("\nWHERE ROWID = CHARTOROWID(").append(prefix).append("XROWID)");
	return b.toString();
}


/*
println genObject(true, true, false, "TQUEUE");
println genObject(true, true, false, "TQSTUBS");

println genObject(true, true, true, "TQUEUE");
println genObject(true, true, true, "TQSTUBS");

println genPipeRecsIntoObjects(true, "TQUEUE");
println genPipeRecsIntoObjects(true, "TQSTUBS");

println genObject(true, true, false, "ACCOUNT");
println genObject(true, true, false, "SECURITY");


*/


//println genTableSelect(true, true, "", "TQUEUE");

//println genTableParams(true, false, "IN", "", "TQUEUE");


//println genPipeRecsIntoObjects(true, "TQSTUBS");
//println genPipeRecsIntoObjects(true, "TQUEUE");

//println genTableParams(true, false, "IN", "", "TQSTUBS");
//println genTableSelect(true, false, "rec.", "TQUEUE");
println genObjToTabUpdate("trades(i).", "TQUEUE");

