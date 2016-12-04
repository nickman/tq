create or replace PACKAGE LOGGING authid definer AS 
  TYPE SOCKET IS TABLE OF utl_tcp.connection INDEX BY VARCHAR2(100);
  procedure tcplog(message IN VARCHAR2, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 1234);
END LOGGING;

create or replace PACKAGE BODY LOGGING AS

  /* An associative array of connections keyed by host:port */
  sockets SOCKET;
  /* The SID of the current session */
  sid NUMBER;


  /* Disconnects the keyed connection */
  PROCEDURE DISCONNECT(key IN VARCHAR2) AS
  BEGIN
    IF sockets.EXISTS(key) THEN 
      BEGIN
        utl_tcp.close_connection(sockets(key));    
        EXCEPTION WHEN OTHERS THEN NULL;  
      END;
      sockets.DELETE(key);
    END IF;  
  END DISCONNECT;
  
  /* Disconnects the specified connection */
  PROCEDURE DISCONNECT(host IN VARCHAR2, port IN PLS_INTEGER) AS
    key VARCHAR2(100) := LOWER(LTRIM(RTRIM(host))) || ':' || port; 
  BEGIN
    DISCONNECT(key);
  END DISCONNECT;
  

  /* Returns a connection to the specified host/port or null if connection fails */
  FUNCTION TCPCONNECT(host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 1234) RETURN utl_tcp.connection AS
    c  utl_tcp.connection;
    key VARCHAR2(100) := LOWER(LTRIM(RTRIM(host))) || ':' || port;
  BEGIN
    IF sockets.EXISTS(key) THEN RETURN sockets(key); END IF;  
    c := utl_tcp.open_connection(remote_host => host,remote_port =>  port,  charset     => 'US7ASCII');  -- open connection
    sockets(key) := c;
    RETURN c;    
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(key);
      RETURN NULL;
  END TCPCONNECT;
  
  PROCEDURE TLOG(ts IN TIMESTAMP, sid IN NUMBER, message IN VARCHAR2) IS 
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO OFFLINE_LOGS(TS, SID, MESSAGE) VALUES (:1, :2, :3)' USING ts, sid, message;
    COMMIT;
  END TLOG;

  procedure tcplog(message IN VARCHAR2, host IN VARCHAR2 DEFAULT 'localhost', port IN PLS_INTEGER DEFAULT 1234) AS
    ret_val pls_integer; 
    ts VARCHAR2(22) := NULL;
    c  utl_tcp.connection;
  BEGIN
    c := TCPCONNECT(host, port);
    IF(c.remote_port IS NOT NULL) THEN
      ts := TO_CHAR(SYSTIMESTAMP,'YY/MM/DD HH24:MI:SS,FF3');
      ret_val := utl_tcp.write_line(c, ts || ': [' || sid || '/' || c.private_sd || ']:' || message);       
    ELSE
      TLOG(SYSTIMESTAMP, sid, message);
    END IF;
    EXCEPTION WHEN OTHERS THEN
      DISCONNECT(host, port);    
      TLOG(SYSTIMESTAMP, sid, message);        
  END tcplog;
  
  PROCEDURE INIT_TABLE IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE OFFLINE_LOGS(TS TIMESTAMP NOT NULL, SID NUMBER NOT NULL, MESSAGE VARCHAR2(4000))';    
    EXCEPTION WHEN OTHERS THEN NULL;
  END INIT_TABLE;
  

  BEGIN
    SELECT SYS_CONTEXT('USERENV', 'SID') INTO sid FROM DUAL;    
    INIT_TABLE;
END LOGGING;

grant execute on LOGGING to public;

create public synonym LOGGING for LOGGING;
  