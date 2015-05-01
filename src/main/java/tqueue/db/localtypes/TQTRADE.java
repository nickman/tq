package tqueue.db.localtypes;

import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;

import oracle.jdbc.OracleTypes;

public class TQTRADE implements SQLData, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQTRADE";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  private String m_xrowid;
  private int m_tqueueId;
  private byte[] m_xid;
  private String m_statusCode;
  private String m_securityDisplayName;
  private String m_accountDisplayName;
  private int m_securityId;
  private String m_securityType;
  private int m_accountId;
  private int m_batchId;
  private java.sql.Timestamp m_createTs;
  private java.sql.Timestamp m_updateTs;
  private String m_errorMessage;

  /* constructor */
  public TQTRADE()
  {
  }

  public TQTRADE(String xrowid, int tqueueId, byte[] xid, String statusCode, String securityDisplayName, String accountDisplayName, int securityId, String securityType, int accountId, int batchId, java.sql.Timestamp createTs, java.sql.Timestamp updateTs, String errorMessage) throws SQLException
  {
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
  public void readSQL(SQLInput stream, String type)
  throws SQLException
  {
      setXrowid(stream.readString());
      setTqueueId(stream.readInt());
      setXid(stream.readBytes());
      setStatusCode(stream.readString());
      setSecurityDisplayName(stream.readString());
      setAccountDisplayName(stream.readString());
      setSecurityId(stream.readInt());
      setSecurityType(stream.readString());
      setAccountId(stream.readInt());
      setBatchId(stream.readInt());
      setCreateTs(stream.readTimestamp());
      setUpdateTs(stream.readTimestamp());
      setErrorMessage(stream.readString());
  }

  public void writeSQL(SQLOutput stream)
  throws SQLException
  {
      stream.writeString(getXrowid());
      stream.writeInt(getTqueueId());
      stream.writeBytes(getXid());
      stream.writeString(getStatusCode());
      stream.writeString(getSecurityDisplayName());
      stream.writeString(getAccountDisplayName());
      stream.writeInt(getSecurityId());
      stream.writeString(getSecurityType());
      stream.writeInt(getAccountId());
      stream.writeInt(getBatchId());
      stream.writeTimestamp(getCreateTs());
      stream.writeTimestamp(getUpdateTs());
      stream.writeString(getErrorMessage());
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


  public int getTqueueId()
  { return m_tqueueId; }

  public void setTqueueId(int tqueueId)
  { m_tqueueId = tqueueId; }


  public byte[] getXid()
  { return m_xid; }

  public void setXid(byte[] xid)
  { m_xid = xid; }


  public String getStatusCode()
  { return m_statusCode; }

  public void setStatusCode(String statusCode)
  { m_statusCode = statusCode; }


  public String getSecurityDisplayName()
  { return m_securityDisplayName; }

  public void setSecurityDisplayName(String securityDisplayName)
  { m_securityDisplayName = securityDisplayName; }


  public String getAccountDisplayName()
  { return m_accountDisplayName; }

  public void setAccountDisplayName(String accountDisplayName)
  { m_accountDisplayName = accountDisplayName; }


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


  public java.sql.Timestamp getCreateTs()
  { return m_createTs; }

  public void setCreateTs(java.sql.Timestamp createTs)
  { m_createTs = createTs; }


  public java.sql.Timestamp getUpdateTs()
  { return m_updateTs; }

  public void setUpdateTs(java.sql.Timestamp updateTs)
  { m_updateTs = updateTs; }


  public String getErrorMessage()
  { return m_errorMessage; }

  public void setErrorMessage(String errorMessage)
  { m_errorMessage = errorMessage; }

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
