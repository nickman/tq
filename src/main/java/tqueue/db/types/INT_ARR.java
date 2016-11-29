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

public class INT_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.INT_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final INT_ARR _INT_ARRFactory = new INT_ARR();

  public static ORADataFactory getORADataFactory()
  { return _INT_ARRFactory; }
  /* constructors */
  public INT_ARR()
  {
    this((int[])null);
  }

  public INT_ARR(int[] a)
  {
    _array = new MutableArray(4, a, null);
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
    INT_ARR a = new INT_ARR();
    a._array = new MutableArray(4, (ARRAY) d, null);
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
  { }
  private void writeObject(java.io.ObjectOutputStream oos)
          throws java.io.IOException, SQLException
  { oos.defaultWriteObject();
    oos.writeObject(getArray());
  }
  private void readObject(java.io.ObjectInputStream ois)
          throws java.io.IOException, ClassNotFoundException, java.sql.SQLException
  { ois.defaultReadObject();
    int[] a = (int[]) ois.readObject();
    _array = new MutableArray(4, a, null);
  }


  /* array accessor methods */
  public int[] getArray() throws SQLException
  {
    return (int[]) _array.getArray();
}

  public int[] getArray(long index, int count) throws SQLException
  {
    return (int[]) _array.getArray(index, count);
  }

  public void setArray(int[] a) throws SQLException
  {
    _array.setArray(a);
  }

  public void setArray(int[] a, long index) throws SQLException
  {
    _array.setArray(a, index);
  }

  public int getElement(long index) throws SQLException
  {
    return ((Integer) _array.getObjectElement(index)).intValue();
  }

  public void setElement(int a, long index) throws SQLException
  {
    _array.setObjectElement(new Integer(a), index);
  }

  public String toString()
  { try { String r = "TQREACTOR.INT_ARR" + "(";
     int[] a = (int[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + a[i];
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
