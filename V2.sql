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


CREATE OR REPLACE TYPE TQSTUBS_OBJ FORCE AS OBJECT (
	XROWID VARCHAR2(18),
	TQROWID VARCHAR2(18),
	TQUEUE_ID NUMBER(22),
	XID RAW(8),
	SECURITY_ID NUMBER(22),
	SECURITY_TYPE CHAR(1),
	ACCOUNT_ID NUMBER(22),
	BATCH_ID NUMBER(22),
	BATCH_TS TIMESTAMP(6),
MEMBER FUNCTION TOV RETURN VARCHAR2
);
/
CREATE OR REPLACE TYPE BODY TQSTUBS_OBJ AS
MEMBER FUNCTION TOV RETURN VARCHAR2 AS
BEGIN
RETURN SELF.XROWID || ',' || SELF.TQROWID || ',' || SELF.TQUEUE_ID || ',' || SELF.XID || ',' || SELF.SECURITY_ID || ',' || SELF.SECURITY_TYPE || ',' || SELF.ACCOUNT_ID || ',' || SELF.BATCH_ID || ',' || SELF.BATCH_TS;
END TOV;
END;
/
CREATE OR REPLACE TYPE TQSTUBS_OBJ_ARR FORCE AS TABLE OF TQSTUBS_OBJ;
/


select * from TABLE(TQV.TQSTUBS_RECS_TO_OBJS(CURSOR(SELECT T.ROWID, T.* FROM TQSTUBS T WHERE ROWNUM < 10)));



select * /* VALUE(X).TOV() */ from TABLE(TQV.TQSTUBS_RECS_TO_OBJS(CURSOR(
  SELECT T.ROWID, T.* FROM TQSTUBS T WHERE MOD(ORA_HASH(ACCOUNT_ID, 999999),12) = 3 ORDER BY t.ACCOUNT_ID, T.TQUEUE_ID
))) X;


select count(distinct ORA_HASH(ACCOUNT_ID, 999999)), count(distinct ACCOUNT_ID) FROM ACCOUNT;


  -- *******************************************************
  --    Decode TQSTUBS records to objects. 
  --    e.g. select * from TABLE(TQV.TQSTUBS_RECS_TO_OBJS(CURSOR(SELECT T.ROWID, T.* FROM TQSTUBS T WHERE ROWNUM < 10)))
  -- *******************************************************
  FUNCTION TQSTUBS_RECS_TO_OBJS(p IN TQSTUBS_REC_CUR) RETURN TQSTUBS_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    rec TQSTUBS_REC;
  BEGIN
      LOOP
        FETCH p into rec;
        EXIT WHEN p%NOTFOUND;
        PIPE ROW(TQSTUBS_OBJ(rec.XROWID,ROWIDTOCHAR(rec.TQROWID),rec.TQUEUE_ID,rec.XID,rec.SECURITY_ID,rec.SECURITY_TYPE,rec.ACCOUNT_ID,rec.BATCH_ID,rec.BATCH_TS));
      END LOOP;
      RETURN;
      EXCEPTION
        WHEN NO_DATA_NEEDED THEN RAISE;
  END TQSTUBS_RECS_TO_OBJS;


  -- *******************************************************
  --    Decode TQUEUE records to objects
  -- *******************************************************
  
  FUNCTION TQUEUE_RECS_TO_OBJS(p IN TQUEUE_REC_CUR) RETURN TQUEUE_OBJ_ARR PIPELINED PARALLEL_ENABLE IS 
    obj TQUEUE_REC;
  BEGIN
      LOOP
        FETCH p into obj;
        EXIT WHEN p%NOTFOUND;
        PIPE ROW(TQUEUE_OBJ(obj.XROWID,obj.TQUEUE_ID,obj.XID,obj.STATUS_CODE,obj.SECURITY_DISPLAY_NAME,obj.ACCOUNT_DISPLAY_NAME,obj.SECURITY_ID,obj.SECURITY_TYPE,obj.ACCOUNT_ID,obj.BATCH_ID,obj.CREATE_TS,obj.UPDATE_TS,obj.ERROR_MESSAGE));
      END LOOP;
      RETURN;
      EXCEPTION
        WHEN NO_DATA_NEEDED THEN RAISE;
  END TQUEUE_RECS_TO_OBJS;
  
  -- *******************************************************
  --    Decode SecurityDisplayName
  -- *******************************************************
  
  PROCEDURE DECODE_SECURITY(securityDisplayName IN VARCHAR2, securityId OUT NUMBER, securityType OUT CHAR) IS
  BEGIN
    SELECT SECURITY_ID, SECURITY_TYPE INTO securityId, securityType FROM SECURITY WHERE SECURITY_DISPLAY_NAME = securityDisplayName;
  END DECODE_SECURITY;

  -- *******************************************************
  --    Decode AccountDisplayName
  -- *******************************************************
  PROCEDURE DECODE_ACCOUNT(accountDisplayName IN VARCHAR2, accountId OUT NUMBER) IS
  BEGIN
    SELECT ACCOUNT_ID INTO accountId FROM ACCOUNT WHERE ACCOUNT_DISPLAY_NAME = accountDisplayName;
  END DECODE_ACCOUNT;


  -- *******************************************************
  --    Handle TQUEUE INSERT Trigger
  -- *******************************************************
  PROCEDURE TRIGGER_STUB(rowid IN ROWID, tqueueId IN NUMBER, statusCode IN VARCHAR2, securityDisplayName IN VARCHAR2, accountDisplayName IN VARCHAR2, batchId IN NUMBER) IS
    securityId NUMBER;
    securityType CHAR;
    accountId NUMBER;
  BEGIN
    DECODE_SECURITY(securityDisplayName, securityId, securityType);
    DECODE_ACCOUNT(accountDisplayName, accountId);
    INSERT INTO TQSTUBS VALUES(rowid, tqueueId, CURRENTXID(), securityId, securityType, accountId, batchId, SYSTIMESTAMP);
  END TRIGGER_STUB;


create or replace TRIGGER STUB_REPLICATION_TRG 
AFTER INSERT ON TQUEUE 
REFERENCING OLD AS OLD NEW AS NEW 
FOR EACH ROW 
BEGIN
  TQV.TRIGGER_STUB(:NEW.ROWID, :NEW.TQUEUE_ID, :NEW.STATUS_CODE, :NEW.SECURITY_DISPLAY_NAME, :NEW.ACCOUNT_DISPLAY_NAME, :NEW.BATCH_ID);
END;

-- TODO: calc diff on inserts with trigger vs. without