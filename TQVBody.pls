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
  TYPE SEC_DECODE_CACHE IS TABLE OF SEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;


  TYPE XIDCUR IS REF CURSOR RETURN QROWID;



  -- =====================================================================
  -- ==== done ====
  -- =====================================================================

  FUNCTION CS(arr IN TQSTUB_ARR) RETURN INT IS
  BEGIN
    IF arr IS NOT NULL THEN
      RETURN arr.COUNT;
    ELSE
      RETURN 0;
    END IF;
  END CS;
  
  FUNCTION BATCHTXIDS(tqbatch IN TQBATCH) RETURN XROWIDS IS
    rids XROWIDS := new XROWIDS();
  BEGIN
    rids.EXTEND(tqbatch.STUBS.COUNT);
    FOR i in 1..tqbatch.STUBS.COUNT LOOP
      rids(i) := tqbatch.STUBS(i).TQROWID;
    END LOOP;
    RETURN rids;
  END BATCHTXIDS;
--
  FUNCTION BATCHXIDS(tqbatch IN TQBATCH) RETURN XROWIDS IS
    rids XROWIDS := new XROWIDS();
  BEGIN
    IF tqbatch.ROWIDS IS NULL THEN
      rids := new XROWIDS();
      rids.extend(tqbatch.STUBS.COUNT);
      FOR i in 1..tqbatch.STUBS.COUNT LOOP
            rids(i) := tqbatch.STUBS(i).XROWID;
      END LOOP;
      RETURN rids;
    ELSE
      return tqbatch.ROWIDS;
    END IF;
  END BATCHXIDS;
  


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
  PROCEDURE SORTTRADEARR(tqb IN OUT TQBATCH, tqStubs IN TQSTUB_ARR) IS
    fTx INT := 0;
    lTx INT := 0;
    sortedStubs TQSTUB_ARR;
    rowids XROWIDS;
  CURSOR tQByID IS
    SELECT VALUE(T), T.XROWID
      FROM TABLE(tqStubs) T ORDER BY T.TQUEUE_ID;

   BEGIN
      IF (tqStubs.COUNT = 0) THEN
      tqb.FIRST_T := -1;
      tqb.LAST_T := -1;
      tqb.STUBS := tqStubs;
    ELSE
      OPEN tQByID;
        FETCH tQByID BULK COLLECT INTO sortedStubs, rowids;
      CLOSE tQByID;
      tqb.FIRST_T := sortedStubs(1).TQUEUE_ID;
      tqb.LAST_T := sortedStubs(tqStubs.COUNT).TQUEUE_ID;
      tqb.STUBS:= sortedStubs;
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
      IF (T.ACCOUNT_ID != currentPosAcctId OR tcount = MAX_BATCH_SIZE OR T.SECURITY_TYPE='X') THEN
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
          PIPE ROW (new TQBATCH(ACCOUNT => currentPosAcctId, TCOUNT => 1, FIRST_T => T.TQUEUE_ID, LAST_T => T.TQUEUE_ID, BATCH_ID => NEXTBATCHID, ROWIDS => new XROWIDS(T.XROWID), STUBS => new TQSTUB_ARR(T)));
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
  -- **************************************************************
  --    Waits on a CQN activity complete event
  -- **************************************************************
  FUNCTION WAITONSIGNAL(WAIT_TIME IN INT) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    message VARCHAR2(2000);
    status INTEGER;
    events INTEGER;
  BEGIN
    DBMS_ALERT.REGISTER('TQSTUB.ALERT.EVENT');
    DBMS_ALERT.WAITONE('TQSTUB.ALERT.EVENT', message, status, WAIT_TIME);
    IF status = 1 THEN
      events := 0;
    ELSIF status = 0 THEN
      events := TO_NUMBER(RTRIM(LTRIM(message)));
    END IF;
    DBMS_ALERT.REMOVE('TQSTUB.ALERT.EVENT');
    return events;
    EXCEPTION WHEN OTHERS THEN
      BEGIN
        DBMS_ALERT.REMOVE('TQSTUB.ALERT.EVENT');
        RAISE;
      END;
  END WAITONSIGNAL;
