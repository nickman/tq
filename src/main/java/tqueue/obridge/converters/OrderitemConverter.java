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
public final class OrderitemConverter {

    public static final String TYPE_NAME = "ORDERITEM";

    private OrderitemConverter() {
    }

    public static Struct getStruct(Orderitem o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getOrderitemId()); // ORDERITEM_ID
    struct.add(1, o.getItemName()); // ITEM_NAME
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<Orderitem> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (Orderitem e : o) {
        array.add(OrderitemConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static Orderitem getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    Orderitem result = new Orderitem();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setOrderitemId((BigDecimal)attr[0]); // ORDERITEM_ID
    }
    if (attr[1] != null) {
        result.setItemName((String)attr[1]); // ITEM_NAME
    }
    return result;
}

    public static List<Orderitem> getObjectList(Array array) throws SQLException {
    List<Orderitem> result = new ArrayList<Orderitem>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(OrderitemConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
