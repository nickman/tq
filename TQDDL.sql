/*
CREATE USER TQREACTOR IDENTIFIED BY tq;
GRANT DBA TO TQREACTOR;
GRANT EXECUTE ON DBMS_LOCK TO TQREACTOR;
GRANT EXECUTE ON DBMS_CQ_NOTIFICATION TO TQREACTOR;
GRANT CHANGE NOTIFICATION TO TQREACTOR;    
GRANT EXECUTE ON DBMS_CHANGE_NOTIFICATION TO TQREACTOR;
GRANT SELECT ON V_$TRANSACTION TO TQREACTOR;
*/

--------------------------------------------------------
--  DDL for Sequence SEQ_ACCOUNT_ID
--------------------------------------------------------

   CREATE SEQUENCE  SEQ_ACCOUNT_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;
--------------------------------------------------------
--  DDL for Sequence SEQ_SECURITY_ID
--------------------------------------------------------

   CREATE SEQUENCE  SEQ_SECURITY_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;
--------------------------------------------------------
--  DDL for Sequence SEQ_TQUEUE_ID
--------------------------------------------------------

   CREATE SEQUENCE  SEQ_TQUEUE_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;
--------------------------------------------------------
--  DDL for Sequence SEQ_TQUEUE_ID
--------------------------------------------------------
   
   CREATE SEQUENCE  SEQ_TQBATCH_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;



