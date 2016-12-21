--------------------------------------------------------
--  File created - Wednesday-December-21-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Type METRIC
--------------------------------------------------------

  CREATE OR REPLACE TYPE "METRIC" FORCE AS OBJECT (
  -- The metric name
  METRICNAME VARCHAR2(100),
  -- The metric tags
  TAGS TAGPAIR_ARR,
  -- The effective timestamp of this metric instance
  TSTAMP NUMBER,
  -- The effective value of this metric instance
  VALUE NUMBER,
  -- Start time of a measurement on this metric  
  START_TIME TIMESTAMP(9),  
  -- The elapsed time of a measurement on this metric, if the value is not the elapsed time
  TIMING NUMBER,
  -- Adds a new tagpair to this metric
  MEMBER FUNCTION PUSHTAG(tag IN TAGPAIR) RETURN METRIC,
  -- Adds a new tagpair to this metric
  MEMBER FUNCTION PUSHTAG(k IN VARCHAR2, v IN VARCHAR2) RETURN METRIC,  
  -- Pops the specified number of tagpairs from this metric, defaulting to 1 
  MEMBER FUNCTION POPTAG(tagCnt IN INT DEFAULT 1) RETURN METRIC,
  -- Clears all tags
  MEMBER FUNCTION CLEARTAGS RETURN METRIC,
  -- Sets the value of this metric
  MEMBER FUNCTION VAL(v IN NUMBER) RETURN METRIC,
  -- Sets the effective timestamp of this metric
  MEMBER FUNCTION TS(ts IN NUMBER) RETURN METRIC,
  -- Starts a new timing at the specified timestamp, defaulting to SYSTIMESTAMP
  MEMBER FUNCTION OPEN(ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN METRIC,
  -- Completes a timing computing the elapsed time from the passed timestamp (default SYSTIMESTAMP)
  -- If the passed value is null, the metric value is the elapsed time in ms.
  MEMBER FUNCTION CLOSE(ts IN TIMESTAMP DEFAULT SYSTIMESTAMP, mvalue IN NUMBER DEFAULT NULL) RETURN METRIC,
  -- Returns this metric as a JSON string with a ms timestamp
  MEMBER FUNCTION JSONMS(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2,
  -- Returns this metric as a JSON string with a sec timestamp
  MEMBER FUNCTION JSONSEC(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2,  
  -- Returns this metric as a telnet put command string with a ms timestamp
  MEMBER FUNCTION PUTMS(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2,
  -- Returns this metric as a telnet put command string with a sec timestamp
  MEMBER FUNCTION PUTSEC(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2,  
  -- Adds the default metrics for host and app
  MEMBER FUNCTION HOSTAPPTAGS RETURN METRIC,
  -- Updates this metric, setting the value to passed-metric.VALUE - this-metric.VALUE and setting the timestamp. Returns this metric.
  MEMBER FUNCTION DELTA(met_ric IN METRIC, ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN METRIC,  
  -- Updates this metric, setting the value to passed-metric.VALUE - this-metric.VALUE and setting the timestamp.
  MEMBER PROCEDURE DELTA(met_ric IN METRIC, ts IN TIMESTAMP DEFAULT SYSTIMESTAMP),  
  
  -- Generates a unique key for this metric made up of the metric name and tag keys concatenated together  
  MEMBER FUNCTION METRICKEY RETURN VARCHAR2,
  -- Parameterized metric renderer
    -- met_ric: The metric to render
    -- ts: The optional timestamp to use to trace. If null, uses current time. If supplied, should be time since epoch in seconds or milliseconds
    -- tsInMs: If ts is not supplied, indicates if the current time is rendered in ms (true) or seconds (false)
    -- asJson: If true, renders in JSON, otherwise renders as a telnet put  
  STATIC FUNCTION RENDER(met_ric IN OUT NOCOPY METRIC, ts IN NUMBER DEFAULT NULL, tsInMs IN BOOLEAN DEFAULT TRUE, asJson IN BOOLEAN DEFAULT TRUE) RETURN VARCHAR2,
  -- Sorts a TAGPAIR array
  STATIC FUNCTION SORT(tags IN TAGPAIR_ARR) RETURN TAGPAIR_ARR,
  -- Creates a new Metric. The name is mandatory, the tags default to an empty array if null
  CONSTRUCTOR FUNCTION METRIC(name IN VARCHAR2, tags IN TAGPAIR_ARR DEFAULT TAGPAIR_ARR()) RETURN SELF AS RESULT
);
/
CREATE OR REPLACE TYPE BODY "METRIC" AS

  -- Adds a new tagpair to this metric
  MEMBER FUNCTION PUSHTAG(tag IN TAGPAIR) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.TAGS.extend();
    me.TAGS(TAGS.COUNT + 1) := tag;
    RETURN me;
  END PUSHTAG;
  
  -- Adds a new tagpair to this metric
  MEMBER FUNCTION PUSHTAG(k IN VARCHAR2, v IN VARCHAR2) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.TAGS.extend();
    me.TAGS(TAGS.COUNT + 1) := TAGPAIR(TSDB_UTIL.CLEAN(k),TSDB_UTIL.CLEAN(v));
    RETURN me;
  END PUSHTAG;
  
  
  -- Pops the specified number of tagpairs from this metric, defaulting to 1 
  MEMBER FUNCTION POPTAG(tagCnt IN INT DEFAULT 1) RETURN METRIC AS
    me METRIC := SELF;
    sz CONSTANT INT := me.TAGS.COUNT;
  BEGIN
    IF(TAGS.COUNT > 0) THEN
      FOR i in 1..sz LOOP
        --me.TAGS.DELETE(TAGS.COUNT);
        me.TAGS.TRIM();
        EXIT WHEN me.TAGS.COUNT = 0;
      END LOOP;
    END IF;
    RETURN me;
  END POPTAG;
  
    -- Clears all tags
  MEMBER FUNCTION CLEARTAGS RETURN METRIC  AS
    me METRIC := SELF;    
  BEGIN
    me.TAGS.DELETE();
    RETURN me;
  END CLEARTAGS;
  
  -- Sets the value for this metric
  MEMBER FUNCTION VAL(v IN NUMBER) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.VALUE := v;
    RETURN me;
  END VAL;
  
  -- Sets the effective timestamp of this metric
  MEMBER FUNCTION TS(ts IN NUMBER) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.TSTAMP:= ts;
    RETURN me;
  END TS;  
  
  
  -- Starts a new timing at the specified timestamp, defaulting to SYSTIMESTAMP
  MEMBER FUNCTION OPEN(ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.START_TIME := ts;
    RETURN me;
  END OPEN;
  
  -- Completes a timing computing the elapsed time from the passed timestamp (default SYSTIMESTAMP)
  -- If the passed value is null, the metric value is the elapsed time in ms.
  MEMBER FUNCTION CLOSE(ts IN TIMESTAMP DEFAULT SYSTIMESTAMP, mvalue IN NUMBER DEFAULT NULL) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    IF(mvalue IS NULL) THEN
      me.VALUE := TSDB_UTIL.ELAPSEDMS(me.START_TIME, ts);
    ELSE
      me.VALUE := mvalue;
      me.TIMING := TSDB_UTIL.ELAPSEDMS(me.START_TIME, ts);
    END IF;    
    RETURN me;
  END CLOSE;
  
  -- Updates this metric, setting the value to passed-metric.VALUE - this-metric.VALUE and setting the timestamp.
  -- Returns this metric
  MEMBER FUNCTION DELTA(met_ric IN METRIC, ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me.VALUE := met_ric.VALUE - me.VALUE;
    me.TSTAMP := TSDB_UTIL.ELAPSEDMS(TSDB_UTIL.EPOCH, ts);
    RETURN me;
  END DELTA;
  
  -- Updates this metric, setting the value to passed-metric.VALUE - this-metric.VALUE and setting the timestamp.
  MEMBER PROCEDURE DELTA(met_ric IN METRIC, ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS
  BEGIN
    VALUE := met_ric.VALUE - VALUE;
    TSTAMP := TSDB_UTIL.ELAPSEDMS(TSDB_UTIL.EPOCH, ts);
  END DELTA;
  
  
    -- Adds the default metrics for host and app
  MEMBER FUNCTION HOSTAPPTAGS RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    me := me.PUSHTAG(TAGPAIR('host', TSDB_UTIL.DB_HOST));
    me := me.PUSHTAG(TAGPAIR('app', TSDB_UTIL.DB_NAME));
    me := me.PUSHTAG(TAGPAIR('user', TSDB_UTIL.DB_USER));
    RETURN me;
  END HOSTAPPTAGS;
  
  -- Parametersized metric renderer
    -- met_ric: The metric to render
    -- ts: The optional timestamp to use to trace. If null, uses current time. If supplied, should be time since epoch in seconds or milliseconds
    -- tsInMs: If ts is not supplied, indicates if the current time is rendered in ms (true) or seconds (false)
    -- asJson: If true, renders in JSON, otherwise renders as a telnet put
  STATIC FUNCTION RENDER(met_ric IN OUT NOCOPY METRIC, ts IN NUMBER DEFAULT NULL, tsInMs IN BOOLEAN DEFAULT TRUE, asJson IN BOOLEAN DEFAULT TRUE) RETURN VARCHAR2 AS
    met VARCHAR2(1000);
    delim CHAR(1);
    endchar VARCHAR2(3);
    sz PLS_INTEGER := met_ric.TAGS.COUNT;
  BEGIN
    met_ric.TAGS := METRIC.SORT(met_ric.TAGS);
    IF(ts IS NULL) THEN
      IF(tsInMs) THEN
        met_ric.TSTAMP := TSDB_UTIL.CURRENTMS();
      ELSE 
        met_ric.TSTAMP := TSDB_UTIL.CURRENTSEC();
      END IF;
    ELSE
      met_ric.TSTAMP := ts;
    END IF;
  
    IF(asJson) THEN
      met := '{"metric":"' || met_ric.METRICNAME || '","value":' || met_ric.VALUE || ',"timestamp":' || met_ric.TSTAMP || ',"tags":{';
      delim := ',';
      endchar := '}}';
    ELSE
      -- put $metric $now $value dc=$DC host=$HOST
      met := 'put ' || met_ric.METRICNAME || ' ' || met_ric.TSTAMP || ' ' || met_ric.VALUE || ' ';
      delim := ' ';
      endchar := TSDB_UTIL.EOL;
    END IF;

    FOR i in 1..sz LOOP
      IF(i > 1) THEN
        met := met || delim;
      END IF;
      IF(asJson) THEN
        met := met || met_ric.TAGS(i).JSON();
      ELSE
        met := met || met_ric.TAGS(i).PUT();
      END IF;
    END LOOP;
    met := met || endchar;
    RETURN met;
  END RENDER;
  
    -- Returns this metric as a JSON string with a ms timestamp
  MEMBER FUNCTION JSONMS(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2 AS
    me METRIC := SELF;
  BEGIN
    RETURN METRIC.RENDER(me, ts, TRUE, TRUE);
  END JSONMS;
  
  -- Returns this metric as a JSON string with a sec timestamp
  MEMBER FUNCTION JSONSEC(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2  AS
    me METRIC := SELF;
  BEGIN
    RETURN METRIC.RENDER(me, ts, FALSE, TRUE);
  END JSONSEC;
  
  -- Returns this metric as a telnet put command string with a ms timestamp
  MEMBER FUNCTION PUTMS(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2 AS
    me METRIC := SELF;
  BEGIN
    RETURN METRIC.RENDER(me, ts, TRUE, FALSE);
  END PUTMS;
  
  -- Returns this metric as a telnet put command string with a sec timestamp
  MEMBER FUNCTION PUTSEC(ts IN NUMBER DEFAULT NULL) RETURN VARCHAR2 AS
    me METRIC := SELF;
  BEGIN
    RETURN METRIC.RENDER(me, ts, FALSE, FALSE);
  END PUTSEC;
  
  -- Sorts a TAGPAIR array
  STATIC FUNCTION SORT(tags IN TAGPAIR_ARR) RETURN TAGPAIR_ARR AS
    tparr TAGPAIR_ARR;
  BEGIN
    SELECT VALUE(T) BULK COLLECT INTO tparr FROM TABLE(tags) T ORDER BY VALUE(T);
    RETURN tparr;
  END SORT;

  -- Generates a unique key for this metric made up of the metric name and tag keys concatenated together
  MEMBER FUNCTION METRICKEY RETURN VARCHAR2 AS
    key VARCHAR2(320);
  BEGIN
    SELECT METRICNAME || ':' || LISTAGG(T.K || '=' || T.V, ',') WITHIN GROUP (ORDER BY VALUE(T)) INTO key FROM TABLE(TAGS) T;
    RETURN key;
  END METRICKEY;
  
  
  -- Creates a new Metric. The name is mandatory, the tags default to an empty array if null
  CONSTRUCTOR FUNCTION METRIC(name IN VARCHAR2, tags IN TAGPAIR_ARR DEFAULT TAGPAIR_ARR()) RETURN SELF AS RESULT AS
  BEGIN
    IF(name IS NULL) THEN
      RAISE_APPLICATION_ERROR(-20101, 'Metric name was null');
    END IF;
    
    METRICNAME := TSDB_UTIL.CLEAN(name);
    IF(METRICNAME IS NULL) THEN
      RAISE_APPLICATION_ERROR(-20101, 'Metric name was null');
    END IF;
    
    SELF.TAGS := tags;
    
    RETURN;
  END;
END;

/
--------------------------------------------------------
--  DDL for Type METRIC_ARR
--------------------------------------------------------

  CREATE OR REPLACE TYPE "METRIC_ARR" as table of metric

/
--------------------------------------------------------
--  DDL for Type TAGPAIR
--------------------------------------------------------

  CREATE OR REPLACE TYPE "TAGPAIR" force as object ( 
  K VARCHAR(60),
  V VARCHAR(60),
  MEMBER FUNCTION JSON RETURN VARCHAR2,
  MEMBER FUNCTION PUT RETURN VARCHAR2,
  CONSTRUCTOR FUNCTION TAGPAIR(K IN VARCHAR, V IN VARCHAR) RETURN SELF AS RESULT,
  CONSTRUCTOR FUNCTION TAGPAIR RETURN SELF AS RESULT,
  ORDER MEMBER FUNCTION MATCH(tp IN TAGPAIR) RETURN INTEGER
);
/
CREATE OR REPLACE TYPE BODY "TAGPAIR" as

  member function json return varchar2 as
    begin    
      return '"' || K || '":"' || V || '"';
    end json;
    
  MEMBER FUNCTION PUT RETURN VARCHAR2 IS
  BEGIN
    RETURN K || '=' || V;
  END PUT;
  
  constructor function tagpair(k in varchar, v in varchar) return self as result as
    begin
      IF(k IS NULL OR RTRIM(LTRIM(k)) IS NULL) THEN
        RAISE_APPLICATION_ERROR(-24000, 'The tag key was null or empty');
      END IF;
      IF(v IS NULL OR RTRIM(LTRIM(v)) IS NULL) THEN
        RAISE_APPLICATION_ERROR(-24000, 'The tag value was null or empty');
      END IF;
      SELF.k := TSDB_UTIL.CLEAN(k); 
      SELF.v := TSDB_UTIL.CLEAN(v);
      return;
    end tagpair;
  
  CONSTRUCTOR FUNCTION TAGPAIR RETURN SELF AS RESULT AS
  BEGIN
    RAISE_APPLICATION_ERROR(-20101, 'Must provide key and value for tagpair. Please use constructor function tagpair(k in varchar, v in varchar)');
  END;

  ORDER MEMBER FUNCTION MATCH(tp IN TAGPAIR) RETURN INTEGER IS
    me TAGPAIR := SELF;
  BEGIN
    IF(tp IS NULL) THEN RETURN NULL; END IF;
    --
    IF(me.K = 'host') THEN
      IF(tp.K = 'host') THEN
        RETURN 0;
      ELSE
        RETURN -1;
      END IF;
    ELSIF(me.K = 'app') THEN
      IF(tp.K = 'app') THEN
        RETURN 0;
      ELSE
        RETURN -1;
      END IF;
    ELSE
      IF(tp.K = 'host' OR tp.K = 'app') THEN
        RETURN 1;
      ELSIF(me.K = tp.K) THEN
        RETURN 0;
      ELSIF(me.K < tp.K) THEN
        RETURN -1;
      ELSE
        RETURN 0;
      END IF;    
    END IF;
  END;

end;

/
--------------------------------------------------------
--  DDL for Type TAGPAIR_ARR
--------------------------------------------------------

  CREATE OR REPLACE TYPE "TAGPAIR_ARR" IS  TABLE OF TAGPAIR;

/
--------------------------------------------------------
--  DDL for Type VARCHAR2_ARR
--------------------------------------------------------

  CREATE OR REPLACE TYPE "VARCHAR2_ARR" FORCE IS TABLE OF VARCHAR2(200);

/
--------------------------------------------------------
--  DDL for Package TSDB_TRACER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "TSDB_TRACER" authid definer AS 
  /* Type defining a map of metrics keyed by the metric key */
  TYPE XMETRIC_ARR IS TABLE OF METRIC INDEX BY VARCHAR2(360);
  /* Type defining a stack of metric arrays for handling nested delta measurements */
  TYPE XMETRIC_ARR_STACK IS TABLE OF XMETRIC_ARR INDEX BY PLS_INTEGER;
  /* Ref Cursor Def */
  TYPE RCUR IS REF CURSOR;
  
  
  /* The max size of a tag key */
  MAX_TAGK CONSTANT PLS_INTEGER := 70;
  /* The max size of a tag value */
  MAX_TAGV CONSTANT PLS_INTEGER := 70;
  /* The max size of a metric name */
  MAX_METRICN CONSTANT PLS_INTEGER := 70;
  
  --==================================================================================
  -- Exception codes
  --==================================================================================
  /* Raised when a metric is added to the stack but there is no current stack entry */
  no_metric_stack_entry EXCEPTION;
  /* Raised when an invalid depth is provided when adding or updating metrics in the specified stack entry */
  invalid_stack_depth EXCEPTION;
  
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
  FUNCTION REFCURTOMETRICS(p IN OUT SYS_REFCURSOR) RETURN METRIC_ARR;  
  
  --====================================================================================================
  -- Converts the results from the passed SQL query to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION SQLTOMETRICS(query IN VARCHAR2) RETURN METRIC_ARR;  

  -- Decodes a class number to the class name
  FUNCTION DECODE_CLASS(classNum IN PLS_INTEGER) RETURN VARCHAR2;
  
  -- Add a metric to the metric stack entry at the specified mdepth
  FUNCTION ADD_METRIC(mdepth IN INT, met_ric IN METRIC) RETURN METRIC;
  -- Adds an array of metrics to the metric stack entry at the specified mdepth
  PROCEDURE ADD_METRICS(mdepth IN INT, metrics IN METRIC_ARR);
  
  -- Trace from a ref cursor
  FUNCTION TRACE(p IN RCUR) RETURN INT;
  
  -- Closes any persistent connections
  PROCEDURE CLOSE_PERSISTENT_CONNS;
  
  -- Clear all metrics
  PROCEDURE CLEARSTACK;
  
  -- Clear all metrics in the current stack and pops the entry
  PROCEDURE CLEAR;

  -- Starts a new metric stack and returns the new depth
  FUNCTION STARTMETRICSTACK RETURN INT;
  
  -- Trace all metrics
  PROCEDURE TRACE(metrics IN METRIC_ARR);
  
  FUNCTION INDIRECT(p IN RCUR) RETURN SYS_REFCURSOR;
  
  -- *******************************************************
  --    Get current XID function
  -- *******************************************************
  FUNCTION CURRENTXID RETURN RAW;  

END TSDB_TRACER;

/
--------------------------------------------------------
--  DDL for Package TSDB_UTIL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "TSDB_UTIL" AS 

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
