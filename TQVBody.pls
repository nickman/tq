create or replace PACKAGE BODY TQV AS
  -- *******************************************************
  --    Private global variables
  -- *******************************************************  

  batchSeq PLS_INTEGER := 0;  
  TYPE INT_ARR IS TABLE OF INT;
  TYPE CHAR_ARR IS TABLE OF CHAR;
  TYPE ROWID_ARR IS TABLE OF ROWID;
  TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;  
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;
  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================
  TYPE SEC_DECODE_CACHE_IDX IS TABLE OF SEC_DECODE INDEX BY PLS_INTEGER;  
  TYPE ACCT_DECODE_CACHE_IDX IS TABLE OF ACCT_DECODE INDEX BY PLS_INTEGER;
  accountCacheIdx ACCT_DECODE_CACHE_IDX;
  securityCacheIdx SEC_DECODE_CACHE_IDX;    
  -- =====================================================================
  -- ==== done ====
  -- =====================================================================
  accountCache ACCT_DECODE_CACHE;
  securityCache SEC_DECODE_CACHE;
  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================  
--
  -- *******************************************************
  --    Returns a random security
  --    To query directly: select * FROM TABLE(NEW SEC_DECODE_ARR(TQV.RANDOMSEC))
  -- *******************************************************  
  FUNCTION RANDOMSEC RETURN SEC_DECODE IS   
  BEGIN
    RETURN securityCacheIdx(ABS(MOD(SYS.DBMS_RANDOM.RANDOM, securityCacheIdx.COUNT-1)));
  END RANDOMSEC;
--
  -- *******************************************************
  --    Returns a random account 
  --    To query directly: select * FROM TABLE(NEW ACCT_DECODE_ARR(TQV.RANDOMACCT))
  -- *******************************************************    
  FUNCTION RANDOMACCT RETURN ACCT_DECODE IS 
    sz NUMBER := accountCacheIdx.COUNT-1;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return accountCacheIdx(rand);
    EXCEPTION WHEN OTHERS THEN 
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
        
      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMACCT. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;    
  END RANDOMACCT;
  
  FUNCTION PIPEACCTCACHE RETURN ACCT_DECODE_ARR PIPELINED IS 
  BEGIN
    FOR i in 1..accountCacheIdx.COUNT LOOP
      PIPE ROW(accountCacheIdx(i));
    END LOOP;
  END;
  
  FUNCTION PIPESECCACHE RETURN SEC_DECODE_ARR PIPELINED IS 
  BEGIN
    FOR i in 1..securityCacheIdx.COUNT LOOP
      PIPE ROW(securityCacheIdx(i));
    END LOOP;
  END;
  
  
--
  -- *******************************************************
  --    Generates the specified number of randomized trades
  --    and inserts them into TQUEUE
  -- *******************************************************    
  PROCEDURE GENTRADES(tradeCount IN NUMBER DEFAULT 1000) IS
    account ACCT_DECODE;
    security SEC_DECODE;
  BEGIN
    FOR i in 1..tradeCount LOOP
      account := RANDOMACCT;
      security := RANDOMSEC;
      INSERT INTO TQUEUE 
        VALUES(SEQ_TQUEUE_ID.NEXTVAL, tqv.CURRENTXID, 'PENDING',  security.SECURITY_DISPLAY_NAME, account.ACCOUNT_DISPLAY_NAME, NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL);
    END LOOP;
    COMMIT;
  END GENTRADES;
  -- =====================================================================
  -- ==== done ====
  -- =====================================================================
  
  

  -- *******************************************************
  --    Root of Pipeline, Finds the unprocessed stubs
  -- *******************************************************  
  FUNCTION FINDSTUBS(p IN TQSTUBCUR, MAX_ROWS IN NUMBER DEFAULT 100) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID)) IS    
    trade TQSTUBV;
    rid VARCHAR2(18);
  BEGIN
    LOOP    
      FETCH p INTO trade;      
      EXIT WHEN p%NOTFOUND;
      PIPE ROW(trade);
      IF LOCKSTUB(trade.xrowid) THEN
        PIPE ROW(trade);
      END IF;
      IF(p%ROWCOUNT=MAX_ROWS) THEN
        EXIT;
      END IF;
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN
        BEGIN
          LOGEVENT('FINDSTUBS >>> CLEAN UP');
        END;
        RETURN;
  END FINDSTUBS;
  
  -- *******************************************************
  --    Converts Trade Record Sets into TQSTUB Object Arrays
  -- *******************************************************  
  FUNCTION TOTQSTUB(p IN TQSTUBCUR) RETURN TQSTUB_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID)) IS
    tv TQSTUBV;    
  BEGIN
    LOOP    
      FETCH p INTO tv;
      EXIT WHEN p%NOTFOUND;
      PIPE ROW(TQSTUB(
      	tv.XROWID, 
      	tv.TQROWID,
      	tv.TQUEUE_ID,
      	tv.XID,
      	tv.SECURITY_ID,
      	tv.SECURITY_TYPE,
      	tv.ACCOUNT_ID
    ));
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN      
        BEGIN
          LOGEVENT('TOTQSTUB >>> CLEAN UP');
        END;
        RETURN;
  END TOTQSTUB;
