package tqueue.obridge.packages;

import tqueue.obridge.context.*;
import tqueue.obridge.converters.*;
import tqueue.obridge.objects.*;

import javax.annotation.Generated;
import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.*;
import java.util.List;
import java.util.Arrays;

@Generated("org.obridge.generators.PackageObjectGenerator")
public final class ProceduresAndFunctions {

    private static final java.util.logging.Logger LOGGER = java.util.logging.Logger.getLogger(ProceduresAndFunctions.class.getName());

    private ProceduresAndFunctions() {
    }


    public static void xlogevent(Xlogevent ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"XLOGEVENT\"( " +
                                      "    \"MSG\" => :MSG" +
                                      "   ,\"ERRCODE\" => :ERRCODE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set MSG from context msg
            if (ctx.getMsg() != null) {
                ocs.setString(1, ctx.getMsg());
            } else {
                ocs.setNull(1, Types.VARCHAR);
            }
            // Set ERRCODE from context errcode
            if (ctx.getErrcode() != null) {
                ocs.setBigDecimal(2, ctx.getErrcode());
            } else {
                ocs.setNull(2, Types.NUMERIC);
            }
            LOGGER.info("ProceduresAndFunctions.xlogevent called");
            ocs.execute();
            LOGGER.info("ProceduresAndFunctions.xlogevent executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static Xlogevent xlogevent(String msg, BigDecimal errcode,  Connection connection) {
    final Xlogevent ctx = new Xlogevent();
    ctx.setMsg(msg);
    ctx.setErrcode(errcode);
    xlogevent(ctx, connection);
    return ctx;
}

    public static Xlogevent xlogevent(String msg, BigDecimal errcode,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return xlogevent(msg, errcode,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void xlogevent(DataSource dataSource, Xlogevent ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            xlogevent(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void squirrelGetErrorOffset(SquirrelGetErrorOffset ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"SQUIRREL_GET_ERROR_OFFSET\"( " +
                                      "    \"QUERY\" => :QUERY" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.NUMERIC); // null
            // Set QUERY from context query
            if (ctx.getQuery() != null) {
                ocs.setString(2, ctx.getQuery());
            } else {
                ocs.setNull(2, Types.VARCHAR);
            }
            LOGGER.info("ProceduresAndFunctions.squirrelGetErrorOffset called");
            ocs.execute();
            LOGGER.info("ProceduresAndFunctions.squirrelGetErrorOffset executed");
            ctx.setFunctionReturn(ocs.getBigDecimal(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static SquirrelGetErrorOffset squirrelGetErrorOffset(String query,  Connection connection) {
    final SquirrelGetErrorOffset ctx = new SquirrelGetErrorOffset();
    ctx.setQuery(query);
    squirrelGetErrorOffset(ctx, connection);
    return ctx;
}

    public static SquirrelGetErrorOffset squirrelGetErrorOffset(String query,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return squirrelGetErrorOffset(query,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void squirrelGetErrorOffset(DataSource dataSource, SquirrelGetErrorOffset ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            squirrelGetErrorOffset(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void tlogevent(Tlogevent ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TLOGEVENT\"( " +
                                      "    \"MESSAGE\" => :MESSAGE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set MESSAGE from context message
            if (ctx.getMessage() != null) {
                ocs.setString(1, ctx.getMessage());
            } else {
                ocs.setNull(1, Types.VARCHAR);
            }
            LOGGER.info("ProceduresAndFunctions.tlogevent called");
            ocs.execute();
            LOGGER.info("ProceduresAndFunctions.tlogevent executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static Tlogevent tlogevent(String message,  Connection connection) {
    final Tlogevent ctx = new Tlogevent();
    ctx.setMessage(message);
    tlogevent(ctx, connection);
    return ctx;
}

    public static Tlogevent tlogevent(String message,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return tlogevent(message,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void tlogevent(DataSource dataSource, Tlogevent ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            tlogevent(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void logevent(Logevent ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"LOGEVENT\"( " +
                                      "    \"MSG\" => :MSG" +
                                      "   ,\"ERRCODE\" => :ERRCODE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set MSG from context msg
            if (ctx.getMsg() != null) {
                ocs.setString(1, ctx.getMsg());
            } else {
                ocs.setNull(1, Types.VARCHAR);
            }
            // Set ERRCODE from context errcode
            if (ctx.getErrcode() != null) {
                ocs.setBigDecimal(2, ctx.getErrcode());
            } else {
                ocs.setNull(2, Types.NUMERIC);
            }
            LOGGER.info("ProceduresAndFunctions.logevent called");
            ocs.execute();
            LOGGER.info("ProceduresAndFunctions.logevent executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static Logevent logevent(String msg, BigDecimal errcode,  Connection connection) {
    final Logevent ctx = new Logevent();
    ctx.setMsg(msg);
    ctx.setErrcode(errcode);
    logevent(ctx, connection);
    return ctx;
}

    public static Logevent logevent(String msg, BigDecimal errcode,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return logevent(msg, errcode,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void logevent(DataSource dataSource, Logevent ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            logevent(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



}
