create or replace PACKAGE BODY TQV AS
  -- *******************************************************
  --    Private global variables
  -- *******************************************************

  batchSeq PLS_INTEGER := 0;
  /*
  TYPE INT_ARR IS TABLE OF INT;
  TYPE CHAR_ARR IS TABLE OF CHAR;
  TYPE ROWID_ARR IS TABLE OF ROWID;
  TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;
  */
  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================
  
  
  TYPE XROWIDSET IS TABLE OF VARCHAR2(18) INDEX BY VARCHAR2(18);
  TYPE CHANGE_TABLE_ARR IS TABLE OF CQ_NOTIFICATION$_TABLE INDEX BY PLS_INTEGER;
  
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
  --    Lock all rows in a batch
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
    ) FOR UPDATE OF BATCH_ID, BATCH_TS SKIP LOCKED;

    FORALL i in 1..lockedStubs.COUNT
        UPDATE TQSTUBS SET BATCH_ID = batch.BATCH_ID, BATCH_TS = now
        WHERE ROWID = CHARTOROWID(lockedStubs(i).XROWID);
    COMMIT;
    batch.TRADES := lockedStubs;
  END LOCKBATCH;
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
--  FIXME:  this can be optimized !!
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
    batch.TRADES := lockedStubs;
  END RELOCKBATCH;

  -- *******************************************************
  --    Locks, selects and returns all the trades for a batch
  -- *******************************************************

  FUNCTION STARTBATCH(tqbatch IN OUT TQBATCH) RETURN TQTRADE_ARR AS
    trades TQTRADE_ARR;
    rids XROWIDS := tqbatch.TXIDS;
    -- BATCH_HAS_LOCKED_ROWS EXCEPTION;
    -- PRAGMA EXCEPTION_INIT(BATCH_HAS_LOCKED_ROWS, -54);
  BEGIN
    SELECT TQTRADE(ROWIDTOCHAR(ROWID), TQUEUE_ID,XID,STATUS_CODE,SECURITY_DISPLAY_NAME,ACCOUNT_DISPLAY_NAME,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID,BATCH_ID,CREATE_TS,UPDATE_TS,ERROR_MESSAGE)
    BULK COLLECT INTO trades
    FROM TQUEUE T
    WHERE ROWID IN (
      SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(rids)
    )
    FOR UPDATE SKIP LOCKED;
    --tqbatch-->TRADES --> TQUEUE_ID
    --TRADES.TQSTUB.TQUEUE_ID
    RETURN trades;
  END STARTBATCH;
--
  -- *******************************************************
  --    Updates all rows in TQUEUE from the passed trade array
  -- *******************************************************

  PROCEDURE SAVETRADES(trades IN TQTRADE_ARR) AS
    tr TQTRADE_ARR := trades;
  BEGIN
    FORALL i IN 1..tr.COUNT
      UPDATE TQUEUE SET
        STATUS_CODE = tr(i).STATUS_CODE,
        UPDATE_TS = tr(i).UPDATE_TS,
        ERROR_MESSAGE = tr(i).ERROR_MESSAGE
      WHERE ROWID = CHARTOROWID(tr(i).XROWID);
  END SAVETRADES;

  /*
      !!!!!   
        Need to put independent logger in CQN CALLBACK.
      !!!!!
  
  */


--
  -- *******************************************************
  --    Deletes all the stubs for a batch by the passed rowids
  -- *******************************************************

  PROCEDURE FINISHBATCH(batchRowids IN XROWIDS) AS
    rids XROWIDS := batchRowids;
  BEGIN
    DELETE FROM TQSTUBS WHERE ROWID IN (
      SELECT CHARTOROWID(COLUMN_VALUE) FROM TABLE(rids)
    );
  END FINISHBATCH;
  
  FUNCTION OVERFLOW(txid IN RAW) RETURN XROWIDS IS
    rids XROWIDS;
  BEGIN
      -- batch was too big. Need to read from TQXIDS
      LOGEVENT('HandleInserts: Batch Overflow on TX:' || txid);
      SELECT ROWIDTOCHAR(ROWID) BULK COLLECT INTO rids FROM TQUEUE WHERE XID = txid; 
      RETURN rids;
  END OVERFLOW;
  
  -- SELECT SYS.CHNF$_RDESC(0, ROWID) BULK COLLECT INTO row_desc_array FROM TQUEUE WHERE XID = ntfnds.transaction_id;
  
  FUNCTION OVERFLOWTABLES(txid IN RAW) RETURN XROWIDS IS
    rids XROWIDS;
  BEGIN
    SELECT ROWIDTOCHAR(ROWID) BULK COLLECT INTO rids FROM TQUEUE WHERE XID = txid; 
    RETURN rids;
  END OVERFLOWTABLES;
  
  PROCEDURE APPEND(rowidset IN OUT XROWIDSET, t IN CQ_NOTIFICATION$_ROW_ARRAY) IS
    rid VARCHAR2(18);
  BEGIN
    FOR i IN 1..t.LAST LOOP
      rid := t(i).row_id;
      rowidset(rid) := rid;
    END LOOP;
  END APPEND;
  
  PROCEDURE APPEND(rowidset IN OUT XROWIDSET, t IN XROWIDS) IS
    rid VARCHAR2(18);
  BEGIN
    FOR i IN 1..t.LAST LOOP
      rid := t(i);
      rowidset(rid) := rid;
    END LOOP;
  END APPEND;
  

