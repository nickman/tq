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
package tqueue.pools;

import java.sql.Connection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import javax.sql.DataSource;

import oracle.sql.ORAData;

import org.apache.log4j.BasicConfigurator;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;

import tqueue.db.types.JTQSTUB;
import tqueue.db.types.TQSTUB;
import tqueue.db.types.TQSTUB_ARR;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import com.zaxxer.hikari.proxy.ConnectionProxy;

/**
 * <p>Title: ConnectionPool</p>
 * <p>Description: Connection pool factory</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.pools.ConnectionPool</code></p>
 */

public class ConnectionPool {
	private static volatile ConnectionPool instance = null;
	private static final Object lock = new Object();
	
	/** Static class logger */
	private static final Logger LOG = Logger.getLogger(ConnectionPool.class);
	
	/** The type map applied to all connections */
	private final Map<String, Class<?>> typeMap = new ConcurrentHashMap<String, Class<?>>();
	
	final HikariDataSource dataSource;
	
	public static ConnectionPool getInstance() {
		if(instance==null) {
			synchronized(lock) {
				if(instance==null) {
					instance = new ConnectionPool();
				}
			}
		}
		return instance;
	}
	
	private ConnectionPool() {
		// ==== known type mappings 
		typeMap.put(TQSTUB._SQL_NAME, TQSTUB.class);
		typeMap.put(JTQSTUB._SQL_NAME, JTQSTUB.class);
		typeMap.put(TQSTUB_ARR._SQL_NAME, TQSTUB_ARR.class);
		// ==== known type mappings 
		HikariConfig config = new HikariConfig();
		config.setDriverClassName("oracle.jdbc.OracleDriver");
		//config.setJdbcUrl("jdbc:oracle:thin:@//tporacle:1521/ORCL");
		//config.setJdbcUrl("jdbc:oracle:thin:@//leopard:1521/XE");
		config.setJdbcUrl("jdbc:oracle:thin:@//localhost:1521/XE");
		//config.setJdbcUrl("jdbc:oracle:thin:@//localhost:1521/ORCL");
		config.setUsername("tqreactor");
		config.setPassword("tq");
		config.addDataSourceProperty("cachePrepStmts", "true");
		config.addDataSourceProperty("prepStmtCacheSize", "250");
		config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
		config.setMaximumPoolSize(50);
		config.setMinimumIdle(10);
		config.setConnectionTestQuery("SELECT SYSDATE FROM DUAL");
		config.setConnectionTimeout(1002);
		config.setAutoCommit(false);
		config.setRegisterMbeans(true);
		dataSource = new HikariDataSource(config);	
		Logger.getLogger(com.zaxxer.hikari.pool.HikariPool.class).setLevel(Level.WARN);
	}
	
	public DataSource getDataSource() {
		return dataSource;
	}
	
	public void putMappingType(final String dbTypeName, final Class<?> type) {
		if(dbTypeName==null || dbTypeName.trim().isEmpty()) throw new IllegalArgumentException("The passed DB Type Name was null or empty");
		if(type==null) throw new IllegalArgumentException("The passed ORAData type was null");
		typeMap.put(dbTypeName, type);
	}
	
	public Connection getConnection() {
		try {
			final Connection conn = dataSource.getConnection();
			final Map<String, Class<?>> tm = conn.getTypeMap();
			tm.putAll(typeMap);
			conn.setTypeMap(tm);
			return conn;
		} catch (Exception ex) {
			throw new RuntimeException(ex);
		}
	}
	
	public static Connection unwrap(final Connection conn) {
		if(conn==null) throw new IllegalArgumentException("The passed connection was null");
		if(!ConnectionProxy.class.isInstance(conn)) throw new IllegalArgumentException("The passed connection of type [" + conn.getClass().getName() + "] is not a ConnectionProxy");
		try {
			return ((ConnectionProxy)conn).unwrap(Connection.class);
		} catch (Exception e) {
			LOG.error("Failed to unwrap connection", e);
			throw new RuntimeException("Failed to unwrap connection", e);
		}
	}
	
	public static <T extends Connection> T unwrap(final Connection conn, final Class<T> type) {
		if(conn==null) throw new IllegalArgumentException("The passed connection was null");
		if(!ConnectionProxy.class.isInstance(conn)) throw new IllegalArgumentException("The passed connection of type [" + conn.getClass().getName() + "] is not a ConnectionProxy");
		try {
			return ((ConnectionProxy)conn).unwrap(type);
		} catch (Exception e) {
			LOG.error("Failed to unwrap connection", e);
			throw new RuntimeException("Failed to unwrap connection", e);
		}		
	}
	
	public static void main(String[] args) {
		BasicConfigurator.configure();
		LOG.info("Testing Connection Pool....");
		final ConnectionPool cp = ConnectionPool.getInstance();
		Connection conn = null;
		try {
			conn = cp.getConnection();
			LOG.info("Acquired Connection: type:[" + conn.getClass().getName() + "]");
			String url = conn.getMetaData().getURL();
			LOG.info("URL: [" + url + "]");
			Connection oraConn = ((ConnectionProxy)conn).unwrap(Connection.class);
			LOG.info("Unwrapped Connection: type:[" + oraConn.getClass().getName() + "]");
		} catch (Exception ex) {
			LOG.error("Connection test failed", ex);
		} finally {
			if(conn!=null) try { conn.close(); } catch (Exception x) {/* No Op */}
		}
		
	}
}
