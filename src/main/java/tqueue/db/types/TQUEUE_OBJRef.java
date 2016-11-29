package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.REF;
import oracle.sql.STRUCT;

public class TQUEUE_OBJRef implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_BASETYPE = "TQREACTOR.TQUEUE_OBJ";
  public static final int _SQL_TYPECODE = OracleTypes.REF;

  REF _ref;

private static final TQUEUE_OBJRef _TQUEUE_OBJRefFactory = new TQUEUE_OBJRef();

  public static ORADataFactory getORADataFactory()
  { return _TQUEUE_OBJRefFactory; }
  /* constructor */
  public TQUEUE_OBJRef()
  {
  }

  /* ORAData interface */
  public Datum toDatum(Connection c) throws SQLException
  {
    return _ref;
  }

  /* ORADataFactory interface */
  public ORAData create(Datum d, int sqlType) throws SQLException
  {
    if (d == null) return null; 
    TQUEUE_OBJRef r = new TQUEUE_OBJRef();
    r._ref = (REF) d;
    return r;
  }

  /* Serializability */
  public void restoreConnection(Connection conn) throws SQLException
  { _ref.setPhysicalConnectionOf(conn); }

  public static TQUEUE_OBJRef cast(ORAData o) throws SQLException
  {
     if (o == null) return null;
     try { return (TQUEUE_OBJRef) getORADataFactory().create(o.toDatum(null), OracleTypes.REF); }
     catch (Exception exn)
     { throw new SQLException("Unable to convert "+o.getClass().getName()+" to TQUEUE_OBJRef: "+exn.toString()); }
  }

  public TQUEUE_OBJ getValue() throws SQLException
  {
     return (TQUEUE_OBJ) TQUEUE_OBJ.getORADataFactory().create(
       _ref.getSTRUCT(), OracleTypes.REF);
  }

  public void setValue(TQUEUE_OBJ c) throws SQLException
  {
    _ref.setValue((STRUCT) c.toDatum(_ref.getJavaSqlConnection()));
  }
  public String toString()
  { try {
      return "REF " + _ref.getBaseTypeName() + "(" + _ref + ")";
    } catch (SQLException e) { return e.toString(); }
  }

}