--
  -- *******************************************************
  --    Handles and delegates any CQ notifications
  -- *******************************************************

  PROCEDURE HANDLE_CHANGE(n IN OUT CQ_NOTIFICATION$_DESCRIPTOR) AS
    --TYPE CHANGE_TABLE_ARR IS TABLE OF CQ_NOTIFICATION$_TABLE INDEX BY PLS_INTEGER;
    
    rowids ROWID_ARR := NEW ROWID_ARR();
    rids XROWIDS;
    overflow XROWIDS := NULL;
    opKeys VARCHAR2_ARR;
    opKeyTab CQ_NOTIFICATION$_TABLE;
    idx PLS_INTEGER;
    opType BINARY_INTEGER;
    
    hasAllRowsInserts BOOLEAN := FALSE;
    hasAllRowsUpdates BOOLEAN := FALSE;
    hasAllRowsDeletes BOOLEAN := FALSE;
    
    insertRowSet XROWIDSET;
    updateRowSet XROWIDSET;
    deleteRowSet XROWIDSET;
    
    tableArrays             CHANGE_TABLE_ARR;
    nonAllRowsTableArrays   CHANGE_TABLE_ARR;
    allRowsTableArrays      CHANGE_TABLE_ARR;
  
    idx     PLS_INTEGER := 0;
    aIdx    PLS_INTEGER := 0;
    nIdx    PLS_INTEGER := 0;
    
  BEGIN
    LOGEVENT(CQN_HELPER.PRINT(n));
    IF n IS NULL THEN RETURN; END IF;
    -- Loop through all table arrays 
    -- For each table array, map the ROWIDs into all applicable
    -- t(INSERT|UPDATE|DELETE) XROWIDS 
    
    IF n.event_type = CQN_HELPER.EVENT_OBJCHANGE THEN
      FOR x IN 1..n.table_desc_array.COUNT LOOP
        idx := idx + 1;
        tableArrays(idx) := n.table_desc_array(x);
      END LOOP;
      n.table_desc_array := null;
    ELSIF n.event_type = CQN_HELPER.EVENT_QUERYCHANGE THEN
      FOR i IN 1..n.query_desc_array.COUNT LOOP
        FOR x IN 1..n.query_desc_array(i).table_desc_array.COUNT LOOP
          idx := idx + 1;
          tableArrays(idx) := n.query_desc_array(i).table_desc_array(x);        
        END LOOP;
      END LOOP;
      n.query_desc_array := null;
    END IF;
    
    -- Now all table-changes are in tableArrays
    
    
    
    FOR i IN 1..tableArrays.LAST LOOP
      opType := tableArrays(i).opflags;
      IF CQN_HELPER.ISALLROWS(opType) THEN
        IF( overflow IS NULL ) THEN
          overflow := OVERFLOWTABLES(n.transaction_id);
          IF CQN_HELPER.ISUPDATE(opType) THEN 
            APPEND(updateRowSet, overflow);
            hasAllRowsUpdates := TRUE;
          END IF;
          IF CQN_HELPER.ISINSERT(opType) THEN 
            APPEND(insertRowSet, overflow);
            hasAllRowsInserts := TRUE;
          END IF;
          /*  No point doing this one
          IF CQN_HELPER.ISDELETE(opType) THEN 
            APPEND(deleteRowSet, overflow);
            hasAllRowsDeletes := TRUE;
          END IF;
          */
        END IF;          
      ELSE         
          IF tableArrays(i).row_desc_array IS NULL THEN 
            CONTINUE;
          END IF;
          IF CQN_HELPER.ISUPDATE(opType) THEN 
            APPEND(updateRowSet, tableArrays(i).row_desc_array);
          END IF;
          IF CQN_HELPER.ISINSERT(opType) THEN 
            APPEND(insertRowSet, tableArrays(i).row_desc_array);
          END IF;
          IF CQN_HELPER.ISDELETE(opType) THEN 
            APPEND(deleteRowSet, tableArrays(i).row_desc_array);
          END IF;
      END IF;
    END LOOP;
    n.event_type := CQN_HELPER.EVENT_OBJCHANGE;
    n.table_desc_array := tableArrays;
    --LOGEVENT('EVENT_OBJCHANGE: u:' || updateRowSet.COUNT || ', i:' || insertRowSet.COUNT || ', d:' || deleteRowSet.COUNT);
    LOGEVENT(CQN_HELPER.PRINT(n));
      
  END HANDLE_CHANGE;

  FUNCTION BVDECODE(code IN NUMBER) RETURN INT_ARR AS
  BEGIN
    -- TODO: Implementation required for FUNCTION TQV.BVDECODE
    RETURN NULL;
  END BVDECODE;
  
  
  -- NOTES
  /*
  
  NEED SUSPEND/RESUME for OLTP PURGE
  
  2015-04-23 11:24:21 CQ NOTIF ||:regid:140, XID:0A001E00E6D20800, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:77, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:UPDATEOP, table:TQREACTOR.TQUEUE, rows: 99

2015-04-23 11:23:59 CQ NOTIF ||:regid:140, XID:0A000300ADD20800, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:77, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:DELETEOP, table:TQREACTOR.TQUEUE, rows: 99

2015-04-23 11:19:15 CQ NOTIF ||:regid:139, XID:0200190038AE0100, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:76, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:UPDATEOP, table:TQREACTOR.TQUEUE, rows: 99

2015-04-23 11:18:20 CQ NOTIF ||:regid:139, XID:09002000DCB80200, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:76, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:ALL_ROWS, INSERTOP, table:TQREACTOR.TQUEUE, rows: 3220 (ALL)

2015-04-23 11:17:45 CQ NOTIF ||:regid:139, XID:01001F0005B40100, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:76, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:INSERTOP, table:TQREACTOR.TQUEUE, rows: 100

2015-04-23 11:17:23 CQ NOTIF ||:regid:139, XID:0A001E00E5D20800, dbname:ORCL, event:EVENT_QUERYCHANGE, qid:76, 
    qop:ALL_ROWS, INSERTOP, UPDATEOP, tops:ALL_ROWS, INSERTOP, table:TQREACTOR.TQUEUE, rows: 2120 (ALL)
    
TYPE CQ_NOTIFICATION$_DESCRIPTOR IS OBJECT(
   registration_id    NUMBER,
   transaction_id     RAW(8),
   dbname             VARCHAR2(30),
   event_type         NUMBER,
   numtables          NUMBER,
   table_desc_array   CQ_NOTIFICATION$_TABLE_ARRAY,
   query_desc_array   CQ_NOTIFICATION$_QUERY_ARRAY);
   
TYPE CQ_NOTIFICATION$_QUERY IS OBJECT (
  queryid            NUMBER,
  queryop            NUMBER,  -- Operation describing change to the query
  table_desc_array   CQ_NOTIFICATION$_TABLE_ARRAY);
  
TYPE CQ_NOTIFICATION$_TABLE  IS OBJECT (
  opflags            NUMBER,  -- It can be an OR of the following bit fields - INSERTOP, UPDATEOP, DELETEOP, DROPOP, ALTEROP, ALL_ROWS
  table_name         VARCHAR2(2*M_IDEN+1),
  numrows            NUMBER,  -- NULL if ALL_ROWS
  row_desc_array     CQ_NOTIFICATION$_ROW_ARRAY)  
  
TYPE CQ_NOTIFICATION$_ROW IS OBJECT (
  opflags            NUMBER,  -- could be INSERTOP, UPDATEOP or DELETEOP
  row_id             VARCAHR2 (2000));  
  
  
   
   
  */


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





END TQV;
/
