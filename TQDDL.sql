
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
--  DDL for Sequence LOG EVENTS
--------------------------------------------------------
   
   CREATE SEQUENCE  SEQ_EVENT_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;

--------------------------------------------------------
--  DDL for Sequence BATCH_IDS
--------------------------------------------------------
   
   CREATE SEQUENCE  SEQ_BATCH_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;

--------------------------------------------------------
--  DDL for Sequence SEQ_REXEC_ID
--------------------------------------------------------

   CREATE SEQUENCE  SEQ_REXEC_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 10 ORDER  NOCYCLE ;

--------------------------------------------------------
--  DDL for Sequence SEQ_READYBATCH_ID
--------------------------------------------------------

   CREATE SEQUENCE  SEQ_READYBATCH_ID  MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE 1000 ORDER  NOCYCLE ;

--------------------------------------------------------
--  DDL for Table REHANDLER
--------------------------------------------------------

CREATE TABLE REHANDLERS (
  ID INT PRIMARY KEY NOT NULL,
  N CQ_NOTIFICATION$_DESCRIPTOR NOT NULL
);



--------------------------------------------------------
--  DDL for Table ACCOUNT
--------------------------------------------------------

  CREATE TABLE ACCOUNT (
  ACCOUNT_ID INT PRIMARY KEY NOT NULL,
  ACCOUNT_DISPLAY_NAME VARCHAR2(36) NOT NULL
  );

-------------------------------------------------------
--  DDL for Index ACCOUNT_AK
--------------------------------------------------------

  CREATE UNIQUE INDEX ACCOUNT_AK ON ACCOUNT (ACCOUNT_DISPLAY_NAME);

--------------------------------------------------------
--  DDL for Table SECURITY
--------------------------------------------------------


  CREATE TABLE SECURITY (
  SECURITY_ID INT PRIMARY KEY NOT NULL,
  SECURITY_DISPLAY_NAME VARCHAR2(64) NOT NULL,
  SECURITY_TYPE CHAR(1) NOT NULL
  );

  CREATE UNIQUE INDEX SECURITY_AK ON SECURITY (SECURITY_DISPLAY_NAME);

--------------------------------------------------------
--  DDL for Table TQUEUE
--------------------------------------------------------

  CREATE TABLE TQUEUE ( 
  TQUEUE_ID INT PRIMARY KEY NOT NULL,
  XID RAW(8) NOT NULL,
  STATUS_CODE VARCHAR2(15) NOT NULL, 
  SECURITY_DISPLAY_NAME VARCHAR2(64) NOT NULL, 
  ACCOUNT_DISPLAY_NAME VARCHAR2(36) NOT NULL, 
  SECURITY_ID INT, 
  SECURITY_TYPE CHAR(1),
  ACCOUNT_ID INT, 
  BATCH_ID INT,
  CREATE_TS DATE NOT NULL, 
  UPDATE_TS DATE, 
  ERROR_MESSAGE VARCHAR2(512)  
  );

  CREATE INDEX TQUEUE_STATUS_IDX ON TQUEUE (STATUS_CODE);
  CREATE INDEX TQUEUE_XID_IDX ON TQUEUE (XID);


-------------------------------------------------------
--  DDL for EVENT table
--------------------------------------------------------

  CREATE TABLE EVENT (
    EVENT_ID NUMBER PRIMARY KEY NOT NULL,
    ERRC NUMBER NOT NULL,
    TS DATE NOT NULL, 
    EVENT VARCHAR2(4000) NOT NULL
  );

-- =====================================================================================================================
--   TQSTUBS
-- =====================================================================================================================


--------------------------------------------------------
--  DDL for Table TQSTUBS
--------------------------------------------------------

  CREATE TABLE TQSTUBS  (
    TQROWID          ROWID PRIMARY KEY NOT NULL, 
    TQUEUE_ID        INT NOT NULL,
    XID              RAW(8) NOT NULL,
    SECURITY_ID      INT NOT NULL, 
    SECURITY_TYPE    CHAR(1) NOT NULL, 
    ACCOUNT_ID       INT NOT NULL,
    BATCH_ID         INT NOT NULL, 
    BATCH_TS         TIMESTAMP    
  );

--------------------------------------------------------
--  DDL for Index TQUEUESTUBS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX TQSTUBS_AK ON TQSTUBS (TQUEUE_ID);
  CREATE UNIQUE INDEX TQSTUBS_IND ON TQSTUBS (TQUEUE_ID, BATCH_ID);

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

CREATE OR REPLACE TYPE INT_ARR FORCE AS TABLE OF INT;
/


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

create or replace TYPE INT_ARR FORCE IS TABLE OF INT;
/

create or replace TYPE VARCHAR2_ARR FORCE IS TABLE OF VARCHAR2(200);
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
  ACCOUNT_ID                INT,                -- The ID of the account
  BATCH_ID                  INT,                -- The batch id assigned when a batch is locked 
  BATCH_TS                  TIMESTAMP           -- The timestamp when the batch id was assigned
);
/



