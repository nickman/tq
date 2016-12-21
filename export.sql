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
  -- Sleeps the specified number of seconds and returns this metric
  MEMBER FUNCTION SLEEP(secs IN NUMBER) RETURN METRIC,
  
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
  -- Parse a metric name
  STATIC FUNCTION PARSE(name IN VARCHAR2) RETURN VARCHAR2_ARR,
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
    LOGGING.tcplog('mev:' || me.VALUE || ',iv:' || met_ric.VALUE);
    me.VALUE := met_ric.VALUE - me.VALUE;
    LOGGING.tcplog('mev:' || me.VALUE);
    me.TSTAMP := TSDB_UTIL.CURRENTMS;
    RETURN me;
  END DELTA;
  
  -- Updates this metric, setting the value to passed-metric.VALUE - this-metric.VALUE and setting the timestamp.
  MEMBER PROCEDURE DELTA(met_ric IN METRIC, ts IN TIMESTAMP DEFAULT SYSTIMESTAMP) AS
  BEGIN
    LOGGING.tcplog('mev:' || VALUE || ',iv:' || met_ric.VALUE);
    VALUE := met_ric.VALUE - VALUE;
    LOGGING.tcplog('mev:' || VALUE);
    TSTAMP := TSDB_UTIL.CURRENTMS;
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
  
  -- Sleeps the specified number of seconds and returns this metric
  MEMBER FUNCTION SLEEP(secs IN NUMBER) RETURN METRIC AS
    me METRIC := SELF;
  BEGIN
    DBMS_LOCK.SLEEP(secs);
    RETURN me;
  END SLEEP;
  
  
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
  
  -- Parse a metric name
  STATIC FUNCTION PARSE(name IN VARCHAR2) RETURN VARCHAR2_ARR IS
    rarr VARCHAR2_ARR := VARCHAR2_ARR();
    x PLS_INTEGER := 0;
    tname VARCHAR2(1000) := RTRIM(LTRIM(name));
  BEGIN
    x := INSTR(name, ':');
    rarr.extend();
    rarr(1) := SUBSTR(tname, 0, x-1);
    tname := SUBSTR(tname, x+1);
    
    
    
    rarr.extend();
    rarr(2) := tname;
    return rarr;
    EXCEPTION WHEN OTHERS THEN
      DECLARE
      errm VARCHAR2(1000) := SQLERRM();
      BEGIN
        RAISE_APPLICATION_ERROR(-20101, 'Could not parse metric [' || name || ']: ' || errm);
      END;    
  END PARSE;
  
  
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
--------------------------------------------------------
--  DDL for Package TSDB_TRACER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "TSDB_TRACER" authid definer AS 
  /* Type defining a map of metrics keyed by the metric key */
  TYPE XMETRIC_ARR IS TABLE OF METRIC INDEX BY VARCHAR2(360);
  /* Type defining a stack of metric arrays for handling nested delta measurements */
  TYPE XMETRIC_ARR_STACK IS TABLE OF XMETRIC_ARR INDEX BY PLS_INTEGER;
  /* Type defining a map of metric arrays keyed by a supplied logical name */
  TYPE XMETRIC_NAMED_ARR IS TABLE OF XMETRIC_ARR INDEX BY VARCHAR2(360);
  
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
  /* Raised when a metric is added to the stack, or the current stack is cleared but there is no current stack entry */
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
  -- Adds an array of metrics to the metric stack entry at the specified mdepth, returns the mdepth
  FUNCTION ADD_METRICS(mdepth IN INT, metrics IN METRIC_ARR) RETURN INT;
  
  -- Update a delta metric in the metric stack entry at the specified mdepth
  -- Returns the updated metric
  FUNCTION UPDATE_DELTA_METRIC(mdepth IN INT, met_ric IN METRIC) RETURN METRIC;
  -- Updates an array of delta metrics in the metric stack entry at the specified mdepth
  PROCEDURE UPDATE_DELTA_METRICS(mdepth IN INT, metrics IN METRIC_ARR);
  
