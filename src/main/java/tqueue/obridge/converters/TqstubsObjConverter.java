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
public final class TqstubsObjConverter {

    public static final String TYPE_NAME = "TQSTUBS_OBJ";

    private TqstubsObjConverter() {
    }

    public static Struct getStruct(TqstubsObj o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getXrowid()); // XROWID
    struct.add(1, o.getTqrowid()); // TQROWID
    struct.add(2, o.getTqueueId()); // TQUEUE_ID
    struct.add(3, o.getXid()); // XID
    struct.add(4, o.getSecurityId()); // SECURITY_ID
    struct.add(5, o.getSecurityType()); // SECURITY_TYPE
    struct.add(6, o.getAccountId()); // ACCOUNT_ID
    struct.add(7, o.getBatchId()); // BATCH_ID
    struct.add(8, o.getBatchTs()); // BATCH_TS
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<TqstubsObj> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (TqstubsObj e : o) {
        array.add(TqstubsObjConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static TqstubsObj getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    TqstubsObj result = new TqstubsObj();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setXrowid((String)attr[0]); // XROWID
    }
    if (attr[1] != null) {
        result.setTqrowid((String)attr[1]); // TQROWID
    }
    if (attr[2] != null) {
        result.setTqueueId(((BigDecimal)attr[2]).intValue()); // TQUEUE_ID
    }
    if (attr[3] != null) {
        result.setXid((byte[])attr[3]); // XID
    }
    if (attr[4] != null) {
        result.setSecurityId(((BigDecimal)attr[4]).intValue()); // SECURITY_ID
    }
    if (attr[5] != null) {
        result.setSecurityType((String)attr[5]); // SECURITY_TYPE
    }
    if (attr[6] != null) {
        result.setAccountId(((BigDecimal)attr[6]).intValue()); // ACCOUNT_ID
    }
    if (attr[7] != null) {
        result.setBatchId(((BigDecimal)attr[7]).intValue()); // BATCH_ID
    }
    if (attr[8] != null) {
        result.setBatchTs((Timestamp)attr[8]); // BATCH_TS
    }
    return result;
}

    public static List<TqstubsObj> getObjectList(Array array) throws SQLException {
    List<TqstubsObj> result = new ArrayList<TqstubsObj>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(TqstubsObjConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
