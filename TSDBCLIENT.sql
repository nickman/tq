create or replace PACKAGE TSDBCLIENT authid definer AS 
  -- Defines a map of tcp connections keyed by host:port
  TYPE SOCKET IS TABLE OF utl_tcp.connection INDEX BY VARCHAR2(100);
  -- Timestamp instance to extract stuff from but is unchanging
  BASETS CONSTANT TIMESTAMP WITH TIME ZONE := SYSTIMESTAMP;
  -- The timzone offset hours
  TZHOUR CONSTANT PLS_INTEGER := extract(TIMEZONE_HOUR from BASETS);
  -- The timzone offset hours
  TZMINUTE CONSTANT PLS_INTEGER := extract(TIMEZONE_MINUTE from BASETS);  
  -- The epoch timestamp
  EPOCH CONSTANT TIMESTAMP := to_timestamp_tz('1970-01-01 ' || TZHOUR || ':' || TZMINUTE, 'YYYY-MM-DD TZH:TZM');  
  -- TZ Offset hours/minutes converted to seconds
  TZOFFSETSECS CONSTANT PLS_INTEGER := (TZHOUR*60*60) + (TZMINUTE*60);
  -- TZ Offset hours/minutes converted to ms
  TZOFFSETMS CONSTANT PLS_INTEGER := TZOFFSETSECS * 1000;
  -- The default max buffer size for TSDBM instances
  MAX_BUFFER_SIZE CONSTANT INT := 32767;
  -- EOL Char
  EOL VARCHAR2(2) := '
';
  
  -- writes a string based message to the specified host/port
  procedure tcpsend(message IN VARCHAR2, host IN VARCHAR2 DEFAULT '192.168.1.182', port IN PLS_INTEGER DEFAULT 4242);
  -- writes a raw based message to the specified host/port
--  procedure tcpsend(message IN RAW, host IN VARCHAR2 DEFAULT '192.168.1.182', port IN PLS_INTEGER DEFAULT 4242);
  
--=====================================================================================
--  The number of seconds since the epoch
--=====================================================================================
  FUNCTION EPOCHSEC RETURN NUMBER;
  
--=====================================================================================
--  The number of milliseconds since the epoch
--=====================================================================================
  FUNCTION EPOCHMS RETURN NUMBER;
  
