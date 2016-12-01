package tqueue.obridge.converters;

import tqueue.obridge.objects.*;
import oracle.jdbc.OracleConnection;
import oracle.sql.ARRAY;
import oracle.sql.ArrayDescriptor;

import javax.annotation.Generated;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Arrays;

@Generated("org.obridge.generators.ConverterObjectGenerator")
public final class TqtradeConverter {

    public static final String TYPE_NAME = "TQTRADE";

    private TqtradeConverter() {
    }

    public static Struct getStruct(Tqtrade o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getXrowid()); // XROWID
    struct.add(1, o.getTqueueId()); // TQUEUE_ID
    struct.add(2, o.getXid()); // XID
    struct.add(3, o.getStatusCode()); // STATUS_CODE
    struct.add(4, o.getSecurityDisplayName()); // SECURITY_DISPLAY_NAME
    struct.add(5, o.getAccountDisplayName()); // ACCOUNT_DISPLAY_NAME
    struct.add(6, o.getSecurityId()); // SECURITY_ID
    struct.add(7, o.getSecurityType()); // SECURITY_TYPE
    struct.add(8, o.getAccountId()); // ACCOUNT_ID
    struct.add(9, o.getBatchId()); // BATCH_ID
    struct.add(10, o.getCreateTs()); // CREATE_TS
    struct.add(11, o.getUpdateTs()); // UPDATE_TS
    struct.add(12, o.getErrorMessage()); // ERROR_MESSAGE
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<Tqtrade> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (Tqtrade e : o) {
        array.add(TqtradeConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static Tqtrade getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    Tqtrade result = new Tqtrade();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setXrowid((String)attr[0]); // XROWID
    }
    if (attr[1] != null) {
        result.setTqueueId(((BigDecimal)attr[1]).intValue()); // TQUEUE_ID
    }
    if (attr[2] != null) {
        result.setXid((byte[])attr[2]); // XID
    }
    if (attr[3] != null) {
        result.setStatusCode((String)attr[3]); // STATUS_CODE
    }
    if (attr[4] != null) {
        result.setSecurityDisplayName((String)attr[4]); // SECURITY_DISPLAY_NAME
    }
    if (attr[5] != null) {
        result.setAccountDisplayName((String)attr[5]); // ACCOUNT_DISPLAY_NAME
    }
    if (attr[6] != null) {
        result.setSecurityId(((BigDecimal)attr[6]).intValue()); // SECURITY_ID
    }
    if (attr[7] != null) {
        result.setSecurityType((String)attr[7]); // SECURITY_TYPE
    }
    if (attr[8] != null) {
        result.setAccountId(((BigDecimal)attr[8]).intValue()); // ACCOUNT_ID
    }
    if (attr[9] != null) {
        result.setBatchId(((BigDecimal)attr[9]).intValue()); // BATCH_ID
    }
    if (attr[10] != null) {
        result.setCreateTs(new Date(((Timestamp)attr[10]).getTime())); // CREATE_TS
    }
    if (attr[11] != null) {
        result.setUpdateTs(new Date(((Timestamp)attr[11]).getTime())); // UPDATE_TS
    }
    if (attr[12] != null) {
        result.setErrorMessage((String)attr[12]); // ERROR_MESSAGE
    }
    return result;
}

    public static List<Tqtrade> getObjectList(Array array) throws SQLException {
    List<Tqtrade> result = new ArrayList<Tqtrade>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(TqtradeConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
