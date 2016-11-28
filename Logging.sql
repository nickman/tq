create or replace PACKAGE LOGGING authid current_user AS 
  c  utl_tcp.connection;  -- TCP/IP connection to the Web server
  procedure tcplog(message IN VARCHAR2);

END LOGGING;

create or replace PACKAGE BODY LOGGING AS
  

  procedure tcplog(message IN VARCHAR2) AS
    ret_val pls_integer; 
  BEGIN
    IF(c.remote_port = -1) THEN
      c := utl_tcp.open_connection(remote_host => '127.0.0.1',remote_port =>  1234,  charset     => 'US7ASCII');  -- open connection
    END IF;
    ret_val := utl_tcp.write_line(c, message);       
    EXCEPTION WHEN OTHERS THEN
          BEGIN            
              utl_tcp.close_connection(c);
              c := NULL;
              EXCEPTION WHEN OTHERS THEN
                c := NULL;
          END;
          
  END tcplog;

  BEGIN
    c.remote_port := -1;
END LOGGING;