--  -- Stacks the passed metrics and starts their elapsed times
--  FUNCTION START_ELAPSED_METRIC(mdepth IN INT, metrics IN METRIC_ARR) RETURN METRIC;
  
  
  
  -- Pops a metric array off the metric stack
  FUNCTION POP RETURN METRIC_ARR;
  
  FUNCTION PIPEX(xarr IN XMETRIC_ARR) RETURN METRIC_ARR PIPELINED;
  
  FUNCTION TOX(arr IN METRIC_ARR) RETURN XMETRIC_ARR;
  
  PROCEDURE DEBUG_UPDATE(mdepth IN INT);
  
  
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
--  DDL for Package PARSE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "PARSE" 
/*
   Generalized delimited string parsing package

   Author: Steven Feuerstein, steven@stevenfeuerstein.com

   Latest version always available on PL/SQL Obsession: 

   www.ToadWorld.com/SF

   Click on "Trainings, Seminars and Presentations" and
   then download the demo.zip file.

   Modification History
      Date          Change
      10-APR-2009   Add support for nested list variations

   Notes:
     * This package does not validate correct use of delimiters.
       It assumes valid construction of lists.
     * Import the Q##PARSE.qut file into an installation of 
       Quest Code Tester 1.8.3 or higher in order to run
       the regression test for this package.

*/
IS
   SUBTYPE maxvarchar2_t IS VARCHAR2 (32767);

   /*
   Each of the collection types below correspond to (are returned by)
   one of the parse functions.

   items_tt - a simple list of strings
   nested_items_tt - a list of lists of strings
   named_nested_items_tt - a list of named lists of strings

   This last type also demonstrates the power and elegance of string-indexed
   collections. The name of the list of elements is the index value for
   the "outer" collection.
   */
   TYPE items_tt IS TABLE OF maxvarchar2_t
                       INDEX BY PLS_INTEGER;

   TYPE nested_items_tt IS TABLE OF items_tt
                              INDEX BY PLS_INTEGER;

   TYPE named_nested_items_tt IS TABLE OF items_tt
                                    INDEX BY maxvarchar2_t;

   /*
   Parse lists with a single delimiter.
   Example: a,b,c,d

   Here is an example of using this function:

   DECLARE
      l_list parse.items_tt;
   BEGIN
      l_list := parse.string_to_list ('a,b,c,d', ',');
   END;
   */
   FUNCTION string_to_list (string_in IN VARCHAR2, delim_in IN VARCHAR2)
      RETURN items_tt;

   /*
   Parse lists with nested delimiters.
   Example: a,b,c,d|1,2,3|x,y,z

   Here is an example of using this function:

   DECLARE
      l_list parse.nested_items_tt;
   BEGIN
      l_list := parse.string_to_list ('a,b,c,d|1,2,3,4', '|', ',');
   END;
   */
   FUNCTION string_to_list (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN nested_items_tt;

   /*
   Parse named lists with nested delimiters.
   Example: letters:a,b,c,d|numbers:1,2,3|names:steven,george

   Here is an example of using this function:

   DECLARE
      l_list parse.named_nested_items_tt;
   BEGIN
   l_list := parse.string_to_list ('letters:a,b,c,d|numbers:1,2,3,4', '|', ':', ',');
   END;
   */
   FUNCTION string_to_list (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , name_delim_in  IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN named_nested_items_tt;
      
   FUNCTION string_to_arr (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN VARCHAR2_ARR;
      

   PROCEDURE display_list (string_in IN VARCHAR2
                         , delim_in  IN VARCHAR2:= ','
                          );

   PROCEDURE display_list (string_in      IN VARCHAR2
                         , outer_delim_in IN VARCHAR2
                         , inner_delim_in IN VARCHAR2
                          );

   PROCEDURE display_list (string_in      IN VARCHAR2
                         , outer_delim_in IN VARCHAR2
                         , name_delim_in  IN VARCHAR2
                         , inner_delim_in IN VARCHAR2
                          );

   PROCEDURE show_variations;

   /* Helper function for automated testing */
   FUNCTION nested_eq (list1_in    IN items_tt
                     , list2_in    IN items_tt
                     , nulls_eq_in IN BOOLEAN
                      )
      RETURN BOOLEAN;

END parse;

/
--------------------------------------------------------
--  DDL for Package Body TSDB_UTIL
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "TSDB_UTIL" AS

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
  /* The common user level stats names */
  commonStatKeys VARCHAR2_ARR := VARCHAR2_ARR(
  'buffer_is_not_pinned_count',
  'bytes_received_via_sqlnet_from_client',
  'bytes_sent_via_sqlnet_to_client',
  'calls_to_get_snapshot_scn:_kcmgss',
  'calls_to_kcmgcs',
  'ccursor_sql_area_evicted',
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
    RETURN commonStatKeys;
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
--------------------------------------------------------
--  DDL for Package Body TSDB_TRACER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "TSDB_TRACER" AS

  /* The metric stack */
  metricStack XMETRIC_ARR_STACK;
  /* The current metric stack depth */
  depth PLS_INTEGER := 0;  
  /* The named metrics map */
  namedMetrics XMETRIC_NAMED_ARR;
  /* A map of timer metrics keyed by the metric key */
  timers XMETRIC_ARR;
  
  
  FUNCTION TOMETRICS(p IN OUT SYS_REFCURSOR) RETURN METRIC_ARR IS
  BEGIN
    --FETCH p BULK COLLECT INTO r;
    RETURN REFCURTOMETRICS(p);
  END TOMETRICS;
  
  

  --===================================================================================================================
  --  Returns the user stats as metrics
  --===================================================================================================================
  FUNCTION USERSTATS RETURN METRIC_ARR IS
    p SYS_REFCURSOR;
  BEGIN
    OPEN p FOR 
      SELECT M.VALUE, TSDB_UTIL.CLEAN(N.NAME) NAME, 'CLASS', TSDB_TRACER.DECODE_CLASS(N.CLASS) CLAZZ
      FROM v$mystat M, v$statname N
      WHERE M.STATISTIC# = N.STATISTIC#
      AND EXISTS (
        SELECT COLUMN_VALUE FROM TABLE(TSDB_UTIL.USERSTATKEYS())
        WHERE COLUMN_VALUE = TSDB_UTIL.CLEAN(N.NAME)
      )
    ;
    RETURN REFCURTOMETRICS(p);
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



  -- Add a metric to the metric stack entry at the specified mdepth
  FUNCTION ADD_METRIC(mdepth IN INT, met_ric IN METRIC) RETURN METRIC IS
  BEGIN
    IF(metricStack.EXISTS(mdepth)) THEN
      metricStack(mdepth)(met_ric.METRICKEY()) := met_ric;
    ELSE
      RAISE invalid_stack_depth;
    END IF;
    RETURN met_ric;
  END ADD_METRIC;
  
  -- Adds an array of metrics to the metric stack entry at the specified mdepth
  PROCEDURE ADD_METRICS(mdepth IN INT, metrics IN METRIC_ARR) IS
  BEGIN
    IF(metricStack.EXISTS(mdepth)) THEN
      FOR i IN 1..metrics.COUNT LOOP
        IF(metrics(i) IS NOT NULL) THEN
          metricStack(mdepth)(metrics(i).METRICKEY()) := metrics(i);
        END IF;
      END LOOP;
    ELSE
      RAISE invalid_stack_depth;
    END IF;
  END ADD_METRICS;
  
  -- Adds an array of metrics to the metric stack entry at the specified mdepth, returns the mdepth
  FUNCTION ADD_METRICS(mdepth IN INT, metrics IN METRIC_ARR) RETURN INT IS
  BEGIN
    ADD_METRICS(mdepth, metrics);
    RETURN mdepth;
  END ADD_METRICS;
  
  
  -- Update a delta metric in the metric stack entry at the specified mdepth
  -- Returns the updated metric
  -- If the mdepth is valid, but the metric is not found, it will be ignored and returns null
  FUNCTION UPDATE_DELTA_METRIC(mdepth IN INT, met_ric IN METRIC) RETURN METRIC IS
    key CONSTANT VARCHAR2(1000) := met_ric.METRICKEY();
  BEGIN
    IF(metricStack.EXISTS(mdepth)) THEN
      IF(metricStack(depth).EXISTS(key)) THEN
        RETURN metricStack(depth)(key).DELTA(met_ric);
      END IF;
      RETURN NULL;
    ELSE
      RAISE invalid_stack_depth;
    END IF;
  END UPDATE_DELTA_METRIC;
  
  PROCEDURE UPD(arr IN OUT NOCOPY XMETRIC_ARR, metrics IN METRIC_ARR) IS
    key VARCHAR2(1000);
  BEGIN
      FOR i IN 1..metrics.COUNT LOOP
        IF(metrics(i) IS NOT NULL) THEN
          key := metrics(i).METRICKEY();
          IF(arr.EXISTS(key)) THEN
            arr(key).DELTA(metrics(i));
          END IF;
        END IF;
      END LOOP;     
  END UPD;
  
  FUNCTION TOX(arr IN METRIC_ARR) RETURN XMETRIC_ARR IS
    a XMETRIC_ARR;
  BEGIN
    FOR i IN 1..arr.COUNT LOOP      
      a(i) := arr(i);
    END LOOP;
    RETURN a;
  END TOX;
  
  -- Updates an array of delta metrics in the metric stack entry at the specified mdepth
  PROCEDURE UPDATE_DELTA_METRICS(mdepth IN INT, metrics IN METRIC_ARR) IS
    key VARCHAR2(1000);
    m METRIC;
    arr XMETRIC_ARR;
  BEGIN
    IF(metricStack.EXISTS(mdepth)) THEN
      UPD(metricStack(mdepth), metrics);
    ELSE
      RAISE invalid_stack_depth;
    END IF;  
  END UPDATE_DELTA_METRICS;
  
  
  
  PROCEDURE DEBUG_UPDATE(mdepth IN INT) IS
    key VARCHAR2(1000);
    arr XMETRIC_ARR;
    m METRIC;
  BEGIN
    arr := metricStack(mdepth);
      key := arr.first;
      WHILE (key IS NOT NULL) LOOP
        LOGGING.tcplog('POST:' || arr(key).METRICNAME || ':' || arr(key).VALUE || '......[' || arr(key).TSTAMP || ']');
        key := arr.next(key);
      END LOOP;        
  END DEBUG_UPDATE;
  
  FUNCTION PIPEX(xarr IN XMETRIC_ARR) RETURN METRIC_ARR PIPELINED IS  
  BEGIN
    FOR indx IN xarr.FIRST .. xarr.LAST LOOP
      PIPE ROW (xarr(indx));
    END LOOP;
    RETURN;
  END PIPEX;
  
  -- Pops a metric array off the metric stack
  FUNCTION POP RETURN METRIC_ARR IS
    xarr XMETRIC_ARR;
    arr METRIC_ARR := METRIC_ARR();
    ind PLS_INTEGER := 1;
    key VARCHAR2(360);
  BEGIN
    IF(depth = 0) THEN
      RAISE no_metric_stack_entry;
    END IF;
    xarr := metricStack(depth);
    metricStack.DELETE(depth);
    depth := depth -1;    
--    FOR a IN (SELECT VALUE(T) FROM TABLE(PIPEX(xarr)) T) LOOP
--      NULL;
--    END LOOP;
    --SELECT * BULK COLLECT INTO arr FROM TABLE(TSDB_TRACER.PIPEX(xarr)) T;    
    key := xarr.first;
    WHILE (key IS NOT NULL) LOOP
      arr.EXTEND();
      arr(ind) := xarr(key);
--      LOGGING.tcplog('POPPED [' || arr(ind).PUTMS || ']');
      ind := ind + 1;
      key := xarr.next(key);
    END LOOP;    
    RETURN arr;
  END POP;

  
  
  
  -- Starts a new metric stack and returns the new depth
  FUNCTION STARTMETRICSTACK RETURN INT IS
    st XMETRIC_ARR;
  BEGIN
    depth := depth + 1;
    metricStack(depth) := st;
    return depth;
  END STARTMETRICSTACK;


  
  -- Clears the current metric stack entry
  PROCEDURE CLEAR IS
  BEGIN
    IF(depth = 0) THEN
      RAISE no_metric_stack_entry;
    END IF;
    metricStack.delete(depth);
    depth := depth -1;
  END CLEAR;
  
    -- Clear all metrics
  PROCEDURE CLEARSTACK IS 
  BEGIN
    metricStack.delete();
    depth := 0;
  END CLEARSTACK;

  
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

  
--  FUNCTION INDIRECT(p IN RCUR) RETURN SYS_REFCURSOR IS
--  BEGIN    
--    RETURN p;
--  END INDIRECT;

  FUNCTION INDIRECT(p IN RCUR) RETURN SYS_REFCURSOR IS
    c SYS_REFCURSOR;
  BEGIN    
    OPEN c FOR SELECT p FROM DUAL;
    --OPEN c FOR p;
    RETURN c;
  END INDIRECT;

--  FUNCTION A(p IN RCUR) RETURN ANYDATASET IS
--    c ANYDATASET;
--    d ANYDATA;
--  BEGIN    
--    --OPEN p;
--    LOOP
--      FETCH p INTO d;
--      EXIT WHEN p%NOTFOUND;
--      c.
--    END LOOP;
--    RETURN c;
--  END A;

  --====================================================================================================
  -- Attempts to convert the results from the passed ref-cursor to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION REFCURTOMETRICSINONLY(p IN SYS_REFCURSOR) RETURN METRIC_ARR IS
    pout SYS_REFCURSOR := INDIRECT(p);
  BEGIN
    RETURN REFCURTOMETRICS(pout);
  END REFCURTOMETRICSINONLY;
  
  --====================================================================================================
  -- Attempts to convert the results from the passed ref-cursor to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION REFCURTOMETRICS(p IN OUT SYS_REFCURSOR) RETURN METRIC_ARR IS
    cntr PLS_INTEGER := 0;
    pout SYS_REFCURSOR;
    indir1 SYS_REFCURSOR;
    indir2 SYS_REFCURSOR;
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
    --pout := INDIRECT(p);        
    --LOGGING.tcplog('RefC:' || pout);
    cursor_name := DBMS_SQL.TO_CURSOR_NUMBER(p);    
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
    LOGGING.tcplog('Tag Count:' || tagCount);
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
      BEGIN
        DBMS_SQL.CLOSE_CURSOR(cursor_name);    
        EXCEPTION WHEN OTHERS THEN NULL;
      END;
      DECLARE
        errm VARCHAR2(200) := SQLERRM();
      BEGIN
        LOGGING.tcplog('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
      END;
      RAISE;                    
  END REFCURTOMETRICS;
  
  
  
  --====================================================================================================
  -- Converts the results from the passed SQL query to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION SQLTOMETRICS(query IN VARCHAR2) RETURN METRIC_ARR IS
    cntr PLS_INTEGER := 0;
    cursor_name NUMBER;
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
    ads anydataset;
  BEGIN
    cursor_name := dbms_sql.open_cursor();
    DBMS_SQL.PARSE(cursor_name, query, DBMS_SQL.NATIVE);
    --cursor_name := DBMS_SQL.TO_CURSOR_NUMBER(pout);    
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
    rowsFetched := DBMS_SQL.EXECUTE(cursor_name);
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
    
--    EXCEPTION WHEN OTHERS THEN       
--      DECLARE
--        errm VARCHAR2(200) := SQLERRM();
--      BEGIN
--        LOGGING.tcplog('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
--        DBMS_OUTPUT.PUT_LINE('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
--        RAISE;                    
--      END;
      
      --NULL;
      RETURN metrics;
  END SQLTOMETRICS;
  
  
    -- Trace from a ref cursor
  FUNCTION TRACE(p IN RCUR) RETURN INT IS
    metrics METRIC_ARR;
  BEGIN
    metrics := REFCURTOMETRICSINONLY(p);
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
--------------------------------------------------------
--  DDL for Package Body PARSE
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "PARSE" 
IS
   FUNCTION string_to_list (string_in IN VARCHAR2, delim_in IN VARCHAR2)
      RETURN items_tt
   IS
      c_end_of_list   CONSTANT PLS_INTEGER := -99;
      l_item          maxvarchar2_t;
      l_startloc      PLS_INTEGER := 1;
      items_out       items_tt;

      PROCEDURE add_item (item_in IN VARCHAR2)
      IS
      BEGIN
         IF item_in = delim_in
         THEN
            /* We don't put delimiters into the collection. */
            NULL;
         ELSE
            items_out (items_out.COUNT + 1) := item_in;
         END IF;
      END;

      PROCEDURE get_next_item (string_in         IN     VARCHAR2
                             , start_location_io IN OUT PLS_INTEGER
                             , item_out             OUT VARCHAR2
                              )
      IS
         l_loc   PLS_INTEGER;
      BEGIN
         l_loc := INSTR (string_in, delim_in, start_location_io);

         IF l_loc = start_location_io
         THEN
            /* A null item (two consecutive delimiters) */
            item_out := NULL;
         ELSIF l_loc = 0
         THEN
            /* We are at the last item in the list. */
            item_out := SUBSTR (string_in, start_location_io);
         ELSE
            /* Extract the element between the two positions. */
            item_out :=
               SUBSTR (string_in
                     , start_location_io
                     , l_loc - start_location_io
                      );
         END IF;

         IF l_loc = 0
         THEN
            /* If the delimiter was not found, send back indication
               that we are at the end of the list. */

            start_location_io := c_end_of_list;
         ELSE
            /* Move the starting point for the INSTR search forward. */
            start_location_io := l_loc + 1;
         END IF;
      END get_next_item;
   BEGIN
      IF string_in IS NULL OR delim_in IS NULL
      THEN
         /* Nothing to do except pass back the empty collection. */
         NULL;
      ELSE
         LOOP
            get_next_item (string_in, l_startloc, l_item);
            add_item (l_item);
            EXIT WHEN l_startloc = c_end_of_list;
         END LOOP;
      END IF;

      RETURN items_out;
   END string_to_list;

   FUNCTION string_to_list (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN nested_items_tt
   IS
      l_elements   items_tt;
      l_return     nested_items_tt;
   BEGIN
      /* Separate out the different lists. */
      l_elements := string_to_list (string_in, outer_delim_in);

      /* For each list, parse out the separate items
         and add them to the end of the list of items
         for that list. */   
      FOR indx IN 1 .. l_elements.COUNT
      LOOP
         l_return (l_return.COUNT + 1) :=
            string_to_list (l_elements (indx), inner_delim_in);
      END LOOP;

      RETURN l_return;
   END string_to_list;
   
   
      FUNCTION string_to_arr (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN VARCHAR2_ARR         
      IS
          -- TYPE nested_items_tt IS TABLE OF items_tt INDEX BY PLS_INTEGER;
        ni nested_items_tt := string_to_list(string_in, outer_delim_in, inner_delim_in);
        k VARCHAR2(70);
        v VARCHAR2(70);
        items items_tt;
      BEGIN
        RETURN NULL;
      END string_to_arr;


   FUNCTION string_to_list (string_in      IN VARCHAR2
                          , outer_delim_in IN VARCHAR2
                          , name_delim_in  IN VARCHAR2
                          , inner_delim_in IN VARCHAR2
                           )
      RETURN named_nested_items_tt
   IS
      c_name_position constant pls_integer := 1;
      c_items_position constant pls_integer := 2;
      l_elements          items_tt;
      l_name_and_values   items_tt;
      l_return            named_nested_items_tt;
   BEGIN
      /* Separate out the different lists. */
      l_elements := string_to_list (string_in, outer_delim_in);

      FOR indx IN 1 .. l_elements.COUNT
      LOOP
         /* Extract the name and the list of items that go with 
            the name. This collection always has just two elements:
              index 1 - the name
              index 2 - the list of values
         */
         l_name_and_values :=
            string_to_list (l_elements (indx), name_delim_in);
         /*
         Use the name as the index value for this list.
         */
         l_return (l_name_and_values (c_name_position)) :=
            string_to_list (l_name_and_values (c_items_position), inner_delim_in);
      END LOOP;

      RETURN l_return;
   END string_to_list;

   PROCEDURE display_list (string_in IN VARCHAR2
                         , delim_in  IN VARCHAR2:= ','
                          )
   IS
      l_items   items_tt;
   BEGIN
      DBMS_OUTPUT.put_line (
         'Parse "' || string_in || '" using "' || delim_in || '"'
      );

      l_items := string_to_list (string_in, delim_in);

      FOR indx IN 1 .. l_items.COUNT
      LOOP
         DBMS_OUTPUT.put_line ('> ' || indx || ' = ' || l_items (indx));
      END LOOP;
   END display_list;

   PROCEDURE display_list (string_in      IN VARCHAR2
                         , outer_delim_in IN VARCHAR2
                         , inner_delim_in IN VARCHAR2
                          )
   IS
      l_items   nested_items_tt;
   BEGIN
      DBMS_OUTPUT.put_line(   'Parse "'
                           || string_in
                           || '" using "'
                           || outer_delim_in
                           || '-'
                           || inner_delim_in
                           || '"');
      l_items := string_to_list (string_in, outer_delim_in, inner_delim_in);


      FOR outer_index IN 1 .. l_items.COUNT
      LOOP
         DBMS_OUTPUT.put_line(   'List '
                              || outer_index
                              || ' contains '
                              || l_items (outer_index).COUNT
                              || ' elements');

         FOR inner_index IN 1 .. l_items (outer_index).COUNT
         LOOP
            DBMS_OUTPUT.put_line(   '> Value '
                                 || inner_index
                                 || ' = '
                                 || l_items (outer_index) (inner_index));
         END LOOP;
      END LOOP;
   END display_list;

   PROCEDURE display_list (string_in      IN VARCHAR2
                         , outer_delim_in IN VARCHAR2
                         , name_delim_in  IN VARCHAR2
                         , inner_delim_in IN VARCHAR2
                          )
   IS
      l_items   named_nested_items_tt;
      l_index   maxvarchar2_t;
   BEGIN
      DBMS_OUTPUT.put_line(   'Parse "'
                           || string_in
                           || '" using "'
                           || outer_delim_in
                           || '-'
                           || name_delim_in
                           || '-'
                           || inner_delim_in
                           || '"');
      l_items :=
         string_to_list (string_in
                       , outer_delim_in
                       , name_delim_in
                       , inner_delim_in
                        );

      l_index := l_items.FIRST;

      WHILE (l_index IS NOT NULL)
      LOOP
         DBMS_OUTPUT.put_line(   'List "'
                              || l_index
                              || '" contains '
                              || l_items (l_index).COUNT
                              || ' elements');

         FOR inner_index IN 1 .. l_items (l_index).COUNT
         LOOP
            DBMS_OUTPUT.put_line(   '> Value '
                                 || inner_index
                                 || ' = '
                                 || l_items (l_index) (inner_index));
         END LOOP;

         l_index := l_items.NEXT (l_index);
      END LOOP;
   END display_list;

   PROCEDURE show_variations
   IS
      PROCEDURE show_header (title_in IN VARCHAR2)
      IS
      BEGIN
         DBMS_OUTPUT.put_line (RPAD ('=', 60, '='));
         DBMS_OUTPUT.put_line (title_in);
         DBMS_OUTPUT.put_line (RPAD ('=', 60, '='));
      END show_header;
   BEGIN
      show_header ('Single Delimiter Lists');
      display_list ('a,b,c');
      display_list ('a;b;c', ';');
      display_list ('a,,b,c');
      display_list (',,b,c,,');

      show_header ('Nested Lists');
      display_list ('a,b,c,d|1,2,3|x,y,z', '|', ',');

      show_header ('Named, Nested Lists');
      display_list ('letters:a,b,c,d|numbers:1,2,3|names:steven,george'
                  , '|'
                  , ':'
                  , ','
                   );
   END;

   FUNCTION nested_eq (list1_in    IN items_tt
                     , list2_in    IN items_tt
                     , nulls_eq_in IN BOOLEAN
                      )
      RETURN BOOLEAN
   IS
      l_return   BOOLEAN := list1_in.COUNT = list2_in.COUNT;
      l_index    PLS_INTEGER := 1;
   BEGIN
      WHILE (l_return AND l_index IS NOT NULL)
      LOOP
         l_return := list1_in (l_index) = list2_in (l_index);
         l_index := list1_in.NEXT (l_index);
      END LOOP;

      RETURN l_return;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN FALSE;
   END nested_eq;
END;

/