--
  -- *******************************************************
  --    Main query point to get new batches
  --    To keep and process the batches,
  --    call LOCKBATCH(batch) or LOCKBATCHES(batch_arr)
  -- *******************************************************

  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10, WAIT_TIME IN INT DEFAULT 0) RETURN TQBATCH_ARR PIPELINED IS
      batchy TQBATCH;
      latency NUMBER  := 0;
      pipedRows PLS_INTEGER := 0;
      waitCount PLS_INTEGER := 0;
      events NUMBER := 0;
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
      WHILE(1 = 1) LOOP
        open qx;
          LOOP
            fetch qx into batchy;
            EXIT WHEN qx%NOTFOUND;
            pipe row(batchy);
            pipedRows := pipedRows + 1;
          END LOOP;
        close qx;
        IF pipedRows > 0 OR waitCount = 1 OR WAIT_TIME = 0 THEN
          RETURN;
        END IF;
        waitCount := waitCount + 1;
        events := WAITONSIGNAL(WAIT_TIME);
        IF events = 0 THEN
          IF waitCount = 1 THEN
            CONTINUE;
          END IF;
          PIPE ROW (new TQBATCH(-1, 0, -1, -1, -1, NULL, NULL));
          RETURN;
        END IF;
      END LOOP;
    RETURN;

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
/*
  PROCEDURE LOGEVENT(msg VARCHAR2, errcode NUMBER default 0) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO EVENT(EVENT_ID, ERRC, TS, EVENT) VALUES (SEQ_EVENT_ID.NEXTVAL, ABS(errcode), SYSDATE, msg);
    COMMIT;
  END LOGEVENT;
*/
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
  
  PROCEDURE UPDATE_STUBS(lockedStubs IN TQSTUB_ARR, tqbatch IN OUT TQBATCH) IS  -- , droppedStubs IN TQSTUB_ARR
    rids XROWIDS := new XROWIDS();
  BEGIN
    --SELF.DSTUBS := droppedStubs;
    IF lockedStubs IS NULL OR lockedStubs.COUNT = 0 THEN
      tqbatch.STUBS := new TQSTUB_ARR();
      tqbatch.ROWIDS := new XROWIDS();
      tqbatch.TCOUNT := 0;
      tqbatch.FIRST_T := -1;
      tqbatch.LAST_T := -1;
    ELSE
      tqbatch.STUBS := lockedStubs;
      rids.extend(tqbatch.STUBS.COUNT);
      FOR i in 1..tqbatch.STUBS.COUNT LOOP
        rids(i) := tqbatch.STUBS(i).XROWID;
      END LOOP;
      tqbatch.ROWIDS := rids;
      tqbatch.TCOUNT := CS(tqbatch.STUBS);
      tqbatch.FIRST_T := tqbatch.STUBS(1).TQUEUE_ID;
      tqbatch.LAST_T := tqbatch.STUBS(tqbatch.TCOUNT).TQUEUE_ID;
    END IF;
  END UPDATE_STUBS;
