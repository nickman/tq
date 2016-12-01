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
public final class FullorderConverter {

    public static final String TYPE_NAME = "FULLORDER";

    private FullorderConverter() {
    }

    public static Struct getStruct(Fullorder o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getOrderId()); // ORDER_ID
    struct.add(1, o.getOrderDate()); // ORDER_DATE
    struct.add(2, OrderitemConverter.getListArray(o.getItems(), connection, "ORDERITEM_ARR")); // ITEMS
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<Fullorder> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (Fullorder e : o) {
        array.add(FullorderConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static Fullorder getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    Fullorder result = new Fullorder();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setOrderId((BigDecimal)attr[0]); // ORDER_ID
    }
    if (attr[1] != null) {
        result.setOrderDate(new Date(((Timestamp)attr[1]).getTime())); // ORDER_DATE
    }
    if (attr[2] != null) {
        result.setItems(OrderitemConverter.getObjectList((Array)attr[2])); // ITEMS
    }
    return result;
}

    public static List<Fullorder> getObjectList(Array array) throws SQLException {
    List<Fullorder> result = new ArrayList<Fullorder>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(FullorderConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
