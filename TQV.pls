create or replace PACKAGE TQV AS

  TYPE TQTRADEV IS RECORD  (
      TQUEUE_ID             TQUEUEO.TQUEUE_ID%TYPE,
      XID                   TQUEUEO.XID%TYPE,
      STATUS_CODE           TQUEUEO.STATUS_CODE%TYPE,
      SECURITY_DISPLAY_NAME TQUEUEO.SECURITY_DISPLAY_NAME%TYPE,
      ACCOUNT_DISPLAY_NAME  TQUEUEO.ACCOUNT_DISPLAY_NAME%TYPE,
      SECURITY_ID           TQUEUEO.SECURITY_ID%TYPE,
      SECURITY_TYPE         TQUEUEO.SECURITY_TYPE%TYPE,
      ACCOUNT_ID            TQUEUEO.ACCOUNT_ID%TYPE,
      BATCH_ID              TQUEUEO.BATCH_ID%TYPE,
      CREATE_TS             TQUEUEO.CREATE_TS%TYPE,
      UPDATE_TS             TQUEUEO.UPDATE_TS%TYPE,
      ERROR_MESSAGE         TQUEUEO.ERROR_MESSAGE%TYPE
  );

  TYPE TQSTUBV IS RECORD  (
      XROWID          TQSTUBOV.XROWID%TYPE,
      TQROWID         TQSTUBOV.TQROWID%TYPE,
      TQUEUE_ID       TQSTUBOV.TQUEUE_ID%TYPE,
      XID             TQSTUBOV.XID%TYPE,
      SECURITY_ID     TQSTUBOV.SECURITY_ID%TYPE,
      SECURITY_TYPE   TQSTUBOV.SECURITY_TYPE%TYPE,
      ACCOUNT_ID      TQSTUBOV.ACCOUNT_ID%TYPE,
      BATCH_ID        TQSTUBOV.BATCH_ID%TYPE,
      BATCH_TS        TQSTUBOV.BATCH_TS%TYPE
  );


  TYPE SPEC_DECODE IS RECORD (
    SECURITY_DISPLAY_NAME   SECURITY.SECURITY_DISPLAY_NAME%TYPE,
    SECURITY_TYPE           SECURITY.SECURITY_TYPE%TYPE,
    SECURITY_ID             SECURITY.SECURITY_ID%TYPE
  );


  TYPE QROWIDS IS TABLE OF VARCHAR2(18);

  TYPE TQSTUBVO IS RECORD  (
    TRADE           TQSTUB
  );

  TYPE TQBATCH_REC IS RECORD  (
    TBATCH           TQBATCH
  );

  TYPE TQUEUE_ID_ARR IS TABLE OF NUMBER;

  TYPE EVENTM_ARR IS TABLE OF VARCHAR2(4000);

  TYPE TQSTUBVO_ARR IS TABLE OF TQSTUBVO;

  TYPE TQSTUBV_ARR IS TABLE OF TQSTUBV;

  TYPE TQSTUBCUR IS REF CURSOR RETURN TQSTUBV;

  TYPE TQSBATCHCUR IS REF CURSOR RETURN TQBATCH_REC;

  --TYPE INT_ARR IS TABLE OF INT;
  TYPE NUM_ARR IS TABLE OF NUMBER;
  TYPE CHAR_ARR IS TABLE OF CHAR;
  TYPE ROWID_ARR IS TABLE OF ROWID;
  TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;
  TYPE CQNDECODE IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;






  -- =============================================================================
  --    TQSTUB Operations
  -- =============================================================================

  -- Finds unprocessed stubs
  FUNCTION FINDSTUBS(p IN TQSTUBCUR, MAX_ROWS IN NUMBER DEFAULT 100) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID));
  -- Pipeline transform from a stub record (TQSTUBV) to a stub (TQSTUB)
  FUNCTION TOTQSTUB(p IN TQSTUBCUR) RETURN TQSTUB_ARR PIPELINED PARALLEL_ENABLE (PARTITION p BY RANGE(TQUEUE_ID));
  -- Tests a stub to see if it can be locked
  FUNCTION LOCKSTUB(rid in VARCHAR2) RETURN BOOLEAN;

  -- =============================================================================
  --    TQBATCH Operations
  -- =============================================================================

  -- Groups a pipelined stream of TQSTUBs into TQBATCHes
  FUNCTION TRADEBATCH(STUBS IN TQSTUB_ARR, MAX_BATCH_SIZE IN PLS_INTEGER DEFAULT 100) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;
  -- Starts a pipelined query to find TQSTUBs to process
  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCH_ARR PIPELINED;
  -- Pipelined Query for viewing existing TQBATCHes
  FUNCTION GETBATCHES RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;
  -- Locks the stubs in a batch and assigns a batch id and batch timestamp
  PROCEDURE LOCKBATCH(batch IN OUT TQBATCH);
  -- Relocks the stubs in a batch as part of the actual trade processing transaction
  PROCEDURE RELOCKBATCH(batch IN OUT TQBATCH);
  -- Locks the trades in an array of batches
  PROCEDURE LOCKBATCHES(batches IN TQBATCH_ARR);
  -- Locks, selects and returns all the trades for a batch
  FUNCTION STARTBATCH(tqbatch IN OUT TQBATCH) RETURN TQTRADE_ARR;
  -- Updates all rows in the passed trade array
  PROCEDURE SAVETRADES(trades IN TQTRADE_ARR);
  -- Deletes all the stubs for a batch by the passed rowids
  PROCEDURE FINISHBATCH(batchRowids IN XROWIDS);

  -- Updates the trades in a batch
  --PROCEDURE UPDATEBATCH(batch IN TQBATCH);
  -- Updates the trades in an array of batches
  --PROCEDURE UPDATEBATCHES(batches IN TQBATCH_ARR);
  -- The TQSTUB insert handler, fired when a new trade comes into scope in the TQUEUE table
  PROCEDURE HANDLE_INSERT(transaction_id IN RAW, ntfnds IN CQ_NOTIFICATION$_DESCRIPTOR);

  PROCEDURE HANDLE_CHANGE(n IN CQ_NOTIFICATION$_DESCRIPTOR);


  -- =============================================================================
  --    Misc and Utility Operations
  -- =============================================================================
  -- a toString for TQSTUBs in an array of TQSTUBs
  FUNCTION STUBTOSTR(STUBS IN TQSTUB_ARR) RETURN VARCHAR2;
  -- Autonomous TX Logger, super basic
  PROCEDURE LOGEVENT(msg VARCHAR2, errcode NUMBER default 0);
  -- Acquires the XID of the current transaction
  FUNCTION CURRENTXID RETURN RAW;

  FUNCTION BVDECODE(code IN NUMBER) RETURN INT_ARR;

  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================
  FUNCTION RANDOMACCT RETURN ACCT_DECODE;
  FUNCTION RANDOMSEC RETURN SEC_DECODE;
  PROCEDURE GENTRADES(tradeCount IN NUMBER DEFAULT 1000);
  FUNCTION PIPEACCTCACHE RETURN ACCT_DECODE_ARR PIPELINED;
  FUNCTION PIPESECCACHE RETURN SEC_DECODE_ARR PIPELINED;
  FUNCTION FORCELOADCACHE RETURN VARCHAR2;
  FUNCTION RANDOMSECTYPE RETURN CHAR;
  PROCEDURE GENACCTS(acctCount IN NUMBER DEFAULT 1000);
  PROCEDURE GENSECS(secCount IN NUMBER DEFAULT 10000);
  -- =====================================================================
  -- ==== done ====
  -- =====================================================================

END TQV;
/
