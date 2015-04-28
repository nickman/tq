/**
 * Helios, OpenSource Monitoring
 * Brought to you by the Helios Development Group
 *
 * Copyright 2007, Helios Development Group and individual contributors
 * as indicated by the @author tags. See the copyright.txt file in the
 * distribution for a full listing of individual contributors.
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org. 
 *
 */
package tqueue.db.types;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * <p>Title: DBType</p>
 * <p>Description: Enumerates the superset of standard JDBC and Oracle specific type codes</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.db.types.DBType</code></p>
 */


public enum DBType {
    /** JDBC Type Code BIT */
    BIT(true, -7),
    /** JDBC Type Code TINYINT */
    TINYINT(true, -6),
    /** JDBC Type Code SMALLINT */
    SMALLINT(true, 5),
    /** JDBC Type Code INTEGER */
    INTEGER(true, 4),
    /** JDBC Type Code BIGINT */
    BIGINT(true, -5),
    /** JDBC Type Code FLOAT */
    FLOAT(true, 6),
    /** JDBC Type Code REAL */
    REAL(true, 7),
    /** JDBC Type Code DOUBLE */
    DOUBLE(true, 8),
    /** JDBC Type Code NUMERIC */
    NUMERIC(true, 2),
    /** JDBC Type Code DECIMAL */
    DECIMAL(true, 3),
    /** JDBC Type Code CHAR */
    CHAR(true, 1),
    /** JDBC Type Code VARCHAR */
    VARCHAR(true, 12),
    /** JDBC Type Code LONGVARCHAR */
    LONGVARCHAR(true, -1),
    /** JDBC Type Code DATE */
    DATE(true, 91),
    /** JDBC Type Code TIME */
    TIME(true, 92),
    /** JDBC Type Code TIMESTAMP */
    TIMESTAMP(true, 93),
    /** JDBC Type Code BINARY */
    BINARY(true, -2),
    /** JDBC Type Code VARBINARY */
    VARBINARY(true, -3),
    /** JDBC Type Code LONGVARBINARY */
    LONGVARBINARY(true, -4),
    /** JDBC Type Code NULL */
    NULL(true, 0),
    /** JDBC Type Code OTHER */
    OTHER(true, 1111),
    /** JDBC Type Code JAVA_OBJECT */
    JAVA_OBJECT(true, 2000),
    /** JDBC Type Code DISTINCT */
    DISTINCT(true, 2001),
    /** JDBC Type Code STRUCT */
    STRUCT(true, 2002),
    /** JDBC Type Code ARRAY */
    ARRAY(true, 2003),
    /** JDBC Type Code BLOB */
    BLOB(true, 2004),
    /** JDBC Type Code CLOB */
    CLOB(true, 2005),
    /** JDBC Type Code REF */
    REF(true, 2006),
    /** JDBC Type Code DATALINK */
    DATALINK(true, 70),
    /** JDBC Type Code BOOLEAN */
    BOOLEAN(true, 16),
    /** JDBC Type Code ROWID */
    ROWID(true, -8),
    /** JDBC Type Code NCHAR */
    NCHAR(true, -15),
    /** JDBC Type Code NVARCHAR */
    NVARCHAR(true, -9),
    /** JDBC Type Code LONGNVARCHAR */
    LONGNVARCHAR(true, -16),
    /** JDBC Type Code NCLOB */
    NCLOB(true, 2011),
    /** JDBC Type Code SQLXML */
    SQLXML(true, 2009),
    /** Oracle Type Code TIMESTAMPNS */
    TIMESTAMPNS(false, -100),
    /** Oracle Type Code TIMESTAMPTZ */
    TIMESTAMPTZ(false, -101),
    /** Oracle Type Code TIMESTAMPLTZ */
    TIMESTAMPLTZ(false, -102),
    /** Oracle Type Code INTERVALYM */
    INTERVALYM(false, -103),
    /** Oracle Type Code INTERVALDS */
    INTERVALDS(false, -104),
    /** Oracle Type Code CURSOR */
    CURSOR(false, -10),
    /** Oracle Type Code BFILE */
    BFILE(false, -13),
    /** Oracle Type Code OPAQUE */
    OPAQUE(false, 2007),
    /** Oracle Type Code JAVA_STRUCT */
    JAVA_STRUCT(false, 2008),
    /** Oracle Type Code PLSQL_INDEX_TABLE */
    PLSQL_INDEX_TABLE(false, -14),
    /** Oracle Type Code BINARY_FLOAT */
    BINARY_FLOAT(false, 100),
    /** Oracle Type Code BINARY_DOUBLE */
    BINARY_DOUBLE(false, 101),
    /** Oracle Type Code FIXED_CHAR */
    FIXED_CHAR(false, 999);
    
    private DBType(final boolean standard, final int typeCode) {
        this.standard = standard;
        this.typeCode = typeCode;
    }
    
    public static final Map<Integer, DBType> CODE2TYPE;
    
    static {
        DBType[] types = values();
        Map<Integer, DBType> tmp = new HashMap<Integer, DBType>(types.length);
        for(DBType type: types) {
            tmp.put(type.typeCode, type);
        }
        CODE2TYPE = Collections.unmodifiableMap(tmp);
    }
            
    /** Indicates if this type is JDBC standard or Oracle proprietary */
    public final boolean standard;
    /** The int type code of this type */
    public final int typeCode;

    public static void main(String[] args) {
        System.out.println("Types: " + values().length);
    }
}

