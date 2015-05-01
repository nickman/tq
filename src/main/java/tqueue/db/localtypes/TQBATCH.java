package tqueue.db.localtypes;

import java.sql.SQLData;
import java.sql.SQLException;
import java.sql.SQLInput;
import java.sql.SQLOutput;

import oracle.jdbc.OracleTypes;

public class TQBATCH implements SQLData, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQBATCH";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  private int m_account;
  private int m_tcount;
  private int m_firstT;
  private int m_lastT;
  private int m_batchId;
  private java.sql.Array m_rowids;
  private java.sql.Array m_stubs;

  /* constructor */
  public TQBATCH()
  {
  }

  public TQBATCH(int account, int tcount, int firstT, int lastT, int batchId, java.sql.Array rowids, java.sql.Array stubs) throws SQLException
  {
    setAccount(account);
    setTcount(tcount);
    setFirstT(firstT);
    setLastT(lastT);
    setBatchId(batchId);
    setRowids(rowids);
    setStubs(stubs);
  }
  public void readSQL(SQLInput stream, String type)
  throws SQLException
  {
      setAccount(stream.readInt());
      setTcount(stream.readInt());
      setFirstT(stream.readInt());
      setLastT(stream.readInt());
      setBatchId(stream.readInt());
      setRowids(stream.readArray());
      setStubs(stream.readArray());
  }

  public void writeSQL(SQLOutput stream)
  throws SQLException
  {
      stream.writeInt(getAccount());
      stream.writeInt(getTcount());
      stream.writeInt(getFirstT());
      stream.writeInt(getLastT());
      stream.writeInt(getBatchId());
      stream.writeArray(getRowids());
      stream.writeArray(getStubs());
  }

  public String getSQLTypeName() throws SQLException
  {
    return _SQL_NAME;
  }

  /* Serialization interface */
  public void restoreConnection(java.sql.Connection conn) throws SQLException
  { }
  /* accessor methods */
  public int getAccount()
  { return m_account; }

  public void setAccount(int account)
  { m_account = account; }


  public int getTcount()
  { return m_tcount; }

  public void setTcount(int tcount)
  { m_tcount = tcount; }


  public int getFirstT()
  { return m_firstT; }

  public void setFirstT(int firstT)
  { m_firstT = firstT; }


  public int getLastT()
  { return m_lastT; }

  public void setLastT(int lastT)
  { m_lastT = lastT; }


  public int getBatchId()
  { return m_batchId; }

  public void setBatchId(int batchId)
  { m_batchId = batchId; }


  public java.sql.Array getRowids()
  { return m_rowids; }

  public void setRowids(java.sql.Array rowids)
  { m_rowids = rowids; }


  public java.sql.Array getStubs()
  { return m_stubs; }

  public void setStubs(java.sql.Array stubs)
  { m_stubs = stubs; }

  public String toString()
  { try {
     return "TQREACTOR.TQBATCH" + "(" +
       getAccount() + "," +
       getTcount() + "," +
       getFirstT() + "," +
       getLastT() + "," +
       getBatchId() + "," +
       getRowids() + "," +
       getStubs() +
     ")";
    } catch (Exception e) { return e.toString(); }
  }

}
