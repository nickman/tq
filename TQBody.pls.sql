create or replace PACKAGE BODY TQ as


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
        PIPE ROW(TQUEUE_OBJ(rec.XROWID,rec.TQUEUE_ID,rec.XID,rec.STATUS_CODE,rec.SECURITY_DISPLAY_NAME,rec.ACCOUNT_DISPLAY_NAME,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.CREATE_TS,rec.UPDATE_TS,rec.ERROR_MESSAGE, null));
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
      FETCH p INTO
        rec.TQROWID,
        rec.TQUEUE_ID,
        rec.XID,
        rec.SECURITY_ID,
        rec.SECURITY_TYPE,
        rec.ACCOUNT_ID,
        rec.BATCH_ID,
        rec.BATCH_TS;
    EXIT WHEN p%NOTFOUND;
     SELECT sid
      INTO   rec.SID
      FROM   v$mystat
      WHERE  rownum = 1;      

        
        PIPE ROW(TQSTUBS_OBJ(null,rec.TQROWID,rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS));
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
  PROCEDURE DECODE_SECURITY(securityDisplayName IN VARCHAR2, securityId OUT NUMBER, securityType OUT NOCOPY CHAR) IS
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
    ts TIMESTAMP(6) := SYSTIMESTAMP;
  BEGIN
    srec := DECODE_SECURITY(securityDisplayName);
    accountId := DECODE_ACCOUNT(accountDisplayName).ACCOUNT_ID;
    INSERT INTO TQSTUBS VALUES(ROWIDTOCHAR(rowid), tqueueId, CURRENTXID(), srec.SECURITY_ID, srec.SECURITY_TYPE, accountId, batchId, ts);
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
      tqb := NULL;
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
  --    Groups an array of TQSTUBS_OBJ into an 
  --    array of TQBATCHes.
  -- *******************************************************
  FUNCTION GROUP_TQBATCHES2(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE IS
    batches TQBATCH_ARR;    
    batch TQBATCH;
    CURSOR p IS SELECT VALUE(V) FROM TABLE(TQ.QUERY_BATCHES2(CURSOR(
      SELECT /*+ parallel(t1, 5) */ ROWIDTOCHAR(ROWID) XROWID, T.* 
        FROM TQSTUBS T WHERE (threadMod = -1 OR MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod) ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID    
      ), rowLimit)) V;
      
      

      

  BEGIN
--    SELECT VALUE(V) BULK COLLECT INTO batches FROM TABLE(QUERY_BATCHES2(CURSOR(
--      SELECT ROWIDTOCHAR(ROWID) XROWID, T.* 
--        FROM TQSTUBS T WHERE (threadMod = -1 OR MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod) ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID    
--    ), rowLimit))V;
--    FOR i in batches.FIRST..batches.LAST LOOP
--      PIPE ROW (batches(i));
--    END LOOP;
    OPEN p;
    LOOP
      EXIT WHEN p%NOTFOUND;
      FETCH p INTO batch;
      PIPE ROW(batch);
    END LOOP;
    CLOSE P;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('GROUP_TQBATCHES2: no_data_needed');
        RETURN;
      WHEN OTHERS THEN 
        DECLARE
          errm VARCHAR2(2000) := SQLERRM;
          errc NUMBER := SQLCODE;
        BEGIN
          Log('GROUP_TQBATCHES2 ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() || ', ERRCODE:' || errc);
          RAISE;
        END;
  END GROUP_TQBATCHES2;
  
  FUNCTION QUERY_BATCHES2(p IN TQSTUBS_REC_CUR, rowLimit IN PLS_INTEGER DEFAULT 1024) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)) IS
    rec TQSTUBS_REC := NULL;
    stub TQSTUBS_OBJ;
    piped PLS_INTEGER := 1;
    rows PLS_INTEGER := 0;      
    currentBatch TQBATCH := null;
  BEGIN
    LOOP
     FETCH p INTO
        rec.TQROWID,
        rec.TQUEUE_ID,
        rec.XID,
        rec.SECURITY_ID,
        rec.SECURITY_TYPE,
        rec.ACCOUNT_ID,
        rec.BATCH_ID,
        rec.BATCH_TS;
    EXIT WHEN p%NOTFOUND;
     SELECT sid
      INTO   rec.SID
      FROM   v$mystat
      WHERE  rownum = 1;      
      rows := rows +1;
      EXIT WHEN(rows > rowLimit);
      stub := NEW TQSTUBS_OBJ(NULL, ROWIDTOCHAR(rec.TQROWID),rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS);
      IF(stub.SECURITY_TYPE = 'X') THEN
        IF(currentBatch IS NOT NULL) THEN
          PIPE ROW (currentBatch);
          piped := piped +1;
          Log('QUERY_BATCHES2: Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows); 
          currentBatch := NULL;
        END IF;
        PIPE ROW (NEW TQBATCH(stub, piped));
        piped := piped + 1;
        Log('QUERY_BATCHES2: Acct:' || stub.ACCOUNT_ID ||  ', PIPED:' || piped || ', size:1' || ',trows:' || rows);
        CONTINUE;
      END IF;
      IF(currentBatch IS NULL) THEN
        currentBatch := NEW TQBATCH(stub, piped);
      ELSE
        IF(currentBatch.ACCOUNT != stub.ACCOUNT_ID) THEN
          PIPE ROW (currentBatch);
          piped := piped +1;
          Log('QUERY_BATCHES2: Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows); 
          currentBatch := NEW TQBATCH(stub, piped);
        ELSE 
          currentBatch.ADDSTUB(stub);
        END IF;
      END IF;
    END LOOP;
    CLOSE p;
    IF(currentBatch IS NOT NULL) THEN 
      PIPE ROW(currentBatch);
      piped := piped + 1;
      Log('QUERY_BATCHES2 FINAL: Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows); 
      currentBatch := NULL;
    END IF;    
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('QUERY_BATCHES2: no_data_needed');
        IF(p%ISOPEN) THEN 
          CLOSE p; 
        END IF;
        RETURN;
      WHEN OTHERS THEN 
        DECLARE
          errm VARCHAR2(2000) := SQLERRM;
          errc NUMBER := SQLCODE;
        BEGIN
          IF(p%ISOPEN) THEN 
            CLOSE p; 
          END IF;
          Log('QUERY_BATCHES2 ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() || ', ERRCODE:' || errc);
          RAISE;
        END;    
  END QUERY_BATCHES2;
  
  FUNCTION NEWBATCH(stub IN TQSTUBS_OBJ, piped IN PLS_INTEGER) RETURN TQBATCH_REC IS
    b TQBATCH_REC;
  BEGIN
    b.ACCOUNT := stub.ACCOUNT_ID;
    b.TCOUNT := 1;
    b.FIRST_T := stub.TQUEUE_ID;
    b.LAST_T := stub.TQUEUE_ID;
    b.BATCH_ID := piped;
    b.ROWIDS := NEW XROWIDS(stub.XROWID);
    b.TQROWIDS := new XROWIDS(stub.TQROWID);
    b.STUBS := NEW TQSTUBS_OBJ_ARR(stub);
    return b;
  END NEWBATCH;
  
  PROCEDURE UPDATEBATCH(b IN OUT NOCOPY TQBATCH_REC, stub IN TQSTUBS_OBJ) IS
  BEGIN
    b.LAST_T := stub.TQUEUE_ID;
    b.ROWIDS.extend();
    b.TQROWIDS.extend();
    b.STUBS.extend();
    b.TCOUNT := b.TCOUNT + 1;
    b.ROWIDS(b.TCOUNT) := stub.XROWID;
    b.TQROWIDS(b.TCOUNT) := stub.TQROWID;
    b.STUBS(b.TCOUNT) := stub;
  END UPDATEBATCH;
  
  
  FUNCTION QUERY_BATCHES3(p IN TQSTUBS_REC_CUR, rowLimit IN PLS_INTEGER DEFAULT 1024) RETURN TQBATCH_REC_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)) IS
    rec TQSTUBS_REC := NULL;
    stub TQSTUBS_OBJ;
    piped PLS_INTEGER := 1;
    rows PLS_INTEGER := 0;      
    currentBatch TQBATCH_REC := null;
  BEGIN
    LOOP
     FETCH p INTO
        rec.TQROWID,
        rec.TQUEUE_ID,
        rec.XID,
        rec.SECURITY_ID,
        rec.SECURITY_TYPE,
        rec.ACCOUNT_ID,
        rec.BATCH_ID,
        rec.BATCH_TS;
    EXIT WHEN p%NOTFOUND;
     SELECT sid
      INTO   rec.SID
      FROM   v$mystat
      WHERE  rownum = 1;      
      rows := rows +1;
      EXIT WHEN(rows > rowLimit);
      stub := NEW TQSTUBS_OBJ(NULL, ROWIDTOCHAR(rec.TQROWID),rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS);
      IF(stub.SECURITY_TYPE = 'X') THEN
        IF(currentBatch.ACCOUNT IS NOT NULL) THEN
          PIPE ROW (currentBatch);
          piped := piped +1;
          Log('QUERY_BATCHES3 [' || MYSID() || ': Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows); 
          currentBatch.ACCOUNT := NULL;
        END IF;
        PIPE ROW (NEWBATCH(stub, piped));
        piped := piped + 1;
        Log('QUERY_BATCHES3 [' || MYSID() || ': Acct:' || stub.ACCOUNT_ID ||  ', PIPED:' || piped || ', size:1' || ',trows:' || rows);
        CONTINUE;
      END IF;
      IF(currentBatch.ACCOUNT IS NULL) THEN
        currentBatch := NEWBATCH(stub, piped);
      ELSE
        IF(currentBatch.ACCOUNT != stub.ACCOUNT_ID) THEN
          PIPE ROW (currentBatch);
          piped := piped +1;
          Log('QUERY_BATCHES3 [' || MYSID() || ': Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows); 
          currentBatch := NEWBATCH(stub, piped);
        ELSE 
          UPDATEBATCH(currentBatch, stub);
        END IF;
      END IF;
    END LOOP;
    CLOSE p;
    IF(currentBatch.ACCOUNT IS NOT NULL) THEN
      PIPE ROW(currentBatch);
      piped := piped + 1;
      Log('QUERY_BATCHES3 FINAL [' || MYSID() || ': Acct:' || currentBatch.ACCOUNT ||  ',PIPED:' || piped || ', size:' || currentBatch.TCOUNT || ',trows:' || rows);       
    END IF;    
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('QUERY_BATCHES3 [' || MYSID() || ': no_data_needed');        
        RETURN;
      WHEN OTHERS THEN 
        DECLARE
          errm VARCHAR2(2000) := SQLERRM;
          errc NUMBER := SQLCODE;
        BEGIN
          Log('QUERY_BATCHES3 ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() || ', ERRCODE:' || errc);
          RAISE;
        END;    
  END QUERY_BATCHES3;
  
  
  FUNCTION QUERY_BATCHES4(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_REC_ARR PIPELINED PARALLEL_ENABLE (PARTITION p BY HASH(ACCOUNT_ID)) IS
    rec TQSTUBS_REC;
  BEGIN
    LOOP
      FETCH p INTO
        rec.TQROWID,
        rec.TQUEUE_ID,
        rec.XID,
        rec.SECURITY_ID,
        rec.SECURITY_TYPE,
        rec.ACCOUNT_ID,
        rec.BATCH_ID,
        rec.BATCH_TS;
      EXIT WHEN p%NOTFOUND;  
     SELECT sid
      INTO   rec.SID
      FROM   v$mystat
      WHERE  rownum = 1;      

      PIPE ROW (rec);
      --LOGGING.tcplog('QUERY_BATCHES4: PIPED ROW');
      
    END LOOP;
    RETURN;  
  END QUERY_BATCHES4;
  
  
  -- *******************************************************
  --    Query batches of trade stubs
  -- *******************************************************
  FUNCTION QUERY_BATCHES(threadMod IN PLS_INTEGER, rowLimit IN PLS_INTEGER DEFAULT 1024, threadCount IN PLS_INTEGER DEFAULT 16, bucketSize IN PLS_INTEGER DEFAULT 999999 ) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE IS
    CURSOR pipeBatches IS 
      SELECT TQSTUBS_OBJ(ROWIDTOCHAR(ROWID), ROWIDTOCHAR(TQROWID),TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,BATCH_TS)
        FROM TQSTUBS T WHERE MOD(ORA_HASH(ACCOUNT_ID, bucketSize),threadCount) = threadMod ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID;
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
    SELECT TQUEUE_OBJ(ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE, NULL) 
      BULK COLLECT INTO arr FROM TQUEUE T WHERE EXISTS (
      SELECT RID FROM (
        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID
    );
    RETURN arr;
  END;
  
  FUNCTION MYSID RETURN VARCHAR2 IS
    sid VARCHAR2(12);
  BEGIN
    SELECT SYS_CONTEXT('USERENV', 'SID') INTO sid FROM DUAL;
    RETURN sid;
  END MYSID;
  
--=============================================================================================================  
-- Enriches each passed trade supplied in the cursor with the security id, security type 
-- and account id then pipes the enriched trades out
--=============================================================================================================  
  FUNCTION XENRICH_TRADE(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID)) CLUSTER p BY (ACCOUNT_ID) IS
    rec TQUEUE_REC;
  BEGIN
    LOOP
      FETCH p into rec;
      EXIT WHEN p%NOTFOUND;
      DECODE_SECURITY(rec.SECURITY_DISPLAY_NAME, rec.SECURITY_ID, rec.SECURITY_TYPE);
      DECODE_ACCOUNT(rec.ACCOUNT_DISPLAY_NAME, rec.ACCOUNT_ID);
      PIPE ROW (TQUEUE_OBJ(rec.XROWID,rec.TQUEUE_ID,rec.XID,rec.STATUS_CODE,rec.SECURITY_DISPLAY_NAME,rec.ACCOUNT_DISPLAY_NAME,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.CREATE_TS,rec.UPDATE_TS,rec.ERROR_MESSAGE, NULL));      
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN NULL;  
  END XENRICH_TRADE;
  
  
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
  
  
  -- *******************************************************
  --    Attempts to lock the rows in TQSTUBS
  -- *******************************************************
  FUNCTION LOCKTRADES(xrowids IN XROWIDS) RETURN PLS_INTEGER IS
    tradeIds INT_ARR;
  BEGIN
    SELECT TQUEUE_ID BULK COLLECT INTO tradeIds FROM TQUEUE T WHERE EXISTS (
        SELECT RID FROM (
          SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS) X
      ) WHERE RID = T.ROWID) FOR UPDATE;
    RETURN tradeIds.COUNT;
  END LOCKTRADES;
  
  FUNCTION XROWIDSPLIT(str IN VARCHAR2) RETURN XROWIDS IS 
    l_idx    pls_integer;
    l_list    varchar2(32767) := str;
    l_value    varchar2(32767);  
  BEGIN
    RETURN NULL;
  END;
--=============================================================================================================  
-- Pipes out all trades matching the passed TQUEUE XROWIDs
--=============================================================================================================  
  FUNCTION PARSE_PIPE_TRADE_BATCH(xrowidStr IN VARCHAR2) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS
    v_array apex_application_global.vc_arr2;
    x XROWIDS := NEW XROWIDS();
    pipes PLS_INTEGER := 1;
    cursor p is SELECT DISTINCT VALUE(V) FROM TABLE(XENRICH_TRADE(
                  CURSOR(
                    SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                    FROM TQUEUE T WHERE EXISTS (
                      SELECT RID FROM (
                        SELECT DISTINCT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(x)
                      ) 
                      WHERE RID = T.ROWID
                    )            
                    ORDER BY TQUEUE_ID                     
                  )
                )
      )V;
      trade TQUEUE_OBJ;    
  BEGIN
    v_array := apex_util.string_to_table(xrowidStr, ',');    
    x.extend(v_array.COUNT);
    FOR i in v_array.FIRST..v_array.LAST LOOP
      x(i) := ltrim(rtrim(v_array(i)));
    END LOOP;    
    log(MYSID() || ', Processing Trade Batch for [' || x.COUNT || '] ROWIDs');
    OPEN p;
    LOOP      
      FETCH p into trade;
      EXIT WHEN p%NOTFOUND;
      log(MYSID() || ', TRADE OUT:' || pipes);
      pipes := pipes + 1;
      --LOCKTRADE(trade.XROWID);
      PIPE ROW (trade);
    END LOOP;
    log(MYSID() || ', END LOOP');
    CLOSE p;
    log(MYSID() || ', CLOSED CURSOR');
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        log('PIPE_TRADE_BATCH: NO_DATA_NEEDED');
        IF(p%ISOPEN) THEN CLOSE p; END IF;
        NULL;
      WHEN OTHERS THEN 
        IF(p%ISOPEN) THEN CLOSE p; END IF;
        RAISE;                
  END  PARSE_PIPE_TRADE_BATCH;
--=============================================================================================================  
-- Pipes out all trades matching the passed TQUEUE XROWIDs
--=============================================================================================================  
-- FUNCTION XENRICH_TRADE(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(ACCOUNT_ID));
  FUNCTION PIPE_TRADE_BATCH(xrowids IN XROWIDS) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS     
    cursor p is SELECT VALUE(V) FROM TABLE(XENRICH_TRADE(
                  CURSOR(
                    SELECT ROWIDTOCHAR(ROWID),TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE
                    FROM TQUEUE T WHERE EXISTS (
                      SELECT RID FROM (
                        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(XROWIDS)
                      ) 
                      WHERE RID = T.ROWID
                    )            
                    ORDER BY TQUEUE_ID                     
                  )
                )
      )V;
      trade TQUEUE_OBJ;
      pipes PLS_INTEGER := 1;
  BEGIN
    OPEN p;
    LOOP
      FETCH p into trade;
      EXIT WHEN p%NOTFOUND;      
      --LOCKTRADE(trade.XROWID);
      PIPE ROW (trade);
      log(MYSID() || ', TRADE OUT:' || pipes);
      pipes := pipes + 1;      
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN 
        Log('PIPE_TRADE_BATCH: NO_DATA_NEEDED');
        IF(p%ISOPEN) THEN CLOSE p; END IF;
        NULL;
      WHEN OTHERS THEN 
        IF(p%ISOPEN) THEN CLOSE p; END IF;
        RAISE;                
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
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs
--=============================================================================================================  
  PROCEDURE UPDATE_TRADES(trades IN TQUEUE_OBJ_ARR) IS
    now TIMESTAMP := SYSTIMESTAMP;
  BEGIN
    FORALL i IN trades.FIRST..trades.LAST
      UPDATE TQUEUE SET
      STATUS_CODE='COMPLETE',
      SECURITY_ID=trades(i).SECURITY_ID,
      SECURITY_TYPE=trades(i).SECURITY_TYPE,
      ACCOUNT_ID=trades(i).ACCOUNT_ID,
      BATCH_ID=trades(i).BATCH_ID,
      UPDATE_TS=now
      WHERE ROWID = CHARTOROWID(trades(i).XROWID);      
  END UPDATE_TRADES;
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs and deletes the stubs
--=============================================================================================================  
  PROCEDURE COMPLETE_BATCH(trades IN TQUEUE_OBJ_ARR, xrowids IN XROWIDS) IS
    drows INT;
    now TIMESTAMP := SYSTIMESTAMP;
  BEGIN    
    FORALL i IN trades.FIRST..trades.LAST
      UPDATE TQUEUE SET
      STATUS_CODE='COMPLETE',
      SECURITY_ID=trades(i).SECURITY_ID,
      SECURITY_TYPE=trades(i).SECURITY_TYPE,
      ACCOUNT_ID=trades(i).ACCOUNT_ID,
      BATCH_ID=trades(i).BATCH_ID,
      UPDATE_TS=now
      WHERE ROWID = CHARTOROWID(trades(i).XROWID);   
    drows := DELETE_STUB_BATCH(xrowids);
  END COMPLETE_BATCH;
  
--=============================================================================================================  
-- Updates rows in TQUEUE from the passed TQUEUE_OBJs and deletes the stubs
--=============================================================================================================  
  FUNCTION COMPLETE_BATCH_WCOUNTS(trades IN TQUEUE_OBJ_ARR, xrowids IN XROWIDS) RETURN INT_ARR IS
    drows INT_ARR := NEW INT_ARR(0,0);
    now TIMESTAMP := SYSTIMESTAMP;
  BEGIN    
    FORALL i IN trades.FIRST..trades.LAST
      UPDATE TQUEUE SET
      STATUS_CODE='COMPLETE',
      SECURITY_ID=trades(i).SECURITY_ID,
      SECURITY_TYPE=trades(i).SECURITY_TYPE,
      ACCOUNT_ID=trades(i).ACCOUNT_ID,
      BATCH_ID=trades(i).BATCH_ID,
      UPDATE_TS=now
      WHERE ROWID = CHARTOROWID(trades(i).XROWID);   
    drows(2) := DELETE_STUB_BATCH(xrowids);
    return drows;
  END COMPLETE_BATCH_WCOUNTS;
  
  
  
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