--
  -- *******************************************************
  --    Sorts the TQSTUBs in a batch by TQ ID
  -- *******************************************************  
  PROCEDURE SORTTRADEARR(tqb IN OUT TQBATCH, STUBS IN TQSTUB_ARR) IS
    fTx INT := 0;
    lTx INT := 0;
    sortedStubs TQSTUB_ARR;    
    rowids XROWIDS;
  CURSOR tQByID IS 
    SELECT VALUE(T), T.XROWID
      FROM TABLE(STUBS) T ORDER BY T.TQUEUE_ID;            
      
   BEGIN
      IF (STUBS.COUNT = 0) THEN 
      tqb.FIRST_T := -1;
      tqb.LAST_T := -1;  
      tqb.TRADES := STUBS;
    ELSE 
      OPEN tQByID;
        FETCH tQByID BULK COLLECT INTO sortedStubs, rowids;
      CLOSE tQByID;      
      tqb.FIRST_T := sortedStubs(1).TQUEUE_ID;
      tqb.LAST_T := sortedStubs(STUBS.COUNT).TQUEUE_ID;
      tqb.TRADES := sortedStubs;  
      tqb.ROWIDS := rowids;
    END IF;
  END;  
--
-- *******************************************************
--    Fetches the next batch id
-- *******************************************************  
  FUNCTION NEXTBATCHID RETURN NUMBER IS 
    seq NUMBER;
  BEGIN
    SELECT SEQ_TQBATCH_ID.NEXTVAL INTO seq FROM DUAL;
    RETURN seq;
  END NEXTBATCHID;  
--
-- *******************************************************
--    Preps a batch of trades for piping
-- *******************************************************
  FUNCTION PREPBATCH(currentPosAcct IN INT, currentTradeArr IN TQSTUB_ARR) RETURN TQBATCH IS
    batch TQBATCH;
  BEGIN
    batch := new TQBATCH(currentPosAcct, currentTradeArr.COUNT, 0, 0, NEXTBATCHID, NULL, NULL);
    SORTTRADEARR(batch, currentTradeArr);
    return batch;
  END PREPBATCH;
