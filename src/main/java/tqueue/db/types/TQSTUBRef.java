package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.REF;
import oracle.sql.STRUCT;

public class TQSTUBRef implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_BASETYPE = "TQREACTOR.TQSTUB";
  public static final int _SQL_TYPECODE = OracleTypes.REF;

  REF _ref;

private static final TQSTUBRef _TQSTUBRefFactory = new TQSTUBRef();

  public static ORADataFactory getORADataFactory()
  { return _TQSTUBRefFactory; }
  /* constructor */
  public TQSTUBRef()
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
    TQSTUBRef r = new TQSTUBRef();
    r._ref = (REF) d;
    return r;
  }

  /* Serializability */
  public void restoreConnection(Connection conn) throws SQLException
  { _ref.setPhysicalConnectionOf(conn); }

  public static TQSTUBRef cast(ORAData o) throws SQLException
  {
     if (o == null) return null;
     try { return (TQSTUBRef) getORADataFactory().create(o.toDatum(null), OracleTypes.REF); }
     catch (Exception exn)
     { throw new SQLException("Unable to convert "+o.getClass().getName()+" to TQSTUBRef: "+exn.toString()); }
  }

  public TQSTUB getValue() throws SQLException
  {
     return (TQSTUB) TQSTUB.getORADataFactory().create(
       _ref.getSTRUCT(), OracleTypes.REF);
  }

  public void setValue(TQSTUB c) throws SQLException
  {
    _ref.setValue((STRUCT) c.toDatum(_ref.getJavaSqlConnection()));
  }
  public String toString()
  { try {
      return "REF " + _ref.getBaseTypeName() + "(" + _ref + ")";
    } catch (SQLException e) { return e.toString(); }
  }

}
