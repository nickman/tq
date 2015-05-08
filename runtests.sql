Declare
  idx NUMBER := 0;
  sname VARCHAR2(100);
  csize NUMBER;
  cursor c is select sequence_name, cache_size from user_sequences where SEQUENCE_NAME NOT LIKE '%ACCOUNT%' AND SEQUENCE_NAME NOT LIKE '%SECURITY%';
Begin  
  Execute Immediate 'truncate table event';
  Execute Immediate 'truncate table tqueue';
  Execute Immediate 'truncate table tqstubs';
/*
  for seqInfo in c LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE TQREACTOR.' || c.SEQUENCE_NAME;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || c.SEQUENCE_NAME || ' MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE ' || c.cache_size || ' ORDER  NOCYCLE';
  END LOOP;
*/  
  SELECT COUNT(*) INTO IDX FROM ACCOUNT;
  IF IDX < 1000 THEN
    TESTDATA.GENACCTS(1000-IDX);
    COMMIT;
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100);
  END IF;
  SELECT COUNT(*) INTO IDX FROM SECURITY;
  IF IDX < 10000 THEN
    TESTDATA.GENSECS(10000-IDX);
    COMMIT;
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100);
  END IF;
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TESTDATA.FORCELOADCACHE);
  FOR i in 1..1 LOOP
    Testdata.Gentrades(100);
    --DBMS_OUTPUT.PUT_LINE('Loop ' || i);    
    Commit;
    --DBMS_LOCK.SLEEP(1);
  END LOOP;
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100);  
End;


Declare
  idx NUMBER := 0;
  sname VARCHAR2(100);
  csize NUMBER;
  cursor c is select sequence_name, cache_size from user_sequences where SEQUENCE_NAME NOT LIKE '%ACCOUNT%' AND SEQUENCE_NAME NOT LIKE '%SECURITY%';
Begin  
/*
  Execute Immediate 'truncate table event';
  Execute Immediate 'truncate table tqueue';
  Execute Immediate 'truncate table tqstubs';
  Execute Immediate 'truncate table tqbatches';
*/  
/*
  for seqInfo in c LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE TQREACTOR.' || c.SEQUENCE_NAME;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || c.SEQUENCE_NAME || ' MINVALUE 0 MAXVALUE 2147483647 INCREMENT BY 1 START WITH 1 CACHE ' || c.cache_size || ' ORDER  NOCYCLE';
  END LOOP;
*/  
  SELECT COUNT(*) INTO IDX FROM ACCOUNT;
  IF IDX < 1000 THEN
    TESTDATA.GENACCTS(1000-IDX);
    COMMIT;
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100);
  END IF;
  SELECT COUNT(*) INTO IDX FROM SECURITY;
  IF IDX < 10000 THEN
    TESTDATA.GENSECS(10000-IDX);
    COMMIT;
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100);
  END IF;
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TESTDATA.FORCELOADCACHE);
  FOR i in 1..10 LOOP
    FOR x in 1..100 LOOP
      Testdata.Gentrades(100);
      COMMIT;
    END LOOP;
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100);
    DBMS_LOCK.SLEEP(10);
  END LOOP;   
End;



select 'ACCOUNTS', count(*) from account
UNION ALL
select 'SECURITIES', count(*) from security
UNION ALL
select 'TRADES', count(*) from tqueue
UNION ALL
select 'STUBS', count(*) from tqstubs
UNION ALL
select '---------> PENDING', count(*) from tqueue where status_code = 'PENDING'
UNION ALL
select '---------> CLEARED', count(*) from tqueue where status_code = 'CLEARED'
UNION ALL
select 'LAST TQ', max(tqueue_id) from tqueue where status_code = 'CLEARED'
UNION ALL
select 'NEXT STUB', min(tqueue_id) from tqstubs
UNION ALL
select 'LAST STUB', max(tqueue_id) from tqstubs
UNION ALL
select 'TPS', count(*)/15 from tqueue where status_code = 'CLEARED' and UPDATE_TS >= (SYSDATE - (1/24/60/4))

select * from tqstubs

select * from event order by event_id desc

SELECT ROWIDTOCHAR(ROWID) XROWID, TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS  FROM TQSTUBS
WHERE TQUEUE_ID > 0
AND BATCH_ID < 1 OR BATCH_ID IS NULL
AND BATCH_TS IS NULL
ORDER BY TQUEUE_ID, ACCOUNT_ID





select * from event order by event_id desc

