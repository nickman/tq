create or replace PACKAGE LOGGING authid definer AS 
  
  procedure tcplog(message IN VARCHAR2);

END LOGGING;

create or replace PACKAGE BODY LOGGING AS

sid NUMBER;
localPort PLS_INTEGER := -1;
c  utl_tcp.connection;

PROCEDURE DISCONNECT AS
BEGIN
  utl_tcp.close_connection(c);
  EXCEPTION WHEN OTHERS THEN NULL;
  c.remote_port := -1;
  localPort := -1;
END DISCONNECT;

PROCEDURE TCPCONNECT AS
BEGIN
  c := utl_tcp.open_connection(remote_host => '127.0.0.1',remote_port =>  1234,  charset     => 'US7ASCII');  -- open connection
  localPort := c.private_sd;
  EXCEPTION WHEN OTHERS THEN
    DISCONNECT();
END TCPCONNECT;

procedure tcplog(message IN VARCHAR2) AS
    ret_val pls_integer; 
    ts VARCHAR2(22);
  BEGIN
    IF(c.remote_port = -1) THEN
      TCPCONNECT();
    END IF;
    SELECT TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3') INTO ts FROM DUAL;
    ret_val := utl_tcp.write_line(c, ts || ', [' || sid || '/' || localPort || ']:' || message);       
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT();          
  END tcplog;

  BEGIN
    SELECT SYS_CONTEXT('USERENV', 'SID') INTO sid FROM DUAL;
    TCPCONNECT();
END LOGGING;