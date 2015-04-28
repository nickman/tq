package tqueue.db.types;

import java.sql.SQLException;
import java.sql.Connection;
import oracle.jdbc.OracleTypes;
import oracle.sql.ORAData;
import oracle.sql.ORADataFactory;
import oracle.sql.Datum;
import oracle.sql.REF;
import oracle.sql.STRUCT;

public class TQTRADERef implements ORAData, ORADataFactory, java.io.Serializable
{
  public static final String _SQL_BASETYPE = "TQREACTOR.TQTRADE";
  public static final int _SQL_TYPECODE = OracleTypes.REF;

  REF _ref;

private static final TQTRADERef _TQTRADERefFactory = new TQTRADERef();

  public static ORADataFactory getORADataFactory()
  { return _TQTRADERefFactory; }
  /* constructor */
  public TQTRADERef()
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
    TQTRADERef r = new TQTRADERef();
    r._ref = (REF) d;
    return r;
  }

  /* Serializability */
  public void restoreConnection(Connection conn) throws SQLException
  { _ref.setPhysicalConnectionOf(conn); }

  public static TQTRADERef cast(ORAData o) throws SQLException
  {
     if (o == null) return null;
     try { return (TQTRADERef) getORADataFactory().create(o.toDatum(null), OracleTypes.REF); }
     catch (Exception exn)
     { throw new SQLException("Unable to convert "+o.getClass().getName()+" to TQTRADERef: "+exn.toString()); }
  }

  public TQTRADE getValue() throws SQLException
  {
     return (TQTRADE) TQTRADE.getORADataFactory().create(
       _ref.getSTRUCT(), OracleTypes.REF);
  }

  public void setValue(TQTRADE c) throws SQLException
  {
    _ref.setValue((STRUCT) c.toDatum(_ref.getJavaSqlConnection()));
  }
  public String toString()
  { try {
      return "REF " + _ref.getBaseTypeName() + "(" + _ref + ")";
    } catch (SQLException e) { return e.toString(); }
  }

}
