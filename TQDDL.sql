
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


create or replace TYPE BATCH_SPEC AS OBJECT  (
    THREAD_MOD INT,         -- The thread mod for this request 
    BATCH_LIMIT INT,        -- The maximum number of batches to return
    ROW_LIMIT INT,          -- The maximum number of rows to process per call
    THREAD_COUNT INT,       -- The total number of threads polling
    CPU_MULTI INT,          -- A multiplier on the number of cpus to determine the parallelism of the driving query. 
    WAIT_LOOPS  INT,        -- The number of times to loop waiting on rows to show up
    WAIT_SLEEP  NUMBER,     -- The number of seconds to wait after each loop (fractional 100ths of seconds allowed),    
    MEMBER FUNCTION TOV RETURN VARCHAR2,    
    CONSTRUCTOR FUNCTION BATCH_SPEC(THREAD_MOD INT DEFAULT -1, BATCH_LIMIT IN INT DEFAULT 32, ROW_LIMIT INT DEFAULT 2147483647, THREAD_COUNT INT DEFAULT 8, CPU_MULTI INT DEFAULT 1, WAIT_LOOPS IN INT DEFAULT 2, WAIT_SLEEP IN NUMBER DEFAULT 1) RETURN SELF AS RESULT
  );
/
create or replace TYPE BODY BATCH_SPEC AS
  CONSTRUCTOR FUNCTION BATCH_SPEC(THREAD_MOD INT DEFAULT -1, BATCH_LIMIT IN INT DEFAULT 32, ROW_LIMIT INT DEFAULT 2147483647, THREAD_COUNT INT DEFAULT 8, CPU_MULTI INT DEFAULT 1, WAIT_LOOPS IN INT DEFAULT 2, WAIT_SLEEP IN NUMBER DEFAULT 1) RETURN SELF AS RESULT IS
  BEGIN
    -- TODO: Validate that THREAD_COUNT > 0
    -- TODO: Validate that THREAD_MOD is -1 or >= 0 and < THREAD_COUNT
    SELF.THREAD_MOD := THREAD_MOD;
    SELF.BATCH_LIMIT := BATCH_LIMIT;
    SELF.ROW_LIMIT := ROW_LIMIT;
    SELF.THREAD_COUNT := THREAD_COUNT;
    SELF.CPU_MULTI := CPU_MULTI;
    SELF.WAIT_LOOPS := WAIT_LOOPS;
    SELF.WAIT_SLEEP := WAIT_SLEEP;
    RETURN;
  END BATCH_SPEC;
  MEMBER FUNCTION TOV RETURN VARCHAR2 IS
  BEGIN
    RETURN 'BATCH_SPEC [tmod:' || THREAD_MOD || ', blimit:' || BATCH_LIMIT || ', rlimit:' || ROW_LIMIT || ', tcount:' || THREAD_COUNT || 
      ', cpum:' || CPU_MULTI || ', wloops:' || WAIT_LOOPS || ', wsleep:' || WAIT_SLEEP || ']';
  END TOV;
END;
/


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




-- =====================================================================================================================
--   TQSTUBS
-- =====================================================================================================================


--------------------------------------------------------
--  DDL for Table TQSTUBS
--------------------------------------------------------

  CREATE TABLE TQSTUBS  (    
    TQROWID          VARCHAR2(18) NOT NULL, 
    TQUEUE_ID        INT PRIMARY KEY NOT NULL,
    XID              RAW(8) NOT NULL,
    SECURITY_ID      INT NOT NULL, 
    SECURITY_TYPE    CHAR(1) NOT NULL, 
    ACCOUNT_ID       INT NOT NULL,
    ACCOUNT_BUCKET   SMALLINT NOT NULL,
    BATCH_ID         INT NOT NULL, 
    BATCH_TS         TIMESTAMP    
  );

--------------------------------------------------------
--  DDL for Index TQUEUESTUBS_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX TQSTUBS_IND ON TQSTUBS (TQUEUE_ID, BATCH_ID);

  CREATE INDEX TQSTUBS_AB_IND ON TQSTUBS (ACCOUNT_BUCKET);


CREATE OR REPLACE TYPE INT_ARR FORCE AS TABLE OF INT;
/


create or replace TYPE XROWIDS FORCE AS TABLE OF VARCHAR2(18);
/

create or replace TYPE INT_ARR FORCE IS TABLE OF INT;
/

