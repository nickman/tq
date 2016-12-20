create or replace PACKAGE TSDB_TRACER AS 

  TYPE XMETRIC_ARR IS TABLE OF METRIC INDEX BY VARCHAR2(360);
  TYPE RCUR IS REF CURSOR;
  
  MAX_TAGK CONSTANT PLS_INTEGER := 70;
  MAX_TAGV CONSTANT PLS_INTEGER := 70;
  MAX_METRICN CONSTANT PLS_INTEGER := 70;
  
    -- EOL Char
  EOL VARCHAR2(2) := '
';

  
  --===================================================================================================================
  --  Returns the user stats as metrics
  --===================================================================================================================
  FUNCTION USERSTATS RETURN METRIC_ARR;

  --====================================================================================================
  -- Attempts to convert the results from the passed ref-cursor to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION SQLTOMETRICS(p IN RCUR) RETURN METRIC_ARR;  

  -- Decodes a class number to the class name
  FUNCTION DECODE_CLASS(classNum IN PLS_INTEGER) RETURN VARCHAR2;
  
  -- Add a metric 
  FUNCTION ADD_METRIC(met_ric IN METRIC) RETURN METRIC;
  -- Adds an array of metrics
  PROCEDURE ADD_METRICS(metrics IN METRIC_ARR);
  
  -- Trace from a ref cursor
  FUNCTION TRACE(p IN RCUR) RETURN INT;
  
  -- Closes any persistent connections
  PROCEDURE CLOSE_PERSISTENT_CONNS;
  
  -- Clear all metrics
  PROCEDURE CLEAR;
  
  -- Trace all metrics
  PROCEDURE TRACE(metrics IN METRIC_ARR);
  
  FUNCTION INDIRECT(p IN RCUR) RETURN SYS_REFCURSOR;
  
  -- *******************************************************
  --    Get current XID function
  -- *******************************************************
  FUNCTION CURRENTXID RETURN RAW;  

END TSDB_TRACER;
/

create or replace PACKAGE BODY TSDB_TRACER AS

