  --====================================================================================================
  -- Converts the results from the passed SQL query to an array of metrics
  -- Doc needed
  --====================================================================================================
  FUNCTION QUERYTOMETRICS(query IN VARCHAR2) RETURN METRIC_ARR IS
    cntr PLS_INTEGER := 0;
    pout RCUR;
    cursor_name NUMBER;
    rows_processed INTEGER;    
    desctab  DBMS_SQL.DESC_TAB2;
    colcnt   NUMBER;   
    colnum INT;
    hasTs BOOLEAN;
    tId PLS_INTEGER := 3;
    tagCount PLS_INTEGER;
    met METRIC := NULL;
    metrics METRIC_ARR := METRIC_ARR();
    metName VARCHAR2(100);
    metValue NUMBER;
    tagK VARCHAR2(100);
    tagV VARCHAR2(100);
    rowsFetched PLS_INTEGER := 0;
    execRows PLS_INTEGER := 0;
    ads anydataset;
  BEGIN
    cursor_name := dbms_sql.open_cursor(1);
    DBMS_SQL.PARSE(cursor_name, query, DBMS_SQL.NATIVE);
    --cursor_name := DBMS_SQL.TO_CURSOR_NUMBER(pout);    
    DBMS_SQL.DESCRIBE_COLUMNS2(cursor_name, colcnt, desctab);
    IF(colcnt < 2) THEN
      RETURN metrics;
    END IF;
    hasTs := MOD(colcnt, 2) != 0;
    IF(hasTs) THEN
      tagCount := (colcnt - 3) / 2;
    ELSE
      tagCount := (colcnt - 2) / 2;
    END IF;
    DBMS_SQL.DEFINE_COLUMN(cursor_name, 1, metValue); 
    DBMS_SQL.DEFINE_COLUMN(cursor_name, 2, metName, 100); 
    FOR i IN 1..tagCount LOOP
      DBMS_SQL.DEFINE_COLUMN(cursor_name, tId, tagK, 100);
      tId := tId + 1;
      DBMS_SQL.DEFINE_COLUMN(cursor_name, tId, tagV, 100);
      tId := tId + 1;
    END LOOP;
    tId := 3;
    colnum := desctab.first;
    rowsFetched := DBMS_SQL.EXECUTE(cursor_name);
    LOOP      
      rowsFetched := DBMS_SQL.FETCH_ROWS(cursor_name);
      EXIT WHEN rowsFetched = 0;
      IF(rowsFetched > 0) THEN
        cntr := cntr + 1;        
        DBMS_SQL.COLUMN_VALUE(cursor_name, 1, metValue);        
        DBMS_SQL.COLUMN_VALUE(cursor_name, 2, metName);
        met := METRIC(metName).HOSTAPPTAGS().VAL(metValue);
        FOR i IN 1..tagCount LOOP
          --IF(met IS NOT NULL) THEN met := met.CLEARTAGS().HOSTAPPTAGS(); END IF;
          DBMS_SQL.COLUMN_VALUE(cursor_name, tId, tagK);
          tId := tId + 1;
          DBMS_SQL.COLUMN_VALUE(cursor_name, tId, tagV);
          tId := tId + 1;
          met := met.PUSHTAG(tagK, tagV);
        END LOOP;
        tId := 3;
        metrics.EXTEND();
        metrics(cntr) := met;
        --LOGGING.tcplog(met.JSONMS());
      END IF;
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(cursor_name);
    
--    EXCEPTION WHEN OTHERS THEN       
--      DECLARE
--        errm VARCHAR2(200) := SQLERRM();
--      BEGIN
--        LOGGING.tcplog('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
--        DBMS_OUTPUT.PUT_LINE('SQLTOMETRICS(REF CUR) ERROR: errm:' || errm || ', backtrace:' || dbms_utility.format_error_backtrace);
--        RAISE;                    
--      END;
      
      --NULL;
      RETURN metrics;
  END QUERYTOMETRICS;
  
