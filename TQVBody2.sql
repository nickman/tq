create or replace PACKAGE BODY TQV AS
  -- *******************************************************
  --    Private global variables
  -- *******************************************************  

  batchSeq PLS_INTEGER := 0;  
  --TYPE INT_ARR IS TABLE OF INT;
  --TYPE CHAR_ARR IS TABLE OF CHAR;
  --TYPE ROWID_ARR IS TABLE OF ROWID;
  --TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;  
  --TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;
  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================
  TYPE SEC_DECODE_CACHE_IDX IS TABLE OF SEC_DECODE INDEX BY PLS_INTEGER;  
  TYPE ACCT_DECODE_CACHE_IDX IS TABLE OF ACCT_DECODE INDEX BY PLS_INTEGER;
  accountCacheIdx ACCT_DECODE_CACHE_IDX;
  securityCacheIdx SEC_DECODE_CACHE_IDX; 
  securityTypes CHAR_ARR := new CHAR_ARR('A', 'B', 'C', 'D', 'E', 'V', 'W', 'X', 'Y', 'Z', 'P');

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
    sz NUMBER := securityCacheIdx.COUNT-1;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return securityCacheIdx(rand);
    EXCEPTION WHEN OTHERS THEN 
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;        
      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMSEC. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;    
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
--
  -- *******************************************************
  --    Returns a random security type
  -- *******************************************************    
FUNCTION RANDOMSECTYPE RETURN CHAR IS   
    sz NUMBER := securityTypes.COUNT;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return securityTypes(rand);
    EXCEPTION WHEN OTHERS THEN 
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
        
      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMSECTYPE. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;    
  END RANDOMSECTYPE;  
--  
  FUNCTION PIPEACCTCACHE RETURN ACCT_DECODE_ARR PIPELINED IS 
  BEGIN
    FOR i in 1..accountCacheIdx.COUNT LOOP
      PIPE ROW(accountCacheIdx(i));
    END LOOP;
  END;
--  
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
--
  -- *******************************************************
  --    Generates the specified number of randomized accounts
  --    and inserts them into ACCOUNT
  -- *******************************************************      
  PROCEDURE GENACCTS(acctCount IN NUMBER DEFAULT 1000) IS
  BEGIN
    FOR i in 1..acctCount LOOP
      INSERT INTO ACCOUNT VALUES(SEQ_ACCOUNT_ID.NEXTVAL, SYS_GUID());
    END LOOP;
    COMMIT;
  END GENACCTS;
--
  -- *******************************************************
  --    Generates the specified number of randomized securities
  --    and inserts them into SECURITY
  -- *******************************************************      
  PROCEDURE GENSECS(secCount IN NUMBER DEFAULT 10000) IS
  BEGIN
    FOR i in 1..secCount LOOP
      INSERT INTO SECURITY VALUES(SEQ_SECURITY_ID.NEXTVAL, SYS_GUID(), TQV.RANDOMSECTYPE);
    END LOOP;
    COMMIT;
  END GENSECS;
  
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
      /*
      IF LOCKSTUB(trade.xrowid) THEN
        PIPE ROW(trade);
      END IF;
      */
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
        tv.ACCOUNT_ID,
        tv.BATCH_ID,
        tv.BATCH_TS
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
        T.ACCOUNT_ID,
        T.BATCH_ID,
        T.BATCH_TS
    );
    END LOOP;
    IF tcount > 0 THEN
        PIPE ROW (PREPBATCH(currentPosAcctId, currentTradeArr));
    END IF;
  END TRADEBATCH;
