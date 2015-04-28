create or replace PACKAGE BODY TESTDATA AS

  TYPE SEC_DECODE_CACHE_IDX IS TABLE OF SEC_DECODE INDEX BY PLS_INTEGER;
  TYPE ACCT_DECODE_CACHE_IDX IS TABLE OF ACCT_DECODE INDEX BY PLS_INTEGER;

  accountCacheIdx ACCT_DECODE_CACHE_IDX;
  securityCacheIdx SEC_DECODE_CACHE_IDX;
  securityTypes CHAR_ARR := new CHAR_ARR('A', 'B', 'C', 'D', 'E', 'P', 'V', 'W', 'X', 'Y', 'Z', 'P');

  -- =====================================================================
  -- ==== done ====
  -- =====================================================================
  accountCache ACCT_DECODE_CACHE;
  securityCache SEC_DECODE_CACHE;
  -- =====================================================================
  -- These are temp for testing
  -- =====================================================================
--
  -- *******************************************************
  --    Returns a random security
  --    To query directly: select * FROM TABLE(NEW SEC_DECODE_ARR(TQV.RANDOMSEC))
  -- *******************************************************
  FUNCTION RANDOMSEC RETURN SEC_DECODE IS
    sz NUMBER := securityCacheIdx.COUNT-1;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return securityCacheIdx(rand);
    EXCEPTION WHEN OTHERS THEN
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;
      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMSEC. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;
  END RANDOMSEC;
--
  -- *******************************************************
  --    Returns a random account
  --    To query directly: select * FROM TABLE(NEW ACCT_DECODE_ARR(TQV.RANDOMACCT))
  -- *******************************************************
  FUNCTION RANDOMACCT RETURN ACCT_DECODE IS
    sz NUMBER := accountCacheIdx.COUNT-1;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return accountCacheIdx(rand);
    EXCEPTION WHEN OTHERS THEN
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;

      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMACCT. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;
  END RANDOMACCT;
--
  -- *******************************************************
  --    Returns a random security type
  -- *******************************************************
