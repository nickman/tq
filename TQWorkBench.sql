SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

   -- select count(*) from tqueue
/*

begin 
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100); 
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100);
  DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100);
end;  

*/

ALTER SYSTEM SET "JOB_QUEUE_PROCESSES"=500
select * from v$parameter where name like '%job%'

select * from dba_jobs_running 

SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

truncate table tqueue;
truncate table event;
truncate table tqstubs;

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event


SELECT dbms_change_notification.cq_notification_queryid
FROM dual

BEGIN
  DBMS_DDL.alter_compile('PACKAGE', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PROCEDURE', 'TQREACTOR', 'TQUEUE_INSERT_CALLBACK');
END;

select * from tqueue order by tqueue_id desc
select * from tqstubs

select * from event order by ts desc
select distinct event from event

select event, count(*) from event group by event
 

DECLARE
  ixid RAW(8);
  TXID VARCHAR2(200);
  RID ROWID;
BEGIN
  TXID := DBMS_TRANSACTION.local_transaction_id(TRUE);
  SELECT XID INTO ixid from V$TRANSACTION where xidusn || '.' || xidslot || '.' || xidsqn = TXID;
  FOR i in 1..100 LOOP
  INSERT INTO TQUEUE VALUES(SEQ_TQUEUE_ID.NEXTVAL, 'PENDING', 'b346652a-5194-41a1-a3ef-ac73af8d7548',
    '3b6d54cc-9bf5-40ed-966d-b0a4dbd1f7a2', NULL, NULL, NULL, NULL, SYSDATE, NULL, NULL) 
    RETURNING ROWID INTO RID;
  INSERT INTO TQXIDS VALUES (RID, ixid);
    
  END LOOP;
    COMMIT;
END;



BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (301);
END;

SELECT queryid, regid, TO_CHAR(querytext)
   FROM user_cq_notification_queries


declare
  mask NUMBER := -1;
BEGIN
  mask := DBMS_CQ_NOTIFICATION.QOS_QUERY + DBMS_CQ_NOTIFICATION.QOS_RELIABLE +  DBMS_CQ_NOTIFICATION.QOS_ROWIDS;
  DBMS_OUTPUT.PUT_LINE('MASK:' || mask);
END;


select (DBMS_CQ_NOTIFICATION.QOS_QUERY + DBMS_CQ_NOTIFICATION.QOS_RELIABLE +  DBMS_CQ_NOTIFICATION.QOS_ROWIDS) from dual

desc DBMS_CQ_NOTIFICATION

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

declare
  n boolean := true;
  x varchar2(200);
begin
  x := DBMS_TRANSACTION.LOCAL_TRANSACTION_ID(n);
  dbms_output.put_line('TX:' || x);
  commit;
end;

truncate table tqueue;
truncate table event;
truncate table tqstubs;
truncate table TQXIDS;

SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event



BEGIN
  DBMS_DDL.alter_compile('PACKAGE', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PACKAGE BODY', 'TQREACTOR', 'TQV');
  DBMS_DDL.alter_compile('PROCEDURE', 'TQREACTOR', 'TQUEUE_INSERT_CALLBACK');
  EXECUTE IMMEDIATE 'truncate table tqueue';
  EXECUTE IMMEDIATE 'truncate table event';
  EXECUTE IMMEDIATE 'truncate table tqstubs';
END;

select * from tqueue order by tqueue_id desc
select * from tqstubs

select * from event order by ts desc
select distinct event from event

-- 0 -- HandleInserts: Batch Overflow on TX:03000600F9070000
select * from TQXIDS

select event, count(*) from event group by event

BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (2);
END;

 


select * from tqxids


/*

select * FROM TABLE(NEW ACCT_DECODE_ARR(TQV.RANDOMACCT))
select * FROM TABLE(NEW SEC_DECODE_ARR(TQV.RANDOMSEC))
select count(*) from table(TQV.PIPEACCTCACHE)
select * from table(TQV.PIPEACCTCACHE)
select count(*) from table(TQV.PIPESECCACHE)
select * from table(TQV.PIPESECCACHE)
*/

SELECT TQV.FORCELOADCACHE FROM DUAL


BEGIN
  EXECUTE IMMEDIATE 'truncate table TQUEUE';
  EXECUTE IMMEDIATE 'truncate table EVENT';
  EXECUTE IMMEDIATE 'truncate table TQSTUBS';
  FOR i in 1..3 LOOP
    TQV.GENTRADES;
    COMMIT;
  END LOOP;
END;  

select * from v$transaction
select * from TQUEUE

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event

select * from event order by ts desc


select ACCOUNT, TCOUNT, FIRST_T, LAST_T, BATCH_ID, TQV.STUBTOSTR(TRADES) from TQBATCHOV

DECLARE
  batches TQBATCH_ARR;
BEGIN
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0)) 
  ORDER BY FIRST_T;
  TQV.LOCKBATCHES(batches);
