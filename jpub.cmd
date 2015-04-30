@echo off
set JAVA_HOME=c:\java\jdk1.7.0_40_X64
set ORACLE_HOME=c:\oracle\app\nwhitehe\product\11.2.0\dbhome_1
set JPUB_LIBS=c:\libs\java\oracle\jpub
set CLASSPATH=%JPUB_LIBS%\ojdbc6.jar;%JPUB_LIBS%\translator.jar;%JPUB_LIBS%\runtime12.jar
set CLASS_DIR=c:\hprojects\tq\src\main\java
set PACKAGE=tqueue.db.types
set TYPES=TQSTUB,TQSTUB_ARR,TQBATCH_ARR,TQBATCH,TQTRADE,TQTRADE_ARR,XROWIDS
set JURL=jdbc:oracle:thin:@//localhost:1521/ORCL
echo %CLASSPATH%
%JAVA_HOME%\bin\java.exe oracle.jpub.Doit -url=%JURL% -user=tqreactor/tq -dir=%CLASS_DIR% -numbertypes=jdbc -builtintypes=jdbc -package=%PACKAGE% -case=mixed -serializable=true -tostring=true -compile=true -sql=%TYPES%