--
  -- *******************************************************
  --    Main query point to get new batches
  --    To keep and process the batches, 
  --    call LOCKBATCH(batch) or LOCKBATCHES(batch_arr)
  -- *******************************************************

  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCH_ARR PIPELINED IS
      batchy TQBATCH;    
      latency NUMBER  := 0;
      cursor qx is SELECT VALUE(T) FROM TABLE (
          TQV.TRADEBATCH(
            TQV.TOTQSTUB(CURSOR(SELECT * FROM TABLE(
            TQV.FINDSTUBS(
              CURSOR (
                SELECT ROWIDTOCHAR(ROWID) XROWID, TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS  FROM TQSTUBS
                WHERE TQUEUE_ID > STARTING_ID 
                AND BATCH_ID < 1
                AND BATCH_TS IS NULL
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
  
  -- TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
-- ROWIDTOCHAR(ROWID) XROWID, TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS 
-- TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID

  -- *******************************************************
  --    Main query point to get existing batches
  --    Basically reconstitutes batches from locked
  --    stubs in TQSTUBS.
  -- *******************************************************
  FUNCTION GETBATCHES RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE IS
    batch TQBATCH;
    stubs TQSTUB_ARR;
    CURSOR c1 IS SELECT ACCOUNT_ID, BATCH_ID, BATCH_TS, COUNT(*) TCOUNT, MIN(TQUEUE_ID) FIRST_T, MAX(TQUEUE_ID) LAST_T,
    CAST(collect(ROWIDTOCHAR(ROWID)) AS XROWIDS) AS ROWIDS,
    CAST(collect(ROWIDTOCHAR(TQROWID)) AS XROWIDS) AS TQROWIDS,
    CAST(collect(TQSTUB(ROWIDTOCHAR(ROWID), TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,BATCH_TS)) AS TQSTUB_ARR) AS TQSTBS
    FROM TQSTUBS 
    WHERE BATCH_ID > 0
    AND BATCH_TS IS NOT NULL
    GROUP BY BATCH_ID, BATCH_TS, ACCOUNT_ID
    ORDER BY BATCH_ID, BATCH_TS, ACCOUNT_ID;
  BEGIN
    FOR T IN c1 LOOP
      PIPE ROW (new TQBATCH(T.ACCOUNT_ID, T.TCOUNT, T.FIRST_T, T.LAST_T, T.BATCH_ID, T.ROWIDS, T.TQSTBS));
    END LOOP;
    RETURN;
  END GETBATCHES;
  
  /*
  ACCOUNT           INT,
  TCOUNT            INT,
  FIRST_T           INT,
  LAST_T            INT,
  BATCH_ID          INT,
  ROWIDS            XROWIDS,
  TRADES            TQSTUB_ARR,
  */

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
      str := str || '[id:' || st.TQUEUE_ID || ', batch:' || st.batch_id || ', type:' || st.SECURITY_TYPE || ',sec:' || st.SECURITY_ID || ',acct:' || st.ACCOUNT_ID || ']';
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
  
  PROCEDURE LOGEVENT(msg VARCHAR2, errcode NUMBER default 0) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO EVENT(EVENT_ID, ERRC, TS, EVENT) VALUES (SEQ_EVENT_ID.NEXTVAL, ABS(errcode), SYSDATE, msg);
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
  --    Lock all rows in a batch.
  --    Intended to reserve TQSTUBs after fetching
  --    with QUERYBATCHES.
  -- *******************************************************

  PROCEDURE LOCKBATCH(batch IN OUT TQBATCH) IS
    lockedStubs TQSTUB_ARR;
    now TIMESTAMP := SYSTIMESTAMP;

  BEGIN
    SELECT TQSTUB(
        ROWIDTOCHAR(ROWID),
        TQROWID,
        TQUEUE_ID,
        XID,
        SECURITY_ID,
        SECURITY_TYPE,
        ACCOUNT_ID,
        BATCH_ID,
        BATCH_TS
    ) BULK COLLECT INTO lockedStubs
    FROM TQSTUBS 
    WHERE ROWID IN (
      SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(batch.ROWIDS)
    ) FOR UPDATE SKIP LOCKED;

    FORALL i in 1..lockedStubs.COUNT
        UPDATE TQSTUBS SET BATCH_ID = batch.BATCH_ID, BATCH_TS = now
        WHERE ROWID = CHARTOROWID(lockedStubs(i).XROWID);
    COMMIT;
    batch.TRADES := lockedStubs;
  END LOCKBATCH;
--  
  -- *******************************************************
  --    Lock all rows in a batch.
  --    Intended to re-lock a batch when trade processing starts
  -- *******************************************************

  PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH) IS
    lockedStubs TQSTUB_ARR;
    now TIMESTAMP := SYSTIMESTAMP;  
  BEGIN
    SELECT TQSTUB(
        ROWIDTOCHAR(ROWID),
        TQROWID,
        TQUEUE_ID,
        XID,
        SECURITY_ID,
        SECURITY_TYPE,
        ACCOUNT_ID,
        BATCH_ID,
        BATCH_TS
    ) BULK COLLECT INTO lockedStubs
    FROM TQSTUBS 
    WHERE ROWID IN (
      SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(batch.ROWIDS)
    ) FOR UPDATE SKIP LOCKED;  
  END RELOCKBATCH;
    
--
  -- *******************************************************
  --    Lock all rows in all passed batches
  -- *******************************************************

  PROCEDURE LOCKBATCHES(batches IN TQBATCH_ARR) IS
    batch TQBATCH;
  BEGIN
    FOR i in 1..batches.COUNT LOOP   /**  !! FORALL with EXECUTE IMMEDIATE ?  */
      batch := batches(i);
      LOCKBATCH(batch);
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
  
  

--
  -- *******************************************************
  --    Handles INSERT Query notifications
  -- *******************************************************  
  PROCEDURE HANDLE_INSERT(transaction_id RAW, ntfnds CQ_NOTIFICATION$_DESCRIPTOR) IS
    secids INT_ARR := new INT_ARR();
    actids INT_ARR := new INT_ARR();
    tqids INT_ARR := new INT_ARR();
    sectypes CHAR_ARR := new CHAR_ARR();
    rowids XROWIDS;
    
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
    SELECT row_id BULK COLLECT INTO rowids FROM TABLE(row_desc_array);
    --LOGEVENT('HandleInserts: FOUND ROWS:' || row_desc_array.COUNT); 
    
    SELECT TQSTUB(NULL, ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, transaction_id, S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID, -1 , NULL )
    BULK COLLECT INTO stubs
    FROM TQUEUE T, ACCOUNT A, SECURITY S
    WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
    AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
    AND T.ROWID IN (
      (SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(rowids)) 
    );
    
    FORALL i in stubs.FIRST..stubs.LAST
      INSERT INTO TQSTUBS (TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS)
      VALUES(
        stubs(i).TQROWID, 
        stubs(i).TQUEUE_ID,
        stubs(i).XID, 
        stubs(i).SECURITY_ID,
        stubs(i).SECURITY_TYPE,
        stubs(i).ACCOUNT_ID,
        stubs(i).BATCH_ID,
        stubs(i).BATCH_TS
      );      
    
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
  --    Load cache procedure
  -- *******************************************************
  
  FUNCTION FORCELOADCACHE RETURN VARCHAR2 IS
    d VARCHAR2(64);
    s NUMBER := 0;
    a NUMBER := 0;
  BEGIN
      accountCache.delete;
      accountCacheIdx.delete;
      securityCache.delete;
      securityCacheIdx.delete;      
      LOADCACHES;
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

  
  -- *******************************************************
  --    Package Initialization
  -- *******************************************************
  
  
  BEGIN
    LOADCACHES;
END TQV;