END;



select account, tcount, first_t, last_t, batch_id, TQV.STUBTOSTR(TRADES) from TABLE(TQV.QUERYTBATCHES()) ORDER BY FIRST_T 

select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) FROM TABLE(TQV.QUERYTBATCHES(0, 10)) ORDER BY FIRST_T 

DECLARE
  batches TQBATCH_ARR;
BEGIN
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0)) 
  ORDER BY FIRST_T;
  TQV.LOCKBATCHES(batches);
END;


BEGIN
  TQV.GENACCTS;
  COMMIT;
  TQV.GENSECS;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE(TQV.FORCELOADCACHE);
  FOR i in 1..100 LOOP
    TQV.GENTRADES;
  END LOOP;
END;




DECLARE
  batches TQBATCH_ARR;
  batch TQBATCH;
  trades TQTRADE_ARR;
  trade TQTRADE;
  now DATE := SYSDATE;
BEGIN
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0)) 
  ORDER BY FIRST_T;
  DBMS_OUTPUT.put_line('FOUND ' || batches.COUNT || ' BATCHES');
  TQV.LOCKBATCHES(batches);
  DBMS_OUTPUT.put_line('LOCKED ' || batches.COUNT || ' BATCHES');
  FOR i in 1..batches.COUNT LOOP
    batch := batches(i);    
    TQV.RELOCKBATCH(batch);
    DBMS_OUTPUT.put_line('RELOCKED BATCH#' || i);
    trades := TQV.STARTBATCH(batch);
    now := SYSDATE;
    FOR x in 1..trades.COUNT LOOP
      trade := trades(x);
      trade.STATUS_CODE := 'CLEARED';
      trade.UPDATE_TS :=  now;
    END LOOP;
    TQV.SAVETRADES(trades);  
    TQV.FINISHBATCH(batch.ROWIDS);
    COMMIT;
  END LOOP;
END;


DECLARE
  batches TQBATCH_ARR;
  batch TQBATCH;
  trades TQTRADE_ARR;
  now DATE := SYSDATE;
  stubCount int;
BEGIN
  EXECUTE IMMEDIATE 'truncate table event';
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0,100,10)) 
  ORDER BY FIRST_T;
  --DBMS_OUTPUT.put_line('FOUND ' || batches.COUNT || ' BATCHES');
  TQV.LOCKBATCHES(batches);
  --DBMS_OUTPUT.put_line('LOCKED ' || batches.COUNT || ' BATCHES');
  FOR i in 1..batches.COUNT LOOP
    batch := batches(i);    
    stubCount := batch.TRADES.COUNT;
    TQV.RELOCKBATCH(batch);
    --DBMS_OUTPUT.put_line('BATCH#' || i || ' RELOCK: b:' || stubCount || ', a:' || batch.TRADES.COUNT );
    IF (stubCount != batch.TRADES.COUNT) THEN 
      DBMS_OUTPUT.put_line('BATCH#' || i || ' LOST TRADES ON RELOCK: b:' || stubCount || ', a:' || batch.TRADES.COUNT );
    END IF;
    
    trades := TQV.STARTBATCH(batch);
    --DBMS_OUTPUT.put_line('BATCH#' || i || ' has [' || trades.COUNT || '] trades');
    now := SYSDATE;
    FOR x in 1..trades.COUNT LOOP
      trades(x).STATUS_CODE := 'CLEARED';
      trades(x).UPDATE_TS :=  now;
      trades(x).ERROR_MESSAGE := NULL;
      --TQV.LOGEVENT('UPDATED STATUS --> [' || trades(x).STATUS_CODE || '] for TRADE [' || trades(x).TQUEUE_ID || ']');
    END LOOP;
    TQV.SAVETRADES(trades);  
    TQV.FINISHBATCH(batch.ROWIDS);
    COMMIT;
  END LOOP;
