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
public final class Tq {

    private static final java.util.logging.Logger LOGGER = java.util.logging.Logger.getLogger(Tq.class.getName());

    private Tq() {
    }


    public static void log(TqLog ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"LOG\"( " +
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
            LOGGER.info("Tq.log called");
            ocs.execute();
            LOGGER.info("Tq.log executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqLog log(String message,  Connection connection) {
    final TqLog ctx = new TqLog();
    ctx.setMessage(message);
    log(ctx, connection);
    return ctx;
}

    public static TqLog log(String message,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return log(message,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void log(DataSource dataSource, TqLog ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            log(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void setTcplogEnabled(TqSetTcplogEnabled ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"SET_TCPLOG_ENABLED\"( " +
                                      "    \"ENABLED\" => :ENABLED" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set ENABLED from context enabled
            if (ctx.getEnabled() != null) {
                ocs.setInt(1, ctx.getEnabled());
            } else {
                ocs.setNull(1, Types.INTEGER);
            }
            LOGGER.info("Tq.setTcplogEnabled called");
            ocs.execute();
            LOGGER.info("Tq.setTcplogEnabled executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqSetTcplogEnabled setTcplogEnabled(Integer enabled,  Connection connection) {
    final TqSetTcplogEnabled ctx = new TqSetTcplogEnabled();
    ctx.setEnabled(enabled);
    setTcplogEnabled(ctx, connection);
    return ctx;
}

    public static TqSetTcplogEnabled setTcplogEnabled(Integer enabled,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return setTcplogEnabled(enabled,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void setTcplogEnabled(DataSource dataSource, TqSetTcplogEnabled ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            setTcplogEnabled(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void isTcplogEnabled(TqIsTcplogEnabled ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"IS_TCPLOG_ENABLED\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.INTEGER); // null
            LOGGER.info("Tq.isTcplogEnabled called");
            ocs.execute();
            LOGGER.info("Tq.isTcplogEnabled executed");
            ctx.setFunctionReturn(ocs.getInt(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqIsTcplogEnabled isTcplogEnabled( Connection connection) {
    final TqIsTcplogEnabled ctx = new TqIsTcplogEnabled();
    isTcplogEnabled(ctx, connection);
    return ctx;
}

    public static TqIsTcplogEnabled isTcplogEnabled( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return isTcplogEnabled( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void isTcplogEnabled(DataSource dataSource, TqIsTcplogEnabled ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            isTcplogEnabled(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void decodeSecurity2(TqDecodeSecurity2 ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"DECODE_SECURITY\"( " +
                                      "    \"SECURITYDISPLAYNAME\" => :SECURITYDISPLAYNAME" +
                                      "   ,\"SECURITYID\" => :SECURITYID" +
                                      "   ,\"SECURITYTYPE\" => :SECURITYTYPE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set SECURITYDISPLAYNAME from context securitydisplayname
            if (ctx.getSecuritydisplayname() != null) {
                ocs.setString(1, ctx.getSecuritydisplayname());
            } else {
                ocs.setNull(1, Types.VARCHAR);
            }
            ocs.registerOutParameter(2, Types.NUMERIC); // SECURITYID
            ocs.registerOutParameter(3, Types.CHAR); // SECURITYTYPE
            LOGGER.info("Tq.decodeSecurity2 called");
            ocs.execute();
            LOGGER.info("Tq.decodeSecurity2 executed");
            ctx.setSecurityid(ocs.getBigDecimal(2)); // SECURITYID
            ctx.setSecuritytype(ocs.getString(3)); // SECURITYTYPE
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqDecodeSecurity2 decodeSecurity2(String securitydisplayname,  Connection connection) {
    final TqDecodeSecurity2 ctx = new TqDecodeSecurity2();
    ctx.setSecuritydisplayname(securitydisplayname);
    decodeSecurity2(ctx, connection);
    return ctx;
}

    public static TqDecodeSecurity2 decodeSecurity2(String securitydisplayname,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return decodeSecurity2(securitydisplayname,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void decodeSecurity2(DataSource dataSource, TqDecodeSecurity2 ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            decodeSecurity2(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void decodeAccount2(TqDecodeAccount2 ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"DECODE_ACCOUNT\"( " +
                                      "    \"ACCOUNTDISPLAYNAME\" => :ACCOUNTDISPLAYNAME" +
                                      "   ,\"ACCOUNTID\" => :ACCOUNTID" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set ACCOUNTDISPLAYNAME from context accountdisplayname
            if (ctx.getAccountdisplayname() != null) {
                ocs.setString(1, ctx.getAccountdisplayname());
            } else {
                ocs.setNull(1, Types.VARCHAR);
            }
            ocs.registerOutParameter(2, Types.NUMERIC); // ACCOUNTID
            LOGGER.info("Tq.decodeAccount2 called");
            ocs.execute();
            LOGGER.info("Tq.decodeAccount2 executed");
            ctx.setAccountid(ocs.getBigDecimal(2)); // ACCOUNTID
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqDecodeAccount2 decodeAccount2(String accountdisplayname,  Connection connection) {
    final TqDecodeAccount2 ctx = new TqDecodeAccount2();
    ctx.setAccountdisplayname(accountdisplayname);
    decodeAccount2(ctx, connection);
    return ctx;
}

    public static TqDecodeAccount2 decodeAccount2(String accountdisplayname,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return decodeAccount2(accountdisplayname,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void decodeAccount2(DataSource dataSource, TqDecodeAccount2 ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            decodeAccount2(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void triggerStub(TqTriggerStub ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"TRIGGER_STUB\"( " +
                                      "    \"ROWID\" => :ROWID" +
                                      "   ,\"TQUEUEID\" => :TQUEUEID" +
                                      "   ,\"STATUSCODE\" => :STATUSCODE" +
                                      "   ,\"SECURITYDISPLAYNAME\" => :SECURITYDISPLAYNAME" +
                                      "   ,\"ACCOUNTDISPLAYNAME\" => :ACCOUNTDISPLAYNAME" +
                                      "   ,\"BATCHID\" => :BATCHID" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set ROWID from context rowid
            if (ctx.getRowid() != null) {
                ocs.setObject(1, ctx.getRowid());
            } else {
                ocs.setNull(1, Types.ROWID);
            }
            // Set TQUEUEID from context tqueueid
            if (ctx.getTqueueid() != null) {
                ocs.setBigDecimal(2, ctx.getTqueueid());
            } else {
                ocs.setNull(2, Types.NUMERIC);
            }
            // Set STATUSCODE from context statuscode
            if (ctx.getStatuscode() != null) {
                ocs.setString(3, ctx.getStatuscode());
            } else {
                ocs.setNull(3, Types.VARCHAR);
            }
            // Set SECURITYDISPLAYNAME from context securitydisplayname
            if (ctx.getSecuritydisplayname() != null) {
                ocs.setString(4, ctx.getSecuritydisplayname());
            } else {
                ocs.setNull(4, Types.VARCHAR);
            }
            // Set ACCOUNTDISPLAYNAME from context accountdisplayname
            if (ctx.getAccountdisplayname() != null) {
                ocs.setString(5, ctx.getAccountdisplayname());
            } else {
                ocs.setNull(5, Types.VARCHAR);
            }
            // Set BATCHID from context batchid
            if (ctx.getBatchid() != null) {
                ocs.setBigDecimal(6, ctx.getBatchid());
            } else {
                ocs.setNull(6, Types.NUMERIC);
            }
            LOGGER.info("Tq.triggerStub called");
            ocs.execute();
            LOGGER.info("Tq.triggerStub executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqTriggerStub triggerStub(Object rowid, BigDecimal tqueueid, String statuscode, String securitydisplayname, String accountdisplayname, BigDecimal batchid,  Connection connection) {
    final TqTriggerStub ctx = new TqTriggerStub();
    ctx.setRowid(rowid);
    ctx.setTqueueid(tqueueid);
    ctx.setStatuscode(statuscode);
    ctx.setSecuritydisplayname(securitydisplayname);
    ctx.setAccountdisplayname(accountdisplayname);
    ctx.setBatchid(batchid);
    triggerStub(ctx, connection);
    return ctx;
}

    public static TqTriggerStub triggerStub(Object rowid, BigDecimal tqueueid, String statuscode, String securitydisplayname, String accountdisplayname, BigDecimal batchid,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return triggerStub(rowid, tqueueid, statuscode, securitydisplayname, accountdisplayname, batchid,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void triggerStub(DataSource dataSource, TqTriggerStub ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            triggerStub(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void groupTqbatches(TqGroupTqbatches ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"GROUP_TQBATCHES\"( " +
                                      "    \"THREADMOD\" => :THREADMOD" +
                                      "   ,\"ROWLIMIT\" => :ROWLIMIT" +
                                      "   ,\"THREADCOUNT\" => :THREADCOUNT" +
                                      "   ,\"BUCKETSIZE\" => :BUCKETSIZE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "TQBATCH_ARR"); // null
            // Set THREADMOD from context threadmod
            if (ctx.getThreadmod() != null) {
                ocs.setInt(2, ctx.getThreadmod());
            } else {
                ocs.setNull(2, Types.INTEGER);
            }
            // Set ROWLIMIT from context rowlimit
            if (ctx.getRowlimit() != null) {
                ocs.setInt(3, ctx.getRowlimit());
            } else {
                ocs.setNull(3, Types.INTEGER);
            }
            // Set THREADCOUNT from context threadcount
            if (ctx.getThreadcount() != null) {
                ocs.setInt(4, ctx.getThreadcount());
            } else {
                ocs.setNull(4, Types.INTEGER);
            }
            // Set BUCKETSIZE from context bucketsize
            if (ctx.getBucketsize() != null) {
                ocs.setInt(5, ctx.getBucketsize());
            } else {
                ocs.setNull(5, Types.INTEGER);
            }
            LOGGER.info("Tq.groupTqbatches called");
            ocs.execute();
            LOGGER.info("Tq.groupTqbatches executed");
            ctx.setFunctionReturn(TqbatchConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqGroupTqbatches groupTqbatches(Integer threadmod, Integer rowlimit, Integer threadcount, Integer bucketsize,  Connection connection) {
    final TqGroupTqbatches ctx = new TqGroupTqbatches();
    ctx.setThreadmod(threadmod);
    ctx.setRowlimit(rowlimit);
    ctx.setThreadcount(threadcount);
    ctx.setBucketsize(bucketsize);
    groupTqbatches(ctx, connection);
    return ctx;
}

    public static TqGroupTqbatches groupTqbatches(Integer threadmod, Integer rowlimit, Integer threadcount, Integer bucketsize,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return groupTqbatches(threadmod, rowlimit, threadcount, bucketsize,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void groupTqbatches(DataSource dataSource, TqGroupTqbatches ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            groupTqbatches(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void queryBatches(TqQueryBatches ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"QUERY_BATCHES\"( " +
                                      "    \"THREADMOD\" => :THREADMOD" +
                                      "   ,\"ROWLIMIT\" => :ROWLIMIT" +
                                      "   ,\"THREADCOUNT\" => :THREADCOUNT" +
                                      "   ,\"BUCKETSIZE\" => :BUCKETSIZE" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "TQSTUBS_OBJ_ARR"); // null
            // Set THREADMOD from context threadmod
            if (ctx.getThreadmod() != null) {
                ocs.setInt(2, ctx.getThreadmod());
            } else {
                ocs.setNull(2, Types.INTEGER);
            }
            // Set ROWLIMIT from context rowlimit
            if (ctx.getRowlimit() != null) {
                ocs.setInt(3, ctx.getRowlimit());
            } else {
                ocs.setNull(3, Types.INTEGER);
            }
            // Set THREADCOUNT from context threadcount
            if (ctx.getThreadcount() != null) {
                ocs.setInt(4, ctx.getThreadcount());
            } else {
                ocs.setNull(4, Types.INTEGER);
            }
            // Set BUCKETSIZE from context bucketsize
            if (ctx.getBucketsize() != null) {
                ocs.setInt(5, ctx.getBucketsize());
            } else {
                ocs.setNull(5, Types.INTEGER);
            }
            LOGGER.info("Tq.queryBatches called");
            ocs.execute();
            LOGGER.info("Tq.queryBatches executed");
            ctx.setFunctionReturn(TqstubsObjConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqQueryBatches queryBatches(Integer threadmod, Integer rowlimit, Integer threadcount, Integer bucketsize,  Connection connection) {
    final TqQueryBatches ctx = new TqQueryBatches();
    ctx.setThreadmod(threadmod);
    ctx.setRowlimit(rowlimit);
    ctx.setThreadcount(threadcount);
    ctx.setBucketsize(bucketsize);
    queryBatches(ctx, connection);
    return ctx;
}

    public static TqQueryBatches queryBatches(Integer threadmod, Integer rowlimit, Integer threadcount, Integer bucketsize,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return queryBatches(threadmod, rowlimit, threadcount, bucketsize,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void queryBatches(DataSource dataSource, TqQueryBatches ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            queryBatches(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void getTradeBatch(TqGetTradeBatch ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"GET_TRADE_BATCH\"( " +
                                      "    \"XROWIDS\" => :XROWIDS" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "TQUEUE_OBJ_ARR"); // null
            // Set XROWIDS from context xrowids
            ocs.setObject(2, PrimitiveTypeConverter.getListArray(ctx.getXrowids(), connection, "XROWIDS"));
            LOGGER.info("Tq.getTradeBatch called");
            ocs.execute();
            LOGGER.info("Tq.getTradeBatch executed");
            ctx.setFunctionReturn(TqueueObjConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqGetTradeBatch getTradeBatch(List<String> xrowids,  Connection connection) {
    final TqGetTradeBatch ctx = new TqGetTradeBatch();
    ctx.setXrowids(xrowids);
    getTradeBatch(ctx, connection);
    return ctx;
}

    public static TqGetTradeBatch getTradeBatch(List<String> xrowids,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return getTradeBatch(xrowids,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void getTradeBatch(DataSource dataSource, TqGetTradeBatch ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            getTradeBatch(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void pipeTradeBatch(TqPipeTradeBatch ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"PIPE_TRADE_BATCH\"( " +
                                      "    \"XROWIDS\" => :XROWIDS" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "TQUEUE_OBJ_ARR"); // null
            // Set XROWIDS from context xrowids
            ocs.setObject(2, PrimitiveTypeConverter.getListArray(ctx.getXrowids(), connection, "XROWIDS"));
            LOGGER.info("Tq.pipeTradeBatch called");
            ocs.execute();
            LOGGER.info("Tq.pipeTradeBatch executed");
            ctx.setFunctionReturn(TqueueObjConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqPipeTradeBatch pipeTradeBatch(List<String> xrowids,  Connection connection) {
    final TqPipeTradeBatch ctx = new TqPipeTradeBatch();
    ctx.setXrowids(xrowids);
    pipeTradeBatch(ctx, connection);
    return ctx;
}

    public static TqPipeTradeBatch pipeTradeBatch(List<String> xrowids,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return pipeTradeBatch(xrowids,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void pipeTradeBatch(DataSource dataSource, TqPipeTradeBatch ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            pipeTradeBatch(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void parsePipeTradeBatch(TqParsePipeTradeBatch ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"PARSE_PIPE_TRADE_BATCH\"( " +
                                      "    \"XROWIDSTR\" => :XROWIDSTR" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.ARRAY, "TQUEUE_OBJ_ARR"); // null
            // Set XROWIDSTR from context xrowidstr
            if (ctx.getXrowidstr() != null) {
                ocs.setString(2, ctx.getXrowidstr());
            } else {
                ocs.setNull(2, Types.VARCHAR);
            }
            LOGGER.info("Tq.parsePipeTradeBatch called");
            ocs.execute();
            LOGGER.info("Tq.parsePipeTradeBatch executed");
            ctx.setFunctionReturn(TqueueObjConverter.getObjectList((Array)ocs.getObject(1))); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqParsePipeTradeBatch parsePipeTradeBatch(String xrowidstr,  Connection connection) {
    final TqParsePipeTradeBatch ctx = new TqParsePipeTradeBatch();
    ctx.setXrowidstr(xrowidstr);
    parsePipeTradeBatch(ctx, connection);
    return ctx;
}

    public static TqParsePipeTradeBatch parsePipeTradeBatch(String xrowidstr,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return parsePipeTradeBatch(xrowidstr,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void parsePipeTradeBatch(DataSource dataSource, TqParsePipeTradeBatch ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            parsePipeTradeBatch(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void deleteStubBatch(TqDeleteStubBatch ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"DELETE_STUB_BATCH\"( " +
                                      "    \"XROWIDS\" => :XROWIDS" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.NUMERIC); // null
            // Set XROWIDS from context xrowids
            ocs.setObject(2, PrimitiveTypeConverter.getListArray(ctx.getXrowids(), connection, "XROWIDS"));
            LOGGER.info("Tq.deleteStubBatch called");
            ocs.execute();
            LOGGER.info("Tq.deleteStubBatch executed");
            ctx.setFunctionReturn(ocs.getBigDecimal(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqDeleteStubBatch deleteStubBatch(List<String> xrowids,  Connection connection) {
    final TqDeleteStubBatch ctx = new TqDeleteStubBatch();
    ctx.setXrowids(xrowids);
    deleteStubBatch(ctx, connection);
    return ctx;
}

    public static TqDeleteStubBatch deleteStubBatch(List<String> xrowids,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return deleteStubBatch(xrowids,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void deleteStubBatch(DataSource dataSource, TqDeleteStubBatch ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            deleteStubBatch(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void updateTrades(TqUpdateTrades ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  \"TQ\".\"UPDATE_TRADES\"( " +
                                      "    \"TRADES\" => :TRADES" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            // Set TRADES from context trades
            ocs.setObject(1, TqueueObjConverter.getListArray(ctx.getTrades(), connection, "TQUEUE_OBJ_ARR"));
            LOGGER.info("Tq.updateTrades called");
            ocs.execute();
            LOGGER.info("Tq.updateTrades executed");
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqUpdateTrades updateTrades(List<TqueueObj> trades,  Connection connection) {
    final TqUpdateTrades ctx = new TqUpdateTrades();
    ctx.setTrades(trades);
    updateTrades(ctx, connection);
    return ctx;
}

    public static TqUpdateTrades updateTrades(List<TqueueObj> trades,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return updateTrades(trades,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void updateTrades(DataSource dataSource, TqUpdateTrades ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            updateTrades(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void locktrades(TqLocktrades ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"LOCKTRADES\"( " +
                                      "    \"XROWIDS\" => :XROWIDS" +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.INTEGER); // null
            // Set XROWIDS from context xrowids
            ocs.setObject(2, PrimitiveTypeConverter.getListArray(ctx.getXrowids(), connection, "XROWIDS"));
            LOGGER.info("Tq.locktrades called");
            ocs.execute();
            LOGGER.info("Tq.locktrades executed");
            ctx.setFunctionReturn(ocs.getInt(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqLocktrades locktrades(List<String> xrowids,  Connection connection) {
    final TqLocktrades ctx = new TqLocktrades();
    ctx.setXrowids(xrowids);
    locktrades(ctx, connection);
    return ctx;
}

    public static TqLocktrades locktrades(List<String> xrowids,  DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return locktrades(xrowids,  conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void locktrades(DataSource dataSource, TqLocktrades ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            locktrades(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



    public static void currentxid(TqCurrentxid ctx, Connection connection) {
    try {
        final CallableStatement ocs = connection.prepareCall(                "" +
                                      "DECLARE " +
                                      "BEGIN " +
                                      "  :result := " +
                                      "  \"TQ\".\"CURRENTXID\"( " +
                                      "   );" +
                                      "END;" +
                                      "");
        try {
            ocs.registerOutParameter(1, Types.VARBINARY); // null
            LOGGER.info("Tq.currentxid called");
            ocs.execute();
            LOGGER.info("Tq.currentxid executed");
            ctx.setFunctionReturn(ocs.getBytes(1)); // null
        } finally  {
            ocs.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}

    public static TqCurrentxid currentxid( Connection connection) {
    final TqCurrentxid ctx = new TqCurrentxid();
    currentxid(ctx, connection);
    return ctx;
}

    public static TqCurrentxid currentxid( DataSource dataSource) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            return currentxid( conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}


    public static void currentxid(DataSource dataSource, TqCurrentxid ctx) {
    try {
        final Connection conn = dataSource.getConnection();
        try {
            currentxid(ctx, conn);
        } finally {
            conn.close();
        }
    } catch (SQLException e) {
        throw new StoredProcedureCallException(e);
    }
}



}
