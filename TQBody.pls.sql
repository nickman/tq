create or replace PACKAGE BODY TQ as

    cursor sqx(xrowids IN XROWIDS) is SELECT TQUEUE_OBJ(V) FROM TABLE (
      CURSOR(SELECT * FROM TABLE(TQUEUE_RECS_TO_OBJS(
            CURSOR(SELECT * FROM TABLE(XENRICH_TRADE_ACCOUNTS(
              CURSOR(SELECT * FROM TABLE(XENRICH_TRADE_SECURITIES(
                CURSOR(
                  SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                  FROM TQUEUE T WHERE EXISTS (
                    SELECT RID FROM (
                      SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS)
                  ) WHERE RID = T.ROWID)              
                )
              )))
            )))
          )))
    )V;


  PROCEDURE log(message IN VARCHAR2) IS
  BEGIN
    IF(TCPLOG_ENABLED) THEN
      LOGGING.tcplog(message);
    END IF;
  END log;

  PROCEDURE SET_TCPLOG_ENABLED(enabled IN PLS_INTEGER) IS
  BEGIN
    IF(enabled=0) THEN
      TCPLOG_ENABLED := FALSE;
    ELSE
      TCPLOG_ENABLED := TRUE;
    END IF;
  END SET_TCPLOG_ENABLED;
  
  FUNCTION IS_TCPLOG_ENABLED RETURN PLS_INTEGER IS
  BEGIN
    IF(TCPLOG_ENABLED) THEN RETURN 1;
    ELSE RETURN 0;
    END IF;
  END IS_TCPLOG_ENABLED;

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
        WHEN NO_DATA_NEEDED THEN 
          Log('TQUEUE_RECS_TO_OBJS: no_data_needed');
          return;
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
        WHEN NO_DATA_NEEDED THEN 
          Log('TQSTUBS_RECS_TO_OBJS: no_data_needed');
          return;        
  END TQSTUBS_RECS_TO_OBJS;
  
  -- *******************************************************
  --    Decode SecurityDisplayName
  -- *******************************************************  
  FUNCTION DECODE_SECURITY(securityDisplayName IN VARCHAR2) RETURN SECURITY_REC RESULT_CACHE RELIES_ON (SECURITY)  IS
    rec SECURITY_REC;
  BEGIN
    SELECT S.ROWID, S.* into rec FROM SECURITY S WHERE SECURITY_DISPLAY_NAME = securityDisplayName;
    RETURN rec;
  END DECODE_SECURITY;
  
  -- *******************************************************
  --    Decode SecurityDisplayName (OUT vars)
  -- *******************************************************  
  PROCEDURE DECODE_SECURITY(securityDisplayName IN VARCHAR2, securityId OUT NUMBER, securityType OUT CHAR) IS
    rec SECURITY_REC;
  BEGIN
    rec := DECODE_SECURITY(securityDisplayName);
    securityId := rec.SECURITY_ID;
    securityType := rec.SECURITY_TYPE;
  END DECODE_SECURITY;
  

  -- *******************************************************
  --    Decode AccountDisplayName
  -- *******************************************************
  FUNCTION DECODE_ACCOUNT(accountDisplayName IN VARCHAR2) RETURN ACCOUNT_REC RESULT_CACHE RELIES_ON (ACCOUNT) IS
    rec ACCOUNT_REC;
  BEGIN
    SELECT A.ROWID, A.* INTO rec FROM ACCOUNT A WHERE ACCOUNT_DISPLAY_NAME = accountDisplayName;
    RETURN rec;
  END DECODE_ACCOUNT;
  
  -- *******************************************************
  --    Decode AccountDisplayName (OUT vars)
  -- *******************************************************
  PROCEDURE DECODE_ACCOUNT(accountDisplayName IN VARCHAR2, accountId OUT NUMBER) IS
    rec ACCOUNT_REC;
  BEGIN
    rec := DECODE_ACCOUNT(accountDisplayName);
    accountId := rec.ACCOUNT_ID;
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
  --    Groups an array of TQSTUBS_OBJ into an 
  --    array of TQBATCHes.
  -- *******************************************************
  FUNCTION GROUP_TQBATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE IS
    tqb TQBATCH := NULL;
    stub TQSTUBS_OBJ;
    piped PLS_INTEGER := 1;
    rows PLS_INTEGER := 0;
