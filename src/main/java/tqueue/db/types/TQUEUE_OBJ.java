/*@lineinfo:filename=TQUEUE_OBJ*//*@lineinfo:user-code*//*@lineinfo:1^1*/package tqueue.db.types;

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

public class TQUEUE_OBJ implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQUEUE_OBJ";
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

  protected static int[] _sqlType =  { 12,2,-2,12,12,12,2,1,2,2,91,91,12 };
  protected static ORADataFactory[] _factory = new ORADataFactory[13];
  protected static final TQUEUE_OBJ _TQUEUE_OBJFactory = new TQUEUE_OBJ();

  public static ORADataFactory getORADataFactory()
  { return _TQUEUE_OBJFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[13], _sqlType, _factory); }
  public TQUEUE_OBJ()
  { _init_struct(true); __tx = DefaultContext.getDefaultContext(); }
  public TQUEUE_OBJ(DefaultContext c) /*throws SQLException*/
  { _init_struct(true); __tx = c; }
  public TQUEUE_OBJ(Connection c) /*throws SQLException*/
  { _init_struct(true); __onn = c; }
  public TQUEUE_OBJ(String xrowid, java.math.BigDecimal tqueueId, byte[] xid, String statusCode, String securityDisplayName, String accountDisplayName, java.math.BigDecimal securityId, String securityType, java.math.BigDecimal accountId, java.math.BigDecimal batchId, java.sql.Timestamp createTs, java.sql.Timestamp updateTs, String errorMessage) throws SQLException
  {
    _init_struct(true);
    setXrowid(xrowid);
    setTqueueId(tqueueId);
    setXid(xid);
    setStatusCode(statusCode);
    setSecurityDisplayName(securityDisplayName);
    setAccountDisplayName(accountDisplayName);
    setSecurityId(securityId);
    setSecurityType(securityType);
    setAccountId(accountId);
    setBatchId(batchId);
    setCreateTs(createTs);
    setUpdateTs(updateTs);
    setErrorMessage(errorMessage);
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
  public void setFrom(TQUEUE_OBJ o) throws SQLException
  { setContextFrom(o); setValueFrom(o); }
  protected void setContextFrom(TQUEUE_OBJ o) throws SQLException
  { release(); __tx = o.__tx; __onn = o.__onn; }
  protected void setValueFrom(TQUEUE_OBJ o) { _struct = o._struct; }
  protected ORAData create(TQUEUE_OBJ o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) { if (o!=null) { o.release(); }; return null; }
    if (o == null) o = new TQUEUE_OBJ();
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
    oos.writeObject(getTqueueId());
    oos.writeObject(getXid());
    oos.writeObject(getStatusCode());
    oos.writeObject(getSecurityDisplayName());
    oos.writeObject(getAccountDisplayName());
    oos.writeObject(getSecurityId());
    oos.writeObject(getSecurityType());
    oos.writeObject(getAccountId());
    oos.writeObject(getBatchId());
    oos.writeObject(getCreateTs());
    oos.writeObject(getUpdateTs());
    oos.writeObject(getErrorMessage());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    Object[] o = new Object[13];
    o[0] = ois.readObject();
    o[1] = ois.readObject();
    o[2] = ois.readObject();
    o[3] = ois.readObject();
    o[4] = ois.readObject();
    o[5] = ois.readObject();
    o[6] = ois.readObject();
    o[7] = ois.readObject();
    o[8] = ois.readObject();
    o[9] = ois.readObject();
    o[10] = ois.readObject();
    o[11] = ois.readObject();
    o[12] = ois.readObject();
    _struct = new MutableStruct(o, _sqlType, _factory);
  }

  /* accessor methods */
  public String getXrowid() throws SQLException
  { return (String) _struct.getAttribute(0); }

  public void setXrowid(String xrowid) throws SQLException
  { _struct.setAttribute(0, xrowid); }


  public java.math.BigDecimal getTqueueId() throws SQLException
  { return (java.math.BigDecimal) _struct.getAttribute(1); }

  public void setTqueueId(java.math.BigDecimal tqueueId) throws SQLException
  { _struct.setAttribute(1, tqueueId); }


  public byte[] getXid() throws SQLException
  { return (byte[]) _struct.getAttribute(2); }

  public void setXid(byte[] xid) throws SQLException
  { _struct.setAttribute(2, xid); }


  public String getStatusCode() throws SQLException
  { return (String) _struct.getAttribute(3); }

  public void setStatusCode(String statusCode) throws SQLException
  { _struct.setAttribute(3, statusCode); }


  public String getSecurityDisplayName() throws SQLException
  { return (String) _struct.getAttribute(4); }

  public void setSecurityDisplayName(String securityDisplayName) throws SQLException
  { _struct.setAttribute(4, securityDisplayName); }


  public String getAccountDisplayName() throws SQLException
  { return (String) _struct.getAttribute(5); }

  public void setAccountDisplayName(String accountDisplayName) throws SQLException
  { _struct.setAttribute(5, accountDisplayName); }


  public java.math.BigDecimal getSecurityId() throws SQLException
  { return (java.math.BigDecimal) _struct.getAttribute(6); }

  public void setSecurityId(java.math.BigDecimal securityId) throws SQLException
  { _struct.setAttribute(6, securityId); }


  public String getSecurityType() throws SQLException
  { return (String) _struct.getAttribute(7); }

  public void setSecurityType(String securityType) throws SQLException
  { _struct.setAttribute(7, securityType); }


  public java.math.BigDecimal getAccountId() throws SQLException
  { return (java.math.BigDecimal) _struct.getAttribute(8); }

  public void setAccountId(java.math.BigDecimal accountId) throws SQLException
  { _struct.setAttribute(8, accountId); }


  public java.math.BigDecimal getBatchId() throws SQLException
  { return (java.math.BigDecimal) _struct.getAttribute(9); }

  public void setBatchId(java.math.BigDecimal batchId) throws SQLException
  { _struct.setAttribute(9, batchId); }


  public java.sql.Timestamp getCreateTs() throws SQLException
  { return (java.sql.Timestamp) _struct.getAttribute(10); }

  public void setCreateTs(java.sql.Timestamp createTs) throws SQLException
  { _struct.setAttribute(10, createTs); }


  public java.sql.Timestamp getUpdateTs() throws SQLException
  { return (java.sql.Timestamp) _struct.getAttribute(11); }

  public void setUpdateTs(java.sql.Timestamp updateTs) throws SQLException
  { _struct.setAttribute(11, updateTs); }


  public String getErrorMessage() throws SQLException
  { return (String) _struct.getAttribute(12); }

  public void setErrorMessage(String errorMessage) throws SQLException
  { _struct.setAttribute(12, errorMessage); }

  public String toString()
  { try {
     return "TQREACTOR.TQUEUE_OBJ" + "(" +
       ((getXrowid()==null)?"null": "'" + getXrowid()+"'" ) + "," +
       getTqueueId() + "," +
       getXid() + "," +
       ((getStatusCode()==null)?"null": "'" + getStatusCode()+"'" ) + "," +
       ((getSecurityDisplayName()==null)?"null": "'" + getSecurityDisplayName()+"'" ) + "," +
       ((getAccountDisplayName()==null)?"null": "'" + getAccountDisplayName()+"'" ) + "," +
       getSecurityId() + "," +
       ((getSecurityType()==null)?"null": "'" + getSecurityType()+"'" ) + "," +
       getAccountId() + "," +
       getBatchId() + "," +
       getCreateTs() + "," +
       getUpdateTs() + "," +
       ((getErrorMessage()==null)?"null": "'" + getErrorMessage()+"'" ) +
     ")";
    } catch (Exception e) { return e.toString(); }
  }


  public String tov ()
  throws java.sql.SQLException
  {
    TQUEUE_OBJ __jPt_temp = (TQUEUE_OBJ) this;
    String __jPt_result;
 try {
    /*@lineinfo:generated-code*//*@lineinfo:283^5*/

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
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"0tqueue.db.types.TQUEUE_OBJ",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.VARCHAR);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQUEUE_OBJ"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (String)__sJT_st.getString(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:287^5*/
 } catch(java.sql.SQLException _err) {
   try {
      getConnectionContext().getExecutionContext().close();
      closeConnection();
      if (__dataSource==null) throw _err;
    /*@lineinfo:generated-code*//*@lineinfo:293^5*/

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
   __sJT_st = __sJT_ec.prepareOracleCall(__sJT_cc,"1tqueue.db.types.TQUEUE_OBJ",theSqlTS);
   if (__sJT_ec.isNew())
   {
      __sJT_st.registerOutParameter(1,oracle.jdbc.OracleTypes.VARCHAR);
   }
   // set IN parameters
   if (__jPt_temp==null) __sJT_st.setNull(2,2002,"TQREACTOR.TQUEUE_OBJ"); else __sJT_st.setORAData(2,__jPt_temp);
  // execute statement
   __sJT_ec.oracleExecuteUpdate();
   // retrieve OUT parameters
   __jPt_result = (String)__sJT_st.getString(1);
  } finally { __sJT_ec.oracleClose(); }
}


//  ************************************************************

/*@lineinfo:user-code*//*@lineinfo:297^5*/
   } catch (java.sql.SQLException _err2) { 
     try { getConnectionContext().getExecutionContext().close(); } catch (java.sql.SQLException _sqle) {}
     throw _err; 
  }
 }
    return __jPt_result;
  }
}/*@lineinfo:generated-code*/