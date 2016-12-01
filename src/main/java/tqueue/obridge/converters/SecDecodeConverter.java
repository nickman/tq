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
public final class SecDecodeConverter {

    public static final String TYPE_NAME = "SEC_DECODE";

    private SecDecodeConverter() {
    }

    public static Struct getStruct(SecDecode o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getSecurityDisplayName()); // SECURITY_DISPLAY_NAME
    struct.add(1, o.getSecurityType()); // SECURITY_TYPE
    struct.add(2, o.getSecurityId()); // SECURITY_ID
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<SecDecode> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (SecDecode e : o) {
        array.add(SecDecodeConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static SecDecode getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    SecDecode result = new SecDecode();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setSecurityDisplayName((String)attr[0]); // SECURITY_DISPLAY_NAME
    }
    if (attr[1] != null) {
        result.setSecurityType((String)attr[1]); // SECURITY_TYPE
    }
    if (attr[2] != null) {
        result.setSecurityId((BigDecimal)attr[2]); // SECURITY_ID
    }
    return result;
}

    public static List<SecDecode> getObjectList(Array array) throws SQLException {
    List<SecDecode> result = new ArrayList<SecDecode>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(SecDecodeConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