--=====================================================================================
--  The elapsed seconds between the passed timestamps
--=====================================================================================
  FUNCTION ELAPSEDSEC(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER;
  
  FUNCTION T(p IN SYS_REFCURSOR) RETURN INT_ARR PIPELINED;
  
  

END TSDBCLIENT;

create or replace PACKAGE BODY TSDBCLIENT AS
  /* An associative array of connections keyed by host:port */
  sockets SOCKET;
  /* The SID of the current session */
  sid NUMBER;
  
  
--=====================================================================================
--  The number of seconds since the epoch
--=====================================================================================
  FUNCTION EPOCHSEC RETURN NUMBER IS    
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := SYSTIMESTAMP - EPOCH;
  BEGIN  
    RETURN ROUND(
      (extract(day from delta)*24*60*60) + 
      (extract(hour from delta)*60*60) + 
      (extract(minute from delta)*60) + 
      extract(second from delta) - TZOFFSETSECS
    ,0);
  END EPOCHSEC;
  
--=====================================================================================
--  The number of milliseconds since the epoch
--=====================================================================================
  FUNCTION EPOCHMS RETURN NUMBER IS    
    now TIMESTAMP := SYSTIMESTAMP;
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := now - EPOCH;
  BEGIN  
    RETURN ROUND(
      (extract(day from delta)*24*60*60*1000) + 
      (extract(hour from delta)*60*60*1000) + 
      (extract(minute from delta)*60*1000) + 
      extract(second from delta)*1000
       - (TZOFFSETSECS * 1000)
      + to_number(to_char(sys_extract_utc(now), 'FF3'))
    ,0);
  END EPOCHMS;
  
--=====================================================================================
--  The elapsed seconds between the passed timestamps
--=====================================================================================
  FUNCTION ELAPSEDSEC(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER IS
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := toTime - fromTime;
  BEGIN
    RETURN ROUND(
      (extract(day from delta)*24*60*60) + 
      (extract(hour from delta)*60*60) + 
      (extract(minute from delta)*60) + 
      extract(second from delta)
    ,0);
  END ELAPSEDSEC;
  
--=====================================================================================
--  The elapsed milli-seconds between the passed timestamps
--=====================================================================================
  FUNCTION ELAPSEDMS(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER IS
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := toTime - fromTime;
  BEGIN
    RETURN ROUND(
      (extract(day from delta)*24*60*60*1000) + 
      (extract(hour from delta)*60*60*1000) + 
      (extract(minute from delta)*60*1000) + 
      extract(second from delta*1000)
    ,0);
  END ELAPSEDMS;
  
  

  /* Disconnects the keyed connection */
  PROCEDURE DISCONNECT(key IN VARCHAR2) AS
  BEGIN
    IF sockets.EXISTS(key) THEN 
      BEGIN
        utl_tcp.close_connection(sockets(key));    
        EXCEPTION WHEN OTHERS THEN NULL;  
      END;
      sockets.DELETE(key);
    END IF;  
  END DISCONNECT;
  
  /* Disconnects the specified connection */
  PROCEDURE DISCONNECT(host IN VARCHAR2, port IN PLS_INTEGER) AS
    key VARCHAR2(100) := LOWER(LTRIM(RTRIM(host))) || ':' || port; 
  BEGIN
    DISCONNECT(key);
  END DISCONNECT;
  

  /* Returns a connection to the specified host/port or null if connection fails */
  FUNCTION TCPCONNECT(host IN VARCHAR2 DEFAULT '192.168.1.182', port IN PLS_INTEGER DEFAULT 4242) RETURN utl_tcp.connection AS
    c  utl_tcp.connection;
    key VARCHAR2(100) := LOWER(LTRIM(RTRIM(host))) || ':' || port;
  BEGIN
    IF sockets.EXISTS(key) THEN RETURN sockets(key); END IF;  
    c := utl_tcp.open_connection(remote_host => host,remote_port =>  port,  charset     => 'US7ASCII');  -- open connection
    sockets(key) := c;
    RETURN c;    
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(key);
      DECLARE
        err VARCHAR2(200) := SQLERRM;    
      BEGIN
        DBMS_OUTPUT.PUT_LINE(err);
      END;
      
      RETURN NULL;
  END TCPCONNECT;
  
  PROCEDURE TLOG(ts IN TIMESTAMP, sid IN NUMBER, message IN VARCHAR2) IS 
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO OFFLINE_LOGS(TS, SID, MESSAGE) VALUES (ts, sid, message);
    COMMIT;
  END TLOG;

  procedure tcpsend(message IN VARCHAR2, host IN VARCHAR2 DEFAULT '192.168.1.182', port IN PLS_INTEGER DEFAULT 4242) AS    
    ret_val pls_integer; 
    ts VARCHAR2(22) := NULL;
    c  utl_tcp.connection;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('SENDING VARCHAR2 MESSAGE');
    DBMS_OUTPUT.PUT_LINE('CONNECTING to [' || host || ':' || port || ']');
    c := TCPCONNECT(host, port);
    DBMS_OUTPUT.PUT_LINE('CONNECTED to [' || host || ':' || c.remote_port || ']');
    IF(c.remote_port IS NOT NULL) THEN
      ts := TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3');
      
      ret_val := utl_tcp.write_text(c, message);  
      UTL_TCP.FLUSH(c);
      DBMS_OUTPUT.PUT_LINE('SENT [' || message || ']');
    ELSE
      TLOG(SYSTIMESTAMP, sid, message);
      DBMS_OUTPUT.PUT_LINE('TLOG');
    END IF;
    EXCEPTION WHEN OTHERS THEN      
      --TLOG(SYSTIMESTAMP, sid, message);    
      DECLARE
        err VARCHAR2(200) := SQLERRM;    
      BEGIN
        DBMS_OUTPUT.PUT_LINE(err);
      END;
      DISCONNECT(host, port);    
  END tcpsend;
  
--  procedure tcpsend(message IN RAW, host IN VARCHAR2 DEFAULT '192.168.1.182', port IN PLS_INTEGER DEFAULT 4242) AS    
--    ret_val pls_integer; 
--    ts VARCHAR2(22) := NULL;
--    c  utl_tcp.connection;
--  BEGIN
--    DBMS_OUTPUT.PUT_LINE('SENDING RAW MESSAGE');
--    c := TCPCONNECT(host, port);
--    IF(c.remote_port IS NOT NULL) THEN
--      ts := TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3');
--      ret_val := utl_tcp.write_line(c, message);       
--    ELSE
--      TLOG(SYSTIMESTAMP, sid, message);
--    END IF;
--    EXCEPTION WHEN OTHERS THEN
--      DISCONNECT(host, port);    
--      TLOG(SYSTIMESTAMP, sid, message);        
--  END tcpsend;

  FUNCTION T(p IN SYS_REFCURSOR) RETURN INT_ARR PIPELINED IS
    px SYS_REFCURSOR := p;
    tsdb TQREACTOR.TSDBM := new TQREACTOR.TSDBM('');
  BEGIN
    tsdb := tsdb.trace(px);
    RETURN;
  END T;

  BEGIN
    SELECT SYS_CONTEXT('USERENV', 'SID') INTO sid FROM DUAL;        
    -- ADD HOST AND DBNAME for tags
END TSDBCLIENT;



create or replace type tsdbm as object 
( 
  METRIC VARCHAR2(200),
  TS NUMBER(22, 0),
  VALUE NUMBER,
  TAGS TAGPAIR_ARR,
  START_TS TIMESTAMP,
  BUFFER CLOB,
  MAX_SIZE INT,
  MEMBER FUNCTION BUFFERSIZE RETURN INT,
  MEMBER FUNCTION MAXBUFFERSIZE(maxSize IN INT) RETURN TSDBM,
  MEMBER FUNCTION TAG(k IN VARCHAR2, v IN VARCHAR2) RETURN TSDBM,
  MEMBER FUNCTION MET(m IN VARCHAR2) RETURN TSDBM,
  MEMBER FUNCTION VAL(v IN NUMBER) RETURN TSDBM,
  MEMBER FUNCTION TIME(ts IN NUMBER) RETURN TSDBM,
  MEMBER FUNCTION STARTTIME(startTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM,
  MEMBER FUNCTION ELAPSEDSEC(endTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM,
  MEMBER FUNCTION ELAPSEDMS(endTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM,
  MEMBER FUNCTION TOPUT RETURN VARCHAR2,
  MEMBER FUNCTION TOJSONSEC RETURN VARCHAR2,
  MEMBER FUNCTION TOJSONMS RETURN VARCHAR2,
  MEMBER FUNCTION FLUSH RETURN TSDBM,
  MEMBER FUNCTION TRACE RETURN TSDBM,
  MEMBER FUNCTION CLEAR RETURN TSDBM,
  MEMBER FUNCTION TRACE(p IN OUT SYS_REFCURSOR) RETURN TSDBM,
  MEMBER PROCEDURE RELEASE,
  CONSTRUCTOR FUNCTION TSDBM(metricName IN VARCHAR) RETURN SELF AS RESULT
);

create or replace type body tsdbm as

  MEMBER FUNCTION TAG(k in varchar2, v in varchar2) return tsdbm as
    me tsdbm := self;
  BEGIN
    me.TAGS.extend();
    me.tags(me.TAGS.COUNT) := NEW TAGPAIR(k, v);
    return me;
  END TAG;
  
  MEMBER FUNCTION MET(m IN VARCHAR2) RETURN TSDBM IS    
    me tsdbm := self;
  BEGIN
    me.METRIC := RTRIM(LTRIM(m));
    RETURN me;
  END MET;
  
  MEMBER FUNCTION VAL(v IN NUMBER) RETURN TSDBM IS
    me tsdbm := self;
  BEGIN
    me.VALUE := v;
    RETURN me;
  END VAL;
  
  MEMBER FUNCTION TIME(ts IN NUMBER) RETURN TSDBM IS
    me tsdbm := self;
  BEGIN
    me.TS := ts;
    RETURN me;
  END TIME;  
  
  MEMBER FUNCTION STARTTIME(startTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM IS
    me tsdbm := self;
  BEGIN
    me.START_TS := startTime;
    RETURN me;
  END STARTTIME;  
  
  MEMBER FUNCTION ELAPSEDMS(endTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM IS
  BEGIN
    RETURN VAL(ROUND(EXTRACT(SECOND FROM (endTime-START_TS)) * 1000, 0));
  END ELAPSEDMS;
  
  
  MEMBER FUNCTION ELAPSEDSEC(endTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN TSDBM IS
  BEGIN    
    RETURN VAL(ROUND(EXTRACT(SECOND FROM (endTime-START_TS)), 0));
  END ELAPSEDSEC;
  
  MEMBER FUNCTION TOPUT RETURN VARCHAR2 IS
     out VARCHAR(3000);
  BEGIN
    out := 'put ';
    RETURN out;
  END TOPUT;
  
  MEMBER FUNCTION TOJSONSEC RETURN VARCHAR2 IS
    out VARCHAR(3000);
    tgs VARCHAR(2000) := NULL;
  BEGIN
    out := '{ "metric":"' || METRIC || '","timestamp":' || NVL(TS, (ROUND((sysdate - TO_DATE('1969/12/31 19:00:00', 'YYYY/MM/DD HH24:MI:SS')) * 24 * 60 * 60, 0))) || 
      ',"value":' || VALUE || ',"tags": {';
    FOR i IN 1..TAGS.COUNT LOOP
      IF(tgs IS NOT NULL) THEN
        tgs := tgs || ',';
      END IF;
      tgs := tgs || TAGS(i).TOJSON();
    END LOOP;
    out := out || tgs || '}';
    RETURN out;
  END TOJSONSEC;
  
  MEMBER FUNCTION TOJSONMS RETURN VARCHAR2 IS
    out VARCHAR(3000);
    tgs VARCHAR(2000) := NULL;
  BEGIN
    out := '{ "metric":"' || METRIC || '","timestamp":' || NVL(TS, ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP)) * 1000, 0)) || 
      ',"value":' || VALUE || ',"tags": {';
    FOR i IN 1..TAGS.COUNT LOOP
      IF(tgs IS NOT NULL) THEN
        tgs := tgs || ',';
      END IF;
      tgs := tgs || TAGS(i).TOJSON();
    END LOOP;
    out := out || tgs || '}';
    RETURN out;
  END TOJSONMS;
  
  MEMBER FUNCTION BUFFERSIZE RETURN INT IS
  BEGIN
    RETURN DBMS_LOB.GETLENGTH(BUFFER);
  END BUFFERSIZE;
  
  MEMBER FUNCTION MAXBUFFERSIZE(maxSize IN INT) RETURN TSDBM IS
    me TSDBM := SELF;
  BEGIN
    IF(maxSize < 1 OR maxSize > TSDBCLIENT.MAX_BUFFER_SIZE) THEN
      RAISE_APPLICATION_ERROR(-20000, 'Invalid max buffer size [' || maxSize || ']. Must be gt 0 and lte ' || TSDBCLIENT.MAX_BUFFER_SIZE);
    END IF;
    me.MAX_SIZE := maxSize;
    IF(DBMS_LOB.GETLENGTH(BUFFER) > maxSize) THEN
      me := me.FLUSH();
    END IF;
    RETURN me;    
  END MAXBUFFERSIZE;
  
  MEMBER FUNCTION FLUSH RETURN TSDBM IS
    me TSDBM := SELF;
  BEGIN
    IF(LENGTH(me.BUFFER) > 0) THEN
      SYS.TSDBCLIENT.TCPSEND(me.BUFFER);
      DBMS_LOB.TRIM(me.BUFFER, 0);
    END IF;
    RETURN me;
  END FLUSH;
  
  MEMBER PROCEDURE RELEASE IS
  BEGIN
    DBMS_LOB.CLOSE(BUFFER);
    DBMS_LOB.FREETEMPORARY(BUFFER);
  END RELEASE;
  
  MEMBER FUNCTION TRACE RETURN TSDBM IS
    me TSDBM := SELF;
    b VARCHAR2(2000);
    len INT := DBMS_LOB.GETLENGTH(BUFFER);
  BEGIN
    -- put $metric $now $value dc=$DC host=$HOST    
    b := 'put ' || METRIC || ' ' || TSDBCLIENT.EPOCHSEC() || ' ' || VALUE || ' ';
    FOR i in 1..TAGS.COUNT LOOP
      b := b || TAGS(i).TOPUT() || ' ';
    END LOOP;
    b := b || TSDBCLIENT.EOL;
    IF(LENGTH(b) + DBMS_LOB.GETLENGTH(BUFFER) > MAX_SIZE) THEN
      me := me.FLUSH;
      len := 0;
    END IF;
    DBMS_LOB.WRITE(me.BUFFER, LENGTH(b), len+1, LOWER(b));
    RETURN me;
  END TRACE;
  
  MEMBER FUNCTION CLEAR RETURN TSDBM IS
    me TSDBM := SELF;
  BEGIN
    me.TS := NULL;
    me.VALUE := NULL;
    me.TAGS.DELETE();
    RETURN me;
  END CLEAR; 
  
  
  MEMBER FUNCTION TRACE(p IN OUT SYS_REFCURSOR) RETURN TSDBM IS
    -- <VALUE>, <METRIC NAME>, <TAG KEY 1>, <TAG VALUE 2>, .... <TAG KEY n>, <TAG VALUE n>, [<TIMESTAMP / DATE>]
    me TSDBM := SELF;
    col_cnt INTEGER;
    desctab  DBMS_SQL.DESC_TAB;
    curid NUMBER;
    col_num    NUMBER;
    hasTs BOOLEAN;
    tagCount PLS_INTEGER;
    tagK VARCHAR2(60);
    tagV VARCHAR2(60);
    tId PLS_INTEGER := 3;
  BEGIN
    curid := DBMS_SQL.TO_CURSOR_NUMBER(p);
    DBMS_SQL.DESCRIBE_COLUMNS(curid, col_cnt, desctab);
    IF(col_cnt < 2) THEN
      RETURN me;
    END IF;
    me := me.CLEAR();
    hasTs := MOD(col_cnt, 2) != 0;
    IF(hasTs) THEN
      tagCount := (col_cnt - 3) / 2;
    ELSE
      tagCount := (col_cnt - 2) / 2;
    END IF;
    
    col_num := desctab.first;
    LOOP 
      IF DBMS_SQL.FETCH_ROWS(curid)>0 THEN 
         DBMS_SQL.COLUMN_VALUE(curid, 1, me.VALUE);     
         DBMS_SQL.COLUMN_VALUE(curid, 2, me.METRIC);
         FOR i in 1..tagCount LOOP
          DBMS_SQL.COLUMN_VALUE(curid, tId, tagK);     
          tId := tId + 1;
          DBMS_SQL.COLUMN_VALUE(curid, tId, tagV);
          tId := tId + 1;
          me := me.TAG(tagK, tagV);
         END LOOP;
         me := me.trace().clear();
      END IF;
    END LOOP;
    RETURN me;
  END TRACE;
  
  
  CONSTRUCTOR FUNCTION TSDBM(metricName IN VARCHAR) RETURN SELF AS RESULT IS
  BEGIN
    METRIC := metricName;
    TAGS := NEW TAGPAIR_ARR();
    MAX_SIZE := TSDBCLIENT.MAX_BUFFER_SIZE;
    DBMS_LOB.CREATETEMPORARY(BUFFER, TRUE);
    DBMS_LOB.OPEN(BUFFER, DBMS_LOB.LOB_READWRITE);
    RETURN;
  END TSDBM;
  
end;

--{
--    "metric": "sys.cpu.nice",
--    "timestamp": 1346846400,
--    "value": 18,
--    "tags": {
--       "host": "web01",
--       "dc": "lga"
--    }
--}


--  METRIC VARCHAR2(200),
--  TS NUMBER(22, 0),
--  VALUE NUMBER,
--  TAGS TAGPAIR_ARR,
--  START_TS TIMESTAMP,

/


SELECT * FROM TABLE(SYS.TSDBCLIENT.t(cursor(
    SELECT count(v.username), 'conns', 'app', instance_name, 'host', i.HOST_NAME, 'user', v.username, 'status', v.status from gv$session v, v$instance i  where i.instance_number = v.INST_ID AND type != 'BACKGROUND' and v.username is not null group by v.username, v.status, instance_name, i.HOST_NAME
)));