--------------------------------------------------------
--  DDL for Table ACCOUNT
--------------------------------------------------------

  CREATE TABLE ACCOUNT (
  ACCOUNT_ID INT, 
  ACCOUNT_DISPLAY_NAME VARCHAR2(36 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  DDL for Index ACCOUNT_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX ACCOUNT_PK ON ACCOUNT (ACCOUNT_ID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  DDL for Index ACCOUNT_AK
--------------------------------------------------------

  CREATE UNIQUE INDEX ACCOUNT_AK ON ACCOUNT (ACCOUNT_DISPLAY_NAME) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  Constraints for Table ACCOUNT
--------------------------------------------------------

  ALTER TABLE ACCOUNT ADD PRIMARY KEY (ACCOUNT_ID)
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS  ENABLE;
 
  ALTER TABLE ACCOUNT MODIFY (ACCOUNT_DISPLAY_NAME NOT NULL ENABLE);
 
  ALTER TABLE ACCOUNT MODIFY (ACCOUNT_ID NOT NULL ENABLE);


--------------------------------------------------------
--  DDL for Table SECURITY
--------------------------------------------------------


  CREATE TABLE SECURITY (
  SECURITY_ID INT, 
  SECURITY_DISPLAY_NAME VARCHAR2(64 BYTE), 
  SECURITY_TYPE CHAR(1 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  DDL for Index SECURITY_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX SECURITY_PK ON SECURITY (SECURITY_ID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  DDL for Index SECURITY_AK
--------------------------------------------------------

  CREATE UNIQUE INDEX SECURITY_AK ON SECURITY (SECURITY_DISPLAY_NAME) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  Constraints for Table SECURITY
--------------------------------------------------------

  ALTER TABLE SECURITY ADD PRIMARY KEY (SECURITY_ID)
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS  ENABLE;
 
  ALTER TABLE SECURITY MODIFY (SECURITY_TYPE NOT NULL ENABLE);
 
  ALTER TABLE SECURITY MODIFY (SECURITY_DISPLAY_NAME NOT NULL ENABLE);
 
  ALTER TABLE SECURITY MODIFY (SECURITY_ID NOT NULL ENABLE);

--------------------------------------------------------
--  DDL for Table TQUEUE
--------------------------------------------------------

  CREATE TABLE TQUEUE ( 
  TQUEUE_ID INT, 
  XID RAW(8) NOT NULL,
  STATUS_CODE VARCHAR2(15 BYTE), 
  SECURITY_DISPLAY_NAME VARCHAR2(64 BYTE), 
  ACCOUNT_DISPLAY_NAME VARCHAR2(36 BYTE), 
  SECURITY_ID INT, 
  SECURITY_TYPE CHAR(1),
  ACCOUNT_ID INT, 
  BATCH_ID INT,
  CREATE_TS DATE, 
  UPDATE_TS DATE, 
  ERROR_MESSAGE VARCHAR2(512 BYTE)  
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;
--------------------------------------------------------
--  DDL for Index TQUEUE_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX TQUEUE_PK ON TQUEUE (TQUEUE_ID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;

  CREATE INDEX TQUEUE_STATUS_IDX ON TQUEUE (STATUS_CODE) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;

  CREATE INDEX TQUEUE_XID_IDX ON TQUEUE (XID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;


--------------------------------------------------------
--  Constraints for Table TQUEUE
--------------------------------------------------------

  ALTER TABLE TQUEUE ADD PRIMARY KEY (TQUEUE_ID)
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 NOLOGGING COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS  ENABLE;
 
  ALTER TABLE TQUEUE MODIFY (CREATE_TS NOT NULL ENABLE);
 
  ALTER TABLE TQUEUE MODIFY (ACCOUNT_DISPLAY_NAME NOT NULL ENABLE);
 
  ALTER TABLE TQUEUE MODIFY (SECURITY_DISPLAY_NAME NOT NULL ENABLE);
 
  ALTER TABLE TQUEUE MODIFY (STATUS_CODE NOT NULL ENABLE);
 
  ALTER TABLE TQUEUE MODIFY (TQUEUE_ID NOT NULL ENABLE);

--------------------------------------------------------
--  DDL for EVENT table
--------------------------------------------------------

  CREATE TABLE EVENT (
    TS DATE, 
    EVENT VARCHAR2(4000)
  ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;


-- =====================================================================================================================
--   TQSTUBS
-- =====================================================================================================================


--------------------------------------------------------
--  DDL for Table TQSTUBS
--------------------------------------------------------

  CREATE TABLE TQSTUBS  (
    TQROWID          ROWID NOT NULL, 
    TXID             RAW(8) NOT NULL,
    SECURITY_ID      NUMBER(*,0) NOT NULL, 
    SECURITY_TYPE    CHAR(1 BYTE) NOT NULL, 
    ACCOUNT_ID       NUMBER(*,0) NOT NULL
  )
  SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;

--------------------------------------------------------
--  DDL for Index TQUEUESTUBS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX TQSTUBS_PK ON TQSTUBS (TQROWID) 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS NOLOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS ;

--------------------------------------------------------
--  Constraints for Table TQSTUBS
--------------------------------------------------------

  ALTER TABLE TQSTUBS ADD PRIMARY KEY (TQROWID)
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS NOLOGGING 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE USERS  ENABLE;



--------------------------------------------------------
--  DDL for View TQUEUEV
--------------------------------------------------------

CREATE OR REPLACE VIEW TQUEUEV AS SELECT ROWIDTOCHAR(ROWID) XROWID, TQUEUE_ID, XID, STATUS_CODE, 
  SECURITY_DISPLAY_NAME, ACCOUNT_DISPLAY_NAME, 
  SECURITY_ID, SECURITY_TYPE, 
  ACCOUNT_ID, BATCH_ID,
  CREATE_TS, UPDATE_TS, ERROR_MESSAGE FROM TQUEUE;


--------------------------------------------------------
--  DDL for Object Types
--------------------------------------------------------

  CREATE OR REPLACE TYPE TQTRADE FORCE AS OBJECT (
  XROWID                    VARCHAR2(18),
  TQUEUE_ID                 INT,
  XID                       RAW(8),
  STATUS_CODE               VARCHAR2(15),
  SECURITY_DISPLAY_NAME     VARCHAR2(64),
  ACCOUNT_DISPLAY_NAME      VARCHAR2(36),
  SECURITY_ID               INT,
  SECURITY_TYPE             CHAR(1),
  ACCOUNT_ID                INT,
  BATCH_ID                  INT,
  CREATE_TS                 DATE,
  UPDATE_TS                 DATE,
  ERROR_MESSAGE             VARCHAR2(512)
);
/



create or replace TYPE TQTRADE_ARR FORCE AS TABLE OF TQTRADE;
/

create or replace TYPE XROWIDS FORCE AS TABLE OF VARCHAR2(18);
/

create or replace TYPE TQBATCH FORCE AS OBJECT ( 
  ACCOUNT           INT,
  TCOUNT            INT,
  FIRST_T           INT,
  LAST_T            INT,
  BATCH_ID          INT,
  ROWIDS            XROWIDS,
  TRADES            TQTRADE_ARR,
  MEMBER PROCEDURE SETXIDS,
  MEMBER PROCEDURE SETXIDS(rowids IN XROWIDS),
  MEMBER FUNCTION XIDS RETURN XROWIDS
);
/

--------------------------------------------------------
--  DDL for View TQUEUEO
--------------------------------------------------------

  CREATE OR REPLACE VIEW TQUEUEO OF TQTRADE
  WITH OBJECT IDENTIFIER (TQUEUE_ID) AS 
  SELECT ROWIDTOCHAR(ROWID) XROWID, TQUEUE_ID, XID, STATUS_CODE, 
  SECURITY_DISPLAY_NAME, ACCOUNT_DISPLAY_NAME, 
  SECURITY_ID, SECURITY_TYPE, 
  ACCOUNT_ID, BATCH_ID,
  CREATE_TS, UPDATE_TS, ERROR_MESSAGE FROM TQUEUE;



--------------------------------------------------------
--  TQBatch Body
--------------------------------------------------------

create or replace type body tqbatch as 
  --
  MEMBER PROCEDURE SETXIDS IS
    rids XROWIDS;
  BEGIN
    IF SELF.ROWIDS IS NULL THEN
      rids := new XROWIDS();
      rids.extend(TRADES.COUNT);
      FOR i in 1..TRADES.COUNT LOOP
            rids(i) := TRADES(i).XROWID;
      END LOOP;
      SELF.ROWIDS := rowids;
    END IF;    
  END;
  --
  MEMBER PROCEDURE SETXIDS(rowids IN XROWIDS) IS
    BEGIN
    IF SELF.ROWIDS IS NULL THEN
      IF rowids IS NOT NULL THEN
        IF rowids.COUNT = SELF.TRADES.COUNT THEN
          SELF.ROWIDS := rowids;
        END IF;
      END IF;
    END IF;
  END;
  --
  MEMBER FUNCTION XIDS RETURN XROWIDS IS
    rids XROWIDS;
  BEGIN
    IF SELF.ROWIDS IS NULL THEN
      rids := new XROWIDS();
      rids.extend(TRADES.COUNT);
      FOR i in 1..TRADES.COUNT LOOP
            rids(i) := TRADES(i).XROWID;
      END LOOP;    
      RETURN rids;
    ELSE  
      return SELF.ROWIDS;
    END IF;    
  END;
END;
/

create or replace TYPE TQBATCH_ARR AS TABLE OF TQBATCH;
/  

CREATE OR REPLACE TYPE TQBATCHMLOAD AS OBJECT ( 
  TQBATCHES TQBATCH_ARR,
  FIRST_T   INT,
  LAST_T    INT,
  LATENCY   INT
); 
/

create or replace TYPE TQBATCHMLOAD_ARR AS TABLE OF TQBATCHMLOAD;
/

--------------------------------------------------------
--  TQSTUB type
--------------------------------------------------------


CREATE OR REPLACE TYPE TQSTUB FORCE AS OBJECT (
  XROWID                    VARCHAR2(18),       -- The TQSTUBS ROWID
  TQROWID                   VARCHAR2(18),       -- The TQUEUE ROWID
  TQUEUE_ID                 INT,                -- The TQUEUE PK
  XID                       RAW(8),             -- The XID of the transaction that INSERTed/UPDATEd TQUEUE
  SECURITY_ID               INT,                -- The ID of the security
  SECURITY_TYPE             CHAR(1),            -- The type of the security
  ACCOUNT_ID                INT                -- The ID of the account
);
/

--------------------------------------------------------
--  DDL for View TQUSTUBOV
--------------------------------------------------------

  CREATE OR REPLACE VIEW TQUSTUBOV OF TQTSTUB
  WITH OBJECT IDENTIFIER (TQROWID) AS SELECT
  ROWIDTOCHAR(ROWID) XROWID, 
  ROWIDTOCHAR(TQROWID) TQROWID, 
  TQUEUE_ID, 
  XID, 
  SECURITY_ID, 
  SECURITY_TYPE, 
  ACCOUNT_ID
  FROM TQSTUBS;



--------------------------------------------------------
--  TQV Package
--------------------------------------------------------

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
      XROWID          TQUSTUBOV.XROWID%TYPE,
      TQROWID         TQUSTUBOV.TQROWID%TYPE,
      TQUEUE_ID       TQUSTUBOV.TQUEUE_ID%TYPE,
      XID             TQUSTUBOV.XID%TYPE,
      SECURITY_ID     TQUSTUBOV.SECURITY_ID%TYPE,
      SECURITY_TYPE   TQUSTUBOV.SECURITY_TYPE%TYPE,
      ACCOUNT_ID      TQUSTUBOV.ACCOUNT_ID%TYPE
  )
  
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
  

  TYPE SPEC_DECODE IS RECORD (
    SECURITY_DISPLAY_NAME   SECURITY.SECURITY_DISPLAY_NAME%TYPE,
    SECURITY_TYPE           SECURITY.SECURITY_TYPE%TYPE,
    SECURITY_ID             SECURITY.SECURITY_ID%TYPE
  );
  
  
  TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;  
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;
  accountCache ACCT_DECODE_CACHE;
  securityCache SEC_DECODE_CACHE;
  
  FUNCTION FINDRAWTQS(p IN TQSTUBCUR, MAX_ROWS IN NUMBER DEFAULT 100) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID));
  
  FUNCTION ENRICHACCOUNT(p IN TQSTUBCUR) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID));
  
  FUNCTION ENRICHSECURITY(p IN TQSTUBCUR) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID));
  
  FUNCTION TOTQSTUB(p IN TQSTUBCUR) RETURN TQSTUB_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID));
  
  FUNCTION TRADEBATCH(STUBS IN TQSTUB_ARR, MAX_BATCH_SIZE IN PLS_INTEGER DEFAULT 100) RETURN TQBATCH_ARR PIPELINED PARALLEL_ENABLE;
  
  FUNCTION TRADESTOVARCHAR(STUBS IN TQSTUB_ARR) RETURN VARCHAR2;

  PROCEDURE DEBUGME(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10);
  
  FUNCTION LOADBATCHES(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCHMLOAD;
  
  FUNCTION QUERYBATCHES(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCHMLOAD_ARR PIPELINED;
  
  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCH_ARR PIPELINED;
  
  FUNCTION STREAMEVENTS(MAX_EVENTS IN INT DEFAULT 20) RETURN EVENTM_ARR PIPELINED;
  
  PROCEDURE LOCKBATCH(batch IN TQBATCH);
  
  PROCEDURE LOCKBATCHES(batches IN TQBATCH_ARR);
  
  PROCEDURE UPDATEBATCH(batch IN TQBATCH);
  
  PROCEDURE UPDATEBATCHES(batches IN TQBATCH_ARR);
  
  PROCEDURE HANDLE_INSERT(transaction_id RAW, ntfnds CQ_NOTIFICATION$_DESCRIPTOR);
  
  PROCEDURE TESTINSERT;
  
  PROCEDURE LOGEVENT(msg VARCHAR2, errc NUMBER default 0);
  
  FUNCTION CURRENTXID RETURN RAW;
  
  FUNCTION RANDACCT RETURN VARCHAR2;

END TQV;
/


create or replace PACKAGE BODY TQV AS
  -- *******************************************************
  --    Private global variables
  -- *******************************************************  

  batchSeq PLS_INTEGER := 0;  
  TYPE INT_ARR IS TABLE OF INT;
  TYPE CHAR_ARR IS TABLE OF CHAR;
  TYPE ROWID_ARR IS TABLE OF ROWID;
  
  
  -- *******************************************************
  --    Autonomous TX Logger
  -- *******************************************************  
  
  PROCEDURE LOGEVENT(msg VARCHAR2, errc NUMBER default 0) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO EVENT VALUES (SYSDATE, '' || errc || ' -- ' || msg);
    COMMIT;
  END LOGEVENT;

  -- *******************************************************
  --    Event Listener
  -- *******************************************************  
  
  FUNCTION STREAMEVENTS(MAX_EVENTS IN INT DEFAULT 20) RETURN EVENTM_ARR PIPELINED IS
    eventCount PLS_INTEGER := 0;
    startTs DATE := SYSDATE;
  BEGIN
    WHILE(eventCount < MAX_EVENTS) LOOP
      FOR e IN (SELECT TS, EVENT FROM EVENT WHERE TS >= startTs) LOOP
        PIPE ROW('EVENT >> [' || e.EVENT || ']');
        eventCount := eventCount + 1;
        startTs := e.TS;
      END LOOP;      
      IF(eventCount < MAX_EVENTS) THEN
        SYS.DBMS_LOCK.SLEEP(2);
      END IF;
    END LOOP;
    RETURN;
  END STREAMEVENTS;
  

  FUNCTION QUERYTBATCHES(STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCH_ARR PIPELINED IS
      batchy TQBATCH;    
      latency NUMBER  := 0;
      cursor qx is SELECT VALUE(T) FROM TABLE (
          TQV.TRADEBATCH(
            TQV.TOTQSTUB(CURSOR(SELECT * FROM TABLE(
              TQV.ENRICHSECURITY(CURSOR(SELECT * FROM TABLE(
                TQV.ENRICHACCOUNT(CURSOR(SELECT * FROM TABLE(
                  TQV.FINDRAWTQS (
                    CURSOR (
                      SELECT * FROM TQUEUEV
                      WHERE TQUEUE_ID > STARTING_ID 
                      AND STATUS_CODE IN ('PENDING')
                      ORDER BY TQUEUE_ID, ACCOUNT_DISPLAY_NAME                  
                    )
                  , MAX_ROWS) -- MAX ROWS (Optional)                  
                )))
              )))
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


  PROCEDURE DEBUGME(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10) AS
    cnt int := 0;
  BEGIN
    NULL;
  END DEBUGME;
  
  FUNCTION LOCKR(rid in VARCHAR2) RETURN BOOLEAN IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    rrid VARCHAR2(18) := NULL;
  BEGIN
    SELECT ROWIDTOCHAR(ROWID) INTO rrid FROM TQUEUE WHERE ROWID = CHARTOROWID(rid) FOR UPDATE SKIP LOCKED;
    COMMIT;
    RETURN TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      COMMIT;
      RETURN FALSE;
  END LOCKR;

  -- *******************************************************
  --    Root of Pipeline, Finds the raw trades
  -- *******************************************************  
  FUNCTION FINDRAWTQS(p IN TQSTUBCUR, MAX_ROWS IN NUMBER DEFAULT 100) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID)) IS    
    trade TQSTUBV;
    rid VARCHAR2(18);
  BEGIN
    LOOP    
      FETCH p INTO trade;      
      EXIT WHEN p%NOTFOUND;
      PIPE ROW(trade);
      /*
      IF LOCKR(trade.xrowid) THEN
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
          LOGEVENT('FINDRAWTQS >>> CLEAN UP');
        END;
        RETURN;
  END FINDRAWTQS;
  
  -- *******************************************************
  --    Enriches each trade with Account details
  -- *******************************************************  
  FUNCTION ENRICHACCOUNT(p IN TQSTUBCUR) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID)) IS    
    trade TQSTUBV;    
  BEGIN
    LOOP    
      FETCH p INTO trade;
      EXIT WHEN p%NOTFOUND;
      trade.ACCOUNT_ID := accountCache(trade.ACCOUNT_DISPLAY_NAME);
/*
      SELECT ACCOUNT_ID INTO trade.ACCOUNT_ID FROM ACCOUNT
        WHERE ACCOUNT_DISPLAY_NAME = trade.ACCOUNT_DISPLAY_NAME;
*/        
      PIPE ROW(trade);
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN      
        BEGIN
          LOGEVENT('ENRICHACCOUNT >>> CLEAN UP');
        END;
        RETURN;
  END ENRICHACCOUNT;
  
  -- *******************************************************
  --    Enriches each trade with Specie details
  -- *******************************************************  
  FUNCTION ENRICHSECURITY(p IN TQSTUBCUR) RETURN TQSTUBV_ARR PIPELINED PARALLEL_ENABLE ( PARTITION p BY RANGE(TQUEUE_ID)) IS
    trade TQSTUBV;    
  BEGIN
    LOOP    
      FETCH p INTO trade;
      EXIT WHEN p%NOTFOUND;
      trade.SECURITY_TYPE := securityCache(trade.SECURITY_DISPLAY_NAME).SECURITY_TYPE;
      trade.SECURITY_ID := securityCache(trade.SECURITY_DISPLAY_NAME).SECURITY_ID;
/*      
      SELECT SECURITY_ID, SECURITY_TYPE INTO trade.SECURITY_ID, trade.SECURITY_TYPE FROM SECURITY
        WHERE SECURITY_DISPLAY_NAME = trade.SECURITY_DISPLAY_NAME;
*/        
      PIPE ROW(trade);
    END LOOP;
    RETURN;
    EXCEPTION
      WHEN NO_DATA_NEEDED THEN      
        BEGIN
          LOGEVENT('ENRICHSECURITY >>> CLEAN UP');
        END;
        RETURN;
  END ENRICHSECURITY;

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
        tv.TQUEUE_ID, 
        tv.XID,
        tv.STATUS_CODE, 
        tv.SECURITY_DISPLAY_NAME, 
        tv.ACCOUNT_DISPLAY_NAME, 
        tv.SECURITY_ID,         
        tv.SECURITY_TYPE,
        tv.ACCOUNT_ID,
        tv.BATCH_ID,
        tv.CREATE_TS, 
        tv.UPDATE_TS, 
        tv.ERROR_MESSAGE));
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
--    Fetches the next batch id
-- *******************************************************  
  FUNCTION NEXTBATCHID RETURN NUMBER IS 
    seq NUMBER;
  BEGIN
    SELECT SEQ_TQBATCH_ID.NEXTVAL INTO seq FROM DUAL;
    RETURN seq;
  END NEXTBATCHID;

  -- *******************************************************
  --    Sorts the trades in a batch by TQ ID
  -- *******************************************************  
  PROCEDURE SORTTRADEARR(tqb IN OUT TQBATCH, STUBS IN TQSTUB_ARR) IS
    fTx INT := 0;
    lTx INT := 0;
    sortedStubs TQSTUB_ARR;    
    rowids XROWIDS;
  CURSOR tQByID IS 
    SELECT TQSTUB(
        XROWID, TQUEUE_ID, XID, STATUS_CODE, 
        SECURITY_DISPLAY_NAME, ACCOUNT_DISPLAY_NAME, 
        SECURITY_ID, SECURITY_TYPE, 
        ACCOUNT_ID, BATCH_ID,
        CREATE_TS, UPDATE_TS, ERROR_MESSAGE), XROWID
      FROM TABLE(STUBS) ORDER BY TQUEUE_ID;            
      
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
          currentTradeArr.extend();
          --currentTradeArr(1) := TQSTUB(T.XROWID, T.TQUEUE_ID, T.STATUS_CODE, T.SECURITY_DISPLAY_NAME, T.ACCOUNT_DISPLAY_NAME, T.SECURITY_ID, T.SECURITY_TYPE, T.ACCOUNT_ID, T.CREATE_TS, T.UPDATE_TS, T.ERROR_MESSAGE);
          currentTradeArr(1) := T;
          PIPE ROW (new TQBATCH(ACCOUNT => currentPosAcctId, TCOUNT => 1, FIRST_T => T.TQUEUE_ID, LAST_T => T.TQUEUE_ID, BATCH_ID => NEXTBATCHID, ROWIDS => NULL, TRADES => currentTradeArr));
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
        T.TQUEUE_ID, 
        T.XID,
        T.STATUS_CODE, 
        T.SECURITY_DISPLAY_NAME, 
        T.ACCOUNT_DISPLAY_NAME, 
        T.SECURITY_ID,         
        T.SECURITY_TYPE, 
        T.ACCOUNT_ID,
        T.BATCH_ID,
        T.CREATE_TS, 
        T.UPDATE_TS, 
        T.ERROR_MESSAGE);
    END LOOP;
    IF tcount > 0 THEN
        PIPE ROW (PREPBATCH(currentPosAcctId, currentTradeArr));
    END IF;
  END TRADEBATCH;
  
  -- *******************************************************
  --    toString for Trade Arrays
  -- *******************************************************

  FUNCTION TRADESTOVARCHAR(STUBS IN TQSTUB_ARR) RETURN VARCHAR2 IS
    str VARCHAR(2000) := '';
    st TQSTUB;
  BEGIN
    FOR i in STUBS.FIRST..STUBS.LAST LOOP
      st := STUBS(i);
      str := str || '[' || st.TQUEUE_ID || ',' || st.SECURITY_TYPE || ',' || st.SECURITY_ID || ',' || st.ACCOUNT_ID || ']';
    END LOOP;
    return str;
  END TRADESTOVARCHAR;  

  -- *******************************************************
  --    Procedural MLOAD
  -- *******************************************************  
  FUNCTION LOADBATCHES(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCHMLOAD IS
    mlBatches TQBATCH_ARR;    
    latency NUMBER  := 0;
  BEGIN
      SELECT TQBATCH(ACCOUNT, TCOUNT, FIRST_T, LAST_T, BATCH_ID, ROWIDS, TRADES)  
      BULK COLLECT INTO mlBatches
      FROM TABLE (   -- TQ.TRADESTOVARCHAR(T.TRADES) 
        TQV.TRADEBATCH(
          TQV.TOTQSTUB(CURSOR(SELECT * FROM TABLE(
            TQV.ENRICHSECURITY(CURSOR(SELECT * FROM TABLE(
              TQV.ENRICHACCOUNT(CURSOR(SELECT * FROM TABLE(
                TQV.FINDRAWTQS (
                  CURSOR (
                    SELECT * FROM TQUEUEO
                    WHERE TQUEUE_ID >= 0 
                    AND STATUS_CODE IN ('PENDING','ENRICH','RETRY')
                    ORDER BY TQUEUE_ID, ACCOUNT_DISPLAY_NAME
                  ), MAX_ROWS  -- MAX ROWS (Optional)
                )
              )))
            )))
          ) ORDER BY ACCOUNT_ID))
        , MAX_BATCH_SIZE)  -- Max number of trades in a batch
      ) T
      ORDER BY FIRST_T;      
     RETURN NEW TQBATCHMLOAD(mlBatches, mlBatches(1).FIRST_T, mlBatches(mlBatches.COUNT).LAST_T, latency);
  END LOADBATCHES;
  
  -- *******************************************************
  --    Queryt MLOAD
  -- *******************************************************  
  FUNCTION QUERYBATCHES(MAX_ROWS IN INT DEFAULT 1000, MAX_BATCH_SIZE IN INT DEFAULT 10) RETURN TQBATCHMLOAD_ARR PIPELINED IS
    mload TQBATCHMLOAD;
  BEGIN
    mload := LOADBATCHES(MAX_ROWS, MAX_BATCH_SIZE);
    PIPE ROW (mload);
    RETURN;
  END QUERYBATCHES;
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
--
  -- *******************************************************
  --    Updates all rows in all passed batches
  -- *******************************************************

  PROCEDURE UPDATEBATCHES(batches IN TQBATCH_ARR) IS
  BEGIN
    FORALL i IN 1..batches.COUNT
      EXECUTE IMMEDIATE 'BEGIN TQV.UPDATEBATCH(:1); END;' USING IN batches(i);
  END UPDATEBATCHES;
  
  
  FUNCTION RANDACCT RETURN VARCHAR2 IS 
  BEGIN
    RETURN accountCache(MOD(ABS(DBMS_RANDOM.RANDOM), accountCache.COUNT));
  END;
  
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

  PROCEDURE HANDLE_INSERT(transaction_id RAW, ntfnds CQ_NOTIFICATION$_DESCRIPTOR) IS
    secids INT_ARR := new INT_ARR();
    actids INT_ARR := new INT_ARR();
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
    sectypes.extend(row_desc_array.COUNT);
    rowids.extend(row_desc_array.COUNT);
    
    FOR i in 1..row_desc_array.COUNT LOOP
      rowids(i) := CHARTOROWID(row_desc_array(i).row_id);
      secids(i) := SECIDFORROWID(rowids(i));
      actids(i) := ACCTIDFORROWID(rowids(i));
      sectypes(i) := SECTYPEFORROWID(rowids(i));
      INSERT INTO TQSTUBS (TQROWID, TXID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID)
      VALUES(
        rowids(i), 
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
        LOGEVENT( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
      END;
  END HANDLE_INSERT;


  PROCEDURE SNAPTX IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO TX SELECT * FROM V$TRANSACTION WHERE XIDUSN = xidusn AND XIDSLOT = xidslot AND XIDSQN = xidsqn;
    COMMIT;
  END SNAPTX;
  
  
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
    EXCEPTION
      WHEN OTHERS THEN      
        BEGIN
          LOGEVENT('More than 1 TX match for txid [' || xid_usn || '.' || xid_slot || '.' || xid_sqn || ']');
          SNAPTX;
          RAISE;
        END;    
  END CURRENTXID;
  


  -- *******************************************************
  --    Load cache procedure
  -- *******************************************************
  
  PROCEDURE LOADCACHES IS
      spec SPEC_DECODE;
    BEGIN  
        -- populate accountCache 
      FOR R IN (SELECT ACCOUNT_DISPLAY_NAME, ACCOUNT_ID FROM ACCOUNT) LOOP
        accountCache(R.ACCOUNT_DISPLAY_NAME) := R.ACCOUNT_ID;
      END LOOP;
      LOGEVENT('INITIALIZED ACCT CACHE: ' || accountCache.COUNT || ' ACCOUNTS');
      -- populate security cache
      FOR R IN (SELECT SECURITY_ID, SECURITY_DISPLAY_NAME, SECURITY_TYPE FROM SECURITY) LOOP
        spec.SECURITY_ID := R.SECURITY_ID; 
        spec.SECURITY_DISPLAY_NAME := R.SECURITY_DISPLAY_NAME;
        spec.SECURITY_TYPE := R.SECURITY_TYPE;
        securityCache(R.SECURITY_DISPLAY_NAME) := spec;
      END LOOP;
      LOGEVENT('INITIALIZED SECURITY CACHE: ' || securityCache.COUNT || ' SECURITIES');
    END LOADCACHES;
  
  -- *******************************************************
  --    Package Initialization
  -- *******************************************************
  
  
  BEGIN
    LOADCACHES;
END TQV;
/

--------------------------------------------------------
--  TQUEUE Insert Callback Handler
--------------------------------------------------------

create or replace PROCEDURE TQUEUE_INSERT_CALLBACK (
  ntfnds IN CQ_NOTIFICATION$_DESCRIPTOR   ) IS  
BEGIN
/*
  IF (ntfnds.event_type != DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    RETURN;
  END IF;
*/  
  TQV.HANDLE_INSERT(
    ntfnds.transaction_id,
    ntfnds
  );
    EXCEPTION WHEN OTHERS THEN 
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
      BEGIN
        TQV.LOGEVENT('CALLBACK:' ||  DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
      END;
  
END;
/

DECLARE
  reginfo  CQ_NOTIFICATION$_REG_INFO;
  v_cursor SYS_REFCURSOR;
  regid    NUMBER;
BEGIN
  reginfo := cq_notification$_reg_info (
    'TQUEUE_INSERT_CALLBACK',                 -- The callback handler
    DBMS_CQ_NOTIFICATION.QOS_QUERY +          -- Specifies Query Change, Reliable and with ROWIDs
      DBMS_CQ_NOTIFICATION.QOS_RELIABLE + 
      DBMS_CQ_NOTIFICATION.QOS_ROWIDS,
    0,                                        -- No timeout 
    DBMS_CQ_NOTIFICATION.INSERTOP,            -- Specifies INSERT Ops  (DBMS_CQ_NOTIFICATION.ALL_OPERATIONS)
    0                                         -- Ignored for query result change notification 
  );

  regid := DBMS_CQ_NOTIFICATION.new_reg_start(reginfo);

  OPEN v_cursor FOR
    SELECT DBMS_CQ_NOTIFICATION.CQ_NOTIFICATION_QUERYID, ROWID FROM TQUEUE
    WHERE STATUS_CODE IN ('PENDING', 'ENRICH', 'RETRY');
  CLOSE v_cursor;
  DBMS_CQ_NOTIFICATION.REG_END;
END;
/


SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

   -- select count(*) from tqueue
/*

begin 
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100); 
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100);
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100);
end;  

*/

ALTER SYSTEM SET "JOB_QUEUE_PROCESSES"=500
select * from v$parameter where name like '%job%'

select * from dba_jobs_running 

SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

truncate table tqueue;
truncate table event;
truncate table tqstubs;

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event


SELECT dbms_change_notification.cq_notification_queryid
FROM dual

BEGIN
  DBMS_DDL.alter_compile('PACKAGE', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PROCEDURE', 'TQREACTOR', 'TQUEUE_INSERT_CALLBACK');
END;

select * from tqueue order by tqueue_id desc
select * from tqstubs

select * from event order by ts desc
select distinct event from event

select event, count(*) from event group by event
 
BEGIN
  FOR i in 1..100 LOOP
  INSERT INTO TQUEUE VALUES(SEQ_TQUEUE_ID.NEXTVAL, 'PENDING', 'c064e4ae-cb1c-4700-872f-eedde770c937',
    '3c7dea15-cc46-4e9f-816a-f342c8089d86', NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL);
  END LOOP;
    COMMIT;
END;

DECLARE
  ixid RAW(8);
  TXID VARCHAR2(200);
  RID ROWID;
BEGIN
  TXID := DBMS_TRANSACTION.local_transaction_id(TRUE);
  SELECT XID INTO ixid from V$TRANSACTION where xidusn || '.' || xidslot || '.' || xidsqn = TXID;
  FOR i in 1..100 LOOP
  INSERT INTO TQUEUE VALUES(SEQ_TQUEUE_ID.NEXTVAL, 'PENDING', 'b346652a-5194-41a1-a3ef-ac73af8d7548',
    '3b6d54cc-9bf5-40ed-966d-b0a4dbd1f7a2', NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL) 
    RETURNING ROWID INTO RID;
  INSERT INTO TQXIDS VALUES (RID, ixid);
    
  END LOOP;
    COMMIT;
END;



BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (301);
END;

SELECT queryid, regid, TO_CHAR(querytext)
   FROM user_cq_notification_queries


declare
  mask NUMBER := -1;
BEGIN
  mask := DBMS_CQ_NOTIFICATION.QOS_QUERY + DBMS_CQ_NOTIFICATION.QOS_RELIABLE +  DBMS_CQ_NOTIFICATION.QOS_ROWIDS;
  DBMS_OUTPUT.PUT_LINE('MASK:' || mask);
END;


select (DBMS_CQ_NOTIFICATION.QOS_QUERY + DBMS_CQ_NOTIFICATION.QOS_RELIABLE +  DBMS_CQ_NOTIFICATION.QOS_ROWIDS) from dual

desc DBMS_CQ_NOTIFICATION

DECLARE
  reginfo  CQ_NOTIFICATION$_REG_INFO;
  v_cursor SYS_REFCURSOR;
  regid    NUMBER;
BEGIN
  reginfo := cq_notification$_reg_info (
    'TQUEUE_INSERT_CALLBACK',                 -- The callback handler
    --DBMS_CQ_NOTIFICATION.QOS_QUERY +          -- Specifies Query Change, Reliable and with ROWIDs
      DBMS_CQ_NOTIFICATION.QOS_RELIABLE + 
      DBMS_CQ_NOTIFICATION.QOS_ROWIDS,
    0,                                        -- No timeout 
    DBMS_CQ_NOTIFICATION.INSERTOP,            -- Specifies INSERT Ops  (DBMS_CQ_NOTIFICATION.ALL_OPERATIONS)
    0                                         -- Ignored for query result change notification 
  );

  regid := DBMS_CQ_NOTIFICATION.new_reg_start(reginfo);

  OPEN v_cursor FOR
    SELECT DBMS_CQ_NOTIFICATION.CQ_NOTIFICATION_QUERYID, ROWID FROM TQUEUE
    WHERE STATUS_CODE IN ('PENDING', 'ENRICH', 'RETRY');
  CLOSE v_cursor;
  DBMS_CQ_NOTIFICATION.REG_END;
END;
/

declare
  n boolean := true;
  x varchar2(200);
begin
  x := DBMS_TRANSACTION.LOCAL_TRANSACTION_ID(n);
  dbms_output.put_line('TX:' || x);
  commit;
end;

truncate table tqueue;
truncate table event;
truncate table tqstubs;
truncate table TQXIDS;

SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event
UNION ALL
select 'TQXIDS', count(*) from TQXIDS



BEGIN
  DBMS_DDL.alter_compile('PACKAGE', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PACKAGE BODY', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PROCEDURE', 'TQREACTOR', 'TQUEUE_INSERT_CALLBACK');
  EXECUTE IMMEDIATE 'truncate table tqueue';
  EXECUTE IMMEDIATE 'truncate table event';
  EXECUTE IMMEDIATE 'truncate table tqstubs';
  EXECUTE IMMEDIATE 'truncate table tqxids';
END;

select * from tqueue order by tqueue_id desc
select * from tqstubs

select * from event order by ts desc
select distinct event from event

-- 0 -- HandleInserts: Batch Overflow on TX:03000600F9070000
select * from TQXIDS

select event, count(*) from event group by event

BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (2);
END;

 
DECLARE
  ixid RAW(8) := NULL;
  TXID VARCHAR2(200);
  RID ROWID;
BEGIN
  FOR i in 1..100 LOOP
  INSERT INTO TQUEUE VALUES(SEQ_TQUEUE_ID.NEXTVAL, 'PENDING', 'b346652a-5194-41a1-a3ef-ac73af8d7548',
    '3b6d54cc-9bf5-40ed-966d-b0a4dbd1f7a2', NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL) 
    RETURNING ROWID INTO RID;
  /*
  IF (ixid is null) THEN
    --TXID := DBMS_TRANSACTION.local_transaction_id(TRUE);
    --SELECT XID INTO ixid from V$TRANSACTION where xidusn || '.' || xidslot || '.' || xidsqn = TXID;
    ixid := TQV.CURRENTXID();
    DBMS_OUTPUT.PUT_LINE('XID: [' || ixid || ']');
  END IF;
  */
  INSERT INTO TQXIDS VALUES (RID, TQV.CURRENTXID);    
  END LOOP;
    COMMIT;
END;


select * from tqxids