--select N.NAME, TSDB_TRACER.DECODE_CLASS(N.CLASS) CLASSNAME, M.VALUE from v$mystat M, v$statname N
--WHERE M.STATISTIC# = N.STATISTIC#

  /* A map of in use metrics keyed by the metric key */
  activeMetrics XMETRIC_ARR;


  --===================================================================================================================
  --  Returns the user stats as metrics
  --===================================================================================================================
  FUNCTION USERSTATS RETURN METRIC_ARR IS
    metrics METRIC_ARR;
  BEGIN
    SELECT VALUE(T) BULK COLLECT INTO metrics FROM  TABLE(SQLTOMETRICS(CURSOR(
      SELECT M.VALUE, TSDB_UTIL.CLEAN(N.NAME) NAME, 'CLASS', TSDB_TRACER.DECODE_CLASS(N.CLASS) CLAZZ
      FROM v$mystat M, v$statname N
      WHERE M.STATISTIC# = N.STATISTIC#
      AND EXISTS (
        SELECT COLUMN_VALUE FROM TABLE(TSDB_UTIL.USERSTATKEYS())
        WHERE COLUMN_VALUE = TSDB_UTIL.CLEAN(N.NAME)
      )
    ))) T;
    RETURN metrics;
  END USERSTATS;
  


    -- Decodes a class number to the class name
  FUNCTION DECODE_CLASS(classNum IN PLS_INTEGER) RETURN VARCHAR2 IS
    name VARCHAR2(40);
  BEGIN
    select 
    decode (bitand(  1,classNum),  1,'User ',              '') ||
    decode (bitand(  2,classNum),  2,'Redo ',              '') ||
    decode (bitand(  4,classNum),  4,'Enqueue ',           '') ||
    decode (bitand(  8,classNum),  8,'Cache ',             '') ||
    decode (bitand( 16,classNum), 16,'Parallel Server ',   '') ||
    decode (bitand( 32,classNum), 32,'OS ',                '') ||
    decode (bitand( 64,classNum), 64,'SQL ',               '') ||
    decode (bitand(128,classNum),128,'Debug ',             '') INTO name FROM DUAL;
    RETURN name;
  END DECODE_CLASS;


  -- Add a metric 
  FUNCTION ADD_METRIC(met_ric IN METRIC) RETURN METRIC IS
  BEGIN
    activeMetrics(met_ric.METRICKEY()) := met_ric;
    RETURN met_ric;
  END ADD_METRIC;
  
  -- Adds an array of metrics
  PROCEDURE ADD_METRICS(metrics IN METRIC_ARR) IS
  BEGIN
    FOR i IN 1..metrics.COUNT LOOP
      IF(metrics(i) IS NOT NULL) THEN
        activeMetrics(metrics(i).METRICKEY()) := metrics(i);
      END IF;
    END LOOP;
  END ADD_METRICS;

  
  -- Clear all metrics
  PROCEDURE CLEAR IS
  BEGIN
    activeMetrics.delete();
  END CLEAR;
  
  -- Trace all metrics
  PROCEDURE TRACE(metrics IN METRIC_ARR) IS
    content CLOB;
    jsonText VARCHAR2(400);
    now TIMESTAMP(9) := SYSTIMESTAMP;
    req   UTL_HTTP.REQ;
    resp  UTL_HTTP.RESP;    
  BEGIN
    DBMS_LOB.CREATETEMPORARY(content, true, DBMS_LOB.CALL);
    DBMS_LOB.OPEN(content, DBMS_LOB.LOB_READWRITE);
    DBMS_LOB.WRITEAPPEND(content, 1, '[');      
    FOR i IN 1..metrics.COUNT LOOP
      IF(length(content) > 1) THEN
        DBMS_LOB.WRITEAPPEND(content, 1, ',');      
      END IF;
      jsonText := metrics(i).JSONMS();
      DBMS_LOB.WRITEAPPEND(content, length(jsonText), jsonText);      
    END LOOP;
    DBMS_LOB.WRITEAPPEND(content, 1, ']');    
    LOGGING.tcplog(content);
    req := UTL_HTTP.BEGIN_REQUEST (url=> 'http://pdk-pt-cltsdb-05.intcx.net:4242/api/put', method => 'POST');
    --UTL_HTTP.set_persistent_conn_support(req,true);
    UTL_HTTP.SET_HEADER (r      =>  req,
                       name   =>  'Content-Type',
                       value  =>  'application/json;charset=UTF-8');
    UTL_HTTP.SET_HEADER (r      =>   req,
                       name   =>   'Content-Length',
                       value  =>   length(content));
    UTL_HTTP.WRITE_TEXT (r      =>   req,
                       data   =>   content);    
    resp := UTL_HTTP.GET_RESPONSE(req);
    UTL_HTTP.END_RESPONSE(resp);
    EXCEPTION WHEN OTHERS THEN 
        DECLARE
          errm VARCHAR2(200) := SQLERRM();
        BEGIN
          LOGGING.tcplog('PIPE_TRADES ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
        END;
        RAISE;                    
    
    DBMS_LOB.CLOSE(content);
    DBMS_LOB.FREETEMPORARY(content);
  END TRACE;
  
    -- Closes any persistent connections
  PROCEDURE CLOSE_PERSISTENT_CONNS IS
  BEGIN
    UTL_HTTP.CLOSE_PERSISTENT_CONNS(host => 'pdk-pt-cltsdb-05.intcx.net', port => 4242);
  END CLOSE_PERSISTENT_CONNS;

  
  FUNCTION INDIRECT(p IN RCUR) RETURN SYS_REFCURSOR IS
  BEGIN    
    RETURN p;
  END INDIRECT;
  
  --====================================================================================================
  -- Attempts to convert the results from the passed ref-cursor to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION SQLTOMETRICS(p IN RCUR) RETURN METRIC_ARR IS
    cntr PLS_INTEGER := 0;
    pout RCUR;
    cursor_name INTEGER;
    rows_processed INTEGER;    
    desctab  DBMS_SQL.DESC_TAB2;
    colcnt   NUMBER;   
    colnum INT;
    hasTs BOOLEAN;
    tId PLS_INTEGER := 3;
    tagCount PLS_INTEGER;
    met METRIC := NULL;
    metrics METRIC_ARR := METRIC_ARR();
    metName VARCHAR2(100);
    metValue NUMBER;
    tagK VARCHAR2(100);
    tagV VARCHAR2(100);
    rowsFetched PLS_INTEGER := 0;
    execRows PLS_INTEGER := 0;
  BEGIN
    pout := INDIRECT(p);        
    cursor_name := DBMS_SQL.TO_CURSOR_NUMBER(pout);    
    DBMS_SQL.DESCRIBE_COLUMNS2(cursor_name, colcnt, desctab);
    IF(colcnt < 2) THEN
      RETURN metrics;
    END IF;
    hasTs := MOD(colcnt, 2) != 0;
    IF(hasTs) THEN
      tagCount := (colcnt - 3) / 2;
    ELSE
      tagCount := (colcnt - 2) / 2;
    END IF;
    DBMS_SQL.DEFINE_COLUMN(cursor_name, 1, metValue); 
    DBMS_SQL.DEFINE_COLUMN(cursor_name, 2, metName, 100); 
    FOR i IN 1..tagCount LOOP
      DBMS_SQL.DEFINE_COLUMN(cursor_name, tId, tagK, 100);
      tId := tId + 1;
      DBMS_SQL.DEFINE_COLUMN(cursor_name, tId, tagV, 100);
      tId := tId + 1;
    END LOOP;
    tId := 3;
    colnum := desctab.first;
    LOOP      
      rowsFetched := DBMS_SQL.FETCH_ROWS(cursor_name);
      EXIT WHEN rowsFetched = 0;
      IF(rowsFetched > 0) THEN
        cntr := cntr + 1;        
        DBMS_SQL.COLUMN_VALUE(cursor_name, 1, metValue);        
        DBMS_SQL.COLUMN_VALUE(cursor_name, 2, metName);
        met := METRIC(metName).HOSTAPPTAGS().VAL(metValue);
        FOR i IN 1..tagCount LOOP
          --IF(met IS NOT NULL) THEN met := met.CLEARTAGS().HOSTAPPTAGS(); END IF;
          DBMS_SQL.COLUMN_VALUE(cursor_name, tId, tagK);
          tId := tId + 1;
          DBMS_SQL.COLUMN_VALUE(cursor_name, tId, tagV);
          tId := tId + 1;
          met := met.PUSHTAG(tagK, tagV);
        END LOOP;
        tId := 3;
        metrics.EXTEND();
        metrics(cntr) := met;
        --LOGGING.tcplog(met.JSONMS());
      END IF;
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(cursor_name);
    RETURN metrics;
    EXCEPTION WHEN OTHERS THEN 
      DBMS_SQL.CLOSE_CURSOR(cursor_name);    
      DECLARE
        errm VARCHAR2(200) := SQLERRM();
      BEGIN
        LOGGING.tcplog('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
      END;
      RAISE;                    
  END SQLTOMETRICS;
  
    -- Trace from a ref cursor
  FUNCTION TRACE(p IN RCUR) RETURN INT IS
    metrics METRIC_ARR;
  BEGIN
    metrics := SQLTOMETRICS(p);
    IF(metrics IS NOT NULL AND metrics.COUNT > 0) THEN
      FOR i in 1..metrics.COUNT LOOP
        LOGGING.tcplog(metrics(i).JSONMS());
      END LOOP;
      RETURN metrics.COUNT;
    END IF;
    RETURN 0;
  END TRACE;
  
  -- *******************************************************
  --    Get current XID function
  -- *******************************************************
  FUNCTION CURRENTXID RETURN RAW IS
    txid    VARCHAR2(50) := DBMS_TRANSACTION.local_transaction_id;
    idx     pls_integer;
    xid     RAW(8);
    xid_usn  NUMBER;
    xid_slot NUMBER;
    xid_sqn  NUMBER;
    pos1    NUMBER;
    pos2    NUMBER;
  BEGIN
    IF txid IS NULL THEN
        --  ALSO SEE dbms_transaction.step_id
      txid := DBMS_TRANSACTION.local_transaction_id(true);
    END IF;
    pos1 := instr(txid, '.', 1, 1);
    pos2 := instr(txid, '.', pos1+1, 1);
    xid_usn := TO_NUMBER(substr(txid,1,pos1-1));
    xid_slot := TO_NUMBER(substr(txid,pos1+1,pos2-pos1));
    xid_sqn := TO_NUMBER(substr(txid,pos2+1));
    --SNAPTX;
    SELECT XID INTO xid FROM V$TRANSACTION WHERE XIDUSN = xid_usn AND XIDSLOT = xid_slot AND XIDSQN = xid_sqn AND STATUS = 'ACTIVE';
    return xid;
  END CURRENTXID;
  

  BEGIN
    UTL_HTTP.SET_PERSISTENT_CONN_SUPPORT(TRUE, 3);    
END TSDB_TRACER;
/