create or replace TYPE VARCHAR2_ARR FORCE IS TABLE OF VARCHAR2(200);
/

--------------------------------------------------------
--  TQUEUE_OBJ type
--------------------------------------------------------

CREATE OR REPLACE TYPE TQUEUE_OBJ FORCE AS OBJECT (
  XROWID VARCHAR2(18),
  TQUEUE_ID NUMBER(22),
  XID RAW(8),
  STATUS_CODE VARCHAR2(15),
  SECURITY_DISPLAY_NAME VARCHAR2(64),
  ACCOUNT_DISPLAY_NAME VARCHAR2(36),
  SECURITY_ID NUMBER(22),
  SECURITY_TYPE CHAR(1),
  ACCOUNT_ID NUMBER(22),  
  BATCH_ID NUMBER(22),
  CREATE_TS DATE,
  UPDATE_TS DATE,
  ERROR_MESSAGE VARCHAR2(512),
MEMBER FUNCTION TOV RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY TQUEUE_OBJ AS
MEMBER FUNCTION TOV RETURN VARCHAR2 AS
BEGIN
RETURN SELF.XROWID || ',' || SELF.TQUEUE_ID || ',' || SELF.XID || ',' || SELF.STATUS_CODE || ',' || SELF.SECURITY_DISPLAY_NAME || ',' || SELF.ACCOUNT_DISPLAY_NAME || ',' || SELF.SECURITY_ID || ',' || SELF.SECURITY_TYPE || ',' || SELF.ACCOUNT_ID || ',' || SELF.BATCH_ID || ',' || SELF.CREATE_TS || ',' || SELF.UPDATE_TS || ',' || SELF.ERROR_MESSAGE;
END TOV;
END;
/

CREATE OR REPLACE TYPE TQUEUE_OBJ_ARR FORCE AS TABLE OF TQUEUE_OBJ;
/


--------------------------------------------------------
--  TQSTUBS_OBJ type
--------------------------------------------------------

CREATE OR REPLACE TYPE TQSTUBS_OBJ FORCE AS OBJECT (
  XROWID VARCHAR2(18),
  TQROWID VARCHAR2(18),
  TQUEUE_ID NUMBER(22),
  XID RAW(8),
  SECURITY_ID NUMBER(22),
  SECURITY_TYPE CHAR(1),
  ACCOUNT_ID NUMBER(22),
  ACCOUNT_BUCKET SMALLINT,
  BATCH_ID NUMBER(22),
  BATCH_TS TIMESTAMP(6),
  SID NUMBER,
MEMBER FUNCTION TOV RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY TQSTUBS_OBJ AS
MEMBER FUNCTION TOV RETURN VARCHAR2 AS
BEGIN
RETURN '[sid:' || SELF.SID || ', xrowid:' || SELF.XROWID || ', tqrowid:' || SELF.TQROWID || ', tqid:' || SELF.TQUEUE_ID || ', xid:' || SELF.XID || ', sec:' || SELF.SECURITY_ID || ', sectype:' || SELF.SECURITY_TYPE || ', acc:' || SELF.ACCOUNT_ID || ', ab:' || SELF.ACCOUNT_BUCKET || ', batch:' || SELF.BATCH_ID || ', bachts' || SELF.BATCH_TS;
END TOV;
END;
/
CREATE OR REPLACE TYPE TQSTUBS_OBJ_ARR FORCE AS TABLE OF TQSTUBS_OBJ;
/

--------------------------------------------------------
--  DDL for Type TQBATCH
--------------------------------------------------------

create or replace TYPE TQBATCH FORCE AS OBJECT (
  ACCOUNT_ID        INT,
  TCOUNT            INT,
  FIRST_T           INT,
  LAST_T            INT,
  BATCH_ID          INT,
  ROWIDS            XROWIDS,
  TQROWIDS          XROWIDS,
  STUBS             TQSTUBS_OBJ_ARR,
  SID               NUMBER,
  MAP MEMBER FUNCTION F RETURN NUMBER,
  MEMBER PROCEDURE ADDSTUB(stub TQSTUBS_OBJ),
  MEMBER FUNCTION TOV RETURN VARCHAR2,
  CONSTRUCTOR FUNCTION TQBATCH(stub TQSTUBS_OBJ, batchId PLS_INTEGER) RETURN SELF AS RESULT
);
/
create or replace TYPE BODY TQBATCH AS

  MAP MEMBER FUNCTION F RETURN NUMBER AS
  BEGIN    
    RETURN SELF.FIRST_T;
  END F;
  
  MEMBER PROCEDURE ADDSTUB(stub TQSTUBS_OBJ) AS
  BEGIN
    IF(ACCOUNT_ID != stub.ACCOUNT_ID) THEN
      RAISE_APPLICATION_ERROR(-1, 'INVALID ACCOUNT FOR THIS BATCH: (' || stub.ACCOUNT_ID || ') BATCH IS FOR [' || SELF.ACCOUNT_ID || ']');
    END IF;
    TCOUNT := TCOUNT + 1;
    LAST_T := stub.TQUEUE_ID;    
    ROWIDS.extend(); ROWIDS(TCOUNT) := stub.XROWID;
    TQROWIDS.extend(); TQROWIDS(TCOUNT) := stub.TQROWID;
    STUBS.extend(); STUBS(TCOUNT) := stub;    
  END ADDSTUB;
  
  CONSTRUCTOR FUNCTION TQBATCH(stub TQSTUBS_OBJ, batchId PLS_INTEGER)
    RETURN SELF AS RESULT AS
  BEGIN    
    ACCOUNT_ID := stub.ACCOUNT_ID;
    TCOUNT := 1;
    FIRST_T := stub.TQUEUE_ID;
    LAST_T := stub.TQUEUE_ID;
    BATCH_ID := batchId;
    ROWIDS := NEW XROWIDS(stub.XROWID);
    TQROWIDS := NEW XROWIDS(stub.TQROWID);
    STUBS := NEW TQSTUBS_OBJ_ARR(stub);  
    SID := stub.SID;
    RETURN;
  END;
  
  MEMBER FUNCTION TOV RETURN VARCHAR2 IS
  BEGIN
    IF(TCOUNT=1) THEN
      RETURN 'TQBATCH [sid:' || SID || ',acc:' || ACCOUNT_ID || ',batchid:' || BATCH_ID || ',tqid:' || FIRST_T || ',stype:' || STUBS(1).SECURITY_TYPE || ']';
    ELSE 
      RETURN 'TQBATCH [sid:' || SID || ',acc:' || ACCOUNT_ID || ',batchid:' || BATCH_ID || ',tcount:' || TCOUNT || ',tqids:' || FIRST_T || '-' || LAST_T || ']';
    END IF;
  END TOV;

END;
/

create or replace TYPE TQBATCH_ARR AS TABLE OF TQBATCH;
/



--------------------------------------------------------
--  Data types
--------------------------------------------------------


CREATE OR REPLACE TYPE SEC_DECODE IS OBJECT (
    SECURITY_DISPLAY_NAME   VARCHAR2(64),
    SECURITY_TYPE           CHAR(1),
    SECURITY_ID             NUMBER
  );
/

create or replace TYPE SEC_DECODE_ARR IS  TABLE OF SEC_DECODE;
/

create or replace TYPE ACCT_DECODE IS OBJECT (
    ACCOUNT_DISPLAY_NAME    VARCHAR2(64),
    ACCOUNT_ID             NUMBER
);
/

create or replace TYPE ACCT_DECODE_ARR IS  TABLE OF ACCT_DECODE;
/

create view RC as 
select 'ACCOUNTS' as "TABLE", count(*) as "ROWS" from account
UNION ALL
select 'SECURITIES' as "TABLE", count(*) as "ROWS" from security
UNION ALL
select 'TRADES' as "TABLE", count(*) as "ROWS" from tqueue
UNION ALL
select 'STUBS' as "TABLE", count(*) as "ROWS" from tqstubs;



--------------------------------------------------------
--  TQ package
--------------------------------------------------------



CREATE OR REPLACE CONTEXT TQCTX USING TQREACTOR.TQ ACCESSED GLOBALLY;

--------------------------------------------------------
--  TQUEUE trigger
--------------------------------------------------------

  create or replace TRIGGER STUB_REPLICATION_TRG
  AFTER INSERT ON TQUEUE 
  REFERENCING OLD AS OLD NEW AS NEW 
  FOR EACH ROW 
  BEGIN
    TQ.TRIGGER_STUB(:NEW.ROWID, :NEW.TQUEUE_ID, :NEW.STATUS_CODE, :NEW.SECURITY_DISPLAY_NAME, :NEW.ACCOUNT_DISPLAY_NAME, :NEW.BATCH_ID);
  END;
  

