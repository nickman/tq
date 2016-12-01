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
public final class Ord {

    private static final java.util.logging.Logger LOGGER = java.util.logging.Logger.getLogger(Ord.class.getName());

    private Ord() {
    }


    public static void streamorders(OrdStreamorders ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"ORD\".\"STREAMORDERS\"( " +
                                      "    \"CNT\" => :CNT" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "FULLORDER_ARR"); // null
            // Set CNT from context cnt
            if (ctx.getCnt() != null) {
                ocs.setInt(2, ctx.getCnt());
            } else {
                ocs.setNull(2, Types.INTEGER);
            }
            LOGGER.info("Ord.streamorders called");
            ocs.execute();
            LOGGER.info("Ord.streamorders executed");
            ctx.setFunctionReturn(FullorderConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static OrdStreamorders streamorders(Integer cnt,  Connection connection) {
    final OrdStreamorders ctx = new OrdStreamorders();
    ctx.setCnt(cnt);
    streamorders(ctx, connection);
    return ctx;
}

    public static OrdStreamorders streamorders(Integer cnt,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return streamorders(cnt,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void streamorders(DataSource dataSource, OrdStreamorders ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            streamorders(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void streamquery(OrdStreamquery ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"ORD\".\"STREAMQUERY\"( " +
                                      "    \"CNT\" => :CNT" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, -10); // null
            // Set CNT from context cnt
            if (ctx.getCnt() != null) {
                ocs.setInt(2, ctx.getCnt());
            } else {
                ocs.setNull(2, Types.INTEGER);
            }
            LOGGER.info("Ord.streamquery called");
            ocs.execute();
            LOGGER.info("Ord.streamquery executed");
            ctx.setFunctionReturn((ResultSet)ocs.getObject(1)); // null
        } finally  {
            // ResultSet as return parameter, not closing connection
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static OrdStreamquery streamquery(Integer cnt,  Connection connection) {
    final OrdStreamquery ctx = new OrdStreamquery();
    ctx.setCnt(cnt);
    streamquery(ctx, connection);
    return ctx;
}






}
