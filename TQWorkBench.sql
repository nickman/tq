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
