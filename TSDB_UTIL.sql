create or replace PACKAGE TSDB_UTIL AS 

  -- Generic Ref Cursor
  TYPE TRACECUR IS REF CURSOR;
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

  
  --===================================================================================================================
  --  Returns the cleaned user statistic keys
  --===================================================================================================================
  FUNCTION USERSTATKEYS RETURN VARCHAR2_ARR;
  

  --===================================================================================================================
  --  Returns the delta between the fromTime and the toTime in milliseconds
  --  The fromTime in mandatory
  --  The toTime will default to SYSTIMESTAMP if null
  --===================================================================================================================
  FUNCTION ELAPSEDMS(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER;

  --===================================================================================================================
  --  Returns the delta between the fromTime and the toTime in seconds
  --  The fromTime in mandatory
  --  The toTime will default to SYSTIMESTAMP if null
  --===================================================================================================================
  FUNCTION ELAPSEDSEC(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER;
  
  --===================================================================================================================
  --  Returns the current time as the number of milliseconds since epoch (like java.lang.System.getCurrentTimeMillis())
  --===================================================================================================================
  FUNCTION CURRENTMS RETURN NUMBER;
  
  --===================================================================================================================
  --  Returns the current time as the number of seconds since epoch (unix time)
  --===================================================================================================================
  FUNCTION CURRENTSEC RETURN NUMBER;
  
  --===================================================================================================================
  --  Returns the sid for the current session
  --===================================================================================================================
  FUNCTION SESSION_SID RETURN NUMBER;
  
  --===================================================================================================================
  --  Returns the database name
  --===================================================================================================================
  FUNCTION DB_NAME RETURN VARCHAR2;
  
  --===================================================================================================================
  --  Returns the database host
  --===================================================================================================================
  FUNCTION DB_HOST RETURN VARCHAR2;
  
  --===================================================================================================================
  --  Returns the database IP address
  --===================================================================================================================
  FUNCTION DB_IP RETURN VARCHAR2;
  
  --===================================================================================================================
  --  Returns the host name of the connecting client this session was initiated by
  --===================================================================================================================
  FUNCTION CLIENT_HOST RETURN VARCHAR2;
  
  --===================================================================================================================
  --  Returns the db user name for this session
  --===================================================================================================================
  FUNCTION DB_USER RETURN VARCHAR2;  
  
  --===================================================================================================================
  --  Cleans the passed string to remove whitespace, lowercase and illegal punctuation
  --===================================================================================================================
  FUNCTION CLEAN(str IN VARCHAR2) RETURN VARCHAR2;
  
  --===================================================================================================================
  --  Cleans the passed string to remove whitespace, lowercase and illegal punctuation
  --===================================================================================================================
  PROCEDURE CLEAN(str IN OUT NOCOPY VARCHAR2);
  
  
END TSDB_UTIL;
/

create or replace PACKAGE BODY TSDB_UTIL AS

  /* The SID of the current session */
  sid NUMBER;
  /* The DB Name */
  dbName VARCHAR2(30);
  /* The DB host name */
  dbHost VARCHAR2(30);  
  /* The DB user name */
  dbUser VARCHAR2(30);    
  /* The DB IP Address */
  dbIp VARCHAR2(30);  
  /* The host name of the connected client */
  clientHost VARCHAR2(30);
  /* The user level stats names */
  userStatKeys_ VARCHAR2_ARR := VARCHAR2_ARR(
  'buffer_is_not_pinned_count',
  'bytes_received_via_sqlnet_from_client',
  'bytes_sent_via_sqlnet_to_client',
  'calls_to_get_snapshot_scn:_kcmgss',
  'calls_to_kcmgcs',
  'ccursor_%_sql_area_evicted',
  'consistent_gets',
  'consistent_gets_examination',
  'consistent_gets_examination_fastpath',
  'consistent_gets_from_cache',
  'consistent_gets_pin',
  'consistent_gets_pin_fastpath',
  'cpu_used_by_this_session',
  'cpu_used_when_call_started',
  'cursor_authentications',
  'db_time',
  'enqueue_releases',
  'enqueue_requests',
  'execute_count',
  'index_fetch_by_key',
  'index_scans_kdiixs1',
  'logical_read_bytes_from_cache',
  'no_work_consistent_read_gets',
  'nonidle_wait_count',
  'opened_cursors_cumulative',
  'parse_count_hard',
  'parse_count_total',
  'parse_time_elapsed',
  'recursive_calls',
  'recursive_cpu_usage',
  'requests_to_from_client',
  'rows_fetched_via_callback',
  'session_cursor_cache_count',
  'session_cursor_cache_hits',
  'session_logical_reads',
  'sorts_memory',
  'sorts_rows',
  'sqlnet_roundtrips_to_from_client',
  'table_fetch_by_rowid',
  'user_calls',
  'workarea_executions_optimal');  
  
  --===================================================================================================================
  --  Returns the cleaned user statistic keys
  --===================================================================================================================
  FUNCTION USERSTATKEYS RETURN VARCHAR2_ARR IS
  BEGIN
    RETURN userStatKeys_;
  END USERSTATKEYS;


  --===================================================================================================================
  --  Returns the delta between the fromTime and the toTime in milliseconds
  --  The fromTime in mandatory
  --  The toTime will default to SYSTIMESTAMP if null
  --===================================================================================================================
  FUNCTION ELAPSEDMS(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER AS
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := toTime - fromTime;
  BEGIN
    RETURN ROUND(
      (extract(day from delta)*24*60*60*1000) + 
      (extract(hour from delta)*60*60*1000) + 
      (extract(minute from delta)*60*1000) + 
      extract(second from delta*1000)
    ,0);
  END ELAPSEDMS;

  --===================================================================================================================
  --  Returns the delta between the fromTime and the toTime in seconds
  --  The fromTime in mandatory
  --  The toTime will default to SYSTIMESTAMP if null
  --===================================================================================================================
  FUNCTION ELAPSEDSEC(fromTime IN TIMESTAMP, toTime IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN NUMBER AS
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := toTime - fromTime;
  BEGIN
    RETURN ROUND(
      (extract(day from delta)*24*60*60) + 
      (extract(hour from delta)*60*60) + 
      (extract(minute from delta)*60) + 
      extract(second from delta)
    ,0);
  END ELAPSEDSEC;


  --===================================================================================================================
  --  Returns the current time as the number of milliseconds since epoch (like java.lang.System.getCurrentTimeMillis())
  --===================================================================================================================
  FUNCTION CURRENTMS RETURN NUMBER AS
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
  END CURRENTMS;

  --===================================================================================================================
  --  Returns the current time as the number of seconds since epoch (unix time)
  --===================================================================================================================
  FUNCTION CURRENTSEC RETURN NUMBER AS
    delta CONSTANT INTERVAL DAY (9) TO SECOND  := SYSTIMESTAMP - EPOCH;
  BEGIN  
    RETURN ROUND(
      (extract(day from delta)*24*60*60) + 
      (extract(hour from delta)*60*60) + 
      (extract(minute from delta)*60) + 
      extract(second from delta) - TZOFFSETSECS
    ,0);
  END CURRENTSEC;
  
  --===================================================================================================================
  --  Returns the sid for the current session
  --===================================================================================================================
  FUNCTION SESSION_SID RETURN NUMBER IS
  BEGIN
    RETURN sid;
  END SESSION_SID;
  
  --===================================================================================================================
  --  Returns the database name
  --===================================================================================================================
  FUNCTION DB_NAME RETURN VARCHAR2 IS
  BEGIN
    RETURN dbName;
  END DB_NAME;

  --===================================================================================================================
  --  Returns the database host
  --===================================================================================================================
  FUNCTION DB_HOST RETURN VARCHAR2 IS
  BEGIN
    RETURN dbHost;
  END DB_HOST;

  --===================================================================================================================
  --  Returns the database IP address
  --===================================================================================================================
  FUNCTION DB_IP RETURN VARCHAR2 IS
  BEGIN
    RETURN dbIp;
  END DB_IP;

  --===================================================================================================================
  --  Returns the host name of the connecting client this session was initiated by
  --===================================================================================================================
  FUNCTION CLIENT_HOST RETURN VARCHAR2 IS
  BEGIN
    RETURN clientHost;
  END CLIENT_HOST;
  
  --===================================================================================================================
  --  Returns the db user name for this session
  --===================================================================================================================
  FUNCTION DB_USER RETURN VARCHAR2 IS
  BEGIN
    RETURN dbUser;
  END DB_USER;
  
  
  --===================================================================================================================
  --  Cleans the passed string to remove whitespace, lowercase and illegal punctuation
  --===================================================================================================================
  FUNCTION CLEAN(str IN VARCHAR2) RETURN VARCHAR2 IS
    cs VARCHAR2(360);
  BEGIN
    IF(str IS NULL) THEN 
      RAISE_APPLICATION_ERROR(-20101, 'The passed varchar was null');
    END IF;
    cs := TRANSLATE(RTRIM(LTRIM(LOWER(str))), ' /*().+%', '__');
    IF(cs IS NULL) THEN 
      RAISE_APPLICATION_ERROR(-20101, 'The passed varchar was empty');
    END IF;    
    RETURN cs;
  END CLEAN;
  
  --===================================================================================================================
  --  Cleans the passed string to remove whitespace, lowercase and illegal punctuation
  --===================================================================================================================
  PROCEDURE CLEAN(str IN OUT NOCOPY VARCHAR2) IS
  BEGIN
    str := CLEAN(str);
  END CLEAN;
  

  --===================================================================================================================
  --  Initializes the session info for this session
  --===================================================================================================================
  BEGIN
    SELECT 
      SYS_CONTEXT('USERENV', 'SID'),
      SYS_CONTEXT('USERENV', 'DB_NAME'),
      SYS_CONTEXT('USERENV', 'SERVER_HOST'),
      SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
      SYS_CONTEXT('USERENV', 'HOST'),
      USER
      INTO sid, dbName, dbHost, dbIp, clientHost, dbUser FROM DUAL;    
END TSDB_UTIL;
/

