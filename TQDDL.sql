
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
    SECURITY_TYPE    CHAR(1 BYTE) NOT NULL, 
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
  TRADES            TQSTUB_ARR,
  MEMBER PROCEDURE SETXIDS,
  MEMBER PROCEDURE SETXIDS(rowids IN XROWIDS),
  MEMBER FUNCTION XIDS RETURN XROWIDS,
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

CREATE OR REPLACE TYPE TQBATCHMLOAD FORCE AS OBJECT ( 
  TQBATCHES TQBATCH_ARR,
  FIRST_T   INT,
  LAST_T    INT,
  LATENCY   INT
); 
/

create or replace TYPE TQBATCHMLOAD_ARR FORCE AS TABLE OF TQBATCHMLOAD;
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






--------------------------------------------------------
--  TQV Package
--------------------------------------------------------
@TQV.pls
/
@TQVBody.pls
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
        TQV.LOGEVENT('CALLBACK ERROR: [' || errm || '] - ' ||   DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
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


