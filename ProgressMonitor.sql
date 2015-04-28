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
UNION ALL
select 'TPS',  count(*)/15 TPS from tqueue where status_code = 'CLEARED' and UPDATE_TS >= SYSDATE - (1/24/60/4)


select * from tqueue where status_code = 'PENDING' order by XID

select security_type, count(*) from security where security_display_name in (
	select distinct security_display_name from tqueue where status_code = 'PENDING'
) group by security_type

select security_type, count(*) from security group by security_type


select XID, COUNT(*) from tqueue where status_code = 'PENDING' group by XID