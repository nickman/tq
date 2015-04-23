create or replace PACKAGE BODY CQN_HELPER AS
  TYPE BINS IS VARRAY(8) OF BINARY_INTEGER;
--  
  QOS_DECODE BINARY_INTEGER_DECODE;
  EVENT_DECODE BINARY_INTEGER_DECODE;  
  OP_DECODE BINARY_INTEGER_DECODE;
  DOMAIN_DECODE BINARY_INTEGER_DECODE;
--
  QOS_NAMES NAME_DECODE;
  EVENT_NAMES NAME_DECODE;  
  OP_NAMES NAME_DECODE;
  DOMAIN_NAMES NAME_DECODE;
--
  BIN BINS;
--

  PROCEDURE LOADNAMES(decodes IN BINARY_INTEGER_DECODE, names IN OUT NAME_DECODE) IS  
  BEGIN
    FOR i in BIN.FIRST..BIN.LAST LOOP
      IF decodes.EXISTS(i) THEN 
        names(decodes(i)) := i; 
      END IF;
    END LOOP;
  END LOADNAMES;


  FUNCTION DECODE_NAMES(ndecode IN NAME_DECODE, names IN VARCHAR2_ARR) RETURN BINARY_INTEGER IS
    ind BINARY_INTEGER := 0;
    c VARCHAR2(30) := NULL;
  BEGIN
    IF names IS NULL OR names.COUNT=0 THEN
      RETURN ind;
    END IF;
    FOR i in 1..names.COUNT LOOP
      c := UPPER(LTRIM(RTRIM(names(i))));
      IF ndecode.EXISTS(c) THEN
        ind := ind + ndecode(c);
      END IF;
    END LOOP;
    RETURN ind;
  END DECODE_NAMES;
--  
  FUNCTION DECODE_ENUM(code IN NUMBER, enum in BINARY_INTEGER_DECODE) RETURN VARCHAR2_ARR IS
    decodes VARCHAR2_ARR := NEW VARCHAR2_ARR();
  BEGIN
    FOR i in BIN.FIRST..BIN.LAST LOOP
      IF enum.EXISTS(i) THEN
        IF (bitand(i, code) = i) THEN
          TQV.LOGEVENT('DECODING: code:' || code || ', index:' || i || ', bitand:' ||  bitand(i, code));
          decodes.extend();
          decodes(decodes.COUNT) := enum(i);
        END IF;
      END IF;
    END LOOP;
    RETURN decodes;
  END DECODE_ENUM;
--
  -- =============================================================
  --  Decodes the passed CQ EVENT code and returns 
  --  the name that corresponds to the code, or null
  --  if the code is not an EVENT
  -- =============================================================
  FUNCTION DECODE_EVENT(code IN NUMBER) RETURN VARCHAR2_ARR IS  
    c BINARY_INTEGER := code;
  BEGIN
    IF EVENT_DECODE.EXISTS(c) THEN
      RETURN NEW VARCHAR2_ARR(EVENT_DECODE(c));
    END IF;
    RETURN NULL;
  END DECODE_EVENT;
--
  -- =============================================================
  --  Decodes the passed CQ QOS code and returns 
  --  an array of the names of the enabled bit vectors
  -- =============================================================
  FUNCTION DECODE_QOS(code IN NUMBER) RETURN VARCHAR2_ARR IS  
  BEGIN    
    RETURN DECODE_ENUM(code, QOS_DECODE);
  END DECODE_QOS;
--
  -- =============================================================
  --  Decodes the passed CQ OP code and returns 
  --  an array of the names of the enabled bit vectors
  -- =============================================================
  FUNCTION DECODE_OP(code IN NUMBER) RETURN VARCHAR2_ARR IS  
  BEGIN
    RETURN DECODE_ENUM(code, OP_DECODE);
  END DECODE_OP;
--
  -- =============================================================
  --  Decodes the passed CQ DOMAIN code and returns 
  --  an array of the names of the enabled bit vectors
  -- =============================================================
  FUNCTION DECODE_DOMAIN(code IN NUMBER) RETURN VARCHAR2_ARR IS  
  BEGIN
    RETURN DECODE_ENUM(code, DOMAIN_DECODE);
  END DECODE_DOMAIN;

--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(names IN VARCHAR2_ARR) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, names);
  END;
--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(n IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, new VARCHAR2_ARR(n));
  END;
--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, new VARCHAR2_ARR(n1, n2));
  END;
--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, new VARCHAR2_ARR(n1, n2, n3));
  END;
--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4));
  END;
--
  -- =============================================================
  --  Returns the QOS bit mask for the passed names
  -- =============================================================
  FUNCTION QOS_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(QOS_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5));
  END;
  
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(names IN VARCHAR2_ARR) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, names);
  END;

--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2, n7 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6, n7));
  END;