--
-- *******************************************************
--    Batches the current set of trades
-- *******************************************************
  
  FUNCTION TRADEBATCH(STUBS IN TQSTUB_ARR, MAX_BATCH_SIZE IN PLS_INTEGER DEFAULT 100) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE IS
    currentPosAcctId INT := -1;
    currentTradeArr TQSTUB_ARR := NULL;
    tcount INT := 0;
    T TQSTUB;    
  BEGIN
    IF STUBS.COUNT = 0 THEN
      RETURN;
    END IF;
    FOR i IN STUBS.FIRST..STUBS.LAST LOOP
      T := STUBS(i);
      IF currentTradeArr IS NULL THEN 
        currentTradeArr := new TQSTUB_ARR();        
        currentPosAcctId := T.ACCOUNT_ID;        
      END IF;
      IF (T.ACCOUNT_ID != currentPosAcctId OR tcount = MAX_BATCH_SIZE OR T.SECURITY_TYPE='P') THEN
        IF T.SECURITY_TYPE='P' THEN 
          -- If we already batched some trades, flush them and reset state
          IF tcount > 0 THEN  
            PIPE ROW (PREPBATCH(currentPosAcctId, currentTradeArr));
            batchSeq := batchSeq +1;
            -- LOGEVENT('Piped Batch #' || batchSeq);
            tcount := 0;
            currentTradeArr := new TQSTUB_ARR();
            currentPosAcctId := T.ACCOUNT_ID;        
          END IF;
          -- Now flush the single P trade
          PIPE ROW (new TQBATCH(ACCOUNT => currentPosAcctId, TCOUNT => 1, FIRST_T => T.TQUEUE_ID, LAST_T => T.TQUEUE_ID, BATCH_ID => NEXTBATCHID, ROWIDS => new XROWIDS(T.XROWID), TRADES => new TQSTUB_ARR(T)));
          tcount := 0;
          currentTradeArr := new TQSTUB_ARR();
          currentPosAcctId := T.ACCOUNT_ID;                  
          CONTINUE;
        ELSE
          IF tcount > 0  THEN
            PIPE ROW (PREPBATCH(currentPosAcctId, currentTradeArr));
            tcount := 0;
            currentTradeArr := new TQSTUB_ARR();
            currentPosAcctId := T.ACCOUNT_ID;        
          END IF;
        END IF;
      END IF;
      tcount := tcount + 1;
      currentTradeArr.extend();
      currentTradeArr(tcount) := TQSTUB(
      	T.XROWID, 
      	T.TQROWID,
      	T.TQUEUE_ID,
      	T.XID,
      	T.SECURITY_ID,
      	T.SECURITY_TYPE,
      	T.ACCOUNT_ID
	  );
    END LOOP;
    IF tcount > 0 THEN
        PIPE ROW (PREPBATCH(currentPosAcctId, currentTradeArr));
    END IF;
  END TRADEBATCH;
--
  -- *******************************************************
  --    toString for Trade Arrays
  -- *******************************************************

  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCH_ARR PIPELINED IS
      batchy TQBATCH;    
      latency NUMBER  := 0;
      cursor qx is SELECT VALUE(T) FROM TABLE (
          TQV.TRADEBATCH(
            TQV.TOTQSTUB(CURSOR(SELECT * FROM TABLE(
	          TQV.FINDSTUBS(
	            CURSOR (
	              SELECT * FROM TQSTUBS
	              WHERE TQUEUE_ID > STARTING_ID 
	              ORDER BY TQUEUE_ID, ACCOUNT_ID                  
	            )
	          , MAX_ROWS) -- MAX ROWS (Optional)                  
            ) ORDER BY ACCOUNT_ID))
          , MAX_BATCH_SIZE)  -- Max number of trades in a batch
        ) T;
    BEGIN
      open qx;
        LOOP
          fetch qx into batchy;
          EXIT WHEN qx%NOTFOUND;
          pipe row(batchy);
        END LOOP;
      close qx;
    NULL;
  END QUERYTBATCHES;  
--  
  -- *******************************************************
  --    toString for Trade Arrays
  -- *******************************************************

  FUNCTION STUBTOSTR(STUBS IN TQSTUB_ARR) RETURN VARCHAR2 IS
    str VARCHAR(4000) := '';
    st TQSTUB;
  BEGIN
    FOR i in STUBS.FIRST..STUBS.LAST LOOP
      st := STUBS(i);
      str := str || '[id:' || st.TQUEUE_ID || ', type:' || st.SECURITY_TYPE || ',sec:' || st.SECURITY_ID || ',acct:' || st.ACCOUNT_ID || ']';
      IF (LENGTH(str) > 3900) THEN
      	str := (str || '...' || (STUBS.COUNT - i) || ' more...');
      	EXIT;
      END IF;
    END LOOP;
    return str;
  END STUBTOSTR;  