--
  -- *******************************************************
  --    Lock all rows in a batch
  -- *******************************************************

  PROCEDURE LOCKBATCH(batch IN OUT TQBATCH, commitTX IN INT) IS
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

    IF commitTX != 0 THEN
      COMMIT;
    END IF;
    UPDATE_STUBS(lockedStubs, batch);
  END LOCKBATCH;

  PROCEDURE LOCKBATCH(batch IN OUT TQBATCH) IS
  BEGIN
    LOCKBATCH(batch, 1);
  END LOCKBATCH;
  
    --======================================================================================================
    --======================================================================================================
    
  FUNCTION LOCKBATCHREF(batch IN OUT TQBATCH, accountId OUT INT, tcount OUT INT) RETURN VARCHAR2 IS
    srowid VARCHAR2(200);
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

    
    UPDATE_STUBS(lockedStubs, batch);
  
      INSERT INTO TQBATCHES VALUES(batch) RETURNING ROWIDTOCHAR(ROWID) INTO srowid;
      COMMIT;
      accountId := batch.ACCOUNT;
      tcount := batch.STUBS.COUNT;
      RETURN srowid;
  END LOCKBATCHREF;

  --======================================================================================================
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
    FORALL i in 1..lockedStubs.COUNT
        UPDATE TQSTUBS SET BATCH_ID = batch.BATCH_ID, BATCH_TS = now
        WHERE ROWID = CHARTOROWID(lockedStubs(i).XROWID);

    UPDATE_STUBS(lockedStubs, batch);
  END RELOCKBATCH;

  -- *******************************************************
  --    Locks, selects and returns all the trades for a batch
  -- *******************************************************

  FUNCTION STARTBATCH(tqbatch IN OUT TQBATCH) RETURN TQTRADE_ARR AS
    trades TQTRADE_ARR;
    lockedTrades TQTRADE_ARR;
    droppedTrades TQTRADE_ARR;
    tradeRowIds XROWIDS := BATCHTXIDS(tqbatch);
    stubRowIds XROWIDS := BATCHXIDS(tqbatch);
    lockedRids XROWIDS;
    locked int := 0;
    dropped int := 0;
    BATCH_HAS_LOCKED_ROWS EXCEPTION;
    PRAGMA EXCEPTION_INIT(BATCH_HAS_LOCKED_ROWS, -54);

    stubRowids XROWIDS;
    updatedStubs TQSTUB_ARR;
    droppedStubs TQSTUB_ARR;

    TRADE_STUB_MISMATCH EXCEPTION;
    PRAGMA EXCEPTION_INIT( TRADE_STUB_MISMATCH, -20001 );

  BEGIN
    -- First populate the trade ref fields with no locking
    SELECT TQTRADE(ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, T.XID, T.STATUS_CODE, T.SECURITY_DISPLAY_NAME, T.ACCOUNT_DISPLAY_NAME,
      S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID,
      tqbatch.BATCH_ID, T.CREATE_TS, T.UPDATE_TS, T.ERROR_MESSAGE)
    BULK COLLECT INTO trades
    FROM TQUEUE T, ACCOUNT A, SECURITY S
    WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
    AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
    AND EXISTS (
      SELECT RID FROM (
        SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(tradeRowIds) X
      ) WHERE RID = T.ROWID
    );
    LOGEVENT('BATCH TRADES ACQUIRED: [' || trades.COUNT || '] Trades');
    -- Now try to lock all of them
    SELECT ROWIDTOCHAR(ROWID)
      BULK COLLECT INTO lockedRids
      FROM TQUEUE T
      WHERE EXISTS (
        SELECT RID FROM (
          SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(tradeRowIds) X
        ) WHERE RID = T.ROWID
      ) FOR UPDATE NOWAIT;
      LOGEVENT('BATCH LOCKED [' || lockedRids.COUNT || '] TQUEUE TRADES');
    -- If we get here, we're good.
    --tqbatch.UPDATE_TRADES(trades, droppedTrades);
    RETURN trades;
      -- otherwise, we got a lock failure.
      EXCEPTION WHEN BATCH_HAS_LOCKED_ROWS THEN
        BEGIN
          LOGEVENT('BATCH LOCK FAILED');
          -- Rebuild batch out of lockable trades only
          SELECT ROWIDTOCHAR(ROWID)
            BULK COLLECT INTO lockedRids
            FROM TQUEUE T
            WHERE EXISTS (
              SELECT RID FROM (
                SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(tradeRowIds) X
              ) WHERE RID = T.ROWID
            ) FOR UPDATE SKIP LOCKED;
          LOGEVENT('SINGLE LOCKED [' || lockedRids.COUNT || '] TQUEUE TRADES');
          -- Remove any trade in *trades* where the XROWID is not in *lockedRids*
          --batch->TQSTUB->TQROWID
          SELECT VALUE(T) BULK COLLECT INTO lockedTrades FROM TABLE(CAST(trades as TQTRADE_ARR)) T
          WHERE XROWID IN (
              SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(lockedRids)
          );
          SELECT VALUE(T) BULK COLLECT INTO droppedTrades FROM TABLE(CAST(trades as TQTRADE_ARR)) T
          WHERE XROWID NOT IN (
              SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(lockedRids)
          );

          SELECT VALUE(T) BULK COLLECT INTO updatedStubs FROM TABLE(CAST(tqbatch.STUBS as TQSTUB_ARR)) T
          WHERE T.TQROWID IN (
            SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(lockedRids)
          );
          SELECT VALUE(T) BULK COLLECT INTO droppedStubs FROM TABLE(CAST(tqbatch.STUBS as TQSTUB_ARR)) T
          WHERE T.TQROWID NOT IN (
            SELECT CHARTOROWID(COLUMN_VALUE) AS RID FROM TABLE(lockedRids)
          );
          UPDATE_STUBS(updatedStubs, tqbatch);
          locked := tqbatch.ROWIDS.COUNT;
          dropped := CS(droppedStubs);

          LOGEVENT('SINGLE LOCK RESULTS:  locked:[' || locked || '], dropped:[' || dropped || ']');


          IF  (tqbatch.ROWIDS.COUNT != lockedTrades.COUNT) OR (tqbatch.STUBS.COUNT != lockedTrades.COUNT)   THEN
            raise_application_error( -20001, 'Single Row Lock Mismatch. Locked Trades: [' || lockedTrades.COUNT ||'], Locked Stubs: [' || tqbatch.STUBS.COUNT || '], Locked ROWIDS: [' || tqbatch.ROWIDS.COUNT || ']');
          END IF;

          IF CS(droppedStubs) > 0 THEN
            FORALL i in 1..droppedStubs.COUNT
              UPDATE TQSTUBS SET BATCH_ID = -1, BATCH_TS = NULL
                WHERE ROWID = CHARTOROWID(droppedStubs(i).XROWID);
          END IF;


          --tqbatch.UPDATE_TRADES(lockedTrades, droppedTrades);
          RETURN lockedTrades;
        END;
      WHEN OTHERS THEN
        DECLARE
          errm VARCHAR2(2000) := SQLERRM;
          errc NUMBER := SQLCODE;
        BEGIN
          LOGEVENT('STARTBATCH ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
          RAISE;
        END;

    --FOR UPDATE SKIP LOCKED;
    --tqbatch-->TRADES --> TQUEUE_ID
    --TRADES.TQSTUB.TQUEUE_ID


  END STARTBATCH;
--
  -- *******************************************************
  --    Updates all rows in TQUEUE from the passed trade array
  -- *******************************************************

  PROCEDURE SAVETRADES(trades IN TQTRADE_ARR, batchId IN INT) AS
    tr TQTRADE_ARR := trades;
  BEGIN
    LOGEVENT('UPDATING :[' || trades.COUNT || '] TRADES.....');
    FORALL i IN 1..tr.COUNT
      UPDATE TQUEUE SET
        BATCH_ID = tr(i).BATCH_ID,
        ACCOUNT_ID = tr(i).ACCOUNT_ID,
        SECURITY_ID = tr(i).SECURITY_ID,
        SECURITY_TYPE = tr(i).SECURITY_TYPE,
        STATUS_CODE = tr(i).STATUS_CODE,
        UPDATE_TS = tr(i).UPDATE_TS,
        ERROR_MESSAGE = tr(i).ERROR_MESSAGE
      WHERE ROWID = CHARTOROWID(tr(i).XROWID);
      LOGEVENT('SAVETRADES: sub:[' || trades.COUNT || '], upd:[' || SQL%ROWCOUNT || ']');
  END SAVETRADES;

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

  /*
  PROCEDURE RUNBATCH(batchId IN INT, lockName IN VARCHAR2) IS
    tqb TQBATCH := NULL;
    trades TQTRADE_ARR := NULL;
    now DATE := NULL;
  BEGIN
    SELECT VALUE(T) INTO tqb FROM READYTQBATCH T WHERE BATCH_ID = batchId;
    RELOCKBATCH(tqb);
    DBMS_OUTPUT.put_line('RELOCKED BATCH#' || batchId);
    trades := STARTBATCH(tqb);
    now := SYSDATE;
    FOR x in 1..trades.COUNT LOOP
      trades(x).STATUS_CODE := 'CLEARED';
      trades(x).UPDATE_TS :=  now;
    END LOOP;
    SAVETRADES(trades, tqb.BATCH_ID);
    FINISHBATCH(tqb.ROWIDS);
  END RUNBATCH;
  */

--
  -- *******************************************************
  --    Creates a pipeline of all row ROWIDs in TQUEUE
  --    for the given transaction id
  -- *******************************************************
  -- TYPE XIDCUR IS REF CURSOR RETURN VARCHAR2;
  FUNCTION ROWSFORXID(p IN XIDCUR) RETURN QROWID_ARR PIPELINED PARALLEL_ENABLE IS   -- ( PARTITION p BY RANGE(XROWID))
    xrid QROWID;
  BEGIN
    LOOP
      FETCH p INTO xrid;
      EXIT WHEN p%NOTFOUND;
      PIPE ROW(xrid);
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN
        BEGIN LOGEVENT('ROWSFORXID >>> CLEAN UP'); END;
        RETURN;
  END ROWSFORXID;
    /*
  TYPE QROWID IS RECORD  (
      XROWID VARCHAR2(18),
      TQUEUE_ID INT,
      SECURITY_ID INT,
      SECURITY_TYPE CHAR(1),
      ACCOUNT_ID INT
  );
  TYPE QROWID_ARR IS TABLE OF QROWID;
  */
--
  -- *******************************************************
  --    Handle INSERT ALL_ROWS  events
  -- *******************************************************

  FUNCTION HANDLE_INSERT(txid IN RAW) RETURN NUMBER IS
  BEGIN
    INSERT INTO TQSTUBS (TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID, BATCH_ID)
      SELECT ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, txid, S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID, -1
      FROM TQUEUE T, ACCOUNT A, SECURITY S
      WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
      AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
      AND XID = txid
      AND STATUS_CODE IN ('PENDING', 'RETRY', 'ENRICH')
        AND NOT EXISTS (
          SELECT * FROM TQSTUBS X WHERE X.TQROWID = T.ROWID
        );
    RETURN SQL%ROWCOUNT;
  END HANDLE_INSERT;

  FUNCTION HANDLE_INSERT(txid IN RAW, rowids IN CQ_NOTIFICATION$_TABLE) RETURN NUMBER IS
  BEGIN
    FORALL i in 1..rowids.row_desc_array.COUNT
      INSERT INTO TQSTUBS (TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID, BATCH_ID)
        SELECT ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, txid, S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID, -1
        FROM TQUEUE T, ACCOUNT A, SECURITY S
        WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
        AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
        AND T.ROWID = rowids.row_desc_array(i).row_id
        AND XID = txid
        AND STATUS_CODE IN ('PENDING', 'RETRY', 'ENRICH');
    RETURN SQL%ROWCOUNT;
  END HANDLE_INSERT;


  --CQ_NOTIFICATION$_TABLE   CQ_NOTIFICATION$_TABLE.row_desc_array(x).row_id

  FUNCTION HANDLE_UPDATE(txid IN RAW, rowids IN CQ_NOTIFICATION$_TABLE, batchId IN NUMBER) RETURN NUMBER IS
  BEGIN
    FORALL i in 1..rowids.row_desc_array.COUNT
      INSERT INTO TQSTUBS (TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID, BATCH_ID)
        SELECT ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, txid, S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID, batchId
        FROM TQUEUE T, ACCOUNT A, SECURITY S
        WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
        AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
        AND T.ROWID = rowids.row_desc_array(i).row_id
        AND XID = txid
        AND STATUS_CODE IN ('PENDING', 'RETRY', 'ENRICH')
        AND NOT EXISTS (
          SELECT * FROM TQSTUBS X WHERE X.TQROWID = T.ROWID
        );
    RETURN SQL%ROWCOUNT;
  END HANDLE_UPDATE;

  PROCEDURE HANDLE_DELETE(rowids IN CQ_NOTIFICATION$_TABLE, batchId IN NUMBER) IS
  BEGIN
    FORALL i in 1..rowids.row_desc_array.COUNT
      DELETE FROM TQSTUBS WHERE TQROWID = rowids.row_desc_array(i).row_id;
  END HANDLE_DELETE;



--
  -- *******************************************************
  --    Handle UPDATE ALL_ROWS  events
  -- *******************************************************

  FUNCTION HANDLE_UPDATE(txid IN RAW, batchId IN NUMBER) RETURN NUMBER IS
  BEGIN
    INSERT INTO TQSTUBS (TQROWID,TQUEUE_ID,XID,SECURITY_ID,SECURITY_TYPE,ACCOUNT_ID, BATCH_ID)
      SELECT ROWIDTOCHAR(T.ROWID), T.TQUEUE_ID, txid, S.SECURITY_ID, S.SECURITY_TYPE, A.ACCOUNT_ID, batchId
      FROM TQUEUE T, ACCOUNT A, SECURITY S
      WHERE T.ACCOUNT_DISPLAY_NAME = A.ACCOUNT_DISPLAY_NAME
      AND T.SECURITY_DISPLAY_NAME = S.SECURITY_DISPLAY_NAME
      AND XID = txid
      AND STATUS_CODE IN ('PENDING', 'RETRY', 'ENRICH')
      AND NOT EXISTS (
        SELECT * FROM TQSTUBS X WHERE X.TQROWID = T.ROWID
      );
    RETURN SQL%ROWCOUNT;
  END HANDLE_UPDATE;


--
  -- *******************************************************
  --    Handles and delegates any CQ notifications
  -- *******************************************************

  FUNCTION HANDLE_CHANGE(n IN OUT CQ_NOTIFICATION$_DESCRIPTOR) RETURN NUMBER AS
    --TYPE CHANGE_TABLE_ARR IS TABLE OF CQ_NOTIFICATION$_TABLE INDEX BY PLS_INTEGER;

    rowids ROWID_ARR := NEW ROWID_ARR();
    rids XROWIDS;
    overflow XROWIDS := NULL;
    opKeys VARCHAR2_ARR;
    opKeyTab CQ_NOTIFICATION$_TABLE;
    opType BINARY_INTEGER;


    currentTChange    CQ_NOTIFICATION$_TABLE := NULL;

    hasAllRows        BOOLEAN := FALSE;
    hasAllRowsInserts BOOLEAN := FALSE;
    hasAllRowsUpdates BOOLEAN := FALSE;
    hasAllRowsDeletes BOOLEAN := FALSE;
    recordedCurrent   BOOLEAN := FALSE;


    tableArrays             CHANGE_TABLE_ARR;
    allRowsTableArrays      CHANGE_TABLE_ARR;

    idx           PLS_INTEGER := 0;
    aIdx          PLS_INTEGER := 0;

    batchId       NUMBER := NULL;

    totalChanges NUMBER := 0;

  BEGIN
    LOGEVENT(CQN_HELPER.PRINT(n));
    IF n IS NULL THEN RETURN 0; END IF;
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
    LOGEVENT('tableArrays.COUNT:' || tableArrays.COUNT);
    FOR i in 1..tableArrays.COUNT LOOP
      currentTChange := tableArrays(i);
      recordedCurrent := FALSE;
      IF CQN_HELPER.ISALLROWS(currentTChange.opflags) THEN
        LOGEVENT('tableArrays(' || i || ')---> [' || currentTChange.opflags || '] IS ALLROWS');
        -- ***********************************************************
        --    Events with NO ROWIDS (ALL_ROWS)
        -- ***********************************************************
        IF CQN_HELPER.ISUPDATE(currentTChange.opflags) THEN
          hasAllRowsUpdates := TRUE;
          hasAllRows := TRUE;
          aIdx := aIdx + 1;
          allRowsTableArrays(aIdx) := currentTChange;
          recordedCurrent := TRUE;
        END IF;

        IF CQN_HELPER.ISINSERT(currentTChange.opflags) THEN
          hasAllRowsInserts := TRUE;
          hasAllRows := TRUE;
          IF recordedCurrent = FALSE THEN
            aIdx := aIdx + 1;
            allRowsTableArrays(aIdx) := currentTChange;
          END IF;

        END IF;

        IF CQN_HELPER.ISDELETE(currentTChange.opflags) THEN
          hasAllRowsDeletes := TRUE;
        END IF;

      ELSE
        -- ***********************************************************
        --    Events with specified ROWIDS
        -- ***********************************************************
        IF CQN_HELPER.ISUPDATE(currentTChange.opflags) THEN
          IF batchId IS NULL THEN SELECT SEQ_BATCH_ID.NEXTVAL INTO batchId FROM DUAL; END IF;
          totalChanges := totalChanges + HANDLE_UPDATE(n.transaction_id, currentTChange, batchId);
        END IF;

        IF CQN_HELPER.ISINSERT(currentTChange.opflags) THEN
          IF batchId IS NULL THEN SELECT SEQ_BATCH_ID.NEXTVAL INTO batchId FROM DUAL; END IF;
          totalChanges := totalChanges + HANDLE_INSERT(n.transaction_id, currentTChange);
        END IF;

        IF CQN_HELPER.ISDELETE(currentTChange.opflags) THEN
          IF batchId IS NULL THEN SELECT SEQ_BATCH_ID.NEXTVAL INTO batchId FROM DUAL; END IF;
          HANDLE_DELETE(currentTChange, batchId);
        END IF;

      END IF;
      tableArrays(i) := NULL;
    END LOOP;
    batchId := -1;
    IF hasAllRows THEN
      IF hasAllRowsInserts THEN
        IF batchId IS NULL THEN SELECT SEQ_BATCH_ID.NEXTVAL INTO batchId FROM DUAL; END IF;
        totalChanges := totalChanges + HANDLE_INSERT(n.transaction_id);
      END IF;
      IF hasAllRowsUpdates THEN
        IF batchId IS NULL THEN SELECT SEQ_BATCH_ID.NEXTVAL INTO batchId FROM DUAL; END IF;
        totalChanges := totalChanges + HANDLE_UPDATE(n.transaction_id, batchId);
      END IF;

    END IF;
    RETURN totalChanges;
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
