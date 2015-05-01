package tqueue.db.localtypes;

import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;

import oracle.jdbc.OracleTypes;

public class TQSTUB implements SQLData, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQSTUB";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  private String m_xrowid;
  private String m_tqrowid;
  private int m_tqueueId;
  private byte[] m_xid;
  private int m_securityId;
  private String m_securityType;
  private int m_accountId;
  private int m_batchId;
  private java.sql.Timestamp m_batchTs;

  /* constructor */
  public TQSTUB()
  {
  }

  public TQSTUB(String xrowid, String tqrowid, int tqueueId, byte[] xid, int securityId, String securityType, int accountId, int batchId, java.sql.Timestamp batchTs) throws SQLException
  {
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
  public void readSQL(SQLInput stream, String type)
  throws SQLException
  {
      setXrowid(stream.readString());
      setTqrowid(stream.readString());
      setTqueueId(stream.readInt());
      setXid(stream.readBytes());
      setSecurityId(stream.readInt());
      setSecurityType(stream.readString());
      setAccountId(stream.readInt());
      setBatchId(stream.readInt());
      setBatchTs(stream.readTimestamp());
  }

  public void writeSQL(SQLOutput stream)
  throws SQLException
  {
      stream.writeString(getXrowid());
      stream.writeString(getTqrowid());
      stream.writeInt(getTqueueId());
      stream.writeBytes(getXid());
      stream.writeInt(getSecurityId());
      stream.writeString(getSecurityType());
      stream.writeInt(getAccountId());
      stream.writeInt(getBatchId());
      stream.writeTimestamp(getBatchTs());
  }

  public String getSQLTypeName() throws SQLException
  {
    return _SQL_NAME;
  }

  /* Serialization interface */
  public void restoreConnection(java.sql.Connection conn) throws SQLException
  { }
  /* accessor methods */
  public String getXrowid()
  { return m_xrowid; }

  public void setXrowid(String xrowid)
  { m_xrowid = xrowid; }


  public String getTqrowid()
  { return m_tqrowid; }

  public void setTqrowid(String tqrowid)
  { m_tqrowid = tqrowid; }


  public int getTqueueId()
  { return m_tqueueId; }

  public void setTqueueId(int tqueueId)
  { m_tqueueId = tqueueId; }


  public byte[] getXid()
  { return m_xid; }

  public void setXid(byte[] xid)
  { m_xid = xid; }


  public int getSecurityId()
  { return m_securityId; }

  public void setSecurityId(int securityId)
  { m_securityId = securityId; }


  public String getSecurityType()
  { return m_securityType; }

  public void setSecurityType(String securityType)
  { m_securityType = securityType; }


  public int getAccountId()
  { return m_accountId; }

  public void setAccountId(int accountId)
  { m_accountId = accountId; }


  public int getBatchId()
  { return m_batchId; }

  public void setBatchId(int batchId)
  { m_batchId = batchId; }


  public java.sql.Timestamp getBatchTs()
  { return m_batchTs; }

  public void setBatchTs(java.sql.Timestamp batchTs)
  { m_batchTs = batchTs; }

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