FUNCTION RANDOMSECTYPE RETURN CHAR IS
    sz NUMBER := securityTypes.COUNT;
    rand NUMBER := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, sz));
  BEGIN
    IF rand = 0 THEN rand := 1; END IF;
    return securityTypes(rand);
    EXCEPTION WHEN OTHERS THEN
      DECLARE
        errm VARCHAR2(2000) := SQLERRM;
        errc NUMBER := SQLCODE;

      BEGIN
        LOGEVENT( errm || ' : Failed RANDOMSECTYPE. sz:' || sz || ', rand:' || rand || ' : ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), errc);
        raise;
      END;
  END RANDOMSECTYPE;
--
  FUNCTION PIPEACCTCACHE RETURN ACCT_DECODE_ARR PIPELINED IS
  BEGIN
    FOR i in 1..accountCacheIdx.COUNT LOOP
      PIPE ROW(accountCacheIdx(i));
    END LOOP;
  END;
--
  FUNCTION PIPESECCACHE RETURN SEC_DECODE_ARR PIPELINED IS
  BEGIN
    FOR i in 1..securityCacheIdx.COUNT LOOP
      PIPE ROW(securityCacheIdx(i));
    END LOOP;
  END;


--
  -- *******************************************************
  --    Generates the specified number of randomized trades
  --    and inserts them into TQUEUE
  -- *******************************************************
  PROCEDURE GENTRADES(tradeCount IN NUMBER DEFAULT 1000) IS
    account ACCT_DECODE;
    security SEC_DECODE;
    noOfTrades INT := 0;
    done INT := 0;
  BEGIN

    FOR i in 1..tradeCount LOOP
      IF done = tradeCount THEN EXIT; END IF;
      account := RANDOMACCT;
      noOfTrades := ABS(MOD(SYS.DBMS_RANDOM.RANDOM, 10));
      IF noOfTrades = 0 THEN noOfTrades := 1; END IF;
      FOR x in 1..noOfTrades LOOP
        security := RANDOMSEC;
        INSERT INTO TQUEUE
          VALUES(SEQ_TQUEUE_ID.NEXTVAL, tqv.CURRENTXID, 'PENDING',  security.SECURITY_DISPLAY_NAME, account.ACCOUNT_DISPLAY_NAME, NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL);
        done := done + 1;
        IF done = tradeCount THEN EXIT; END IF;
      END LOOP;
    END LOOP;
    COMMIT;
  END GENTRADES;
--
  -- *******************************************************
  --    Generates the specified number of randomized accounts
  --    and inserts them into ACCOUNT
  -- *******************************************************
  PROCEDURE GENACCTS(acctCount IN NUMBER DEFAULT 1000) IS
  BEGIN
    FOR i in 1..acctCount LOOP
      INSERT INTO ACCOUNT VALUES(SEQ_ACCOUNT_ID.NEXTVAL, SYS_GUID());
    END LOOP;
    COMMIT;
  END GENACCTS;
--
  -- *******************************************************
  --    Generates the specified number of randomized securities
  --    and inserts them into SECURITY
  -- *******************************************************
  PROCEDURE GENSECS(secCount IN NUMBER DEFAULT 10000) IS
  BEGIN
    FOR i in 1..secCount LOOP
      INSERT INTO SECURITY VALUES(SEQ_SECURITY_ID.NEXTVAL, SYS_GUID(), RANDOMSECTYPE);
    END LOOP;
    COMMIT;
  END GENSECS;



  PROCEDURE LOADCACHES IS
      spec SPEC_DECODE;
      idx PLS_INTEGER;
      d VARCHAR2(64);
    BEGIN
       -- clear caches
      accountCache.DELETE;
      accountCacheIdx.DELETE;
      securityCache.DELETE;
      securityCacheIdx.DELETE;
       -- populate accountCache
      idx := 1;
      FOR R IN (SELECT ACCOUNT_DISPLAY_NAME, ACCOUNT_ID FROM ACCOUNT) LOOP
        accountCache(R.ACCOUNT_DISPLAY_NAME) := R.ACCOUNT_ID;
        accountCacheIdx(idx) := new ACCT_DECODE(R.ACCOUNT_DISPLAY_NAME, R.ACCOUNT_ID);
        idx := idx + 1;
      END LOOP;
      FOR R IN (SELECT * FROM TABLE(PIPEACCTCACHE)) LOOP
        d := R.ACCOUNT_DISPLAY_NAME;
      END LOOP;
      LOGEVENT('INITIALIZED ACCT CACHE: ' || accountCache.COUNT || ' ACCOUNTS');
      -- populate security cache
      idx := 1;
      FOR R IN (SELECT SECURITY_DISPLAY_NAME, SECURITY_TYPE, SECURITY_ID FROM SECURITY) LOOP
        spec.SECURITY_ID := R.SECURITY_ID;
        spec.SECURITY_DISPLAY_NAME := R.SECURITY_DISPLAY_NAME;
        spec.SECURITY_TYPE := R.SECURITY_TYPE;
        securityCache(R.SECURITY_DISPLAY_NAME) := spec;
        securityCacheIdx(idx) := new SEC_DECODE(R.SECURITY_DISPLAY_NAME, R.SECURITY_TYPE, R.SECURITY_ID);
        idx := idx + 1;
      END LOOP;
      FOR R IN (SELECT * FROM TABLE(PIPESECCACHE)) LOOP
        d := R.SECURITY_DISPLAY_NAME;
      END LOOP;
      LOGEVENT('INITIALIZED SECURITY CACHE: ' || securityCache.COUNT || ' SECURITIES');
    END LOADCACHES;

  -- *******************************************************
  --    Load cache procedure
  -- *******************************************************

  FUNCTION FORCELOADCACHE RETURN VARCHAR2 IS
    d VARCHAR2(64);
    s NUMBER := 0;
    a NUMBER := 0;
  BEGIN
      LOADCACHES;
      FOR R IN (SELECT * FROM TABLE(PIPESECCACHE)) LOOP
        d := R.SECURITY_DISPLAY_NAME;
        s := s+1;
      END LOOP;
      FOR R IN (SELECT * FROM TABLE(PIPEACCTCACHE)) LOOP
        d := R.ACCOUNT_DISPLAY_NAME;
        a := a+1;
      END LOOP;
      return 'read-secs:' || s || ', read-accts:' || a;
  END;

  -- *******************************************************
  --    Package Initialization
  -- *******************************************************
  BEGIN
    LOADCACHES;
END TESTDATA;
/