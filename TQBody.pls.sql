--------------------------------------------------------
--  File created - Monday-November-28-2016   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body TQ
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "TQREACTOR"."TQ" as

--=========================================================================
-- Converts TQUEUE Records to TQUEUE Objects
--=========================================================================  
  FUNCTION TQUEUE_RECS_TO_OBJS(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    rec TQUEUE_REC;
  BEGIN
      LOOP
        FETCH p into rec;
        EXIT WHEN p%NOTFOUND;
        PIPE ROW(TQUEUE_OBJ(rec.XROWID,rec.TQUEUE_ID,rec.XID,rec.STATUS_CODE,rec.SECURITY_DISPLAY_NAME,rec.ACCOUNT_DISPLAY_NAME,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.CREATE_TS,rec.UPDATE_TS,rec.ERROR_MESSAGE));
      END LOOP;
      RETURN;
      EXCEPTION
        WHEN NO_DATA_NEEDED THEN RAISE;
  END TQUEUE_RECS_TO_OBJS;
--=========================================================================
-- Converts TQSTUBS Records to TQSTUBS Objects
--=========================================================================    
  FUNCTION TQSTUBS_RECS_TO_OBJS(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    rec TQSTUBS_REC;
  BEGIN
      LOOP
        FETCH p into rec;
        EXIT WHEN p%NOTFOUND;
        PIPE ROW(TQSTUBS_OBJ(rec.XROWID,rec.TQROWID,rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS));
      END LOOP;
      RETURN;
      EXCEPTION
        WHEN NO_DATA_NEEDED THEN RAISE;
  END TQSTUBS_RECS_TO_OBJS;
  
  -- *******************************************************
  --    Decode SecurityDisplayName
  -- *******************************************************  
  FUNCTION DECODE_SECURITY(securityDisplayName IN VARCHAR2) RETURN SECURITY_REC /* RESULT_CACHE RELIES_ON (SECURITY) */ IS
    rec SECURITY_REC;
  BEGIN
    SELECT S.ROWID, S.* into rec FROM SECURITY S WHERE SECURITY_DISPLAY_NAME = securityDisplayName;
    RETURN rec;
  END DECODE_SECURITY;

  -- *******************************************************
  --    Decode AccountDisplayName
  -- *******************************************************
  FUNCTION DECODE_ACCOUNT(accountDisplayName IN VARCHAR2) RETURN ACCOUNT_REC /* RESULT_CACHE RELIES_ON (ACCOUNT) */ IS
    rec ACCOUNT_REC;
  BEGIN
    SELECT A.ROWID, A.* INTO rec FROM ACCOUNT A WHERE ACCOUNT_DISPLAY_NAME = accountDisplayName;
    RETURN rec;
  END DECODE_ACCOUNT;
  
  -- *******************************************************
  --    Handle TQUEUE INSERT Trigger
  -- *******************************************************
  PROCEDURE TRIGGER_STUB(rowid IN ROWID, tqueueId IN NUMBER, statusCode IN VARCHAR2, securityDisplayName IN VARCHAR2, accountDisplayName IN VARCHAR2, batchId IN NUMBER) IS
    srec SECURITY_REC;
    accountId NUMBER;
  BEGIN
    srec := DECODE_SECURITY(securityDisplayName);
    accountId := DECODE_ACCOUNT(accountDisplayName).ACCOUNT_ID;
    INSERT INTO TQSTUBS VALUES(rowid, tqueueId, CURRENTXID(), srec.SECURITY_ID, srec.SECURITY_TYPE, accountId, batchId, SYSTIMESTAMP);
  END TRIGGER_STUB;
  
  -- *******************************************************
  --    Query batches of trade stubs
  -- *******************************************************
  FUNCTION QUERY_BATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999 ) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE IS
    CURSOR pipeBatches IS 
      SELECT * FROM TABLE(TQSTUBS_RECS_TO_OBJS(CURSOR(
        SELECT T.ROWID, T.* FROM TQSTUBS T WHERE MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID
      ))) X;
  BEGIN
    RETURN;
  END QUERY_BATCHES;
  
  -- MOD(ORA_HASH(ACCOUNT_ID, 999999),12) = 3 
  
  
  
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


end tq;

/