CREATE OR REPLACE TYPE TQSTUB_ARR FORCE AS TABLE OF TQSTUB;
/



create or replace TYPE TQBATCH FORCE AS OBJECT (
  ACCOUNT           INT,
  TCOUNT            INT,
  FIRST_T           INT,
  LAST_T            INT,
  BATCH_ID          INT,
  ROWIDS            XROWIDS,
  STUBS             TQSTUB_ARR
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







create or replace TYPE TQBATCH_ARR FORCE AS TABLE OF TQBATCH;
/  



CREATE OR REPLACE TYPE SEC_DECODE IS OBJECT (
    SECURITY_DISPLAY_NAME   VARCHAR2(64),
    SECURITY_TYPE           CHAR(1),
    SECURITY_ID             NUMBER
  );
/

create or replace TYPE SEC_DECODE_ARR IS  TABLE OF SEC_DECODE;
/

create or replace TYPE ACCT_DECODE IS OBJECT (
    ACCOUNT_DISPLAY_NAME   	VARCHAR2(64),
    ACCOUNT_ID             NUMBER
);
/

create or replace TYPE ACCT_DECODE_ARR IS  TABLE OF ACCT_DECODE;
/


--------------------------------------------------------
--  DDL for View TQSTUBOV
--------------------------------------------------------

  CREATE OR REPLACE VIEW TQSTUBOV OF TQSTUB
  WITH OBJECT IDENTIFIER (TQROWID) AS SELECT
  ROWIDTOCHAR(ROWID) XROWID, 
  ROWIDTOCHAR(TQROWID) TQROWID, 
  TQUEUE_ID, 
  XID, 
  SECURITY_ID, 
  SECURITY_TYPE, 
  ACCOUNT_ID,
  BATCH_ID,
  BATCH_TS
  FROM TQSTUBS;

  -- *******************************************************
  --    Autonomous TX Logger
  -- *******************************************************


  CREATE OR REPLACE PROCEDURE LOGEVENT(msg VARCHAR2, errcode NUMBER default 0) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    --INSERT INTO EVENT(EVENT_ID, ERRC, TS, EVENT) VALUES (SEQ_EVENT_ID.NEXTVAL, ABS(errcode), SYSDATE, msg);
    --COMMIT;
    NULL;
  END LOGEVENT;
  /



--------------------------------------------------------
--  CQN Package
--------------------------------------------------------
@CQN.pls
/
@CQNBody.pls
/

--------------------------------------------------------
--  TQV Package
--------------------------------------------------------
@TQV.pls
/
@TQVBody.pls
/

--------------------------------------------------------
--  TESTDATA Package
--------------------------------------------------------
@TESTDATA.pls
/
@TESTDATABody.pls
/

--------------------------------------------------------
--  TQBATCHOV Object view of TQBATCHes
--------------------------------------------------------

CREATE OR REPLACE FORCE VIEW TQBATCHOV OF TQBATCH
WITH OBJECT IDENTIFIER (BATCH_ID) AS 
SELECT * FROM TABLE(TQV.GETBATCHES);
  


--------------------------------------------------------
--  TQUEUE Insert Callback Handler
--------------------------------------------------------

create or replace PROCEDURE TQUEUE_INSERT_CALLBACK (
  ntfnds IN OUT CQ_NOTIFICATION$_DESCRIPTOR   ) IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  TARGET_CHANGED EXCEPTION;
  PRAGMA EXCEPTION_INIT(TARGET_CHANGED, -6508 );
  events NUMBER := 0;
BEGIN
/*
  IF (ntfnds.event_type != DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    RETURN;
  END IF;
*/
  events := TQV.HANDLE_CHANGE(ntfnds);
  DBMS_ALERT.SIGNAL ('TQSTUB.ALERT.EVENT', TO_CHAR(events));
  COMMIT;
    /*  THIS error happens sometimes:  "CALLBACK ERROR: [ORA-06508: PL/SQL: could not find program unit being called] - ORA-06512: at "TQREACTOR.TQUEUE_INSERT_CALLBACK", line 10 */
    EXCEPTION
    WHEN TARGET_CHANGED THEN
      BEGIN
        EXECUTE IMMEDIATE 'BEGIN TQV.HANDLE_CHANGE(:1); WHEN OTHERS THEN DECLARE errm VARCHAR2(2000) := SQLERRM;errc NUMBER := SQLCODE; BEGIN LOGEVENT(''CALLBACK ERROR: ['' || errm || ''] - '' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc); END;' USING ntfnds;
      END;
    WHEN OTHERS THEN
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
      BEGIN
        LOGEVENT('CALLBACK ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        COMMIT;
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
  --DBMS_CQ_NOTIFICATION.SET_ROWID_THRESHOLD('TQUEUE', 100);
END;
/



