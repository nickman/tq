package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.ARRAY;
import oracle.sql.ArrayDescriptor;
import oracle.jpub.runtime.MutableArray;

public class TQTRADE_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQTRADE_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final TQTRADE_ARR _TQTRADE_ARRFactory = new TQTRADE_ARR();

  public static ORADataFactory getORADataFactory()
  { return _TQTRADE_ARRFactory; }
  /* constructors */
  public TQTRADE_ARR()
  {
    this((TQTRADE[])null);
  }

  public TQTRADE_ARR(TQTRADE[] a)
  {
    _array = new MutableArray(2002, a, TQTRADE.getORADataFactory());
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    return _array.toDatum(c, _SQL_NAME);
  }

  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    TQTRADE_ARR a = new TQTRADE_ARR();
    a._array = new MutableArray(2002, (ARRAY) d, TQTRADE.getORADataFactory());
    return a;
  }

  public int length() throws SQLException
  {
    return _array.length();
  }

  public int getBaseType() throws SQLException
  {
    return _array.getBaseType();
  }

  public String getBaseTypeName() throws SQLException
  {
    return _array.getBaseTypeName();
  }

  public ArrayDescriptor getDescriptor() throws SQLException
  {
    return _array.getDescriptor();
  }

  /* Serialization interface */
  public void restoreConnection(Connection conn) throws SQLException
  { TQTRADE[] a = (TQTRADE[])getArray();
    for (int i=0; i<a.length; i++) { a[i].restoreConnection(conn); }
  }
  private void writeObject(java.io.ObjectOutputStream oos)
          throws java.io.IOException, SQLException
  { oos.defaultWriteObject();
    oos.writeObject(getArray());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    TQTRADE[] a = (TQTRADE[]) ois.readObject();
    _array = new MutableArray(2002, a, TQTRADE.getORADataFactory());
  }


  /* array accessor methods */
  public TQTRADE[] getArray() throws SQLException
  {
    return (TQTRADE[]) _array.getObjectArray(
      new TQTRADE[_array.length()]);
  }

  public TQTRADE[] getArray(long index, int count) throws SQLException
  {
    return (TQTRADE[]) _array.getObjectArray(index,
      new TQTRADE[_array.sliceLength(index, count)]);
  }

  public void setArray(TQTRADE[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(TQTRADE[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public TQTRADE getElement(long index) throws SQLException
  {
    return (TQTRADE) _array.getObjectElement(index);
  }

  public void setElement(TQTRADE a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

  public String toString()
  { try { String r = "TQREACTOR.TQTRADE_ARR" + "(";
     TQTRADE[] a = (TQTRADE[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + a[i];
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
