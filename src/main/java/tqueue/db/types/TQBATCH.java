package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.STRUCT;
import oracle.jpub.runtime.MutableStruct;

public class TQBATCH implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQBATCH";
  public static final int _SQL_TYPECODE = OracleTypes.STRUCT;

  transient protected MutableStruct _struct;

  protected static int[] _sqlType =  { 4,4,4,4,4,2003,2003 };
  protected static ORADataFactory[] _factory = new ORADataFactory[7];
  static
  {
    _factory[5] = XROWIDS.getORADataFactory();
    _factory[6] = TQSTUB_ARR.getORADataFactory();
  }
  protected static final TQBATCH _TQBATCHFactory = new TQBATCH();

  public static ORADataFactory getORADataFactory()
  { return _TQBATCHFactory; }
  /* constructors */
  protected void _init_struct(boolean init)
  { if (init) _struct = new MutableStruct(new Object[7], _sqlType, _factory); }
  public TQBATCH()
  { _init_struct(true); }
  public TQBATCH(int account, int tcount, int firstT, int lastT, int batchId, XROWIDS rowids, TQSTUB_ARR stubs) throws SQLException
  { _init_struct(true);
    setAccount(account);
    setTcount(tcount);
    setFirstT(firstT);
    setLastT(lastT);
    setBatchId(batchId);
    setRowids(rowids);
    setStubs(stubs);
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    return _struct.toDatum(c, _SQL_NAME);
  }


  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  { return create(null, d, sqlType); }
  protected ORAData create(TQBATCH o, Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    if (o == null) o = new TQBATCH();
    o._struct = new MutableStruct((STRUCT) d, _sqlType, _factory);
    return o;
  }
  /* Serialization interface */
  public void restoreConnection(Connection conn) throws SQLException
  {     if (getRowids()!=null) getRowids().restoreConnection(conn);
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
    oos.writeObject(getStubs());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    Object[] o = new Object[7];
    o[0] = ois.readObject();
    o[1] = ois.readObject();
    o[2] = ois.readObject();
    o[3] = ois.readObject();
    o[4] = ois.readObject();
    o[5] = ois.readObject();
    o[6] = ois.readObject();
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


  public TQSTUB_ARR getStubs() throws SQLException
  { return (TQSTUB_ARR) _struct.getAttribute(6); }

  public void setStubs(TQSTUB_ARR stubs) throws SQLException
  { _struct.setAttribute(6, stubs); }

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