--    CURSOR getBatches IS SELECT VALUE(T) FROM TABLE(QUERY_BATCHES(threadMod, rowLimit, threadCount, bucketSize)) T;
    CURSOR getBatches IS 
      SELECT TQSTUBS_OBJ(ROWIDTOCHAR(ROWID), ROWIDTOCHAR(TQROWID),TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,BATCH_TS)
        FROM TQSTUBS T WHERE (threadMod = -1 OR MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod) ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID;
  BEGIN
    Log('GROUP_TQBATCHES START, THREAD:' || threadMod);
    OPEN getBatches;
    Log('GROUP_TQBATCHES: Cursor Opened');
    LOOP
      EXIT WHEN rows >= rowLimit;
      FETCH getBatches INTO stub;
      EXIT WHEN getBatches%NOTFOUND;
      rows := rows + 1;
      --IF(stub.SECURITY_TYPE = 'X' OR stub.SECURITY_TYPE = 'Y' OR stub.SECURITY_TYPE = 'Z') THEN
      IF(stub.SECURITY_TYPE = 'X') THEN
        IF(tqb IS NOT NULL) THEN
          PIPE ROW (tqb);
          piped := piped + 1;
          Log('GROUP_TQBATCHES PIPED:' || piped || ', size:' || tqb.TCOUNT || ',trows:' || rows);        
          tqb := NULL;
        END IF;
        PIPE ROW (NEW TQBATCH(stub, piped));
        piped := piped + 1;
        Log('GROUP_TQBATCHES PIPED:' || piped || ', size:1' || ',trows:' || rows);        
        CONTINUE;
      END IF;
      IF(tqb IS NULL) THEN
        tqb := NEW TQBATCH(stub, piped);
      ELSE 
        IF(tqb.ACCOUNT != stub.ACCOUNT_ID) THEN
          PIPE ROW(tqb);
          piped := piped + 1;
          Log('GROUP_TQBATCHES PIPED:' || piped || ', size:' || tqb.TCOUNT || ',trows:' || rows); 
          tqb := NEW TQBATCH(stub, piped);
        ELSE           
          tqb.ADDSTUB(stub);
        END IF;
      END IF;
    END LOOP;
    Log('GROUP_TQBATCHES: END LOOP');
    IF(tqb IS NOT NULL) THEN 
      PIPE ROW(tqb);
      piped := piped + 1;
      Log('GROUP_TQBATCHES PIPED:' || piped || ', size:' || tqb.TCOUNT || ',trows:' || rows); 
    END IF;
    CLOSE getBatches;
    Log('GROUP_TQBATCHES: CURSOR CLOSED');
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('GROUP_TQBATCHES START: no_data_needed');
        IF(getBatches%ISOPEN) THEN 
          CLOSE getBatches; 
          Log('GROUP_TQBATCHES: CURSOR CLOSED');
        END IF;
        --RAISE;    
        RETURN;
      WHEN OTHERS THEN 
        DECLARE
          errm VARCHAR2(2000) := SQLERRM;
          errc NUMBER := SQLCODE;
        BEGIN
          IF(getBatches%ISOPEN) THEN 
            CLOSE getBatches; 
            Log('GROUP_TQBATCHES: CURSOR CLOSED');
          END IF;
          Log('GROUP_TQBATCHES ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() || ', ERRCODE:' || errc);
          RAISE;
        END;
  END GROUP_TQBATCHES;
  
  
  
  -- *******************************************************
  --    Query batches of trade stubs
  -- *******************************************************
  FUNCTION QUERY_BATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999 ) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE IS
    CURSOR pipeBatches IS 
      SELECT TQSTUBS_OBJ(ROWIDTOCHAR(ROWID), ROWIDTOCHAR(TQROWID),TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,BATCH_TS)
        FROM TQSTUBS T WHERE MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID;
      
