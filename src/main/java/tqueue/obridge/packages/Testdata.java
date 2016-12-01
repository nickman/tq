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
public final class Testdata {

    private static final java.util.logging.Logger LOGGER = java.util.logging.Logger.getLogger(Testdata.class.getName());

    private Testdata() {
    }


    public static void randomacct(TestdataRandomacct ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"RANDOMACCT\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.STRUCT, "ACCT_DECODE"); // null
            LOGGER.info("Testdata.randomacct called");
            ocs.execute();
            LOGGER.info("Testdata.randomacct executed");
            ctx.setFunctionReturn(AcctDecodeConverter.getObject((Struct)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataRandomacct randomacct( Connection connection) {
    final TestdataRandomacct ctx = new TestdataRandomacct();
    randomacct(ctx, connection);
    return ctx;
}

    public static TestdataRandomacct randomacct( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return randomacct( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void randomacct(DataSource dataSource, TestdataRandomacct ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            randomacct(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void randomsec(TestdataRandomsec ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"RANDOMSEC\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.STRUCT, "SEC_DECODE"); // null
            LOGGER.info("Testdata.randomsec called");
            ocs.execute();
            LOGGER.info("Testdata.randomsec executed");
            ctx.setFunctionReturn(SecDecodeConverter.getObject((Struct)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataRandomsec randomsec( Connection connection) {
    final TestdataRandomsec ctx = new TestdataRandomsec();
    randomsec(ctx, connection);
    return ctx;
}

    public static TestdataRandomsec randomsec( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return randomsec( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void randomsec(DataSource dataSource, TestdataRandomsec ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            randomsec(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void gentrades(TestdataGentrades ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TESTDATA\".\"GENTRADES\"( " +
                                      "    \"TRADECOUNT\" => :TRADECOUNT" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set TRADECOUNT from context tradecount
            if (ctx.getTradecount() != null) {
                ocs.setBigDecimal(1, ctx.getTradecount());
            } else {
                ocs.setNull(1, Types.NUMERIC);
            }
            LOGGER.info("Testdata.gentrades called");
            ocs.execute();
            LOGGER.info("Testdata.gentrades executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataGentrades gentrades(BigDecimal tradecount,  Connection connection) {
    final TestdataGentrades ctx = new TestdataGentrades();
    ctx.setTradecount(tradecount);
    gentrades(ctx, connection);
    return ctx;
}

    public static TestdataGentrades gentrades(BigDecimal tradecount,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return gentrades(tradecount,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void gentrades(DataSource dataSource, TestdataGentrades ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            gentrades(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void forceloadcache(TestdataForceloadcache ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"FORCELOADCACHE\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.VARCHAR); // null
            LOGGER.info("Testdata.forceloadcache called");
            ocs.execute();
            LOGGER.info("Testdata.forceloadcache executed");
            ctx.setFunctionReturn(ocs.getString(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataForceloadcache forceloadcache( Connection connection) {
    final TestdataForceloadcache ctx = new TestdataForceloadcache();
    forceloadcache(ctx, connection);
    return ctx;
}

    public static TestdataForceloadcache forceloadcache( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return forceloadcache( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void forceloadcache(DataSource dataSource, TestdataForceloadcache ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            forceloadcache(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void randomsectype(TestdataRandomsectype ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"RANDOMSECTYPE\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.CHAR); // null
            LOGGER.info("Testdata.randomsectype called");
            ocs.execute();
            LOGGER.info("Testdata.randomsectype executed");
            ctx.setFunctionReturn(ocs.getString(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataRandomsectype randomsectype( Connection connection) {
    final TestdataRandomsectype ctx = new TestdataRandomsectype();
    randomsectype(ctx, connection);
    return ctx;
}

    public static TestdataRandomsectype randomsectype( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return randomsectype( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void randomsectype(DataSource dataSource, TestdataRandomsectype ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            randomsectype(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void genaccts(TestdataGenaccts ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TESTDATA\".\"GENACCTS\"( " +
                                      "    \"ACCTCOUNT\" => :ACCTCOUNT" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set ACCTCOUNT from context acctcount
            if (ctx.getAcctcount() != null) {
                ocs.setBigDecimal(1, ctx.getAcctcount());
            } else {
                ocs.setNull(1, Types.NUMERIC);
            }
            LOGGER.info("Testdata.genaccts called");
            ocs.execute();
            LOGGER.info("Testdata.genaccts executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataGenaccts genaccts(BigDecimal acctcount,  Connection connection) {
    final TestdataGenaccts ctx = new TestdataGenaccts();
    ctx.setAcctcount(acctcount);
    genaccts(ctx, connection);
    return ctx;
}

    public static TestdataGenaccts genaccts(BigDecimal acctcount,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return genaccts(acctcount,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void genaccts(DataSource dataSource, TestdataGenaccts ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            genaccts(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void gensecs(TestdataGensecs ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TESTDATA\".\"GENSECS\"( " +
                                      "    \"SECCOUNT\" => :SECCOUNT" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set SECCOUNT from context seccount
            if (ctx.getSeccount() != null) {
                ocs.setBigDecimal(1, ctx.getSeccount());
            } else {
                ocs.setNull(1, Types.NUMERIC);
            }
            LOGGER.info("Testdata.gensecs called");
            ocs.execute();
            LOGGER.info("Testdata.gensecs executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataGensecs gensecs(BigDecimal seccount,  Connection connection) {
    final TestdataGensecs ctx = new TestdataGensecs();
    ctx.setSeccount(seccount);
    gensecs(ctx, connection);
    return ctx;
}

    public static TestdataGensecs gensecs(BigDecimal seccount,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return gensecs(seccount,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void gensecs(DataSource dataSource, TestdataGensecs ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            gensecs(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void pipeacctcache(TestdataPipeacctcache ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"PIPEACCTCACHE\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "ACCT_DECODE_ARR"); // null
            LOGGER.info("Testdata.pipeacctcache called");
            ocs.execute();
            LOGGER.info("Testdata.pipeacctcache executed");
            ctx.setFunctionReturn(AcctDecodeConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataPipeacctcache pipeacctcache( Connection connection) {
    final TestdataPipeacctcache ctx = new TestdataPipeacctcache();
    pipeacctcache(ctx, connection);
    return ctx;
}

    public static TestdataPipeacctcache pipeacctcache( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return pipeacctcache( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void pipeacctcache(DataSource dataSource, TestdataPipeacctcache ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            pipeacctcache(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void pipeseccache(TestdataPipeseccache ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TESTDATA\".\"PIPESECCACHE\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "SEC_DECODE_ARR"); // null
            LOGGER.info("Testdata.pipeseccache called");
            ocs.execute();
            LOGGER.info("Testdata.pipeseccache executed");
            ctx.setFunctionReturn(SecDecodeConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TestdataPipeseccache pipeseccache( Connection connection) {
    final TestdataPipeseccache ctx = new TestdataPipeseccache();
    pipeseccache(ctx, connection);
    return ctx;
}

    public static TestdataPipeseccache pipeseccache( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return pipeseccache( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void pipeseccache(DataSource dataSource, TestdataPipeseccache ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            pipeseccache(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



}
