package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleTypes;
import java.sql.SQLData;
import java.sql.SQLInput;
import java.sql.SQLOutput;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;

public class JTQSTUB implements SQLData, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.JTQSTUB";
  public static final int _SQL_TYPECODE = DBType.JAVA_STRUCT.typeCode;

  private String m_xrowid;
  private int m_tradeQueueId;
  private String m_tradeQueueStatusCode;
  private String m_specieDisplayName;
  private String m_positionaccountAcctNbr;
  private int m_specieId;
  private int m_positionaccountAcctId;
  private java.sql.Timestamp m_createTs;
  private java.sql.Timestamp m_updateTs;
  private String m_errorMessage;

  /* constructor */
  public JTQSTUB()
  {
  }

  public JTQSTUB(String xrowid, int tradeQueueId, String tradeQueueStatusCode, String specieDisplayName, String positionaccountAcctNbr, int specieId, int positionaccountAcctId, java.sql.Timestamp createTs, java.sql.Timestamp updateTs, String errorMessage) throws SQLException
  {
    setXrowid(xrowid);
    setTradeQueueId(tradeQueueId);
    setTradeQueueStatusCode(tradeQueueStatusCode);
    setSpecieDisplayName(specieDisplayName);
    setPositionaccountAcctNbr(positionaccountAcctNbr);
    setSpecieId(specieId);
    setPositionaccountAcctId(positionaccountAcctId);
    setCreateTs(createTs);
    setUpdateTs(updateTs);
    setErrorMessage(errorMessage);
  }
  public void readSQL(SQLInput stream, String type)
  throws SQLException
  {
      setXrowid(stream.readString());
      setTradeQueueId(stream.readInt());
      setTradeQueueStatusCode(stream.readString());
      setSpecieDisplayName(stream.readString());
      setPositionaccountAcctNbr(stream.readString());
      setSpecieId(stream.readInt());
      setPositionaccountAcctId(stream.readInt());
      setCreateTs(stream.readTimestamp());
      setUpdateTs(stream.readTimestamp());
      setErrorMessage(stream.readString());
  }

  public void writeSQL(SQLOutput stream)
  throws SQLException
  {
      stream.writeString(getXrowid());
      stream.writeInt(getTradeQueueId());
      stream.writeString(getTradeQueueStatusCode());
      stream.writeString(getSpecieDisplayName());
      stream.writeString(getPositionaccountAcctNbr());
      stream.writeInt(getSpecieId());
      stream.writeInt(getPositionaccountAcctId());
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


  public int getTradeQueueId()
  { return m_tradeQueueId; }

  public void setTradeQueueId(int tradeQueueId)
  { m_tradeQueueId = tradeQueueId; }


  public String getTradeQueueStatusCode()
  { return m_tradeQueueStatusCode; }

  public void setTradeQueueStatusCode(String tradeQueueStatusCode)
  { m_tradeQueueStatusCode = tradeQueueStatusCode; }


  public String getSpecieDisplayName()
  { return m_specieDisplayName; }

  public void setSpecieDisplayName(String specieDisplayName)
  { m_specieDisplayName = specieDisplayName; }


  public String getPositionaccountAcctNbr()
  { return m_positionaccountAcctNbr; }

  public void setPositionaccountAcctNbr(String positionaccountAcctNbr)
  { m_positionaccountAcctNbr = positionaccountAcctNbr; }


  public int getSpecieId()
  { return m_specieId; }

  public void setSpecieId(int specieId)
  { m_specieId = specieId; }


  public int getPositionaccountAcctId()
  { return m_positionaccountAcctId; }

  public void setPositionaccountAcctId(int positionaccountAcctId)
  { m_positionaccountAcctId = positionaccountAcctId; }


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
     return "TQREACTOR.JTQSTUB" + "(" +
       ((getXrowid()==null)?"null": "'" + getXrowid()+"'" ) + "," +
       getTradeQueueId() + "," +
       ((getTradeQueueStatusCode()==null)?"null": "'" + getTradeQueueStatusCode()+"'" ) + "," +
       ((getSpecieDisplayName()==null)?"null": "'" + getSpecieDisplayName()+"'" ) + "," +
       ((getPositionaccountAcctNbr()==null)?"null": "'" + getPositionaccountAcctNbr()+"'" ) + "," +
       getSpecieId() + "," +
       getPositionaccountAcctId() + "," +
       getCreateTs() + "," +
       getUpdateTs() + "," +
       ((getErrorMessage()==null)?"null": "'" + getErrorMessage()+"'" ) +
     ")";
    } catch (Exception e) { return e.toString(); }
  }

}
