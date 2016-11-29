/*@lineinfo:filename=TQBATCH*//*@lineinfo:user-code*//*@lineinfo:1^1*/package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;
import sqlj.runtime.ref.DefaultContext;
import sqlj.runtime.ConnectionContext;

public class TQBATCH implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQBATCH";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  /* connection management */
  protected Connection __onn = null;
  protected javax.sql.DataSource __dataSource = null;
  public void setDataSource(javax.sql.DataSource dataSource) throws SQLException
  { release(); __dataSource = dataSource; }
  public void setDataSourceLocation(String dataSourceLocation) throws SQLException {
    javax.sql.DataSource dataSource;
    try {
      Class cls = Class.forName("javax.naming.InitialContext");
      Object ctx = cls.newInstance();
      java.lang.reflect.Method meth = cls.getMethod("lookup", new Class[]{String.class});
      dataSource = (javax.sql.DataSource) meth.invoke(ctx, new Object[]{"java:comp/env/" + dataSourceLocation});
      setDataSource(dataSource);
    } catch (Exception e) {
      throw new java.sql.SQLException("Error initializing DataSource at " + dataSourceLocation + ": " + e.getMessage());
    }
  }
  public Connection getConnection() throws SQLException
  { 
    if (__onn!=null) return __onn;
     else if (__tx!=null) return __tx.getConnection(); 
     else if (__dataSource!=null) __onn= __dataSource.getConnection(); 
     return __onn; 
   } 
  public void release() throws SQLException
  { if (__tx!=null && __onn!=null) __tx.close(ConnectionContext.KEEP_CONNECTION);
    __onn = null; __tx = null;
    __dataSource = null;
  }

  public void closeConnection(){
    if (__dataSource!=null) {
      try { if (__onn!=null) { __onn.close(); } } catch (java.sql.SQLException e) {}
      try { if (__tx!=null) {__tx.close(); } } catch (java.sql.SQLException e) {}
      __onn=null;
      __tx=null;
    }
  }
  protected DefaultContext __tx = null;
  public void setConnectionContext(DefaultContext ctx) throws SQLException
  { release(); __tx = ctx; }
  public DefaultContext getConnectionContext() throws SQLException
  { if (__tx==null)
    { __tx = (getConnection()==null) ? DefaultContext.getDefaultContext() : new DefaultContext(getConnection()); }
    return __tx;
  };
  transient protected MutableStruct _struct;

  protected static int[] _sqlType =  { 4,4,4,4,4,2003,2003,2003 };
  protected static ORADataFactory[] _factory = new ORADataFactory[8];
  static
  {
    _factory[5] = XROWIDS.getORADataFactory();
    _factory[6] = XROWIDS.getORADataFactory();
    _factory[7] = TQSTUBS_OBJ_ARR.getORADataFactory();
  }
  protected static final TQBATCH _TQBATCHFactory = new TQBATCH();

  public static ORADataFactory getORADataFactory()
  { return _TQBATCHFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[8], _sqlType, _factory); }
  public TQBATCH()
  { _init_struct(true); __tx = DefaultContext.getDefaultContext(); }
  public TQBATCH(DefaultContext c) /*throws SQLException*/
  { _init_struct(true); __tx = c; }
  public TQBATCH(Connection c) /*throws SQLException*/
  { _init_struct(true); __onn = c; }
  public TQBATCH(int account, int tcount, int firstT, int lastT, int batchId, XROWIDS rowids, XROWIDS tqrowids, TQSTUBS_OBJ_ARR stubs) throws SQLException
  {
    _init_struct(true);
    setAccount(account);
    setTcount(tcount);
    setFirstT(firstT);
    setLastT(lastT);
    setBatchId(batchId);
    setRowids(rowids);
    setTqrowids(tqrowids);
    setStubs(stubs);
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    if (__tx!=null && __onn!=c) release();
    __onn = c;
    return _struct.toDatum(c, _SQL_NAME);
  }


  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  { return create(null, d, sqlType); }
  public void setFrom(TQBATCH o) throws SQLException
  { setContextFrom(o); setValueFrom(o); }
  protected void setContextFrom(TQBATCH o) throws SQLException
  { release(); __tx = o.__tx; __onn = o.__onn; }
  protected void setValueFrom(TQBATCH o) { _struct = o._struct; }
  protected ORAData create(TQBATCH o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) { if (o!=null) { o.release(); }; return null; }
    if (o == null) o = new TQBATCH();
    o._struct = new MutableStruct((STRUCT) d, _sqlType, _factory);
    o.__onn = ((STRUCT) d).getJavaSqlConnection();
    return o;
  }
  /* Serialization interface */
  public void restoreConnection(Connection conn) throws SQLException
  {     if (getRowids()!=null) getRowids().restoreConnection(conn);
    if (getTqrowids()!=null) getTqrowids().restoreConnection(conn);
    if (getStubs()!=null) getStubs().restoreConnection(conn);
  }
  private void writeObject(java.io.ObjectOutputStream oos)
          throws java.io.IOException, SQLException
  { oos.defaultWriteObject();
    oos.writeObject(getAccount());
    oos.writeObject(getTcount());
    oos.writeObject(getFirstT());
    oos.writeObject(getLastT());
    oos.writeObject(getBatchId());
    oos.writeObject(getRowids());
    oos.writeObject(getTqrowids());
    oos.writeObject(getStubs());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    Object[] o = new Object[8];
    o[0] = ois.readObject();
    o[1] = ois.readObject();
    o[2] = ois.readObject();
    o[3] = ois.readObject();
    o[4] = ois.readObject();
    o[5] = ois.readObject();
    o[6] = ois.readObject();
    o[7] = ois.readObject();
    _struct = new MutableStruct(o, _sqlType, _factory);
  }

  /* accessor methods */
  public int getAccount() throws SQLException
  { return ((Integer) _struct.getAttribute(0)).intValue(); }

  public void setAccount(int account) throws SQLException
  { _struct.setAttribute(0, new Integer(account)); }


  public int getTcount() throws SQLException
  { return ((Integer) _struct.getAttribute(1)).intValue(); }

  public void setTcount(int tcount) throws SQLException
  { _struct.setAttribute(1, new Integer(tcount)); }


  public int getFirstT() throws SQLException
  { return ((Integer) _struct.getAttribute(2)).intValue(); }

  public void setFirstT(int firstT) throws SQLException
  { _struct.setAttribute(2, new Integer(firstT)); }


  public int getLastT() throws SQLException
  { return ((Integer) _struct.getAttribute(3)).intValue(); }

  public void setLastT(int lastT) throws SQLException
  { _struct.setAttribute(3, new Integer(lastT)); }


  public int getBatchId() throws SQLException
  { return ((Integer) _struct.getAttribute(4)).intValue(); }

  public void setBatchId(int batchId) throws SQLException
  { _struct.setAttribute(4, new Integer(batchId)); }


  public XROWIDS getRowids() throws SQLException
  { return (XROWIDS) _struct.getAttribute(5); }

  public void setRowids(XROWIDS rowids) throws SQLException
  { _struct.setAttribute(5, rowids); }


  public XROWIDS getTqrowids() throws SQLException
  { return (XROWIDS) _struct.getAttribute(6); }

  public void setTqrowids(XROWIDS tqrowids) throws SQLException
  { _struct.setAttribute(6, tqrowids); }


  public TQSTUBS_OBJ_ARR getStubs() throws SQLException
  { return (TQSTUBS_OBJ_ARR) _struct.getAttribute(7); }

  public void setStubs(TQSTUBS_OBJ_ARR stubs) throws SQLException
  { _struct.setAttribute(7, stubs); }

  public String toString()
  { try {
     return "TQREACTOR.TQBATCH" + "(" +
       getAccount() + "," +
       getTcount() + "," +
       getFirstT() + "," +
       getLastT() + "," +
       getBatchId() + "," +
       getRowids() + "," +
       getTqrowids() + "," +
       getStubs() +
     ")";
    } catch (Exception e) { return e.toString(); }
  }


  public TQBATCH addstub (
    TQSTUBS_OBJ STUB)
  throws java.sql.SQLException
  {
 try {
    TQBATCH __jPt_temp = this;
    /*@lineinfo:generated-code*//*@lineinfo:237^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_temp.ADDSTUB(
//        :STUB);
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1  .ADDSTUB(\n       :2  );\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"0tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,2002,"TQREACTOR.TQBATCH");
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(1,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(1,__jPt_temp);
   if (STUB==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUBS_OBJ"); else __sJT_st.setORAData(2,STUB);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_temp = (tqueue.db.types.TQBATCH)__sJT_st.getORAData(1,tqueue.db.types.TQBATCH.getORADataFactory());
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:242^5*/
    return __jPt_temp;
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    TQBATCH __jPt_temp = this;
    /*@lineinfo:generated-code*//*@lineinfo:250^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_temp.ADDSTUB(
//        :STUB);
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1  .ADDSTUB(\n       :2  );\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"1tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,2002,"TQREACTOR.TQBATCH");
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(1,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(1,__jPt_temp);
   if (STUB==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUBS_OBJ"); else __sJT_st.setORAData(2,STUB);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_temp = (tqueue.db.types.TQBATCH)__sJT_st.getORAData(1,tqueue.db.types.TQBATCH.getORADataFactory());
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:255^5*/
    return __jPt_temp;
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
  }

  public java.math.BigDecimal f ()
  throws java.sql.SQLException
  {
    TQBATCH __jPt_temp = (TQBATCH) this;
    java.math.BigDecimal __jPt_result;
 try {
    /*@lineinfo:generated-code*//*@lineinfo:270^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.F();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .F();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"2tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.NUMERIC);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = __sJT_st.getBigDecimal(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:274^5*/
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    /*@lineinfo:generated-code*//*@lineinfo:280^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.F();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .F();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"3tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.NUMERIC);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = __sJT_st.getBigDecimal(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:284^5*/
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
    return __jPt_result;
  }

  public String tov ()
  throws java.sql.SQLException
  {
    TQBATCH __jPt_temp = (TQBATCH) this;
    String __jPt_result;
 try {
    /*@lineinfo:generated-code*//*@lineinfo:299^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.TOV();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .TOV();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"4tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.VARCHAR);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (String)__sJT_st.getString(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:303^5*/
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    /*@lineinfo:generated-code*//*@lineinfo:309^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.TOV();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .TOV();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"5tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.VARCHAR);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQBATCH"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (String)__sJT_st.getString(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:313^5*/
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
    return __jPt_result;
  }

  public TQBATCH tqbatch (
    TQSTUBS_OBJ STUB,
    int BATCHID,
    TQBATCH __jPt_out[])
  throws java.sql.SQLException
  {
    TQBATCH __jPt_temp = (TQBATCH) this;
    TQBATCH __jPt_result;
 try {
    /*@lineinfo:generated-code*//*@lineinfo:331^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := TQBATCH(
//        :STUB,
//        :BATCHID);
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   := TQBATCH(\n       :2  ,\n       :3  );\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"6tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,2002,"TQREACTOR.TQBATCH");
   }
   // set IN parameters
   if (STUB==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUBS_OBJ"); else __sJT_st.setORAData(2,STUB);
   __sJT_st.setInt(3,BATCHID);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (tqueue.db.types.TQBATCH)__sJT_st.getORAData(1,tqueue.db.types.TQBATCH.getORADataFactory());
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:337^5*/
    __jPt_out[0] = __jPt_temp;
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    /*@lineinfo:generated-code*//*@lineinfo:344^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := TQBATCH(
//        :STUB,
//        :BATCHID);
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   := TQBATCH(\n       :2  ,\n       :3  );\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"7tqueue.db.types.TQBATCH",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,2002,"TQREACTOR.TQBATCH");
   }
   // set IN parameters
   if (STUB==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUBS_OBJ"); else __sJT_st.setORAData(2,STUB);
   __sJT_st.setInt(3,BATCHID);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (tqueue.db.types.TQBATCH)__sJT_st.getORAData(1,tqueue.db.types.TQBATCH.getORADataFactory());
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:350^5*/
    __jPt_out[0] = __jPt_temp;
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
    return __jPt_result;
  }
}/*@lineinfo:generated-code*/