--      SELECT VALUE(X) FROM TABLE(TQSTUBS_RECS_TO_OBJS(CURSOR(
--        SELECT T.ROWID, T.* FROM TQSTUBS T WHERE MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID
--      ))) X;
      -- PIPE ROW(TQSTUBS_OBJ(rec.XROWID,rec.TQROWID,rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS));
    tqStub TQSTUBS_OBJ;
    piped PLS_INTEGER := 0;
  BEGIN
    Log('QUERY_BATCHES START: THREAD:' || threadMod || ',rowLimit:' || rowLimit || ',threadCount:' || threadCount || ',bucketSize:' || bucketSize);
    OPEN pipeBatches;
    Log('QUERY_BATCHES: CURSOR OPENED');
    LOOP
      FETCH pipeBatches into tqStub;
      EXIT WHEN pipeBatches%NOTFOUND;
      PIPE ROW(tqStub);    
      piped := piped + 1;
      Log('QUERY_BATCHES PIPED:' || piped);                
    END LOOP;
    Log('QUERY_BATCHES: END LOOP');
    CLOSE pipeBatches;
    Log('QUERY_BATCHES: CURSOR CLOSED');
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('QUERY_BATCHES: NO_DATA_NEEDED');
        IF(pipeBatches%ISOPEN) THEN CLOSE pipeBatches; END IF;
        --RAISE; 
        RETURN;
      WHEN OTHERS THEN 
        IF(pipeBatches%ISOPEN) THEN CLOSE pipeBatches; END IF;
        RAISE;            
  END QUERY_BATCHES;
  
  
  FUNCTION GET_TRADE_BATCH(xrowids IN XROWIDS) RETURN TQUEUE_OBJ_ARR IS 
    arr TQUEUE_OBJ_ARR;
  BEGIN
    SELECT TQUEUE_OBJ(ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE) 
      BULK COLLECT INTO arr FROM TQUEUE T WHERE EXISTS (
      SELECT RID FROM (
        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID
    );
    RETURN arr;
  END;
  
  
--=============================================================================================================  
-- Enriches each passed trade supplied in the cursor with the account id and pipes the enriched trades out
--=============================================================================================================  
  FUNCTION XENRICH_TRADE_ACCOUNTS(p IN TQUEUE_REC_CUR) RETURN TQUEUE_REC_ARR PIPELINED PARALLEL_ENABLE IS 
    trade TQUEUE_REC;
  BEGIN
    LOOP
      FETCH p into trade;
      EXIT WHEN p%NOTFOUND;
      DECODE_ACCOUNT(trade.ACCOUNT_DISPLAY_NAME, trade.ACCOUNT_ID);
      PIPE ROW (trade);      
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN RETURN;
  END XENRICH_TRADE_ACCOUNTS;
  
--=============================================================================================================  
-- Enriches each passed trade supplied in the cursor with the security id and security type and pipes the enriched trades out
--=============================================================================================================  
  FUNCTION XENRICH_TRADE_SECURITIES(p IN TQUEUE_REC_CUR) RETURN TQUEUE_REC_ARR PIPELINED PARALLEL_ENABLE IS 
    trade TQUEUE_REC;
  BEGIN
    LOOP
      FETCH p into trade;
      EXIT WHEN p%NOTFOUND;
      DECODE_SECURITY(trade.SECURITY_DISPLAY_NAME, trade.SECURITY_ID, trade.SECURITY_TYPE);
      PIPE ROW (trade);      
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN RETURN;
  END XENRICH_TRADE_SECURITIES;
  
  FUNCTION ROOT_CURSOR(xrowids IN XROWIDS) RETURN TQUEUE_REC_CUR IS
    scur TQUEUE_REC_CUR;
  BEGIN
    OPEN scur FOR 
      SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
      FROM TQUEUE T WHERE EXISTS (
        SELECT RID FROM (
          SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID);
    RETURN scur;
  END ROOT_CURSOR;
  
  
  
  -- TQSTUBS_RECS_TO_OBJS(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_OBJ_ARR 
  
--=============================================================================================================  
-- Returns an open cursor to retrieve the trades for the passed TQUEUE XROWIDs
--=============================================================================================================
-- TO DO:  Embedd ENRICH CALLS INTO PIPE
  FUNCTION PIPE_TRADES_CURSOR(xrowids IN XROWIDS) RETURN TQUEUE_REC_CUR IS
    scur TQUEUE_REC_CUR;
    
  BEGIN
    OPEN scur FOR 
--      SELECT VALUE(T) FROM TABLE(
--        CURSOR(SELECT * FROM TABLE(ENRICH_TRADE_ACCOUNTS(
--          CURSOR(SELECT * FROM TABLE(ENRICH_TRADE_SECURITIES(
--            CURSOR(
--              SELECT TQUEUE_OBJ(ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE) obj 
--              FROM TQUEUE T WHERE EXISTS (
--                SELECT RID FROM (
--                  SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
--              ) WHERE RID = T.ROWID)
--          )))
--        )))
--      ));
                SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                FROM TQUEUE T WHERE EXISTS (
                  SELECT RID FROM (
                    SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
                ) WHERE RID = T.ROWID);

--        SELECT T.* FROM TABLE(
--          CURSOR(SELECT * FROM TABLE(XENRICH_TRADE_ACCOUNTS(
--            CURSOR(SELECT * FROM TABLE(XENRICH_TRADE_SECURITIES(
--              CURSOR(
--                SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
--                FROM TQUEUE T WHERE EXISTS (
--                  SELECT RID FROM (
--                    SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
--                ) WHERE RID = T.ROWID)              
--              )
--            )))
--          )))
--        ) T;
    
--    SELECT TQUEUE_OBJ(ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE) obj 
--      FROM TQUEUE T WHERE EXISTS (
--      SELECT RID FROM (
--        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
--      ) WHERE RID = T.ROWID
--    );
    return scur;    
  END PIPE_TRADES_CURSOR;
  
--=============================================================================================================  
-- Enriches each passed trade with the account id and pipes the enriched trades out
--=============================================================================================================  
  FUNCTION ENRICH_TRADE_ACCOUNTS(trades IN TQUEUE_OBJ_ARR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    trade TQUEUE_OBJ;
  BEGIN
    FOR i IN trades.FIRST..trades.LAST LOOP
      trade := trades(i);
      DECODE_ACCOUNT(trade.ACCOUNT_DISPLAY_NAME, trade.ACCOUNT_ID);
      PIPE ROW (trade);
    END LOOP;
    RETURN;
  END ENRICH_TRADE_ACCOUNTS;
  
--=============================================================================================================  
-- Enriches each passed trade with the security id and security type and pipes the enriched trades out
--=============================================================================================================  
  FUNCTION ENRICH_TRADE_SECURITIES(trades IN TQUEUE_OBJ_ARR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    trade TQUEUE_OBJ;
  BEGIN
    FOR i IN trades.FIRST..trades.LAST LOOP
      trade := trades(i);
      DECODE_SECURITY(trade.SECURITY_DISPLAY_NAME, trade.SECURITY_ID, trade.SECURITY_TYPE);
      PIPE ROW (trade);
    END LOOP;
    RETURN;
  END ENRICH_TRADE_SECURITIES;
  
  
--=============================================================================================================  
-- Pipes out all trades matching the passed TQUEUE XROWIDs
--=============================================================================================================  
  FUNCTION PIPE_TRADE_BATCH(xrowids IN XROWIDS) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    arr TQUEUE_OBJ_ARR;
  BEGIN
    FOR trade IN (
    SELECT TQUEUE_OBJ(ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE) obj 
      FROM TQUEUE T WHERE EXISTS (
      SELECT RID FROM (
        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID
    )) LOOP
      PIPE ROW (trade.obj);
    END LOOP;
  END;
  
--=============================================================================================================  
-- Deletes all TQSTUBS matching the passed TQUEUE XROWIDs
--=============================================================================================================  
  FUNCTION DELETE_STUB_BATCH(xrowids IN XROWIDS) RETURN NUMBER IS  
  BEGIN
    DELETE FROM TQSTUBS T WHERE EXISTS (
      SELECT RID FROM (
        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID
    );
    RETURN SQL%ROWCOUNT;
  END DELETE_STUB_BATCH;
  
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