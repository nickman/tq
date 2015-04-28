package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;

public class TQTRADE implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQTRADE";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  transient protected MutableStruct _struct;

  protected static int[] _sqlType =  { 12,4,-2,12,12,12,4,1,4,4,91,91,12 };
  protected static ORADataFactory[] _factory = new ORADataFactory[13];
  protected static final TQTRADE _TQTRADEFactory = new TQTRADE();

  public static ORADataFactory getORADataFactory()
  { return _TQTRADEFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[13], _sqlType, _factory); }
  public TQTRADE()
  { _init_struct(true); }
  public TQTRADE(String xrowid, int tqueueId, byte[] xid, String statusCode, String securityDisplayName, String accountDisplayName, int securityId, String securityType, int accountId, int batchId, java.sql.Timestamp createTs, java.sql.Timestamp updateTs, String errorMessage) throws SQLException
  { _init_struct(true);
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
    return _struct.toDatum(c, _SQL_NAME);
  }


  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  { return create(null, d, sqlType); }
  protected ORAData create(TQTRADE o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    if (o == null) o = new TQTRADE();
    o._struct = new MutableStruct((STRUCT) d, _sqlType, _factory);
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


  public int getTqueueId() throws SQLException
  { return ((Integer) _struct.getAttribute(1)).intValue(); }

  public void setTqueueId(int tqueueId) throws SQLException
  { _struct.setAttribute(1, new Integer(tqueueId)); }


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


  public int getSecurityId() throws SQLException
  { return ((Integer) _struct.getAttribute(6)).intValue(); }

  public void setSecurityId(int securityId) throws SQLException
  { _struct.setAttribute(6, new Integer(securityId)); }


  public String getSecurityType() throws SQLException
  { return (String) _struct.getAttribute(7); }

  public void setSecurityType(String securityType) throws SQLException
  { _struct.setAttribute(7, securityType); }


  public int getAccountId() throws SQLException
  { return ((Integer) _struct.getAttribute(8)).intValue(); }

  public void setAccountId(int accountId) throws SQLException
  { _struct.setAttribute(8, new Integer(accountId)); }


  public int getBatchId() throws SQLException
  { return ((Integer) _struct.getAttribute(9)).intValue(); }

  public void setBatchId(int batchId) throws SQLException
  { _struct.setAttribute(9, new Integer(batchId)); }


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
     return "TQREACTOR.TQTRADE" + "(" +
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

}
