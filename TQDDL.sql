
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

CREATE TABLE READYTQBATCH OF TQBATCH (BATCH_ID PRIMARY KEY)
  NESTED TABLE STUBS STORE AS stubs_tab
  NESTED TABLE ROWIDS STORE AS rowids_tab;

CREATE TABLE BATCHTRACKER (

)


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
  BATCH_TS                  TIMESTAMP,           -- The timestamp when the batch id was assigned
  MAP MEMBER FUNCTION GET_TRADEQUEUE_ID RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY TQSTUB AS
    MAP MEMBER FUNCTION GET_TRADEQUEUE_ID RETURN NUMBER IS
    BEGIN
      RETURN TQUEUE_ID;
    END;
  END;
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
  STUBS             TQSTUB_ARR,
  MEMBER PROCEDURE SETXIDS,
  MEMBER PROCEDURE SETXIDS(rowids IN XROWIDS),
  MEMBER FUNCTION XIDS RETURN XROWIDS,
  MEMBER FUNCTION TXIDS RETURN XROWIDS,
  MEMBER FUNCTION LASTTQ RETURN INT,
  MEMBER FUNCTION FIRSTTQ RETURN INT,
  MEMBER PROCEDURE UPDATE_STUBS(lockedStubs IN TQSTUB_ARR),
  MAP MEMBER FUNCTION GET_FIRST_TRADEQUEUE_ID RETURN NUMBER
);
/

--------------------------------------------------------
--  TQBatch Body
--------------------------------------------------------
create or replace type body tqbatch as
  MAP MEMBER FUNCTION GET_FIRST_TRADEQUEUE_ID RETURN NUMBER IS
  BEGIN
    return FIRST_T;
  END;
  --
  MEMBER PROCEDURE SETXIDS IS
    rids XROWIDS := new XROWIDS();
  BEGIN
    IF SELF.ROWIDS IS NULL THEN      
      rids.extend(STUBS.COUNT);
      FOR i in 1..STUBS.COUNT LOOP
            rids(i) := STUBS(i).XROWID;
      END LOOP;
      SELF.ROWIDS := rowids;
    END IF;
  END;
  --
  MEMBER PROCEDURE SETXIDS(rowids IN XROWIDS) IS
    BEGIN
    IF SELF.ROWIDS IS NULL THEN
      IF rowids IS NOT NULL THEN
        IF rowids.COUNT = SELF.STUBS.COUNT THEN
          SELF.ROWIDS := rowids;
        END IF;
      END IF;
    END IF;
  END;
  --
  MEMBER FUNCTION TXIDS RETURN XROWIDS IS
    rids XROWIDS := new XROWIDS();
  BEGIN
    rids.EXTEND(STUBS.COUNT);
    FOR i in 1..STUBS.COUNT LOOP
      rids(i) := STUBS(i).TQROWID;
    END LOOP;
    RETURN rids;
  END;
--
  MEMBER FUNCTION XIDS RETURN XROWIDS IS
    rids XROWIDS := new XROWIDS();
  BEGIN
    IF SELF.ROWIDS IS NULL THEN
      rids := new XROWIDS();
      rids.extend(STUBS.COUNT);
      FOR i in 1..STUBS.COUNT LOOP
            rids(i) := STUBS(i).XROWID;
      END LOOP;
      RETURN rids;
    ELSE
      return SELF.ROWIDS;
    END IF;
  END;
--
  MEMBER FUNCTION LASTTQ RETURN INT IS
  BEGIN
    IF SELF.STUBS IS NULL OR SELF.STUBS.COUNT = 0 THEN
      RETURN -1;
    ELSE
      RETURN SELF.STUBS(SELF.STUBS.COUNT).TQROWID;
    END IF;
  END;
--  
  MEMBER FUNCTION FIRSTTQ RETURN INT IS
  BEGIN
    IF SELF.STUBS IS NULL OR SELF.STUBS.COUNT = 0 THEN
      RETURN -1;
    ELSE
      RETURN SELF.STUBS(1).TQROWID;
    END IF;  
  END;
--  
  MEMBER PROCEDURE UPDATE_STUBS(lockedStubs IN TQSTUB_ARR) IS
    rids XROWIDS := new XROWIDS();
  BEGIN  
    IF lockedStubs IS NULL OR lockedStubs.COUNT = 0 THEN
      SELF.STUBS := new TQSTUB_ARR();
      SELF.ROWIDS := new XROWIDS();
      SELF.TCOUNT := 0;
      SELF.FIRST_T := -1;
      SELF.LAST_T := -1;          
    ELSE 
      SELF.STUBS := lockedStubs;
      rids.extend(SELF.STUBS.COUNT);
      FOR i in 1..SELF.STUBS.COUNT LOOP
        rids(i) := SELF.STUBS(i).XROWID;
      END LOOP;
      SELF.ROWIDS := rids;    
      SELF.TCOUNT := SELF.STUBS.COUNT;
      SELF.FIRST_T := SELF.FIRSTTQ;
      SELF.LAST_T := SELF.LASTTQ;    
    END IF;
  END;
END;
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
    INSERT INTO EVENT(EVENT_ID, ERRC, TS, EVENT) VALUES (SEQ_EVENT_ID.NEXTVAL, ABS(errcode), SYSDATE, msg);
    COMMIT;
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
  
BEGIN
/*
  IF (ntfnds.event_type != DBMS_CQ_NOTIFICATION.EVENT_QUERYCHANGE) THEN
    RETURN;
  END IF;
*/
  LOGEVENT('CALLBACK:' || ntfnds.transaction_id);
  TQV.HANDLE_CHANGE(ntfnds);  
  COMMIT;
    /*  THIS error happens sometimes:  "CALLBACK ERROR: [ORA-06508: PL/SQL: could not find program unit being called] - ORA-06512: at "TQREACTOR.TQUEUE_INSERT_CALLBACK", line 10 */
    EXCEPTION 
    WHEN TARGET_CHANGED THEN
      BEGIN
        LOGEVENT('RE-EXECUTING....');
        EXECUTE IMMEDIATE 'BEGIN TQV.HANDLE_CHANGE(:1); WHEN OTHERS THEN DECLARE errm VARCHAR2(2000) := SQLERRM;errc NUMBER := SQLCODE; BEGIN LOGEVENT(''CALLBACK ERROR: ['' || errm || ''] - '' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc); END;' USING ntfnds;
        LOGEVENT('RE-EXECUTE SUCCESSFUL');        
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



