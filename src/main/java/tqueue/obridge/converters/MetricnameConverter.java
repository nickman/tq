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
public final class MetricnameConverter {

    public static final String TYPE_NAME = "METRICNAME";

    private MetricnameConverter() {
    }

    public static Struct getStruct(Metricname o, Connection connection) throws SQLException {
    if (o == null) {
        return null;
    }
    List<Object> struct = new ArrayList<Object>();
    struct.add(0, o.getSegmentcount()); // SEGMENTCOUNT
    struct.add(1, o.getSegments()); // SEGMENTS
    struct.add(2, PrimitiveTypeConverter.getListArray(o.getTags(), connection, "VARCHAR2_ARR")); // TAGS
    return connection.createStruct(TYPE_NAME, struct.toArray());
}

    public static Array getListArray(List<Metricname> o, Connection c, String typeName) throws SQLException {
    OracleConnection connection = c.unwrap(OracleConnection.class);
    ArrayDescriptor arrayDescriptor = new ArrayDescriptor(typeName, connection);
    if (o == null) {
        return new ARRAY(arrayDescriptor, connection, new Object[0]);
    }
    List<Object> array = new ArrayList<Object>(o.size());
    for (Metricname e : o) {
        array.add(MetricnameConverter.getStruct(e, connection));
    }
    return new ARRAY(arrayDescriptor, connection, array.toArray());
}

    public static Metricname getObject(Struct struct) throws SQLException {
    if (struct == null || struct.getAttributes() == null || struct.getAttributes().length == 0) {
        return null;
    }
    Metricname result = new Metricname();
    Object[] attr = struct.getAttributes();
    if (attr[0] != null) {
        result.setSegmentcount(((BigDecimal)attr[0]).intValue()); // SEGMENTCOUNT
    }
    if (attr[1] != null) {
        result.setSegments((String)attr[1]); // SEGMENTS
    }
    if (attr[2] != null) {
        result.setTags(PrimitiveTypeConverter.asList((Array) attr[2], String.class)); // TAGS
    }
    return result;
}

    public static List<Metricname> getObjectList(Array array) throws SQLException {
    List<Metricname> result = new ArrayList<Metricname>();
    ResultSet rs = null;
    try {
        rs = array.getResultSet();
        while (rs.next()) {
            result.add(MetricnameConverter.getObject((Struct) rs.getObject(2)));
        }
    } finally {
        if (rs != null) {
            rs.close();
        }
    }
    return result;
}

}