END;


select STATUS_CODE, count(*) from TQUEUE group by STATUS_CODE

--  88979

select 'TQUEUE', count(*) from tqueue
UNION ALL
select 'TQSTUBS', count(*) from tqstubs
UNION ALL
select 'EVENTS', count(*) from event
UNION ALL
select 'PENDING', count(*) from TQUEUE where status_code = 'PENDING'
UNION ALL
select 'CLEARED', count(*) from TQUEUE where status_code = 'CLEARED'


select * from event order by event_id desc

select * from TQUEUE where TQUEUE_ID = 10230

select MAX(TQUEUE_ID) from TQSTUBS

truncate table event


SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (6);
END;

SELECT * FROM TABLE(TQV.BVDECODE(BIN_TO_NUM(1,2,8)))


create or replace TYPE INT_ARR FORCE IS TABLE OF INT;


  DECLARE
  batches TQBATCH_ARR;
  batch TQBATCH;
  trades TQTRADE_ARR;
  now DATE := SYSDATE;
  stubCount int;
BEGIN
  EXECUTE IMMEDIATE 'truncate table event';
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0,100,10)) 
  ORDER BY FIRST_T;
  --DBMS_OUTPUT.put_line('FOUND ' || batches.COUNT || ' BATCHES');
  TQV.LOCKBATCHES(batches);
  --DBMS_OUTPUT.put_line('LOCKED ' || batches.COUNT || ' BATCHES');
  FOR i in 1..batches.COUNT LOOP
    batch := batches(i);    
    stubCount := batch.TRADES.COUNT;
    TQV.RELOCKBATCH(batch);
    --DBMS_OUTPUT.put_line('BATCH#' || i || ' RELOCK: b:' || stubCount || ', a:' || batch.TRADES.COUNT );
    IF (stubCount != batch.TRADES.COUNT) THEN 
      DBMS_OUTPUT.put_line('BATCH#' || i || ' LOST TRADES ON RELOCK: b:' || stubCount || ', a:' || batch.TRADES.COUNT );
    END IF;
    
    trades := TQV.STARTBATCH(batch);
    --DBMS_OUTPUT.put_line('BATCH#' || i || ' has [' || trades.COUNT || '] trades');
    now := SYSDATE;
    FOR x in 1..trades.COUNT LOOP
      trades(x).STATUS_CODE := 'CLEARED';
      trades(x).UPDATE_TS :=  now;
      trades(x).ERROR_MESSAGE := NULL;
      --TQV.LOGEVENT('UPDATED STATUS --> [' || trades(x).STATUS_CODE || '] for TRADE [' || trades(x).TQUEUE_ID || ']');
    END LOOP;
    TQV.SAVETRADES(trades);  
    TQV.FINISHBATCH(batch.ROWIDS);
    COMMIT;
  END LOOP;
END;




/*
SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries
SELECT * FROM dba_cq_notification_queries
SELECT * FROM dba_change_notification_regs

BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (139);
END;

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
    DBMS_CQ_NOTIFICATION.INSERTOP +           -- Specifies INSERT Ops  (DBMS_CQ_NOTIFICATION.ALL_OPERATIONS)
      DBMS_CQ_NOTIFICATION.UPDATEOP + 
      DBMS_CQ_NOTIFICATION.DELETEOP,
    0                                         -- Ignored for query result change notification 
  );

  regid := DBMS_CQ_NOTIFICATION.new_reg_start(reginfo);

  OPEN v_cursor FOR
    SELECT DBMS_CQ_NOTIFICATION.CQ_NOTIFICATION_QUERYID, ROWID FROM TQUEUE
    WHERE STATUS_CODE IN ('PENDING', 'ENRICH', 'RETRY');
  CLOSE v_cursor;
  DBMS_CQ_NOTIFICATION.REG_END;
  COMMIT;
  --DBMS_CQ_NOTIFICATION.SET_ROWID_THRESHOLD('TQREACTOR.TQUEUE', 100);
END;
/

BEGIN
  DBMS_CQ_NOTIFICATION.SET_ROWID_THRESHOLD('TQREACTOR.TQUEUE', 100);
END;


*/

