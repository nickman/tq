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

public class TQSTUB_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQSTUB_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final TQSTUB_ARR _TQSTUB_ARRFactory = new TQSTUB_ARR();

  public static ORADataFactory getORADataFactory()
  { return _TQSTUB_ARRFactory; }
  /* constructors */
  public TQSTUB_ARR()
  {
    this((TQSTUB[])null);
  }

  public TQSTUB_ARR(TQSTUB[] a)
  {
    _array = new MutableArray(2002, a, TQSTUB.getORADataFactory());
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
    TQSTUB_ARR a = new TQSTUB_ARR();
    a._array = new MutableArray(2002, (ARRAY) d, TQSTUB.getORADataFactory());
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
  { TQSTUB[] a = (TQSTUB[])getArray();
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
    TQSTUB[] a = (TQSTUB[]) ois.readObject();
    _array = new MutableArray(2002, a, TQSTUB.getORADataFactory());
  }


  /* array accessor methods */
  public TQSTUB[] getArray() throws SQLException
  {
    return (TQSTUB[]) _array.getObjectArray(
      new TQSTUB[_array.length()]);
  }

  public TQSTUB[] getArray(long index, int count) throws SQLException
  {
    return (TQSTUB[]) _array.getObjectArray(index,
      new TQSTUB[_array.sliceLength(index, count)]);
  }

  public void setArray(TQSTUB[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(TQSTUB[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public TQSTUB getElement(long index) throws SQLException
  {
    return (TQSTUB) _array.getObjectElement(index);
  }

  public void setElement(TQSTUB a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

  public String toString()
  { try { String r = "TQREACTOR.TQSTUB_ARR" + "(";
     TQSTUB[] a = (TQSTUB[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + a[i];
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
