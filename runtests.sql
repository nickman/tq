
Begin  
  Execute Immediate 'truncate table event';
  Execute Immediate 'truncate table tqueue';
  Execute Immediate 'truncate table tqstubs';
  /*  
  TESTDATA.GENACCTS();
  COMMIT;
  TESTDATA.GENSECS();
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TESTDATA.FORCELOADCACHE);
  */
  --FOR i in 1..100 LOOP
    Testdata.Gentrades(10000);
  --END LOOP;
  Commit;
End;


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
