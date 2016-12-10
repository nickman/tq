create or replace type tagpair force as object ( 
  K VARCHAR(60),
  V VARCHAR(60),
  MEMBER FUNCTION TOJSON RETURN VARCHAR2,
  MEMBER FUNCTION TOPUT RETURN VARCHAR2,
  CONSTRUCTOR FUNCTION TAGPAIR(K IN VARCHAR, V IN VARCHAR) RETURN SELF AS RESULT
);
/
create or replace type body tagpair as

member function tojson return varchar2 as
  begin    
    return '"' || K || '":"' || V || '"';
  end tojson;
  
MEMBER FUNCTION TOPUT RETURN VARCHAR2 IS
BEGIN
  RETURN K || '=' || V;
END TOPUT;

constructor function tagpair(k in varchar, v in varchar) return self as result as
  begin
    IF(k IS NULL OR RTRIM(LTRIM(k)) IS NULL) THEN
      RAISE_APPLICATION_ERROR(-24000, 'The tag key was null or empty');
    END IF;
    IF(v IS NULL OR RTRIM(LTRIM(v)) IS NULL) THEN
      RAISE_APPLICATION_ERROR(-24000, 'The tag value was null or empty');
    END IF;
    SELF.k := RTRIM(LTRIM(k)); 
    SELF.v := RTRIM(LTRIM(v));
    return;
  end tagpair;

end;
/
create or replace PACKAGE TSDBCLIENT AS 
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
  
  -- writes a string based message to the specified host/port
  procedure tcpsend(message IN VARCHAR2, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 4242);
  -- writes a raw based message to the specified host/port
  procedure tcpsend(message IN RAW, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 4242);
  
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
  
  

END TSDBCLIENT;
/
CREATE OR REPLACE
PACKAGE BODY TSDBCLIENT AS
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
  FUNCTION TCPCONNECT(host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 1234) RETURN utl_tcp.connection AS
    c  utl_tcp.connection;
    key VARCHAR2(100) := LOWER(LTRIM(RTRIM(host))) || ':' || port;
  BEGIN
    IF sockets.EXISTS(key) THEN RETURN sockets(key); END IF;  
    c := utl_tcp.open_connection(remote_host => host,remote_port =>  port,  charset     => 'US7ASCII');  -- open connection
    sockets(key) := c;
    RETURN c;    
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(key);
      RETURN NULL;
  END TCPCONNECT;
  
  PROCEDURE TLOG(ts IN TIMESTAMP, sid IN NUMBER, message IN VARCHAR2) IS 
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO OFFLINE_LOGS(TS, SID, MESSAGE) VALUES (ts, sid, message);
    COMMIT;
  END TLOG;

  procedure tcpsend(message IN VARCHAR2, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 4242) AS
    ret_val pls_integer; 
    ts VARCHAR2(22) := NULL;
    c  utl_tcp.connection;
  BEGIN
    c := TCPCONNECT(host, port);
    IF(c.remote_port IS NOT NULL) THEN
      ts := TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3');
      ret_val := utl_tcp.write_line(c, message);       
    ELSE
      TLOG(SYSTIMESTAMP, sid, message);
    END IF;
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(host, port);    
      TLOG(SYSTIMESTAMP, sid, message);        
  END tcpsend;
  
  procedure tcpsend(message IN RAW, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 4242) AS
    ret_val pls_integer; 
    ts VARCHAR2(22) := NULL;
    c  utl_tcp.connection;
  BEGIN
    c := TCPCONNECT(host, port);
    IF(c.remote_port IS NOT NULL) THEN
      ts := TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3');
      ret_val := utl_tcp.write_line(c, message);       
    ELSE
      TLOG(SYSTIMESTAMP, sid, message);
    END IF;
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(host, port);    
      TLOG(SYSTIMESTAMP, sid, message);        
  END tcpsend;

  BEGIN
    SELECT SYS_CONTEXT('USERENV', 'SID') INTO sid FROM DUAL;        
    -- ADD HOST AND DBNAME for tags
END TSDBCLIENT;
/


create or replace type tsdbm as object 
( 
  METRIC VARCHAR2(200),
  TS NUMBER(22, 0),
  VALUE NUMBER,
  TAGS TAGPAIR_ARR,
  START_TS TIMESTAMP,
  BUFFER RAW(32767),
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
  CONSTRUCTOR FUNCTION TSDBM(metricName IN VARCHAR) RETURN SELF AS RESULT
);
/
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
  
  CONSTRUCTOR FUNCTION TSDBM(metricName IN VARCHAR) RETURN SELF AS RESULT IS
  BEGIN
    METRIC := metricName;
    TAGS := NEW TAGPAIR_ARR();
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
