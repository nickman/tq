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
public final class TqbatchConverter {

    public static final String TYPE_NAME = "TQBATCH";

    private TqbatchConverter() {
    }

    public static Struct getStruct(Tqbatch o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getAccount()); // ACCOUNT
    struct.add(1, o.getTcount()); // TCOUNT
    struct.add(2, o.getFirstT()); // FIRST_T
    struct.add(3, o.getLastT()); // LAST_T
    struct.add(4, o.getBatchId()); // BATCH_ID
    struct.add(5, PrimitiveTypeConverter.getListArray(o.getRowids(), connection, "XROWIDS")); // ROWIDS
    struct.add(6, PrimitiveTypeConverter.getListArray(o.getTqrowids(), connection, "XROWIDS")); // TQROWIDS
    struct.add(7, TqstubsObjConverter.getListArray(o.getStubs(), connection, "TQSTUBS_OBJ_ARR")); // STUBS
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<Tqbatch> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (Tqbatch e : o) {
        array.add(TqbatchConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static Tqbatch getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    Tqbatch result = new Tqbatch();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setAccount(((BigDecimal)attr[0]).intValue()); // ACCOUNT
    }
    if (attr[1] != null) {
        result.setTcount(((BigDecimal)attr[1]).intValue()); // TCOUNT
    }
    if (attr[2] != null) {
        result.setFirstT(((BigDecimal)attr[2]).intValue()); // FIRST_T
    }
    if (attr[3] != null) {
        result.setLastT(((BigDecimal)attr[3]).intValue()); // LAST_T
    }
    if (attr[4] != null) {
        result.setBatchId(((BigDecimal)attr[4]).intValue()); // BATCH_ID
    }
    if (attr[5] != null) {
        result.setRowids(PrimitiveTypeConverter.asList((Array) attr[5], String.class)); // ROWIDS
    }
    if (attr[6] != null) {
        result.setTqrowids(PrimitiveTypeConverter.asList((Array) attr[6], String.class)); // TQROWIDS
    }
    if (attr[7] != null) {
        result.setStubs(TqstubsObjConverter.getObjectList((Array)attr[7])); // STUBS
    }
    return result;
}

    public static List<Tqbatch> getObjectList(Array array) throws SQLException {
    List<Tqbatch> result = new ArrayList<Tqbatch>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(TqbatchConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