--    
  -- *******************************************************
  --    Autonomous TX Logger
  -- *******************************************************  
  
  PROCEDURE LOGEVENT(msg VARCHAR2, errc NUMBER default 0) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO EVENT VALUES (SYSDATE, '' || errc || ' -- ' || msg);
    COMMIT;
  END LOGEVENT;
--
  -- *******************************************************
  --    Attempts to lock the row in TQSTUBS
  -- *******************************************************  

  FUNCTION LOCKSTUB(rid in VARCHAR2) RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    rrid VARCHAR2(18) := NULL;
  BEGIN
    SELECT ROWIDTOCHAR(ROWID) INTO rrid FROM TQSTUBS WHERE ROWID = CHARTOROWID(rid) FOR UPDATE SKIP LOCKED;
    COMMIT;
    RETURN TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      COMMIT;
      RETURN FALSE;
  END LOCKSTUB; 
--  
  -- *******************************************************
  --    Lock all rows in a batch
  -- *******************************************************

  PROCEDURE LOCKBATCH(batch IN TQBATCH) IS
    ids TQUEUE_ID_ARR;
  BEGIN
    SELECT TQUEUE_ID BULK COLLECT INTO ids FROM TQUEUE
    WHERE ROWID IN (
      SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(batch.ROWIDS)
    ) FOR UPDATE NOWAIT;
  END LOCKBATCH;
--
  -- *******************************************************
  --    Lock all rows in all passed batches
  -- *******************************************************

  PROCEDURE LOCKBATCHES(batches IN TQBATCH_ARR) IS
  BEGIN
    FOR i in 1..batches.COUNT LOOP   /**  !! FORALL with EXECUTE IMMEDIATE ?  */
      LOCKBATCH(batches(i));
    END LOOP;
  END LOCKBATCHES;
--
  -- *******************************************************
  --    Updates all rows in the passed batch
  -- *******************************************************
  /*
  PROCEDURE UPDATEBATCH(batch IN TQBATCH) IS
  BEGIN
    FORALL i IN 1..batch.TRADES.COUNT
      UPDATE TQUEUE SET        
        STATUS_CODE = batch.TRADES(i).STATUS_CODE,
        SECURITY_DISPLAY_NAME = batch.TRADES(i).SECURITY_DISPLAY_NAME,
        ACCOUNT_DISPLAY_NAME = batch.TRADES(i).ACCOUNT_DISPLAY_NAME,
        SECURITY_ID = batch.TRADES(i).SECURITY_ID,
        SECURITY_TYPE = batch.TRADES(i).SECURITY_TYPE,
        ACCOUNT_ID = batch.TRADES(i).ACCOUNT_ID,
        BATCH_ID = batch.TRADES(i).BATCH_ID,
        CREATE_TS = batch.TRADES(i).CREATE_TS,
        UPDATE_TS = batch.TRADES(i).UPDATE_TS,
        ERROR_MESSAGE = batch.TRADES(i).ERROR_MESSAGE
      WHERE ROWID = CHARTOROWID(batch.TRADES(i).XROWID);
      -- WHERE TQUEUE_ID = batch.TRADES(i).TQUEUE_ID;
    
  END UPDATEBATCH;
  */
--
  -- *******************************************************
  --    Updates all rows in all passed batches
  -- *******************************************************
