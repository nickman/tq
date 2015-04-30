package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;

public class TQSTUB implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQSTUB";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

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
  { _init_struct(true); }
  public TQSTUB(String xrowid, String tqrowid, int tqueueId, byte[] xid, int securityId, String securityType, int accountId, int batchId, java.sql.Timestamp batchTs) throws SQLException
  { _init_struct(true);
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
    return _struct.toDatum(c, _SQL_NAME);
  }


  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  { return create(null, d, sqlType); }
  protected ORAData create(TQSTUB o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    if (o == null) o = new TQSTUB();
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

}
