select 'ACCOUNTS', count(*) from account
UNION ALL
select 'SECURITIES', count(*) from security
UNION ALL
select 'TRADES', count(*) from tqueue
UNION ALL
select 'STUBS', count(*) from tqstubs
UNION ALL
select 'BATCHREFS', count(*) from tqbatches
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
select 'TPS(1S)', count(*) from tqueue where status_code = 'CLEARED' and UPDATE_TS >= (SYSDATE - (1/24/60/60))
UNION ALL
select 'TPS(15S)', count(*)/15 from tqueue where status_code = 'CLEARED' and UPDATE_TS >= (SYSDATE - (1/24/60/4))
UNION ALL
select 'TPS(1M)', count(*)/60 from tqueue where status_code = 'CLEARED' and UPDATE_TS >= (SYSDATE - (1/24/60))



select * from tqstubs

select * from event order by event_id desc

SELECT ROWIDTOCHAR(ROWID) XROWID, TQROWID, TQUEUE_ID, XID, SECURITY_ID, SECURITY_TYPE, ACCOUNT_ID, BATCH_ID, BATCH_TS  FROM TQSTUBS
WHERE TQUEUE_ID > 0
AND BATCH_ID < 1 OR BATCH_ID IS NULL
AND BATCH_TS IS NULL
ORDER BY TQUEUE_ID, ACCOUNT_ID



select * from TQBATCHES