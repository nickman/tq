SELECT queryid, regid, TO_CHAR(querytext) FROM user_cq_notification_queries

BEGIN
  DBMS_CQ_NOTIFICATION.DEREGISTER (6);
END;