BEGIN  
  EXECUTE IMMEDIATE 'truncate table account';
  EXECUTE IMMEDIATE 'truncate table security';
  EXECUTE IMMEDIATE 'truncate table tqueue';
  EXECUTE IMMEDIATE 'truncate table event';
  TQV.GENACCTS(10);
  COMMIT;
  TQV.GENSECS(100);
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TQV.FORCELOADCACHE);
  --FOR i in 1..100 LOOP
    TQV.GENTRADES(10);
  --END LOOP;
  COMMIT;
END;

BEGIN  
  /*
  TQV.GENACCTS(10);
  COMMIT;
  TQV.GENSECS(100);
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TQV.FORCELOADCACHE);
  */
  
  --FOR i in 1..100 LOOP
    TQV.GENTRADES(1000);
  --END LOOP;
  COMMIT;
END;



begin
  update tqueue set status_code = 'CLEARED' where rownum < 100;
  --delete from tqueue where rownum < 100;
  commit;
end;  


select * from event order by event_id desc

truncate table event

select 'ACCOUNTS', count(*) from account
UNION ALL
select 'SECURITIES', count(*) from security
UNION ALL
select 'TRADES', count(*) from tqueue
UNION ALL
select 'STUBS', count(*) from tqstubs



DECLARE
TYPE strings_nt 
IS TABLE OF VARCHAR2(100);
my_favorites strings_nt;
dad_favorites strings_nt;
our_favorites 
strings_nt := strings_nt ();

BEGIN

my_favorites 
:= strings_nt ('CHOCOLATE'
, 'BRUSSEL SPROUTS'
, 'SPIDER ROLL'
);

dad_favorites 
:= strings_nt ('PICKLED HERRING' 
, 'POTATOES'
, 'PASTRAMI'
, 'CHOCOLATE'
);

our_favorites := 
my_favorites 
MULTISET UNION 
dad_favorites;

my_favorites := our_favorites;

FOR i in my_favorites.first..my_favorites.last
LOOP
DBMS_OUTPUT.PUT_LINE ( i || '->' || my_favorites(i));
END LOOP;
END;


BEGIN
  EXECUTE IMMEDIATE 'truncate table tqueue';
  EXECUTE IMMEDIATE 'truncate table event';
  COMMIT;
  
  TESTDATA.GENACCTS(10);
  COMMIT;
  TESTDATA.GENSECS(100);
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TESTDATA.FORCELOADCACHE);
  
  
  --FOR i in 1..100 LOOP
    TESTDATA.GENTRADES(1000);
  --END LOOP;
  COMMIT;
END;

select * from event order by event_id desc

select 'ACCOUNTS', count(*) from account
UNION ALL
select 'SECURITIES', count(*) from security
UNION ALL
select 'TRADES', count(*) from tqueue
UNION ALL
select 'STUBS', count(*) from tqstubs




Begin  
  Execute Immediate 'truncate table event';
  Execute Immediate 'truncate table tqueue';
  Execute Immediate 'truncate table tqstubs';
  /*
  TQV.GENACCTS(10);
  COMMIT;
  TQV.GENSECS(100);
  COMMIT;  
  DBMS_OUTPUT.PUT_LINE(TQV.FORCELOADCACHE);
  */
  
  --FOR i in 1..100 LOOP
    Testdata.Gentrades(100);
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



DECLARE
  batches TQBATCH_ARR;
  trades TQTRADE_ARR;
  now DATE := SYSDATE;
