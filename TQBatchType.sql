--------------------------------------------------------
--  DDL for Type TQBATCH
--------------------------------------------------------

  CREATE OR REPLACE TYPE "TQREACTOR"."TQBATCH" FORCE AS OBJECT (
  ACCOUNT           INT,
  TCOUNT            INT,
  FIRST_T           INT,
  LAST_T            INT,
  BATCH_ID          INT,
  ROWIDS            XROWIDS,
  TQROWIDS          XROWIDS,
  STUBS             TQSTUBS_OBJ_ARR,
  MAP MEMBER FUNCTION F RETURN NUMBER,
  MEMBER PROCEDURE ADDSTUB(stub TQSTUBS_OBJ),
  MEMBER FUNCTION TOV RETURN VARCHAR2,
  CONSTRUCTOR FUNCTION TQBATCH(stub TQSTUBS_OBJ, batchId PLS_INTEGER) RETURN SELF AS RESULT
);
/
CREATE OR REPLACE TYPE BODY "TQREACTOR"."TQBATCH" AS

  MAP MEMBER FUNCTION F RETURN NUMBER AS
  BEGIN    
    RETURN SELF.FIRST_T;
  END F;
  
  MEMBER PROCEDURE ADDSTUB(stub TQSTUBS_OBJ) AS
  BEGIN
    IF(ACCOUNT != stub.ACCOUNT_ID) THEN
      RAISE_APPLICATION_ERROR(-1, 'INVALID ACCOUNT FOR THIS BATCH: (' || stub.ACCOUNT_ID || ') BATCH IS FOR [' || SELF.ACCOUNT || ']');
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
    ACCOUNT := stub.ACCOUNT_ID;
    TCOUNT := 1;
    FIRST_T := stub.TQUEUE_ID;
    LAST_T := stub.TQUEUE_ID;
    BATCH_ID := batchId;
    ROWIDS := NEW XROWIDS(stub.XROWID);
    TQROWIDS := NEW XROWIDS(stub.TQROWID);
    STUBS := NEW TQSTUBS_OBJ_ARR(stub);  
    RETURN;
  END;
  
  MEMBER FUNCTION TOV RETURN VARCHAR2 IS
  BEGIN
    IF(TCOUNT=1) THEN
      RETURN 'TQBATCH [acc:' || ACCOUNT || ',batchid:' || BATCH_ID || ',trade:' || FIRST_T || ',stype:' || STUBS(1).SECURITY_TYPE || ']';
    ELSE 
      RETURN 'TQBATCH [acc:' || ACCOUNT || ',batchid:' || BATCH_ID || ',trades:' || TCOUNT || ',trades:' || FIRST_T || '-' || LAST_T || ']';
    END IF;
  END TOV;

END;

/


create or replace TYPE BODY TQBATCH AS

  MAP MEMBER FUNCTION F RETURN NUMBER AS
  BEGIN    
    RETURN SELF.FIRST_T;
  END F;
  
  MEMBER PROCEDURE ADDSTUB(stub TQSTUBS_OBJ) AS
  BEGIN
    IF(ACCOUNT != stub.ACCOUNT_ID) THEN
      RAISE_APPLICATION_ERROR(-1, 'INVALID ACCOUNT FOR THIS BATCH: (' || stub.ACCOUNT_ID || ') BATCH IS FOR [' || SELF.ACCOUNT || ']');
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
    ACCOUNT := stub.ACCOUNT_ID;
    TCOUNT := 1;
    FIRST_T := stub.TQUEUE_ID;
    LAST_T := stub.TQUEUE_ID;
    BATCH_ID := batchId;
    ROWIDS := NEW XROWIDS(stub.XROWID);
    TQROWIDS := NEW XROWIDS(stub.TQROWID);
    STUBS := NEW TQSTUBS_OBJ_ARR(stub);  
    RETURN;
  END;
  
  MEMBER FUNCTION TOV RETURN VARCHAR2 IS
  BEGIN
    IF(TCOUNT=1) THEN
      RETURN 'TQBATCH [acc:' || ACCOUNT || ',batchid:' || BATCH_ID || ',trade:' || FIRST_T || ',stype:' || STUBS(1).SECURITY_TYPE || ']';
    ELSE 
      RETURN 'TQBATCH [acc:' || ACCOUNT || ',batchid:' || BATCH_ID || ',trades:' || TCOUNT || ',trades:' || FIRST_T || '-' || LAST_T || ']';
    END IF;
  END TOV;

END;
/

create or replace TYPE TQBATCH_ARR AS TABLE OF TQBATCH;
/
