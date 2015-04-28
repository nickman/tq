create or replace PACKAGE TESTDATA AS

  TYPE CHAR_ARR IS TABLE OF CHAR;

  /* TQV Test Data Generator */

  TYPE SPEC_DECODE IS RECORD (
    SECURITY_DISPLAY_NAME   SECURITY.SECURITY_DISPLAY_NAME%TYPE,
    SECURITY_TYPE           SECURITY.SECURITY_TYPE%TYPE,
    SECURITY_ID             SECURITY.SECURITY_ID%TYPE
  );

  TYPE SEC_DECODE_CACHE IS TABLE OF SPEC_DECODE INDEX BY SECURITY.SECURITY_DISPLAY_NAME%TYPE;
  TYPE ACCT_DECODE_CACHE IS TABLE OF ACCOUNT.ACCOUNT_ID%TYPE INDEX BY ACCOUNT.ACCOUNT_DISPLAY_NAME%TYPE;

  FUNCTION RANDOMACCT RETURN ACCT_DECODE;
  FUNCTION RANDOMSEC RETURN SEC_DECODE;
  PROCEDURE GENTRADES(tradeCount IN NUMBER DEFAULT 1000);

  FUNCTION FORCELOADCACHE RETURN VARCHAR2;
  FUNCTION RANDOMSECTYPE RETURN CHAR;
  PROCEDURE GENACCTS(acctCount IN NUMBER DEFAULT 1000);
  PROCEDURE GENSECS(secCount IN NUMBER DEFAULT 10000);
  FUNCTION PIPEACCTCACHE RETURN ACCT_DECODE_ARR PIPELINED;
  FUNCTION PIPESECCACHE RETURN SEC_DECODE_ARR PIPELINED;



END TESTDATA;
/