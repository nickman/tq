--------------------------------------------------------
--  File created - Monday-November-28-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package TQ
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "TQREACTOR"."TQ" as 

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
    XROWID VARCHAR2(18),
    TQROWID TQSTUBS.TQROWID%TYPE,
    TQUEUE_ID TQSTUBS.TQUEUE_ID%TYPE,
    XID TQSTUBS.XID%TYPE,
    SECURITY_ID TQSTUBS.SECURITY_ID%TYPE,
    SECURITY_TYPE TQSTUBS.SECURITY_TYPE%TYPE,
    ACCOUNT_ID TQSTUBS.ACCOUNT_ID%TYPE,
    BATCH_ID TQSTUBS.BATCH_ID%TYPE,
    BATCH_TS TQSTUBS.BATCH_TS%TYPE
  );
  TYPE TQSTUBS_REC_ARR IS TABLE OF TQSTUBS_REC;
  TYPE TQSTUBS_REC_CUR IS REF CURSOR RETURN TQSTUBS_REC;
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
  FUNCTION DECODE_SECURITY(securityDisplayName IN VARCHAR2) RETURN SECURITY_REC;

  -- *******************************************************
  --    Decode AccountDisplayName
  -- *******************************************************
  FUNCTION DECODE_ACCOUNT(accountDisplayName IN VARCHAR2) RETURN ACCOUNT_REC;
  
  -- *******************************************************
  --    Handle TQUEUE INSERT Trigger
  -- *******************************************************
  PROCEDURE TRIGGER_STUB(rowid IN ROWID, tqueueId IN NUMBER, statusCode IN VARCHAR2, securityDisplayName IN VARCHAR2, accountDisplayName IN VARCHAR2, batchId IN NUMBER);


  FUNCTION QUERY_BATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999 ) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE;
  
  -- MOD(ORA_HASH(ACCOUNT_ID, 999999),12) = 3 
  
  
  
  -- *******************************************************
  --    Get current XID function
  -- *******************************************************
  FUNCTION CURRENTXID RETURN RAW;  

end tq;

/
