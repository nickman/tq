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

public class TQUEUE_OBJ_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQUEUE_OBJ_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final TQUEUE_OBJ_ARR _TQUEUE_OBJ_ARRFactory = new TQUEUE_OBJ_ARR();

  public static ORADataFactory getORADataFactory()
  { return _TQUEUE_OBJ_ARRFactory; }
  /* constructors */
  public TQUEUE_OBJ_ARR()
  {
    this((TQUEUE_OBJ[])null);
  }

  public TQUEUE_OBJ_ARR(TQUEUE_OBJ[] a)
  {
    _array = new MutableArray(2002, a, TQUEUE_OBJ.getORADataFactory());
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
    TQUEUE_OBJ_ARR a = new TQUEUE_OBJ_ARR();
    a._array = new MutableArray(2002, (ARRAY) d, TQUEUE_OBJ.getORADataFactory());
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
  { TQUEUE_OBJ[] a = (TQUEUE_OBJ[])getArray();
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
    TQUEUE_OBJ[] a = (TQUEUE_OBJ[]) ois.readObject();
    _array = new MutableArray(2002, a, TQUEUE_OBJ.getORADataFactory());
  }


  /* array accessor methods */
  public TQUEUE_OBJ[] getArray() throws SQLException
  {
    return (TQUEUE_OBJ[]) _array.getObjectArray(
      new TQUEUE_OBJ[_array.length()]);
  }

  public TQUEUE_OBJ[] getArray(long index, int count) throws SQLException
  {
    return (TQUEUE_OBJ[]) _array.getObjectArray(index,
      new TQUEUE_OBJ[_array.sliceLength(index, count)]);
  }

  public void setArray(TQUEUE_OBJ[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(TQUEUE_OBJ[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public TQUEUE_OBJ getElement(long index) throws SQLException
  {
    return (TQUEUE_OBJ) _array.getObjectElement(index);
  }

  public void setElement(TQUEUE_OBJ a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

  public String toString()
  { try { String r = "TQREACTOR.TQUEUE_OBJ_ARR" + "(";
     TQUEUE_OBJ[] a = (TQUEUE_OBJ[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + a[i];
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