/*
  PROCEDURE UPDATEBATCHES(batches IN TQBATCH_ARR) IS
  BEGIN
    FORALL i IN 1..batches.COUNT
      EXECUTE IMMEDIATE 'BEGIN TQV.UPDATEBATCH(:1); END;' USING IN batches(i);
  END UPDATEBATCHES;
*/  
  
  
  FUNCTION SECIDFORROWID(id in ROWID) RETURN INT IS
    dispName VARCHAR2(64);
  BEGIN
    SELECT SECURITY_DISPLAY_NAME INTO dispName FROM TQUEUE WHERE ROWID = id;
    return securityCache(dispName).SECURITY_ID;
  END;

  FUNCTION SECTYPEFORROWID(id in ROWID) RETURN CHAR IS
    dispName VARCHAR2(64);
  BEGIN
    SELECT SECURITY_DISPLAY_NAME INTO dispName FROM TQUEUE WHERE ROWID = id;
    return securityCache(dispName).SECURITY_TYPE;
  END;
  
  FUNCTION TQIDFORROWID(id in ROWID) RETURN NUMBER IS
    tqid NUMBER;
  BEGIN
    SELECT TQUEUE_ID INTO tqid FROM TQUEUE WHERE ROWID = id;
    RETURN tqid;
  END TQIDFORROWID;

  FUNCTION ACCTIDFORROWID(id in ROWID) RETURN INT IS
    dispName VARCHAR2(64);
  BEGIN
    SELECT ACCOUNT_DISPLAY_NAME INTO dispName FROM TQUEUE WHERE ROWID = id;
    return accountCache(dispName);
  END;
    
  PROCEDURE TESTINSERT AS
  
  BEGIN
    INSERT INTO TQUEUE VALUES(SEQ_TQUEUE_ID.NEXTVAL, CURRENTXID, 'PENDING', 'c064e4ae-cb1c-4700-872f-eedde770c937',
      '3c7dea15-cc46-4e9f-816a-f342c8089d86', NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL);
      COMMIT;
    
    -- TQUEUE_ID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID
    -- CREATE_TS,UPDATE_TS,ERROR_MESSAGE
    
  END;

--
  -- *******************************************************
  --    Handles INSERT Query notifications
  -- *******************************************************  
