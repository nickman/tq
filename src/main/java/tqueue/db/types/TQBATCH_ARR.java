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

public class TQBATCH_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.TQBATCH_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final TQBATCH_ARR _TQBATCH_ARRFactory = new TQBATCH_ARR();

  public static ORADataFactory getORADataFactory()
  { return _TQBATCH_ARRFactory; }
  /* constructors */
  public TQBATCH_ARR()
  {
    this((TQBATCH[])null);
  }

  public TQBATCH_ARR(TQBATCH[] a)
  {
    _array = new MutableArray(2002, a, TQBATCH.getORADataFactory());
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
    TQBATCH_ARR a = new TQBATCH_ARR();
    a._array = new MutableArray(2002, (ARRAY) d, TQBATCH.getORADataFactory());
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
  { TQBATCH[] a = (TQBATCH[])getArray();
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
    TQBATCH[] a = (TQBATCH[]) ois.readObject();
    _array = new MutableArray(2002, a, TQBATCH.getORADataFactory());
  }


  /* array accessor methods */
  public TQBATCH[] getArray() throws SQLException
  {
    return (TQBATCH[]) _array.getObjectArray(
      new TQBATCH[_array.length()]);
  }

  public TQBATCH[] getArray(long index, int count) throws SQLException
  {
    return (TQBATCH[]) _array.getObjectArray(index,
      new TQBATCH[_array.sliceLength(index, count)]);
  }

  public void setArray(TQBATCH[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(TQBATCH[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public TQBATCH getElement(long index) throws SQLException
  {
    return (TQBATCH) _array.getObjectElement(index);
  }

  public void setElement(TQBATCH a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

  public String toString()
  { try { String r = "TQREACTOR.TQBATCH_ARR" + "(";
     TQBATCH[] a = (TQBATCH[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + a[i];
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
