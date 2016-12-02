create or replace PACKAGE TQ /* authid current_user */ as 
  -- Enablement flag for tcp logging
  TCPLOG_ENABLED BOOLEAN := TRUE;
  
  TYPE StreamCursorTyp IS REF CURSOR;
  
  PROCEDURE log(message IN VARCHAR2);
  PROCEDURE SET_TCPLOG_ENABLED(enabled IN PLS_INTEGER);
  FUNCTION IS_TCPLOG_ENABLED RETURN PLS_INTEGER;
  
  
--=========================================================================
-- Record Types and Cursor for TQBATCHes
--=========================================================================  
  TYPE TQBATCH_REC IS RECORD (
    ACCOUNT           INT,
    TCOUNT            INT,
    FIRST_T           INT,
    LAST_T            INT,
    BATCH_ID          INT,
    ROWIDS            XROWIDS,
    TQROWIDS          XROWIDS,
    STUBS             TQSTUBS_OBJ_ARR
  );  
  TYPE TQBATCH_REC_ARR IS TABLE OF TQBATCH_REC;
  TYPE TQBATCH_REC_ARR_ARR IS TABLE OF TQBATCH_REC_ARR;
  TYPE TQBATCH_REC_CUR IS REF CURSOR RETURN TQBATCH_REC;
  
  TYPE TQSTUBS_OV_REC IS RECORD (
    XROWID        TQSTUBS_OV.XROWID%TYPE,
    TQROWID       TQSTUBS_OV.TQROWID%TYPE,
    TQUEUE_ID     TQSTUBS_OV.TQUEUE_ID%TYPE,
    XID           TQSTUBS_OV.XID%TYPE,
    SECURITY_ID   TQSTUBS_OV.SECURITY_ID%TYPE,
    SECURITY_TYPE TQSTUBS_OV.SECURITY_TYPE%TYPE,
    ACCOUNT_ID    TQSTUBS_OV.ACCOUNT_ID%TYPE,
    BATCH_ID      TQSTUBS_OV.BATCH_ID%TYPE,
    BATCH_TS      TQSTUBS_OV.BATCH_TS%TYPE  
  );
  
  TYPE TQSTUBS_OV_REC_ARR IS TABLE OF TQSTUBS_OV_REC;
  TYPE TQSTUBS_OV_REC_CUR IS REF CURSOR RETURN TQSTUBS_OV_REC;
  

--=========================================================================
-- Record Types and Cursor for table TQUEUE
--=========================================================================
  TYPE TQUEUE_REC IS RECORD (
    XROWID VARCHAR2(18),
    TQUEUE_ID TQUEUE.TQUEUE_ID%TYPE,
    XID TQUEUE.XID%TYPE,
    STATUS_CODE TQUEUE.STATUS_CODE%TYPE,
    SECURITY_DISPLAY_NAME TQUEUE.SECURITY_DISPLAY_NAME%TYPE,
    ACCOUNT_DISPLAY_NAME TQUEUE.ACCOUNT_DISPLAY_NAME%TYPE,
    SECURITY_ID TQUEUE.SECURITY_ID%TYPE,
    SECURITY_TYPE TQUEUE.SECURITY_TYPE%TYPE,
    ACCOUNT_ID TQUEUE.ACCOUNT_ID%TYPE,
    BATCH_ID TQUEUE.BATCH_ID%TYPE,
    CREATE_TS TQUEUE.CREATE_TS%TYPE,
    UPDATE_TS TQUEUE.UPDATE_TS%TYPE,
    ERROR_MESSAGE TQUEUE.ERROR_MESSAGE%TYPE
  );
  TYPE TQUEUE_REC_ARR IS TABLE OF TQUEUE_REC;
  TYPE TQUEUE_REC_CUR IS REF CURSOR RETURN TQUEUE_REC;
--=========================================================================
-- Record Types for table TQSTUBS
--=========================================================================  
  TYPE TQSTUBS_REC IS RECORD (
    TQROWID VARCHAR2(18),
    TQUEUE_ID TQSTUBS.TQUEUE_ID%TYPE,
    XID TQSTUBS.XID%TYPE,
    SECURITY_ID TQSTUBS.SECURITY_ID%TYPE,
    SECURITY_TYPE TQSTUBS.SECURITY_TYPE%TYPE,
    ACCOUNT_ID TQSTUBS.ACCOUNT_ID%TYPE,
    BATCH_ID TQSTUBS.BATCH_ID%TYPE,
    BATCH_TS TQSTUBS.BATCH_TS%TYPE,
    SID NUMBER
  );
  TYPE TQSTUBS_REC_ARR IS TABLE OF TQSTUBS_REC;
  TYPE TQSTUBS_REC_CUR IS REF CURSOR RETURN TQSTUBS%ROWTYPE;
--=========================================================================
-- Record Types for table ACCOUN T
--=========================================================================    
TYPE ACCOUNT_REC IS RECORD (
  XROWID ROWID,
  ACCOUNT_ID ACCOUNT.ACCOUNT_ID%TYPE,
  ACCOUNT_DISPLAY_NAME ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE
);
TYPE ACCOUNT_REC_ARR IS TABLE OF ACCOUNT_REC;
TYPE ACCOUNT_REC_CUR IS REF CURSOR RETURN ACCOUNT_REC;
--=========================================================================
-- Record Types for table SECURITY
--=========================================================================  
TYPE SECURITY_REC IS RECORD (
  XROWID ROWID,
  SECURITY_ID SECURITY.SECURITY_ID%TYPE,
  SECURITY_DISPLAY_NAME SECURITY.SECURITY_DISPLAY_NAME%TYPE,
  SECURITY_TYPE SECURITY.SECURITY_TYPE%TYPE
);
TYPE SECURITY_REC_ARR IS TABLE OF SECURITY_REC;
TYPE SECURITY_REC_CUR IS REF CURSOR RETURN SECURITY_REC;
  
  
--=========================================================================
-- Utility Types
--=========================================================================    
  TYPE NUM_ARR IS TABLE OF NUMBER;
  TYPE CHAR_ARR IS TABLE OF CHAR;
  TYPE ROWID_ARR IS TABLE OF ROWID;
  TYPE CQNDECODE IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
  
  
  