BEGIN
  EXECUTE IMMEDIATE 'truncate table event';
  select TQBATCH(ACCOUNT,TCOUNT,FIRST_T,LAST_T,BATCH_ID,ROWIDS,TRADES ) 
  BULK COLLECT INTO batches
  FROM TABLE(TQV.QUERYTBATCHES(0, 100, 5))    -- STARTING_ID IN INT DEFAULT 0, MAX_ROWS IN INT DEFAULT 5000, MAX_BATCH_SIZE IN INT DEFAULT 10
  ORDER BY FIRST_T;
  DBMS_OUTPUT.put_line('FOUND ' || batches.COUNT || ' BATCHES');
  TQV.LOCKBATCHES(batches);
  DBMS_OUTPUT.put_line('LOCKED ' || batches.COUNT || ' BATCHES');
  FOR i in 1..batches.COUNT LOOP
    TQV.RELOCKBATCH(batches(i));
    --DBMS_OUTPUT.put_line('RELOCKED BATCH#' || i);
    trades := TQV.STARTBATCH(batches(i));
    DBMS_OUTPUT.put_line('LOCKED ' || trades.COUNT || ' TRADES, EXPECTED: ' || batches(i).TRADES.COUNT);
    now := SYSDATE;
    FOR x in 1..trades.COUNT LOOP
      trades(x).STATUS_CODE := 'CLEARED';
      trades(x).UPDATE_TS :=  now;
    END LOOP;
    TQV.SAVETRADES(trades, batches(i).BATCH_ID);  
    TQV.FINISHBATCH(batches(i).ROWIDS);
    COMMIT;
  END LOOP;
END;

select * from event order by event_id desc

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


==========================================================================

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQSTUBS', estimate_percent => 100);
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'TQUEUE', estimate_percent => 100);
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'ACCOUNT', estimate_percent => 100);
    DBMS_STATS.GATHER_TABLE_STATS (ownname => 'TQREACTOR', tabname => 'SECURITY', estimate_percent => 100);
END;


select * from rc;

DECLARE
  q VARCHAR2(2000);
BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE(module_name => 'TQProcessor', action_name => 'NextBatch');
  DBMS_SESSION.SESSION_TRACE_ENABLE(waits => true, binds => true, plan_stat => 'ALL_EXECUTIONS'); 
  SELECT VALUE(T).TOV() INTO q  FROM TABLE(TQ.GROUP_BATCH_STUBS(TQ.MAKE_SPEC(1, 1, 128))) T ORDER BY T.FIRST_T;
  DBMS_OUTPUT.PUT_LINE(q);
  DBMS_APPLICATION_INFO.SET_MODULE(module_name => null, action_name => null);
  DBMS_SESSION.SESSION_TRACE_DISABLE();
END;

                   
select tracefile from v$process where addr=(
  select paddr from v$session where sid = TQ.MYSID()
)


MODS !!!

final int MOD = 35;
final int TCOUNT = 16;

mod = {v, x ->
    return v%x;
}



for(t in 0..TCOUNT-1) {
    b = new StringBuilder("THREAD: $t\n\t");
    for(i in 0..MOD-1) {
        xmod = mod(i,TCOUNT);
        if(xmod==t) {
            b.append(i).append(",");
        }
    }
    b.deleteCharAt(b.length()-1);
    println b.toString();
}


DECLARE 
  a INT_ARR;
  l_start NUMBER;
  l_loops NUMBER := 1000;
  elapsed NUMBER;
  per NUMBER;
BEGIN
  l_start := DBMS_UTILITY.get_time;
  FOR x IN 1..l_loops LOOP
    FOR t IN 0..11 LOOP
      SELECT TQ.GET_ACCOUNT_BUCKET_MODS(t, 12) INTO a FROM DUAL;
      --DBMS_OUTPUT.PUT_LINE('T: [' || t || ']:' || TQ.TOSTR(a));
    END LOOP;
  END LOOP;
  elapsed := DBMS_UTILITY.get_time - l_start;
  per := elapsed/l_loops;
  DBMS_OUTPUT.PUT_LINE('Elapsed: ' || elapsed || ' hsecs. Per Call:' || per || ' hsecs per call');
END;

declare
  stub TQBATCH;
  trades TQUEUE_OBJ_ARR;
begin
  select value(T) into stub FROM TABLE(TQ.GROUP_BATCH_STUBS(TQ.MAKE_SPEC(1,4,10,10))) T ORDER BY T.FIRST_T;
  DBMS_OUTPUT.PUT_LINE('BATCH [' || stub.ROWIDS.COUNT || ']:' || stub.TOV());
  trades := tq.GET_TRADE_BATCH(stub.TQROWIDS);
  DBMS_OUTPUT.PUT_LINE('ACQUIRED AND LOCKED [' || trades.COUNT || '] TRADES');
  for i in 1..trades.count loop
    DBMS_OUTPUT.PUT_LINE(trades(i).XROWID);
  end loop;
end;