select 'ACCOUNTS', count(*) from account
UNION ALL
select 'SECURITIES', count(*) from security
UNION ALL
select 'TRADES', count(*) from tqueue
UNION ALL
select 'STUBS', count(*) from tqstubs
UNION ALL
select '--------->' || status_code, count(*) from tqueue group by status_code
UNION ALL
select 'LAST TQ', max(tqueue_id) from tqueue where status_code = 'CLEARED'




select * from event order by event_id 

select ACCOUNT_ID, COUNT(*) from tqueue where status_code = 'CLEARED'  GROUP BY ACCOUNT_ID ORDER BY COUNT(*) DESC

select * from tqueue where status_code = 'CLEARED' ORDER BY TQUEUE_ID

select max(tqueue_id) from tqueue where status_code = 'CLEARED'



select * from tqueue where status_code = 'PENDING' ORDER BY TQUEUE_ID, ACCOUNT_DISPLAY_NAME

/*
72901 0200000022080000  PENDING 1478BA1EB604D6B4E050007F0101551B  1478BA1D8E20D6B4E050007F0101551B
72902 0200000022080000  PENDING 1478BA1DA14CD6B4E050007F0101551B  1478BA1D8E20D6B4E050007F0101551B
72903 0200000022080000  PENDING 1478BA1EA6D0D6B4E050007F0101551B  1478BA1D8E20D6B4E050007F0101551B
72904 0200000022080000  PENDING 1478BA1E6CE7D6B4E050007F0101551B  1478BA1D8E20D6B4E050007F0101551B
*/

select * from tqstubs

SELECT ROWIDTOCHAR(ROWID) XROWID, TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS  FROM TQSTUBS
WHERE TQUEUE_ID > 0
AND BATCH_ID < 1 OR BATCH_ID IS NULL
AND BATCH_TS IS NULL
ORDER BY TQUEUE_ID, ACCOUNT_ID







DECLARE
  batches TQBATCH_ARR;
  trades TQTRADE_ARR;
  now DATE := SYSDATE;
  stubsBefore INT := 0;
  stubsAfter INT := 0;
  lastProcessed INT := 0;
  TYPE LOCK_TAB IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;  
  lockName VARCHAR2(200);
  allLocks LOCK_TAB := NEW LOCK_TAB;
  lockIndex PLS_INTEGER := 0;
BEGIN
  EXECUTE IMMEDIATE 'truncate table event';
  WHILE(lastProcessed > -1) LOOP
    SELECT TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,STUBS ) 
      BULK COLLECT INTO batches
      FROM TABLE(TQV.QUERYTBATCHES(lastProcessed, 1000, 1000))    -- STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10
      ORDER BY FIRST_T;
    IF batches IS NULL OR batches.COUNT = 0 THEN 
      lastProcessed := -1;
      EXIT;
    END IF;
    --DBMS_OUTPUT.put_line('FOUND ' || batches.COUNT || ' BATCHES');
    TQV.LOCKBATCHES(batches);
    --DBMS_OUTPUT.put_line('LOCKED ' || batches.COUNT || ' BATCHES');
    FOR i in 1..batches.COUNT LOOP
      INSERT INTO READYTQBATCH VALUES(batches(i));
      /*
      TQV.RELOCKBATCH(batches(i));
      --DBMS_OUTPUT.put_line('RELOCKED BATCH#' || i);
      stubsBefore := batches(i).ROWIDS.COUNT;    
      trades := TQV.STARTBATCH(batches(i));
      stubsAfter := batches(i).ROWIDS.COUNT;        
      IF stubsBefore != stubsAfter THEN      
        LOGEVENT('POST-START STUBS DROPS:  before:' || stubsBefore || ', after:' || stubsAfter );
      END IF;
      --DBMS_OUTPUT.put_line('LOCKED ' || trades.COUNT || ' TRADES, EXPECTED: ' || batches(i).STUBS.COUNT);
      now := SYSDATE;
      FOR x in 1..trades.COUNT LOOP
        trades(x).STATUS_CODE := 'CLEARED';
        trades(x).UPDATE_TS :=  now;
      END LOOP;
      TQV.SAVETRADES(trades, batches(i).BATCH_ID);  
      TQV.FINISHBATCH(batches(i).ROWIDS);
      */
      lastProcessed := batches(i).LAST_T;
      DBMS_OUTPUT.put_line('Last Proc:' || lastProcessed);
      DBMS_LOCK.ALLOCATE_UNIQUE ('TQBATCHLOCK#' || batches(i).BATCH_ID, lockName);
      lockIndex := lockIndex +1;
      allLocks(lockIndex) := lockName;
      
      COMMIT;
    END LOOP;
    LOGEVENT('CREATED ' || lockIndex || ' LOCKS');
  END LOOP;
END;
