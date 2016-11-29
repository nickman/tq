package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.REF;
import oracle.sql.STRUCT;

public class TQSTUBS_OBJRef implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_BASETYPE = "TQREACTOR.TQSTUBS_OBJ";
  public static final int _SQL_TYPECODE = OracleTypes.REF;

  REF _ref;

private static final TQSTUBS_OBJRef _TQSTUBS_OBJRefFactory = new TQSTUBS_OBJRef();

  public static ORADataFactory getORADataFactory()
  { return _TQSTUBS_OBJRefFactory; }
  /* constructor */
  public TQSTUBS_OBJRef()
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
    TQSTUBS_OBJRef r = new TQSTUBS_OBJRef();
    r._ref = (REF) d;
    return r;
  }

  /* Serializability */
  public void restoreConnection(Connection conn) throws SQLException
  { _ref.setPhysicalConnectionOf(conn); }

  public static TQSTUBS_OBJRef cast(ORAData o) throws SQLException
  {
     if (o == null) return null;
     try { return (TQSTUBS_OBJRef) getORADataFactory().create(o.toDatum(null), OracleTypes.REF); }
     catch (Exception exn)
     { throw new SQLException("Unable to convert "+o.getClass().getName()+" to TQSTUBS_OBJRef: "+exn.toString()); }
  }

  public TQSTUBS_OBJ getValue() throws SQLException
  {
     return (TQSTUBS_OBJ) TQSTUBS_OBJ.getORADataFactory().create(
       _ref.getSTRUCT(), OracleTypes.REF);
  }

  public void setValue(TQSTUBS_OBJ c) throws SQLException
  {
    _ref.setValue((STRUCT) c.toDatum(_ref.getJavaSqlConnection()));
  }
  public String toString()
  { try {
      return "REF " + _ref.getBaseTypeName() + "(" + _ref + ")";
    } catch (SQLException e) { return e.toString(); }
  }

}
