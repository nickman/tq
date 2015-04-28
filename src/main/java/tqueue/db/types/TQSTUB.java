/*@lineinfo:filename=TQSTUB*//*@lineinfo:user-code*//*@lineinfo:1^1*/package tqueue.db.types;

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

public class TQSTUB implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQSTUB";
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

  protected static int[] _sqlType =  { 12,12,4,-2,4,1,4,4,93 };
  protected static ORADataFactory[] _factory = new ORADataFactory[9];
  protected static final TQSTUB _TQSTUBFactory = new TQSTUB();

  public static ORADataFactory getORADataFactory()
  { return _TQSTUBFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[9], _sqlType, _factory); }
  public TQSTUB()
  { _init_struct(true); __tx = DefaultContext.getDefaultContext(); }
  public TQSTUB(DefaultContext c) /*throws SQLException*/
  { _init_struct(true); __tx = c; }
  public TQSTUB(Connection c) /*throws SQLException*/
  { _init_struct(true); __onn = c; }
  public TQSTUB(String xrowid, String tqrowid, int tqueueId, byte[] xid, int securityId, String securityType, int accountId, int batchId, java.sql.Timestamp batchTs) throws SQLException
  {
    _init_struct(true);
    setXrowid(xrowid);
    setTqrowid(tqrowid);
    setTqueueId(tqueueId);
    setXid(xid);
    setSecurityId(securityId);
    setSecurityType(securityType);
    setAccountId(accountId);
    setBatchId(batchId);
    setBatchTs(batchTs);
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
  public void setFrom(TQSTUB o) throws SQLException
  { setContextFrom(o); setValueFrom(o); }
  protected void setContextFrom(TQSTUB o) throws SQLException
  { release(); __tx = o.__tx; __onn = o.__onn; }
  protected void setValueFrom(TQSTUB o) { _struct = o._struct; }
  protected ORAData create(TQSTUB o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) { if (o!=null) { o.release(); }; return null; }
    if (o == null) o = new TQSTUB();
    o._struct = new MutableStruct((STRUCT) d, _sqlType, _factory);
    o.__onn = ((STRUCT) d).getJavaSqlConnection();
    return o;
  }
  /* Serialization interface */
  public void restoreConnection(Connection conn) throws SQLException
  {   }
  private void writeObject(java.io.ObjectOutputStream oos)
          throws java.io.IOException, SQLException
  { oos.defaultWriteObject();
    oos.writeObject(getXrowid());
    oos.writeObject(getTqrowid());
    oos.writeObject(getTqueueId());
    oos.writeObject(getXid());
    oos.writeObject(getSecurityId());
    oos.writeObject(getSecurityType());
    oos.writeObject(getAccountId());
    oos.writeObject(getBatchId());
    oos.writeObject(getBatchTs());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    Object[] o = new Object[9];
    o[0] = ois.readObject();
    o[1] = ois.readObject();
    o[2] = ois.readObject();
    o[3] = ois.readObject();
    o[4] = ois.readObject();
    o[5] = ois.readObject();
    o[6] = ois.readObject();
    o[7] = ois.readObject();
    o[8] = ois.readObject();
    _struct = new MutableStruct(o, _sqlType, _factory);
  }

  /* accessor methods */
  public String getXrowid() throws SQLException
  { return (String) _struct.getAttribute(0); }

  public void setXrowid(String xrowid) throws SQLException
  { _struct.setAttribute(0, xrowid); }


  public String getTqrowid() throws SQLException
  { return (String) _struct.getAttribute(1); }

  public void setTqrowid(String tqrowid) throws SQLException
  { _struct.setAttribute(1, tqrowid); }


  public int getTqueueId() throws SQLException
  { return ((Integer) _struct.getAttribute(2)).intValue(); }

  public void setTqueueId(int tqueueId) throws SQLException
  { _struct.setAttribute(2, new Integer(tqueueId)); }


  public byte[] getXid() throws SQLException
  { return (byte[]) _struct.getAttribute(3); }

  public void setXid(byte[] xid) throws SQLException
  { _struct.setAttribute(3, xid); }


  public int getSecurityId() throws SQLException
  { return ((Integer) _struct.getAttribute(4)).intValue(); }

  public void setSecurityId(int securityId) throws SQLException
  { _struct.setAttribute(4, new Integer(securityId)); }


  public String getSecurityType() throws SQLException
  { return (String) _struct.getAttribute(5); }

  public void setSecurityType(String securityType) throws SQLException
  { _struct.setAttribute(5, securityType); }


  public int getAccountId() throws SQLException
  { return ((Integer) _struct.getAttribute(6)).intValue(); }

  public void setAccountId(int accountId) throws SQLException
  { _struct.setAttribute(6, new Integer(accountId)); }


  public int getBatchId() throws SQLException
  { return ((Integer) _struct.getAttribute(7)).intValue(); }

  public void setBatchId(int batchId) throws SQLException
  { _struct.setAttribute(7, new Integer(batchId)); }


  public java.sql.Timestamp getBatchTs() throws SQLException
  { return (java.sql.Timestamp) _struct.getAttribute(8); }

  public void setBatchTs(java.sql.Timestamp batchTs) throws SQLException
  { _struct.setAttribute(8, batchTs); }

  public String toString()
  { try {
     return "TQREACTOR.TQSTUB" + "(" +
       ((getXrowid()==null)?"null": "'" + getXrowid()+"'" ) + "," +
       ((getTqrowid()==null)?"null": "'" + getTqrowid()+"'" ) + "," +
       getTqueueId() + "," +
       getXid() + "," +
       getSecurityId() + "," +
       ((getSecurityType()==null)?"null": "'" + getSecurityType()+"'" ) + "," +
       getAccountId() + "," +
       getBatchId() + "," +
       getBatchTs() +
     ")";
    } catch (Exception e) { return e.toString(); }
  }


  public java.math.BigDecimal getTradequeueId ()
  throws java.sql.SQLException
  {
    TQSTUB __jPt_temp = (TQSTUB) this;
    java.math.BigDecimal __jPt_result;
 try {
    /*@lineinfo:generated-code*//*@lineinfo:239^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.GET_TRADEQUEUE_ID();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .GET_TRADEQUEUE_ID();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"0tqueue.db.types.TQSTUB",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.NUMERIC);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUB"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = __sJT_st.getBigDecimal(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:243^5*/
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    /*@lineinfo:generated-code*//*@lineinfo:249^5*/

//  ************************************************************
//  #sql [getConnectionContext()] { BEGIN
//        :__jPt_result := :__jPt_temp.GET_TRADEQUEUE_ID();
//        END;
//       };
//  ************************************************************

{
  // declare temps
  oracle.jdbc.OracleCallableStatement __sJT_st = null;
  sqlj.runtime.ref.DefaultContext __sJT_cc = getConnectionContext(); if (__sJT_cc==null) sqlj.runtime.error.RuntimeRefErrors.raise_NULL_CONN_CTX();
  sqlj.runtime.ExecutionContext.OracleContext __sJT_ec = ((__sJT_cc.getExecutionContext()==null) ? sqlj.runtime.ExecutionContext.raiseNullExecCtx() : __sJT_cc.getExecutionContext().getOracleContext());
  try {
   String theSqlTS = "BEGIN\n       :1   :=  :2  .GET_TRADEQUEUE_ID();\n      END;";
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"1tqueue.db.types.TQSTUB",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.NUMERIC);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQSTUB"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = __sJT_st.getBigDecimal(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:253^5*/
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
    return __jPt_result;
  }
}/*@lineinfo:generated-code*/