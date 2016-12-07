create or replace TYPE BATCH_SPEC AS OBJECT  (
    THREAD_MOD INT,         -- The thread mod for this request 
    ROW_LIMIT INT,          -- The maximum number of rows to process per call
    THREAD_COUNT INT,       -- The total number of threads polling
    CPU_MULTI INT,          -- A multiplier on the number of cpus to determine the parallelism of the driving query. 
    WAIT_LOOPS  INT,        -- The number of times to loop waiting on rows to show up
    WAIT_SLEEP  NUMBER,     -- The number of seconds to wait after each loop (fractional 100ths of seconds allowed),    
    MODS INT_ARR,           -- The account mods for the specified threadmod and thread count
    MEMBER FUNCTION TOV RETURN VARCHAR2,    
    CONSTRUCTOR FUNCTION BATCH_SPEC(THREAD_MOD INT DEFAULT -1, ROW_LIMIT INT DEFAULT 2147483647, THREAD_COUNT INT DEFAULT 8, CPU_MULTI INT DEFAULT 1, WAIT_LOOPS IN INT DEFAULT 2, WAIT_SLEEP IN NUMBER DEFAULT 1) RETURN SELF AS RESULT
  );

create or replace TYPE BODY BATCH_SPEC AS
  CONSTRUCTOR FUNCTION BATCH_SPEC(THREAD_MOD INT DEFAULT -1, ROW_LIMIT INT DEFAULT 2147483647, THREAD_COUNT INT DEFAULT 8, CPU_MULTI INT DEFAULT 1, WAIT_LOOPS IN INT DEFAULT 2, WAIT_SLEEP IN NUMBER DEFAULT 1) RETURN SELF AS RESULT IS
  BEGIN
    -- TODO: Validate that THREAD_COUNT > 0
    -- TODO: Validate that THREAD_MOD is -1 or >= 0 and < THREAD_COUNT
    SELF.THREAD_MOD := THREAD_MOD;
    SELF.ROW_LIMIT := ROW_LIMIT;
    SELF.THREAD_COUNT := THREAD_COUNT;
    SELF.CPU_MULTI := CPU_MULTI;
    SELF.WAIT_LOOPS := WAIT_LOOPS;
    SELF.WAIT_SLEEP := WAIT_SLEEP;
    SELF.MODS := TQ.GET_ACCOUNT_BUCKET_MODS(SELF.THREAD_MOD, SELF.THREAD_COUNT);
    -- TQ.GET_ACCOUNT_BUCKET_MODS(1, 4)
    RETURN;
  END BATCH_SPEC;
  MEMBER FUNCTION TOV RETURN VARCHAR2 IS
  BEGIN
    RETURN 'BATCH_SPEC [tmod:' || THREAD_MOD || ', rlimit:' || ROW_LIMIT || ', tcount:' || THREAD_COUNT || 
      ', cpum:' || CPU_MULTI || ', wloops:' || WAIT_LOOPS || ', wsleep:' || WAIT_SLEEP || ', mods:' || TQ.TOSTR(MODS) || ']';
  END TOV;
END;