--=========================================================================
-- Converts TQUEUE Records to TQUEUE Objects
--=========================================================================  
  FUNCTION TQUEUE_RECS_TO_OBJS(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE;
--=========================================================================
-- Converts TQSTUBS Records to TQSTUBS Objects
--=========================================================================  
  FUNCTION TQSTUBS_RECS_TO_OBJS(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE;
  
  -- *******************************************************
  --    Decode SecurityDisplayName
  -- *******************************************************  
  FUNCTION DECODE_SECURITY(securityDisplayName IN VARCHAR2) RETURN SECURITY_REC RESULT_CACHE;
  -- *******************************************************
  --    Decode SecurityDisplayName (OUT vars)
  -- *******************************************************  
  PROCEDURE DECODE_SECURITY(securityDisplayName IN VARCHAR2, securityId OUT NUMBER, securityType OUT NOCOPY CHAR);

  -- *******************************************************
  --    Decode AccountDisplayName
  -- *******************************************************
  FUNCTION DECODE_ACCOUNT(accountDisplayName IN VARCHAR2) RETURN ACCOUNT_REC RESULT_CACHE;
  -- *******************************************************
  --    Decode AccountDisplayName (OUT vars)
  -- *******************************************************
  PROCEDURE DECODE_ACCOUNT(accountDisplayName IN VARCHAR2, accountId OUT NUMBER);  
  
  -- *******************************************************
  --    Handle TQUEUE INSERT Trigger
  -- *******************************************************
  PROCEDURE TRIGGER_STUB(rowid IN ROWID, tqueueId IN NUMBER, statusCode IN VARCHAR2, securityDisplayName IN VARCHAR2, accountDisplayName IN VARCHAR2, batchId IN NUMBER);

  -- *******************************************************
  --    Groups an array of TQSTUBS_OBJ into an 
  --    array of TQBATCHes.
  -- *******************************************************
  FUNCTION GROUP_TQBATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;
  
  FUNCTION GROUP_TQBATCHES2(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;
  
  --FUNCTION GROUP_TQBATCHES3(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;


  FUNCTION QUERY_BATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999 ) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE;
  
  --FUNCTION QUERY_BATCHES2(p IN TQSTUBS_REC_CUR, rowLimit IN PLS_INTEGER DEFAULT 1024) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)) CLUSTER p BY (ACCOUNT_ID);
  FUNCTION QUERY_BATCHES2(p IN TQSTUBS_REC_CUR, rowLimit IN PLS_INTEGER DEFAULT 1024) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)); -- CLUSTER p BY (ACCOUNT_ID);
  
  --FUNCTION QUERY_BATCHES3(p IN TQSTUBS_REC_CUR, rowLimit IN PLS_INTEGER DEFAULT 1024) RETURN TQBATCH_REC_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)); -- CLUSTER p BY (ACCOUNT_ID);
  
  
  FUNCTION QUERY_BATCHES4(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_REC_ARR PIPELINED PARALLEL_ENABLE (PARTITION p BY HASH(ACCOUNT_ID));
  
  
  
  
  FUNCTION GET_TRADE_BATCH(xrowids IN XROWIDS) RETURN TQUEUE_OBJ_ARR;
  
  FUNCTION PIPE_TRADE_BATCH(xrowids IN XROWIDS) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE;
  
  FUNCTION PARSE_PIPE_TRADE_BATCH(xrowidStr IN VARCHAR2) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE;
  
  FUNCTION DELETE_STUB_BATCH(xrowids IN XROWIDS) RETURN NUMBER;
  
  
  FUNCTION ROOT_CURSOR(xrowids IN XROWIDS) RETURN TQUEUE_REC_CUR;
  
  FUNCTION MYSID RETURN VARCHAR2;

--=============================================================================================================  
-- Enriches each passed trade supplied in the cursor with the security id, security type 
-- and account id then pipes the enriched trades out
--=============================================================================================================  
  FUNCTION XENRICH_TRADE(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)) CLUSTER p BY (ACCOUNT_ID);
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs
--=============================================================================================================  
  PROCEDURE UPDATE_TRADES(trades IN TQUEUE_OBJ_ARR);  
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs and deletes the stubs
--=============================================================================================================  
  PROCEDURE COMPLETE_BATCH(trades IN TQUEUE_OBJ_ARR, xrowids IN XROWIDS);  
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs and deletes the stubs
--=============================================================================================================  
  FUNCTION COMPLETE_BATCH_WCOUNTS(trades IN TQUEUE_OBJ_ARR, xrowids IN XROWIDS) RETURN INT_ARR;
  
  
  
  -- *******************************************************
  --    Attempts to lock the rows in TQUEUE
  -- *******************************************************
  FUNCTION LOCKTRADES(xrowids IN XROWIDS) RETURN PLS_INTEGER;  
  
  
  
  -- *******************************************************
  --    Get current XID function
  -- *******************************************************
  FUNCTION CURRENTXID RETURN RAW;  

end tq;