--
  -- =============================================================
  --  Returns the OP bit mask for the passed names
  -- =============================================================
  FUNCTION OP_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2, n7 IN VARCHAR2, n8 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(OP_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6, n7, n8));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(names IN VARCHAR2_ARR) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, names);
  END;

--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2, n7 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6, n7));
  END;
--
  -- =============================================================
  --  Returns the DOMAIN bit mask for the passed names
  -- =============================================================
  FUNCTION DOMAIN_CODEFOR(n1 IN VARCHAR2, n2 IN VARCHAR2, n3 IN VARCHAR2, n4 IN VARCHAR2, n5 IN VARCHAR2, n6 IN VARCHAR2, n7 IN VARCHAR2, n8 IN VARCHAR2) RETURN BINARY_INTEGER IS
  BEGIN
    RETURN DECODE_NAMES(DOMAIN_NAMES, new VARCHAR2_ARR(n1, n2, n3, n4, n5, n6, n7, n8));
  END;  
--
  -- =============================================================
  --  Returns the EVENT code for the passed name
  -- =============================================================  
  FUNCTION EVENT_CODEFOR(names IN VARCHAR2) RETURN BINARY_INTEGER IS
    c VARCHAR2(30) := UPPER(LTRIM(RTRIM(names)));
  BEGIN
    IF EVENT_NAMES.EXISTS(c) THEN
      RETURN EVENT_NAMES(c);
    END IF;
    RETURN NULL;
  END;
  
  
--
  -- ==========================================
  -- Package Initialization
  -- ==========================================
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Initializing....');
    
    BIN := BINS(0,1,2,4,8,16,32,64);
    DBMS_OUTPUT.PUT_LINE('Initialized BIN:' || BIN.COUNT);
    


    
    QOS_DECODE(QOS_RELIABLE) :=     'QOS_RELIABLE';
    QOS_DECODE(QOS_DEREG_NFY) :=    'QOS_DEREG_NFY';
    QOS_DECODE(QOS_ROWIDS) :=       'QOS_ROWIDS';
    QOS_DECODE(QOS_QUERY) :=        'QOS_QUERY';
    QOS_DECODE(QOS_BEST_EFFORT) :=  'QOS_BEST_EFFORT';
    DBMS_OUTPUT.PUT_LINE('Initialized QOS:' || QOS_DECODE.COUNT);
--
		EVENT_DECODE(EVENT_NONE) := 'EVENT_NONE';
		EVENT_DECODE(EVENT_STARTUP) := 'EVENT_STARTUP';
		EVENT_DECODE(EVENT_SHUTDOWN) := 'EVENT_SHUTDOWN';
		EVENT_DECODE(EVENT_SHUTDOWN_ANY) := 'EVENT_SHUTDOWN_ANY';
		EVENT_DECODE(EVENT_DROP_DB) := 'EVENT_DROP_DB';
		EVENT_DECODE(EVENT_DEREG) := 'EVENT_DEREG';
		EVENT_DECODE(EVENT_OBJCHANGE) := 'EVENT_OBJCHANGE';
		EVENT_DECODE(EVENT_QUERYCHANGE) := 'EVENT_QUERYCHANGE';
    DBMS_OUTPUT.PUT_LINE('Initialized EVENT:' || EVENT_DECODE.COUNT);
--
		OP_DECODE(ALL_OPERATIONS) := 'ALL_OPERATIONS';
		OP_DECODE(ALL_ROWS) := 'ALL_ROWS';
		OP_DECODE(INSERTOP) := 'INSERTOP';
		OP_DECODE(UPDATEOP) := 'UPDATEOP';
		OP_DECODE(DELETEOP) := 'DELETEOP';
		OP_DECODE(ALTEROP) := 'ALTEROP';
		OP_DECODE(DROPOP) := 'DROPOP';
		OP_DECODE(UNKNOWNOP) := 'UNKNOWNOP';
    DBMS_OUTPUT.PUT_LINE('Initialized OP:' || OP_DECODE.COUNT);
--
		DOMAIN_DECODE(STRING_DOMAIN_SCHEMA) := 'DOMAIN_SCHEMA';
		DOMAIN_DECODE(STRING_DOMAIN_DATABASE) := 'DOMAIN_DATABASE';
		DOMAIN_DECODE(STRING_DOMAIN_TABLE) := 'DOMAIN_TABLE';
    DBMS_OUTPUT.PUT_LINE('Initialized DOMAIN:' || DOMAIN_DECODE.COUNT);

    LOADNAMES(QOS_DECODE, QOS_NAMES);
    LOADNAMES(EVENT_DECODE, EVENT_NAMES);
    LOADNAMES(OP_DECODE, OP_NAMES);
    LOADNAMES(DOMAIN_DECODE, DOMAIN_NAMES);



END CQN_HELPER;
/
