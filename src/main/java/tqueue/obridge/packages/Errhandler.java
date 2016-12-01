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
public final class Errhandler {

    private static final java.util.logging.Logger LOGGER = java.util.logging.Logger.getLogger(Errhandler.class.getName());

    private Errhandler() {
    }


    public static void err(ErrhandlerErr ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"ERRHANDLER\".\"ERR\"( " +
                                      "    \"FORMAT\" => :FORMAT" +
                                      "   ,\"ARGS\" => :ARGS" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.VARCHAR); // null
            // Set FORMAT from context format
            if (ctx.getFormat() != null) {
                ocs.setString(2, ctx.getFormat());
            } else {
                ocs.setNull(2, Types.VARCHAR);
            }
            // Set ARGS from context args
            ocs.setObject(3, PrimitiveTypeConverter.getListArray(ctx.getArgs(), connection, "VCHAR_ARR"));
            LOGGER.info("Errhandler.err called");
            ocs.execute();
            LOGGER.info("Errhandler.err executed");
            ctx.setFunctionReturn(ocs.getString(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static ErrhandlerErr err(String format, List<String> args,  Connection connection) {
    final ErrhandlerErr ctx = new ErrhandlerErr();
    ctx.setFormat(format);
    ctx.setArgs(args);
    err(ctx, connection);
    return ctx;
}

    public static ErrhandlerErr err(String format, List<String> args,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return err(format, args,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void err(DataSource dataSource, ErrhandlerErr ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            err(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



}
