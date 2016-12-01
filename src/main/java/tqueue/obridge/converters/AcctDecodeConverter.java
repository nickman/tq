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
public final class AcctDecodeConverter {

    public static final String TYPE_NAME = "ACCT_DECODE";

    private AcctDecodeConverter() {
    }

    public static Struct getStruct(AcctDecode o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getAccountDisplayName()); // ACCOUNT_DISPLAY_NAME
    struct.add(1, o.getAccountId()); // ACCOUNT_ID
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<AcctDecode> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (AcctDecode e : o) {
        array.add(AcctDecodeConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static AcctDecode getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    AcctDecode result = new AcctDecode();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setAccountDisplayName((String)attr[0]); // ACCOUNT_DISPLAY_NAME
    }
    if (attr[1] != null) {
        result.setAccountId((BigDecimal)attr[1]); // ACCOUNT_ID
    }
    return result;
}

    public static List<AcctDecode> getObjectList(Array array) throws SQLException {
    List<AcctDecode> result = new ArrayList<AcctDecode>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(AcctDecodeConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
