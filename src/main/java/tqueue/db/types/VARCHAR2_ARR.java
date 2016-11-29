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

public class VARCHAR2_ARR implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_NAME = "TQREACTOR.VARCHAR2_ARR";
  public static final int _SQL_TYPECODE = OracleTypes.ARRAY;

  transient MutableArray _array;

private static final VARCHAR2_ARR _VARCHAR2_ARRFactory = new VARCHAR2_ARR();

  public static ORADataFactory getORADataFactory()
  { return _VARCHAR2_ARRFactory; }
  /* constructors */
  public VARCHAR2_ARR()
  {
    this((String[])null);
  }

  public VARCHAR2_ARR(String[] a)
  {
    _array = new MutableArray(12, a, null);
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
    VARCHAR2_ARR a = new VARCHAR2_ARR();
    a._array = new MutableArray(12, (ARRAY) d, null);
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
    String[] a = (String[]) ois.readObject();
    _array = new MutableArray(12, a, null);
  }


  /* array accessor methods */
  public String[] getArray() throws SQLException
  {
    return (String[]) _array.getObjectArray();
  }

  public String[] getArray(long index, int count) throws SQLException
  {
    return (String[]) _array.getObjectArray(index, count);
  }

  public void setArray(String[] a) throws SQLException
  {
    _array.setObjectArray(a);
  }

  public void setArray(String[] a, long index) throws SQLException
  {
    _array.setObjectArray(a, index);
  }

  public String getElement(long index) throws SQLException
  {
    return (String) _array.getObjectElement(index);
  }

  public void setElement(String a, long index) throws SQLException
  {
    _array.setObjectElement(a, index);
  }

  public String toString()
  { try { String r = "TQREACTOR.VARCHAR2_ARR" + "(";
     String[] a = (String[])getArray();
     for (int i=0; i<a.length; ) {
       r = r + ((a[i]==null)?"null": "'"+ a[i] +"'");
       i++; if (i<a.length) r = r + ","; }
     r = r + ")"; return r;
    } catch (SQLException e) { return e.toString(); }
  }

}