--  FIXME:  this can be optimized !!
  PROCEDURE HANDLE_INSERT(transaction_id RAW, ntfnds CQ_NOTIFICATION$_DESCRIPTOR) IS
    secids INT_ARR := new INT_ARR();
    actids INT_ARR := new INT_ARR();
    tqids INT_ARR := new INT_ARR();
    sectypes CHAR_ARR := new CHAR_ARR();
    rowids ROWID_ARR := new ROWID_ARR();
    numrows NUMBER := 0;
    row_desc_array CQ_NOTIFICATION$_ROW_ARRAY;
    operation_type  NUMBER;
    event_type      NUMBER;
    stubs TQSTUB_ARR;
  BEGIN
    event_type := ntfnds.event_type;
    IF (event_type = DBMS_CQ_NOTIFICATION.EVENT_OBJCHANGE) THEN
      operation_type := ntfnds.table_desc_array(1).Opflags;
    ELSE
      operation_type := ntfnds.query_desc_array(1).table_desc_array(1).Opflags;
    END IF;
    
    IF (bitand(operation_type, DBMS_CQ_NOTIFICATION.ALL_ROWS) = 0) THEN
      -- We have rows
      IF (event_type = DBMS_CQ_NOTIFICATION.EVENT_OBJCHANGE) THEN
        LOGEVENT('HandleInserts: EVENT_OBJCHANGE'); 
        row_desc_array := ntfnds.table_desc_array(1).row_desc_array;
      ELSIF (event_type = DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
        LOGEVENT('HandleInserts: EVENT_QUERYCHANGE'); 
        row_desc_array := ntfnds.query_desc_array(1).table_desc_array(1).row_desc_array;
      ELSE
        LOGEVENT('HandleInserts: Unsupported Event Type:' || event_type); 
      END IF;
    ELSE 
      -- batch was too big. Need to read from TQXIDS
      LOGEVENT('HandleInserts: Batch Overflow on TX:' || ntfnds.transaction_id); 
      SELECT SYS.CHNF$_RDESC(0, ROWID) BULK COLLECT INTO row_desc_array FROM TQUEUE WHERE XID = ntfnds.transaction_id;
      LOGEVENT('HandleInserts: Retrieved Overflow:' || row_desc_array.COUNT); 
    END IF;
  
    IF ( row_desc_array IS NULL ) THEN
      LOGEVENT('HandleInserts: FOUND NO ROWS'); 
      RETURN;
    END IF;
    LOGEVENT('HandleInserts: FOUND ROWS:' || row_desc_array.COUNT); 
    
    secids.extend(row_desc_array.COUNT);
    actids.extend(row_desc_array.COUNT);
    tqids.extend(row_desc_array.COUNT);
    sectypes.extend(row_desc_array.COUNT);
    rowids.extend(row_desc_array.COUNT);
    
    FOR i in 1..row_desc_array.COUNT LOOP
      rowids(i) := CHARTOROWID(row_desc_array(i).row_id);
      tqids(i) := TQIDFORROWID(row_desc_array(i).row_id);
      secids(i) := SECIDFORROWID(rowids(i));
      actids(i) := ACCTIDFORROWID(rowids(i));
      sectypes(i) := SECTYPEFORROWID(rowids(i));
      -- "-1400 -- ORA-01400: cannot insert NULL into ("TQREACTOR"."TQSTUBS"."TQUEUE_ID") : ORA-06512: at "TQREACTOR.TQV", line 477"
      INSERT INTO TQSTUBS (TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID)
      VALUES(
        rowids(i), 
        tqids(i),
        transaction_id, 
        secids(i),
        sectypes(i),
        actids(i)
      );      
    END LOOP;
    COMMIT;
    --LOGEVENT('HANDLED INSERT EVENTS: '|| numrows); 
    EXCEPTION WHEN OTHERS THEN 
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
        
      BEGIN
        LOGEVENT( errm || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
      END;
  END HANDLE_INSERT;



  
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
  


  -- *******************************************************
  --    Load cache procedure
  -- *******************************************************
  
  FUNCTION FORCELOADCACHE RETURN VARCHAR2 IS
    d VARCHAR2(64);
    s NUMBER := 0;
    a NUMBER := 0;
  BEGIN
      FOR R IN (SELECT * FROM TABLE(TQV.PIPESECCACHE)) LOOP
        d := R.SECURITY_DISPLAY_NAME;
        s := s+1;
      END LOOP;      
      FOR R IN (SELECT * FROM TABLE(TQV.PIPEACCTCACHE)) LOOP
        d := R.ACCOUNT_DISPLAY_NAME;
        a := a+1;
      END LOOP;
      return 'read-secs:' || s || ', read-accts:' || a;
  END;
  
  PROCEDURE LOADCACHES IS
      spec SPEC_DECODE;
      idx PLS_INTEGER;
      d VARCHAR2(64);
    BEGIN  
       -- populate accountCache 
      idx := 1;
      FOR R IN (SELECT ACCOUNT_DISPLAY_NAME, ACCOUNT_ID FROM ACCOUNT) LOOP
        accountCache(R.ACCOUNT_DISPLAY_NAME) := R.ACCOUNT_ID;
        accountCacheIdx(idx) := new ACCT_DECODE(R.ACCOUNT_DISPLAY_NAME, R.ACCOUNT_ID);
        idx := idx + 1;
      END LOOP;
      FOR R IN (SELECT * FROM TABLE(TQV.PIPEACCTCACHE)) LOOP
        d := R.ACCOUNT_DISPLAY_NAME;
      END LOOP;
      LOGEVENT('INITIALIZED ACCT CACHE: ' || accountCache.COUNT || ' ACCOUNTS');
      -- populate security cache
      idx := 1;
      FOR R IN (SELECT SECURITY_DISPLAY_NAME, SECURITY_TYPE, SECURITY_ID FROM SECURITY) LOOP
        spec.SECURITY_ID := R.SECURITY_ID; 
        spec.SECURITY_DISPLAY_NAME := R.SECURITY_DISPLAY_NAME;
        spec.SECURITY_TYPE := R.SECURITY_TYPE;
        securityCache(R.SECURITY_DISPLAY_NAME) := spec;
        securityCacheIdx(idx) := new SEC_DECODE(R.SECURITY_DISPLAY_NAME, R.SECURITY_TYPE, R.SECURITY_ID);
        idx := idx + 1;
      END LOOP;
      FOR R IN (SELECT * FROM TABLE(TQV.PIPESECCACHE)) LOOP
        d := R.SECURITY_DISPLAY_NAME;
      END LOOP;      
      LOGEVENT('INITIALIZED SECURITY CACHE: ' || securityCache.COUNT || ' SECURITIES');
    END LOADCACHES;
  
  -- *******************************************************
  --    Package Initialization
  -- *******************************************************
  
  
  BEGIN
    LOADCACHES;
END TQV;