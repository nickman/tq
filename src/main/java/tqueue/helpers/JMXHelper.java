/**
* Helios Development Group LLC, 2013. 
 *
 */
package tqueue.helpers;



import java.beans.BeanInfo;
import java.beans.Introspector;
import java.io.IOException;
import java.lang.management.ManagementFactory;
import java.lang.reflect.AccessibleObject;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.RMISocketFactory;
import java.rmi.server.UnicastRemoteObject;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.management.Attribute;
import javax.management.AttributeList;
import javax.management.DynamicMBean;
import javax.management.MBeanAttributeInfo;
import javax.management.MBeanInfo;
import javax.management.MBeanNotificationInfo;
import javax.management.MBeanServer;
import javax.management.MBeanServerConnection;
import javax.management.MBeanServerDelegate;
import javax.management.MBeanServerFactory;
import javax.management.MBeanServerInvocationHandler;
import javax.management.MBeanServerNotification;
import javax.management.MalformedObjectNameException;
import javax.management.Notification;
import javax.management.NotificationFilter;
import javax.management.NotificationListener;
import javax.management.ObjectName;
import javax.management.QueryExp;
import javax.management.openmbean.CompositeData;
import javax.management.openmbean.CompositeType;
import javax.management.openmbean.TabularData;
import javax.management.openmbean.TabularType;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXConnectorServer;
import javax.management.remote.JMXConnectorServerFactory;
import javax.management.remote.JMXServiceURL;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;





/**
 * <p>Title: JMXHelper</p>
 * <p>Description: Static JMX Utility methods</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>com.heliosapm.jmx.util.helpers.JMXHelper</code></p>
 */
public class JMXHelper {
	/** The property name where the jmx default domain is referenced */
	public static final String JMX_DOMAIN_PROPERTY = "org.helios.jmx.domain";
	/** The default jmx default domain is referenced */
	public static final String JMX_DOMAIN_DEFAULT = System.getProperty(JMX_DOMAIN_PROPERTY, ManagementFactory.getPlatformMBeanServer().getDefaultDomain());
	/** Regex WildCard Support Pattern for ObjectName key values */
	public static final Pattern OBJECT_NAME_KP_WILDCARD = Pattern.compile("[:|,](\\S+?)~=\\[(\\S+?)\\]");
	
	/** The MBeanInfo changed notification type */
	public static final String MBEAN_INFO_CHANGED = "jmx.mbean.info.changed";
	
	/** A reusable MBeanInfo changed notification */
	public static final MBeanNotificationInfo META_CHANGED_NOTIF = new MBeanNotificationInfo(new String[] {MBEAN_INFO_CHANGED}, Notification.class.getName(), "Broadcast when an MBean's meta-data changes");
	
	/** An object name filter that maps to all registered MBeans */
	public static final ObjectName ALL_MBEANS_FILTER = objectName("*:*");
	
	/** A no arg op signature */
	public static final String[] NO_ARG_SIGNATURE = {}; 
	/** A no arg op arg array */
	public static final Object[] NO_ARG_ARR = {}; 
	
	/** The debug agent library */
	public static final String AGENT_LIB = "-agentlib:";
	
	/** The legacy debug agent library */
	public static final String LEGACY_AGENT_LIB = "-Xrunjdwp:";
	
	/** Static class logger */
	private static final Logger LOG = LoggerFactory.getLogger(JMXHelper.class);

	
	/**
	 * Determines if this JVM is running with the debug agent enabled
	 * @return true if this JVM is running with the debug agent enabled, false otherwise
	 */
	public static boolean isDebugAgentLoaded() {
		List<String> inputArguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
		for(String s: inputArguments) {
			if(s.trim().startsWith(AGENT_LIB) || s.trim().startsWith(LEGACY_AGENT_LIB)) return true;
		}
		return false;
	}

	/**
	 * Creates a new JMXServiceURL
	 * @param url the JMXServiceURL stringy
	 * @return a new JMXServiceURL
	 */
	public static JMXServiceURL serviceUrl(CharSequence url) {
		try {
			return new JMXServiceURL(url.toString());
		} catch (Exception ex) {
			throw new RuntimeException("Failed to create JMXServiceURL for [" + url + "]", ex);
		}
	}
	
	/**
	 * Creates a new JMXServiceURL
	 * @param format The JMXServiceURL template
	 * @param args  the template fill-ins
	 * @return a new JMXServiceURL
	 */
	public static JMXServiceURL serviceUrl(String format, Object...args) {		
		try {
			
			return new JMXServiceURL(String.format(format, args));
		} catch (Exception ex) {
			throw new RuntimeException("Failed to create JMXServiceURL for [" + format +  "]", ex);
		}
	}
	
	/**
	 * Acquires the configured or default Helios target MBeanServer.
	 * @return An MBeanServer.
	 */
	public static MBeanServer getHeliosMBeanServer() {
		MBeanServer server = null;
		String jmxDomain = ConfigurationHelper.getEnvThenSystemProperty(JMX_DOMAIN_PROPERTY, null);
		if(jmxDomain!=null) {
			server = getLocalMBeanServer(jmxDomain, true);
		}
		if(server==null) {
			return ManagementFactory.getPlatformMBeanServer();
		}		
		return server;
	}
	
	/**
	 * Returns an array of matching ObjectNames
	 * @param server The MBeanServer to query
	 * @param pattern The ObjectName pattern
	 * @param query An optional query expression
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(MBeanServerConnection server, ObjectName pattern, QueryExp query) {
		try {
			if(server==null) server = getHeliosMBeanServer();
			Set<ObjectName> ons = server.queryNames(pattern, query);
			return ons.toArray(new ObjectName[ons.size()]);
		} catch (Exception e) {
			throw new RuntimeException("Failed to issue MBean query", e);
		}
	}
	
	/**
	 * Returns an array of matching ObjectNames
	 * @param server The MBeanServer to query
	 * @param pattern The ObjectName pattern
	 * @param query An optional query expression
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(MBeanServerConnection server, CharSequence pattern, QueryExp query) {
		return query(server, objectName(pattern), query);
	}
	
	/**
	 * Returns an array of matching ObjectNames
	 * @param server The MBeanServer to query
	 * @param pattern The ObjectName pattern
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(MBeanServerConnection server, CharSequence pattern) {
		return query(server, objectName(pattern), null);
	}
	
	/**
	 * Returns an array of matching ObjectNames
	 * @param server The MBeanServer to query
	 * @param pattern The ObjectName pattern
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(MBeanServerConnection server, ObjectName pattern) {
		return query(server, pattern, null);
	}
	

	
	
	
	/**
	 * Returns an array of matching ObjectNames from the default MBeanServer
	 * @param pattern The ObjectName pattern
	 * @param query An optional query expression
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(ObjectName pattern, QueryExp query) {
		return query(getHeliosMBeanServer(), pattern, query);
	}
	
	/**
	 * Returns an array of matching ObjectNames from the default MBeanServer
	 * @param pattern The ObjectName pattern
	 * @param query An optional query expression
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(CharSequence pattern, QueryExp query) {
		return query(getHeliosMBeanServer(), objectName(pattern), query);
	}
	
	
	/**
	 * Returns an array of matching ObjectNames from the default MBeanServer
	 * @param pattern The ObjectName pattern
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(ObjectName pattern) {
		return query(getHeliosMBeanServer(), pattern, null);
	}
	
	/**
	 * Returns an array of matching ObjectNames from the default MBeanServer
	 * @param pattern The ObjectName pattern
	 * @return an array of ObjectNames
	 */
	public static ObjectName[] query(CharSequence pattern) {
		return query(getHeliosMBeanServer(), objectName(pattern), null);
	}
	
	/**
	 * Determines if the passed Object is or represents a JMX ObjectName
	 * @param obj the object to test
	 * @return true if the passed Object is or represents a JMX ObjectName, false otherwise
	 */
	public static boolean isObjectName(Object obj) {
		if(obj==null) return false;
		if(obj instanceof ObjectName) return true;
		try {
			new ObjectName(obj.toString());
			return true;
		} catch (Exception e) {
			return false;
		}
	}
	
	/**
	 * Determines if the passed ObjectName is registered in the passed MBeanServer
	 * @param conn The MBeanServer reference
	 * @param on The ObjectName to test for
	 * @return true if registered, false otherwise
	 */
	public static  boolean isRegistered(MBeanServerConnection conn, ObjectName on) {
		try {
			return conn.isRegistered(on);
		} catch (Exception ex) {
			throw new RuntimeException(ex);
		}
	}
	
	/**
	 * Determines if the passed ObjectName is registered in the passed MBeanServer
	 * @param conn The MBeanServer reference
	 * @param on The ObjectName to test for
	 * @return true if registered, false otherwise
	 */
	public static  boolean isRegistered(MBeanServerConnection conn, CharSequence on) {
		return isRegistered(conn, objectName(on));
	}
	
	
	/**
	 * Determines if the passed ObjectName is registered in the default MBeanServer
	 * @param on The ObjectName to test for
	 * @return true if registered, false otherwise
	 */
	public static  boolean isRegistered(ObjectName on) {
		return isRegistered(getHeliosMBeanServer(), on);
	}
	
	/**
	 * Determines if the object registered under the passed object name is an instance of the named class 
	 * @param conn The MBeanServer to check in
	 * @param on The ObjectName of the object to check
	 * @param className The class name to test for
	 * @return true if the object is of the specified inherritance, false otherwise
	 */
	public static boolean isInstanceOf(MBeanServerConnection conn, ObjectName on, String className) {
		try {
			return conn.isInstanceOf(on, className);
		} catch (Exception ex) {
			throw new RuntimeException("Failed to determine inherritance of [" + on + "] for [" + className + "]", ex);
		}
	}
	
	/**
	 * Determines if the object registered under the passed object name is an instance of the named class 
	 * @param conn The MBeanServer to check in
	 * @param on The ObjectName of the object to check
	 * @param className The class name to test for
	 * @return true if the object is of the specified inherritance, false otherwise
	 */
	public static boolean isInstanceOf(MBeanServerConnection conn, CharSequence on, String className) {
		return isInstanceOf(conn, objectName(on), className);
	}
	
	/**
	 * Determines if the object registered under the passed object name in the default MBeanServer is an instance of the named class 
	 * @param on The ObjectName of the object to check
	 * @param className The class name to test for
	 * @return true if the object is of the specified inherritance, false otherwise
	 */
	public static boolean isInstanceOf(ObjectName on, String className) {
		return isInstanceOf(getHeliosMBeanServer(), on, className);
	}
	
	/**
	 * Determines if the object registered under the passed object name in the default MBeanServer is an instance of the named class 
	 * @param on The ObjectName of the object to check
	 * @param className The class name to test for
	 * @return true if the object is of the specified inherritance, false otherwise
	 */
	public static boolean isInstanceOf(CharSequence on, String className) {
		return isInstanceOf(getHeliosMBeanServer(), objectName(on), className);
	}
	
	
	/**
	 * Determines if the passed ObjectName is registered in the default MBeanServer
	 * @param on The ObjectName to test for
	 * @return true if registered, false otherwise
	 */
	public static  boolean isRegistered(CharSequence on) {
		return isRegistered(objectName(on));
	}
	
	
	/**
	 * Returns an MBeanConnection for an in-vm MBeanServer that has the specified default domain.
	 * @param domain The default domain of the requested MBeanServer.
	 * @return The located MBeanServerConnection or null if one cannot be located. 
	 */
	public static MBeanServer getLocalMBeanServer(String domain) {
		return getLocalMBeanServer(domain, true);
	}
	
	/**
	 * Searches for a matching MBeanServer in the passed list of domains and returns the first located.
	 * If one cannot be located a null will be returned. 
	 * @param domains The default domain of the requested MBeanServer.
	 * @return The located MBeanServerConnection or null if one cannot be found.
	 */
	public static MBeanServer getLocalMBeanServer(String...domains) {
		return getLocalMBeanServer(true, domains);
	}
	
	/**
	 * Searches for a matching MBeanServer in the passed list of domains and returns the first located.
	 * If one cannot be located, returnNullIfNotFound will either cause a null to be returned, or a RuntimeException. 
	 * @param returnNullIfNotFound If true, returns a null if a matching MBeanServer cannot be found. Otherwise, throws a RuntimeException.
	 * @param domains The default domain of the requested MBeanServer.
	 * @return The located MBeanServerConnection or null if one cannot be found and returnNullIfNotFound is true.
	 */
	public static MBeanServer getLocalMBeanServer(boolean returnNullIfNotFound, String...domains) {
		MBeanServer server = null;
		StringBuilder buff = new StringBuilder();
		for(String domain: domains) {
			server = getLocalMBeanServer(domain);
			buff.append(domain).append(",");
			if(server!=null) return server;
		}
		if(returnNullIfNotFound) {
			return null;
		}
		throw new RuntimeException("No MBeanServer located for domains [" + buff.toString() + "]");
	}
	
	
	/**
	 * Returns an MBeanConnection for an in-vm MBeanServer that has the specified default domain.
	 * @param domain The default domain of the requested MBeanServer.
	 * @param returnNullIfNotFound If true, returns a null if a matching MBeanServer cannot be found. Otherwise, throws a RuntimeException. 
	 * @return The located MBeanServerConnection or null if one cannot be found and returnNullIfNotFound is true. 
	 */
	public static MBeanServer getLocalMBeanServer(String domain, boolean returnNullIfNotFound) {
		if(domain==null || domain.equals("") || domain.equalsIgnoreCase("DefaultDomain") || domain.equalsIgnoreCase("Default")) {
			return ManagementFactory.getPlatformMBeanServer();
		}
		List<MBeanServer> servers = MBeanServerFactory.findMBeanServer(null);
		for(MBeanServer server: servers) {
			if(server.getDefaultDomain().equals(domain)) return server;
		}
		if(returnNullIfNotFound) {
			return null;
		}
		throw new RuntimeException("No MBeanServer located for domain [" + domain + "]");
	}
	
	/**
	 * Acquires a connected JMX connection
	 * @param jmxUrl The JMXServiceURL of the service to connec to
	 * @return a JMXConnector
	 */
	public static JMXConnector getJMXConnection(CharSequence jmxUrl) {
		return getJMXConnection(jmxUrl, true, null);
	}
	
	
	/**
	 * Acquires a JMX connection
	 * @param jmxUrl The JMXServiceURL of the service to connec to
	 * @param connect If true, the returned connector will be connected
	 * @param environment a set of attributes to determine how the connection is made. Can be null.
	 * @return a JMXConnector
	 */
	public static JMXConnector getJMXConnection(CharSequence jmxUrl, boolean connect, Map<String,?> environment) {
		if(jmxUrl==null) throw new IllegalArgumentException("The passed JMXServiceURL was null", new Throwable());
		try {
			
			JMXConnector connector = JMXConnectorFactory.newJMXConnector(new JMXServiceURL(jmxUrl.toString().trim()), environment);
			if(connect) {
				connector.connect();
			}
			return connector;
		} catch (Exception e) {
			e.printStackTrace(System.err);
			throw new RuntimeException("Failed to acquire JMXConnection to [" + jmxUrl + "]", e);
		}
	}
	
	
	/**
	 * Finds the highest number appended property key key in an ObjectName.
	 * @param objectName The object name to extract the key from
	 * @param prefix The key prefix
	 * @return the highest numeric, or null if none were found
	 */
	public static Integer getHighestKey(final ObjectName objectName, final String prefix) {
		final Hashtable<String, String> keyvals = objectName.getKeyPropertyList();
		final Pattern pattern = Pattern.compile(prefix + ".*?(\\d+)$");
		final TreeSet<Integer> nums = new TreeSet<Integer>();
		for(final String key : keyvals.keySet()) {
			Matcher m = pattern.matcher(key);
			if(m.matches()) {
				nums.add(Integer.parseInt(m.group(1)));
			}
		}
		return nums.isEmpty() ? null : nums.descendingIterator().next();
	}
	
	
	/**
	 * Determines if the passed stringy is a valid object name
	 * @param on The object name stringy to evaluate
	 * @return true if valid, false otherwise
	 */
	public static boolean isValidObjectName(CharSequence on) {
		if(on==null) return false;
		try {
			new ObjectName(on.toString());
			return true;
		} catch (Exception ex) {
			return false;
		}
	}
	
	/**
	 * Creates a new JMX object name.
	 * @param on A string type representing the ObjectName string.
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(CharSequence on) {
		try {
			return new ObjectName(on.toString().trim());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name for value [" + on + "]", e);
		}
	}
	
	/**
	 * Creates a new JMX object name divined from the passed class
	 * @param clazz The class to create an ObjectName from
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(Class<?> clazz) {
		try {
			return new ObjectName(new StringBuilder(
				clazz.getPackage().getName())
				.append(":service=")
				.append(clazz.getSimpleName())
			.toString());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name", e);
		}
	}
	
	
	/**
	 * Creates a new JMX object name.
	 * @param format The string format template 
	 * @param args The arguments to populate the template with
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(String format, Object...args) {
		try {
			return new ObjectName(String.format(format.trim(), args));
		} catch (MalformedObjectNameException moex) {
			if(moex.getMessage().startsWith("Invalid character")) {
				for(int i = 0; i < args.length; i++) {
					args[i] = ObjectName.quote(args[i].toString());
				}
				return objectName(String.format(format.trim(), args));
			}
			throw new RuntimeException("Failed to create Object Name", moex);
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name", e);
		}		
	}
	
	
	/**
	 * Creates a new JMX object name for a simple class
	 * @param clazz The class to generate the ObjectName for
	 * @param key The class name key
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName classObjectName(Class<?> clazz, String key) {
		try {			
			return new ObjectName(new StringBuilder(
				clazz.getPackage().getName())
				.append(":")
				.append(key)
				.append("=")
				.append(clazz.getSimpleName())
				.toString());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name for [" + clazz + "]", e);
		}
	}	
	
	/**
	 * Creates a new JMX ObjectName from the passed AccessibleObject
	 * @param ao The AccessibleObject to create an ObjectName for
	 * @return the ObjectName
	 */
	public static ObjectName objectName(AccessibleObject ao) {
		try {
			Class<?> clazz = getDeclaringClass(ao);
			StringBuilder b = new StringBuilder(clazz.getPackage().getName()).append(":");
			b.append("class=").append(clazz.getSimpleName()).append(",");
			b.append("method=").append(getName(ao));
			return new ObjectName(b.toString());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name [" + getGenericString(ao) + "]", e);
		}
	}
	
	/**
	 * Gets the declaring class of the passed AccessibleObject
	 * @param ao the AccessibleObject to get the declaring class for
	 * @return the declaring class
	 */
	public static Class<?> getDeclaringClass(AccessibleObject ao) {
		if(ao==null) return null;
		if(ao instanceof Method) {
			return ((Method)ao).getDeclaringClass();
		} else if(ao instanceof Constructor) {
			return ((Constructor<?>)ao).getDeclaringClass();
		} else if(ao instanceof Field) {
			return ((Field)ao).getDeclaringClass();
		} else {
			throw new RuntimeException("Unknow AccessibleObject type [" + ao.getClass().getName() + "]");
		}
	}
	
	/**
	 * Gets the name of the passed AccessibleObject
	 * @param ao the AccessibleObject to get the name for
	 * @return the name of the Accessible Object
	 */
	public static String getName(AccessibleObject ao) {
		if(ao==null) return null;
		if(ao instanceof Method) {
			return ((Method)ao).getName();
		} else if(ao instanceof Constructor) {
			return ((Constructor<?>)ao).getDeclaringClass().getSimpleName();
		} else if(ao instanceof Field) {
			return ((Field)ao).getName();
		} else {
			throw new RuntimeException("Unknow AccessibleObject type [" + ao.getClass().getName() + "]");
		}
	}
	
	/**
	 * Gets the generic string of the passed AccessibleObject
	 * @param ao the AccessibleObject to get the generic string for
	 * @return the generic string of the Accessible Object
	 */
	public static String getGenericString(AccessibleObject ao) {		
		if(ao==null) return null;
		if(ao instanceof Method) {
			return ((Method)ao).toGenericString();
		} else if(ao instanceof Constructor) {
			return ((Constructor<?>)ao).toGenericString();
		} else if(ao instanceof Field) {
			Field f = (Field)ao;
			return String.format("%s:%s(%s)", f.getDeclaringClass().getName(), f.getName(), f.getType().getName());
		} else {
			throw new RuntimeException("Unknow AccessibleObject type [" + ao.getClass().getName() + "]");
		}
	}
	
	
	
	
	/**
	 * Creates a new JMX object name.
	 * @param on An object representing the ObjectName
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(Object on) {
		try {
			return new ObjectName(on.toString().trim());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name [" + on + "]", e);
		}
	}	
	
	/**
	 * Creates a new JMX ObjectName from the passed class and method name
	 * @param clazz The class 
	 * @param methodName The method name to create an ObjectName for
	 * @return the ObjectName
	 */
	public static ObjectName objectName(Class<?> clazz, String methodName) {
		try {
			StringBuilder b = new StringBuilder(clazz.getPackage().getName()).append(":");
			b.append("class=").append(clazz.getSimpleName()).append(",");
			b.append("method=").append(methodName);
			return new ObjectName(b.toString());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name [" + clazz.getName() + "/" + methodName + "]", e);
		}
	}
		
	
	/**
	 * Creates a new JMX object name by appending properties on the end of an existing name
	 * @param on An existing ObjectName
	 * @param props Appended properties in the for {@code key=value}
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(ObjectName on, CharSequence...props) {
		StringBuilder b = new StringBuilder(on.toString());
		try {			
			if(props!=null) {
				for(CharSequence prop: props) {
					b.append(",").append(prop);
				}
			}
			return new ObjectName(b.toString());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name from [" + b + "]", e);			 
		}
	}
	
	
	/**
	 * Creates a new JMX object name.
	 * @param domain A string type representing the ObjectName domain
	 * @param properties A hash table of the Object name's properties
	 * @return an ObjectName the created ObjectName
	 */
	public static ObjectName objectName(CharSequence domain, Hashtable<String, String> properties) {
		try {
			return new ObjectName(domain.toString(), properties);
		} catch (Exception e) {
			throw new RuntimeException("Failed to create Object Name", e);
		}
	}
	

//	/**
//	 * Creates a new JMX object name.
//	 * @param domain The ObjectName domain
//	 * @param nameValuePairs an (even lengthed) array of name value pairs making up the key properties
//	 * @return an ObjectName the created ObjectName
//	 */
//	public static ObjectName objectName(CharSequence domain, CharSequence...nameValuePairs) {
//		if(domain==null || domain.toString().length()<1) throw new IllegalArgumentException("Null or zero length domain name");
//		if(nameValuePairs==null || nameValuePairs.length<1 || nameValuePairs.length%2!=0) {
//			throw new IllegalArgumentException("Invalid number of namevaluepairs [" + (nameValuePairs==null ? 0 : nameValuePairs.length) + "]");
//		}
//		try {
//			Hashtable<String, String> props = new Hashtable<String, String>();
//			for(int i = 0; i < nameValuePairs.length; i++) {
//				if(nameValuePairs[i]==null || nameValuePairs[i].toString().length()<1) {
//					throw new IllegalArgumentException("Null or blank nameValuePair entry at index [" + i + "]");
//				}
//				String key = nameValuePairs[i].toString();
//				i++;
//				if(nameValuePairs[i]==null || nameValuePairs[i].toString().length()<1) {
//					throw new IllegalArgumentException("Null or blank nameValuePair entry at index [" + i + "]");
//				}				
//				String value = nameValuePairs[i].toString();
//				props.put(key, value);
//			}
//			return new ObjectName(domain.toString(), props);
//		} catch (IllegalArgumentException iae) {
//			throw iae;
//		} catch (Exception e) {
//			throw new RuntimeException("Failed to create Object Name", e);
//		}
//	}
	
	/**
	 * Registers an MBean
	 * @param server The MBeanServer to register in
	 * @param objectName The ObjectName of the MBean
	 * @param mbean The MBean object instance to register
	 */
	public static void registerMBean(MBeanServer server, ObjectName objectName, Object mbean) {
		try {
			server.registerMBean(mbean, objectName);
		} catch(Exception e) {
			if(isDebugAgentLoaded()) e.printStackTrace(System.err);
			throw new RuntimeException("Failed to register MBean [" + objectName + "]", e);
		}
	}
	
	/**
	 * Registers an MBean in the helios MBeanServer
	 * @param objectName The ObjectName of the MBean
	 * @param mbean The MBean object instance to register
	 */
	public static void registerMBean(ObjectName objectName, Object mbean) {
		registerMBean(getHeliosMBeanServer(), objectName, mbean);
	}
	
	/**
	 * Unregisters the named MBean from the passed MBeanServer
	 * @param server The MBeanServer to unregister from
	 * @param objectName The ObjectName of the MBean to unregister
	 */
	public static void unregisterMBean(MBeanServer server, ObjectName objectName) {
		try {
			server.unregisterMBean(objectName);
		} catch(Exception e) {
			if(isDebugAgentLoaded()) e.printStackTrace(System.err);
			throw new RuntimeException("Failed to unregister MBean [" + objectName + "]", e);
		}		
	}
	
	/**
	 * Registers the named MBean in the passed MBeanServer
	 * @param server The MBeanServer to register with
	 * @param mbean The object to register
	 * @param objectName The ObjectName of the MBean to register
	 */
	public static void registerMBean(MBeanServer server, Object mbean, ObjectName objectName) {
		try {
			server.registerMBean(mbean, objectName);
		} catch(Exception e) {
			if(isDebugAgentLoaded()) e.printStackTrace(System.err);
			throw new RuntimeException("Failed to register MBean [" + objectName + "]", e);
		}		
	}
	
	/**
	 * Registers the named MBean in the helios MBeanServer
	 * @param mbean The object to register
	 * @param objectName The ObjectName of the MBean to register
	 */
	public static void registerMBean(Object mbean, ObjectName objectName) {
		registerMBean(getHeliosMBeanServer(), mbean, objectName);
	}
	
	
	
	/**
	 * Unregisters the named MBean from the Helios MBeanServer
	 * @param objectName The ObjectName of the MBean to unregister
	 */
	public static void unregisterMBean(ObjectName objectName) {
		unregisterMBean(getHeliosMBeanServer(), objectName);
	}
	
	
	/**
	 * Retrieves MBeanInfo on the specified object name.
	 * @param server The mbean server
	 * @param on The object name
	 * @return an MBeanInfo
	 */
	public static MBeanInfo mbeanInfo(MBeanServerConnection server, CharSequence on) {
		try {
			return server.getMBeanInfo(objectName(on));
		} catch (Exception e) {
			throw new RuntimeException("Failed to get MBeanInfo", e);
		}		
	}
	
	/**
	 * Sets an MBean attribute.
	 * @param on The object name
	 * @param server The mbean server
	 * @param name The attribute name
	 * @param value The attribute value
	 */
	public static void setAttribute(CharSequence on, MBeanServerConnection server, String name, Object value) {
		try {
			server.setAttribute(objectName(on), new Attribute(name, value));
		} catch (Exception e) {
			throw new RuntimeException("Failed to set Attribute", e);
		}				
	}
	
	
	/**
	 * Sets a list of MBean attributes. Throws no exceptions. Returns a map of successfully set values.
	 * @param on on the object name
	 * @param server the mbean server
	 * @param attributes The attributes to set
	 * @return a map of successfully set values
	 */
	public static Map<String, Object> setAttributesWithRet(CharSequence on, MBeanServerConnection server, Object...attributes) {
		Map<String, Object> returnValues = new HashMap<String, Object>(attributes.length);		
		Collection<NVP> list = NVP.generate(attributes);
		for(NVP nvp: list) {
			try {
				setAttribute(on, server, nvp.getName(), nvp.getValue());
				returnValues.put(nvp.getName(), nvp.getValue());
			} catch (Exception e) {/* No Op */}
		}
		return returnValues;
	}
	
	/**
	 * Returns a String->Object Map of the named attributes from the Mbean.
	 * @param on The object name of the MBean.
	 * @param server The MBeanServerConnection the MBean is registered in. If this is null, uses the helios mbean server
	 * @param attributes An array of attribute names to retrieve. If this is null or empty, retrieves all the names
	 * @return A name value map of the requested attributes.
	 */
	public static Map<String, Object> getAttributes(ObjectName on, MBeanServerConnection server, String...attributes) {
		try {
			if(attributes==null || attributes.length<1) {
				attributes = getAttributeNames(on, server);				
			}
			Map<String, Object> attrs = new HashMap<String, Object>(attributes.length);
			AttributeList attributeList = server.getAttributes(on, attributes);
			
			
			for(int i = 0; i < attributeList.size(); i++) {
				Attribute at = (Attribute)attributeList.get(i);
				attrs.put(at.getName(), at.getValue());
			}
			return attrs;
		} catch (Exception e) {
			throw new RuntimeException("Failed to getAttributes on [" + on + "]", e);
		}
	}
	
	/**
	 * Returns a String->Object Map of the <b>numeric</b> named attributes from the Mbean.
	 * @param on The object name of the MBean.
	 * @param server The MBeanServerConnection the MBean is registered in. If this is null, uses the helios mbean server
	 * @return A name value map of the requested attributes.
	 */
	public static Map<String, Number> getNumericAttributes(final ObjectName on, MBeanServerConnection server) {
		try {
			final String[] attributes = getNumericAttributeNames(on, server);
			Map<String, Number> attrs = new HashMap<String, Number>(attributes.length);
			if(server==null) server = getHeliosMBeanServer();
			AttributeList attributeList = server.getAttributes(on, attributes);
			for(int i = 0; i < attributeList.size(); i++) {
				Attribute at = (Attribute)attributeList.get(i);
				attrs.put(at.getName(), (Number)at.getValue());
			}
			return attrs;
		} catch (Exception e) {
			throw new RuntimeException("Failed to getAttributes on [" + on + "]", e);
		}
	}
	
	/**
	 * Returns a String->Object Map of the <b>numeric</b> named attributes from the Mbean in the helios mbeanserver
	 * @param on The object name of the MBean.
	 * @return A name value map of the requested attributes.
	 */
	public static Map<String, Number> getNumericAttributes(final ObjectName on) {
		return getNumericAttributes(on, null);
	}
	
	
	
	/**
	 * Returns a String->Object Map of the named attributes from the Mbean in the helios mbeanserver
	 * @param on The object name of the MBean.
	 * @param attributes An array of attribute names to retrieve. If this is null or empty, retrieves all the names
	 * @return A name value map of the requested attributes.
	 */
	public static Map<String, Object> getAttributes(ObjectName on, String...attributes) {
		return getAttributes(on, getHeliosMBeanServer(), attributes);
	}
	
	
	/**
	 * Returns an array of the names of the attributes for the passed ObjectName reached through the helios mbeanserver
	 * @param objectName The mbean to get the attribute names for
	 * @return an array of strings
	 */
	public static String[] getAttributeNames(ObjectName objectName) {
		return getAttributeNames(objectName, getHeliosMBeanServer());
	}
	
	
	/**
	 * Returns an array of the names of the attributes for the passed ObjectName reached through the passed mbean server connection
	 * @param objectName The mbean to get the attribute names for
	 * @param connection The connection to reach the mbean through. If null, uses the helios mbean server
	 * @return an array of strings
	 */
	public static String[] getAttributeNames(ObjectName objectName, MBeanServerConnection connection) {
		if(objectName==null) throw new IllegalArgumentException("The passed objectname was null", new Throwable());
		if(connection==null) connection = getHeliosMBeanServer();		
		try {
			MBeanAttributeInfo[] infos = connection.getMBeanInfo(objectName).getAttributes();
			String[] names = new String[infos.length];
			for(int i = 0; i < infos.length; i++) {
				names[i] = infos[i].getName();
			}
			return names;
		} catch (Exception ex) {
			return new String[0];
		}
	}

	/**
	 * Returns an array of the names of the <b>numeric</b> attributes for the passed ObjectName reached through the local helios mbeanserver
	 * @param objectName The mbean to get the attribute names for
	 * @return an array of strings
	 */
	public static String[] getNumericAttributeNames(final ObjectName objectName) {
		return getNumericAttributeNames(objectName, null);
	}
	
	
	/**
	 * Returns an array of the names of the <b>numeric</b> attributes for the passed ObjectName reached through the passed mbean server connection
	 * @param objectName The mbean to get the attribute names for
	 * @param connection The connection to reach the mbean through. If null, uses the helios mbean server
	 * @return an array of strings
	 */
	public static String[] getNumericAttributeNames(final ObjectName objectName, MBeanServerConnection connection) {
		if(objectName==null) throw new IllegalArgumentException("The passed objectname was null", new Throwable());
		if(connection==null) connection = getHeliosMBeanServer();		
		try {
			MBeanAttributeInfo[] infos = connection.getMBeanInfo(objectName).getAttributes();
			final Set<String> names = new HashSet<String>(infos.length);
			
			for(int i = 0; i < infos.length; i++) {
				try {
					final String typeName = infos[i].getType();
					if(PRIMITIVE_NUMERIC_CLASS_NAMES.contains(typeName) || Number.class.isAssignableFrom(resolveClassName(typeName))) {
						names.add(infos[i].getName());
					}
				} catch (Exception x) {/* No Op */}
			}
			return names.toArray(new String[names.size()]);
		} catch (Exception ex) {
			return new String[0];
		}
	}
	
	public static final Set<String> PRIMITIVE_CLASS_NAMES = Collections.unmodifiableSet(new HashSet<String>(Arrays.asList(
			"boolean", "byte", "short" , "char", "int", "float", "long", "double"
	)));
	public static final Set<String> PRIMITIVE_NUMERIC_CLASS_NAMES = Collections.unmodifiableSet(new HashSet<String>(Arrays.asList(
			"byte", "short" , "int", "float", "long", "double"
	))); 
	
	public static final Map<String, Class<?>> PRIMITIVE_CLASS_DECODE;
	
	static {
		Map<String, Class<?>> tmp = new HashMap<String, Class<?>>(PRIMITIVE_CLASS_NAMES.size());
		tmp.put("boolean", boolean.class);
		tmp.put("byte", byte.class);
		tmp.put("short", short.class);
		tmp.put("char", char.class);
		tmp.put("int", int.class);
		tmp.put("float", float.class);
		tmp.put("long", long.class);
		tmp.put("double", double.class);
		PRIMITIVE_CLASS_DECODE =  Collections.unmodifiableMap(tmp);
	}
	
	/**
	 * Resolves a class name to a class
	 * @param className The class name
	 * @param cl The optional class loader to use. If null, uses {@link Thread#getContextClassLoader()}.
	 * @return the class
	 */
	public static Class<?> resolveClassName(final CharSequence className, final ClassLoader cl) {
		if(className==null || className.toString().trim().isEmpty()) throw new IllegalArgumentException("The passed class name was null or empty");
		try {
			final String cname = className.toString().trim();
			if(PRIMITIVE_CLASS_NAMES.contains(cname)) {
				return PRIMITIVE_CLASS_DECODE.get(cname);
			}
			final ClassLoader _cl = cl==null ? Thread.currentThread().getContextClassLoader() : cl;
			return Class.forName(className.toString(), true, _cl);
		} catch (Exception ex) {
			throw new RuntimeException("Failed to resolve class name: [" + className + "]", ex);
		}
	}
	
	/**
	 * Resolves a class name to a class
	 * @param className The class name
	 * @return the class
	 */
	public static Class<?> resolveClassName(final CharSequence className) {
		return resolveClassName(className, null);
	}
	
	
	
	
	/**
	 * Returns the AgentId for the passed MBeanServer
	 * @param connection The MBeanServerConnection to get the AgentId from
	 * @return the AgentId
	 */
	public static String getAgentId(final MBeanServerConnection connection) {
		if(connection == null) throw new IllegalArgumentException("The passed MBeanServerConnection was null");
		try {
			return (String) connection.getAttribute(MBeanServerDelegate.DELEGATE_NAME, "MBeanServerId");
		} catch (Exception ex) {
			throw new RuntimeException("Failed to get MBeanServer Agent ID", ex);
		}
	}
	
	public static MBeanServerConnection getMBeanServerConnection(final JMXConnector connector) {
		try {
			return connector.getMBeanServerConnection();
		} catch (Exception ex) {
			throw new RuntimeException("Failed to get MBeanServerConnection from [" + connector + "]", ex);
		}
	}
	
	public static MBeanServerConnection getMBeanServerConnection(final CharSequence jmxUrl) {
		try {
			return getJMXConnection(jmxUrl).getMBeanServerConnection();
		} catch (Exception ex) {
			throw new RuntimeException("Failed to get MBeanServerConnection from [" + jmxUrl + "]", ex);
		}
	}
	
	
	/**
	 * Returns the AgentId for the default MBeanServer
	 * @return the AgentId of the default MBeanServer
	 */
	public static String getAgentId() {
		return getAgentId(getHeliosMBeanServer());
	}
	
	
	/**
	 * Inspects the array to see if it contains the passed string.
	 * @param name The name to search for
	 * @param array The array to search
	 * @return true if the array contains the passed string.
	 */
	public static boolean isIn(String name, String[] array) {
		if(array==null || name==null) return false;
		return Arrays.binarySearch(array, name)>=0; 
	}
	
	
	/**
	 * Sets a list of MBean attributes. Throws an exception on any failure. Returns a map of successfully set values.
	 * @param on the object name
	 * @param server the mbean server
	 * @param attributes The attributes to set
	 * @return a map of successfully set values.
	 */
	public static Map<String, Object> setAttributes(CharSequence on, MBeanServerConnection server, Object...attributes) {
		Map<String, Object> returnValues = new HashMap<String, Object>(attributes.length);		
		Collection<NVP> list = NVP.generate(attributes);
		for(NVP nvp: list) {
			setAttribute(on, server, nvp.getName(), nvp.getValue());
			returnValues.put(nvp.getName(), nvp.getValue());
		}
		return returnValues;
	}
	
	/**
	 * Gets an attribute value from an mbean.
	 * @param on on the object name
	 * @param server the mbean server
	 * @param name the name of the attribute
	 * @return the value of the attribute
	 */
	public static Object getAttribute(ObjectName on, MBeanServerConnection server, String name) {
		try {
			return server.getAttribute(on,name);
		} catch (Exception e) {
			throw new RuntimeException("Failed to get attribute", e);
		}
	}
	
	/**
	 * Gets an attribute value from an mbean in the Helios MBeanServer
	 * @param on on the object name
	 * @param name the name of the attribute
	 * @return the value of the attribute
	 */
	public static <T> T getAttribute(ObjectName on, String name) {
		try {
			return (T)getHeliosMBeanServer().getAttribute(on,name);
		} catch (Exception e) {
			throw new RuntimeException("Failed to get attribute", e);
		}
	}
	
	/**
	 * Gets an attribute value from an mbean in the Helios MBeanServer
	 * @param on on the object name
	 * @param name the name of the attribute
	 * @return the value of the attribute
	 */
	public static <T> T getAttribute(CharSequence on, String name) {
		return getAttribute(objectName(on), name);
	}
	
	
	/**
	 * Invokes an operation on the mbean.
	 * @param on the object name
	 * @param server the mbean server
	 * @param action The name of the operation to invoke
	 * @param args The argument values to pass to the invocation
	 * @param signature The argument signature
	 * @return the return value of the invocation
	 */
	public static Object invoke(ObjectName on, MBeanServerConnection server, String action, Object[] args, String[] signature) {
		try {
			return server.invoke(on, action, args, signature);
		} catch (Exception e) {
			throw new RuntimeException("Failed to invoke operation", e);
		}
	}
	
	/**
	 * Invokes an operation on the mbean in the default MBeanServer
	 * @param on the object name
	 * @param action The name of the operation to invoke
	 * @param args The argument values to pass to the invocation
	 * @param signature The argument signature
	 * @return the return value of the invocation
	 */
	public static Object invoke(ObjectName on, String action, Object[] args, String[] signature) {
		return invoke(on, JMXHelper.getHeliosMBeanServer(), action, args, signature);
	}
	

	/**
	 * Invokes an operation on the mbean.
	 * @param on the object name
	 * @param server the mbean server
	 * @param action The name of the operation to invoke
	 * @param args The argument values to pass to the invocation
	 * @param signature The argument signature
	 * @return the return value of the invocation
	 */	
	public static Object invoke(CharSequence on, MBeanServerConnection server, String action, Object[] args, String[] signature) {
		return invoke(objectName(on), server, action, args, signature);
	}
	
	/**
	 * Invokes an operation on the mbean in the default MBeanServer
	 * @param on the object name
	 * @param action The name of the operation to invoke
	 * @param args The argument values to pass to the invocation
	 * @param signature The argument signature
	 * @return the return value of the invocation
	 */
	public static Object invoke(CharSequence on, String action, Object[] args, String[] signature) {
		return invoke(on, JMXHelper.getHeliosMBeanServer(), action, args, signature);
	}
	
	/**
	 * Invokes a no arg operation on the mbean.
	 * @param on the object name
	 * @param server the mbean server
	 * @param action The name of the operation to invoke
	 * @return the return value of the invocation
	 */	
	public static Object invoke(CharSequence on, MBeanServerConnection server, String action) {
		return invoke(objectName(on), server, action, NO_ARG_ARR, NO_ARG_SIGNATURE);
	}
	
	/**
	 * Invokes a no arg operation on the mbean.
	 * @param on the object name
	 * @param server the mbean server
	 * @param action The name of the operation to invoke
	 * @return the return value of the invocation
	 */	
	public static Object invoke(ObjectName on, MBeanServerConnection server, String action) {
		return invoke(objectName(on), server, action, NO_ARG_ARR, NO_ARG_SIGNATURE);
	}
	
	/**
	 * Invokes a no arg operation on the mbean in the default MBeanServer
	 * @param on the object name
	 * @param action The name of the operation to invoke
	 * @return the return value of the invocation
	 */	
	public static Object invoke(CharSequence on, String action) {
		return invoke(objectName(on), JMXHelper.getHeliosMBeanServer(), action, NO_ARG_ARR, NO_ARG_SIGNATURE);
	}
	
	/**
	 * Invokes a no arg operation on the mbean in the default MBeanServer
	 * @param on the object name
	 * @param action The name of the operation to invoke
	 * @return the return value of the invocation
	 */	
	public static Object invoke(ObjectName on, String action) {
		return invoke(objectName(on), JMXHelper.getHeliosMBeanServer(), action, NO_ARG_ARR, NO_ARG_SIGNATURE);
	}
	
	/**
	 * Returns a set of ObjectNames matching the passed wildcard object names
	 * @param wildcardEq The ObjectName equals
	 * @param wildcardWc The ObjectName wildcard
	 * @param conn The MBeanServer connection
	 * @return a set of ObjectNames matching the passed wildcard object name
	 */
	public static Set<ObjectName> getMatchingObjectNames(CharSequence wildcardEq, CharSequence wildcardWc, MBeanServerConnection conn) {
		ObjectName wildcardEquals = objectName(wildcardEq);
		ObjectName wildcard = objectName(wildcardWc);
		
		final String wc = new StringBuilder("(").append(wildcardEquals).append("$)").toString();
		Set<ObjectName> names = new HashSet<ObjectName>();
		// A map of regex patterns to match on, keyed by the actual property key
		Map<String, Pattern> wildcardQueryProps = new HashMap<String, Pattern>();
		// the original wildcard object's key properties
		Hashtable<String, String> wildcardProps = objectName(wildcard).getKeyPropertyList();
		// the non wildcarded property keys we will query the mbean server with
		Hashtable<String, String> queryProps = new Hashtable<String, String>();
		queryProps.putAll(wildcardProps);
		// Extract the wildcarded property keys, ie, where the key is KEY<wildcardEquals>
		for(Map.Entry<String, String> prop: wildcard.getKeyPropertyList().entrySet()) {
			if(prop.getKey().endsWith(wc)) {
				String actualKey = prop.getKey().replaceFirst(wc, "");
				wildcardQueryProps.put(actualKey, Pattern.compile(prop.getValue()));
				queryProps.remove(actualKey);
			}
		}
		// Build the lookup query
		StringBuilder b = new StringBuilder(wildcard.getDomain());
		b.append(":");
		// Append the non regex wildcarded properties
		for(Map.Entry<String, String> qp: queryProps.entrySet()) {
			b.append(qp.getKey()).append("=").append(qp.getValue()).append(",");
		}
		// Append the regex wildcarded property keys and "*" as the value
		for(String key: wildcardQueryProps.keySet()) {
			b.append(key).append("=*,");
		}
		// Append a property wild card if the wildcard objectName had:
		//	Property Pattern:true
		//	PropertyList Pattern:true
		//	PropertyValue Pattern:false
		if(wildcard.isPropertyPattern() && wildcard.isPropertyListPattern() && !wildcard.isPropertyValuePattern()) {
			b.append("*");
		}
		if(b.toString().endsWith(",")) {
			b.deleteCharAt(b.length()-1);
		}
		// Create the query object
		try {
			ObjectName queryObjectName = objectName(b);
			for(ObjectName qon: conn.queryNames(queryObjectName, null)) {
				boolean match = true;
				for(Map.Entry<String, Pattern> pattern: wildcardQueryProps.entrySet()) {
					match = pattern.getValue().matcher(qon.getKeyProperty(pattern.getKey())).matches();
					if(!match) break;
				}
				if(match) {
					names.add(qon);
				}
			}
		} catch (Exception e) {			
		}
		
		// Remove all the wildcarded properties from the wildcard objectname's props
		
		//ObjectName query = new ObjectName(wildcard.getDomain());
		
		
		return names;
	}
	
	/*
import java.util.regex.*;
import javax.management.*;

String value = "com.ecs.jms.destinations:service~=[A/B/C],type~=[Queue|Topic],*";
on =  new ObjectName(value);
println on.getKeyPropertyList();
Pattern p = Pattern.compile("[:|,](\\S+?)~=\\[(\\S+?)\\]");
Matcher m = p.matcher(value);
while(m.find()) {
    println "Group:${m.group(1)}";
    println "Group:${m.group(2)}";
}

	 */
	
	
	
//	/**
//	 * Returns an attribute map for the MBean with the passed object name registered in the passed server
//	 * @param server The MBeanServer where the target MBean is registered
//	 * @param objectName The object name of the target MBean. Should not be a pattern. For pattern lookups, use {@link JMXHelper#getMBeanAttributeMap(MBeanServerConnection, ObjectName, String, Collection)}.
//	 * @return A map of attribute values keyed by attribute name
//	 */
//	public static Map<String, Object> getMBeanAttributeMap(MBeanServerConnection server, ObjectName objectName) {
//		if(objectName==null) throw new IllegalArgumentException("The passed ObjectName was null", new Throwable());
//		if(objectName.isPattern()) throw new IllegalArgumentException("The passed ObjectName was a pattern. For pattern lookups, use {@link JMXHelper#getMBeanAttributeMap(MBeanServerConnection, ObjectName, String, Collection)}", new Throwable());
//		if(server==null) server = getHeliosMBeanServer();
//		MBean
//	}
	
	
	
	
	/**
	 * Retrieves maps of attribute values keyed by attribute name, in turn keyed by the ObjectName of the MBean.
	 * @param server An MBeanServerConnection
	 * @param objectName An ObjectName which can be absolute or a wildcard.
	 * @param delimeter The delimeter for composite type compound names
	 * @param attributeNames An array of absolute or compound attribute names.
	 * @return a map of results.
	 * TODO: TabularData
	 * TODO: Collections / Maps / Arrays --> ref by index
	 */
	public static Map<ObjectName, Map<String, Object>> getMBeanAttributeMap(MBeanServerConnection server, ObjectName objectName, String delimeter, String...attributeNames) {
		if(server==null) throw new RuntimeException("MBeanServerConnection was null", new Throwable());
		if(objectName==null) throw new RuntimeException("ObjectName was null", new Throwable());
		if(attributeNames==null || attributeNames.length<1) {
			attributeNames = new String[]{"*"};
		}
//		String[] rootNames = new String[attributeNames.length];
//		Map<String, String> compoundNames = new HashMap<String, String>();
//		for(int i = 0; i < attributeNames.length; i++) {
//			String rootKey = null;
//			if(attributeNames[i].contains(delimeter)) {
//				String[] fragments = attributeNames[i].split(Pattern.quote(delimeter));
//				rootKey = fragments[0];
//				compoundNames.put(rootKey, attributeNames[i]);
//			} else {
//				rootKey = attributeNames[i];
//			}
//			rootNames[i] = rootKey;
//		}
		Map<ObjectName, Map<String, Object>> map = new HashMap<ObjectName, Map<String, Object>>();		
		try {
			for(ObjectName on: server.queryNames(objectName, null)) {
				AttributeList attrs = null;
				try {
					String[] anames = null;
					if(attributeNames!=null && attributeNames.length==1 && "*".equals(attributeNames[0])) {
						anames = getAttributeNames(on, server);
					} else {
						anames = attributeNames;
					}
					attrs = server.getAttributes(on, anames);
					if(attrs.size()<1) continue;
				} catch (Exception e) {
					continue;
				}
				Map<String, Object> attrMap = new HashMap<String, Object>();
				map.put(on, attrMap);
				final MBeanInfo mbeanInfo = getMBeanInfo(server, on);
				final Map<String, MBeanAttributeInfo> attrInfos = indexAttributes(mbeanInfo);
				for(Attribute attr: attrs.asList()) {
					Object value = attr.getValue();
					if(value==null) continue;
					String name = attr.getName();
					MBeanAttributeInfo attrInfo = attrInfos.get(name);
					if(value instanceof CompositeData || value instanceof TabularData) {
						try {
							Map<String, Object> indexedData = indexOpenData(name, value, delimeter, attrInfo);
							attrMap.putAll(indexedData);
						} catch (Exception e) {
							continue;
						}
					} else {
						attrMap.put(name, value);
					}
				}
			}
		} catch (Exception e) {
			throw new RuntimeException("Failed to acquire attribute names for ObjectName [" + objectName + "] for MBeanServer [" + server + "]", e);
		}
		
		return map;
	}
	
	/**
	 * Retrieves maps of attribute values keyed by attribute name, in turn keyed by the ObjectName of the MBean.
	 * @param server An MBeanServerConnection
	 * @param objectName An ObjectName which can be absolute or a wildcard.
	 * @param delimeter The delimeter for composite type compound names
	 * @param attributeNames An collection of absolute or compound attribute names.
	 * @return a map of results.
	 */
	public static Map<ObjectName, Map<String, Object>> getMBeanAttributeMap(MBeanServerConnection server, ObjectName objectName, String delimeter, Collection<String> attributeNames) {
		if(attributeNames==null || attributeNames.size()<1) throw new RuntimeException("Attribute names collection was null or zero size", new Throwable());
		return getMBeanAttributeMap(server, objectName, delimeter, attributeNames.toArray(new String[attributeNames.size()]));
	}
	
	/**
	 * Returns the MBeanInfo for the passed ObjectName from the specified MBeanServer
	 * @param server The MBeanServer to get the MBeanInfo from
	 * @param objectName The ObjectName of the MBean to get info for
	 * @return the MBeanInfo of the specified ObjectName
	 */
	public static MBeanInfo getMBeanInfo(MBeanServerConnection server, ObjectName objectName) {
		try {
			return server.getMBeanInfo(objectName);
		} catch (Exception ex) {
			throw new RuntimeException("Failed to get MBeanInfo for [" + objectName + "]");
		}
	}
	
	/**
	 * Returns the MBeanInfo for the passed ObjectName from the helios MBeanServer
	 * @param objectName The ObjectName of the MBean to get info for
	 * @return the MBeanInfo of the specified ObjectName
	 */
	public static MBeanInfo getMBeanInfo(ObjectName objectName) {
		return getMBeanInfo(getHeliosMBeanServer(), objectName);
	}
	
	/**
	 * Returns the MBeanInfo for the passed ObjectName from the specified MBeanServer
	 * @param server The MBeanServer to get the MBeanInfo from
	 * @param objectName The ObjectName of the MBean to get info for
	 * @return the MBeanInfo of the specified ObjectName
	 */
	public static MBeanInfo getMBeanInfo(MBeanServerConnection server, CharSequence objectName) {
		return getMBeanInfo(server, objectName(objectName));
	}
	
	/**
	 * Returns the MBeanInfo for the passed ObjectName from the helios MBeanServer
	 * @param objectName The ObjectName of the MBean to get info for
	 * @return the MBeanInfo of the specified ObjectName
	 */
	public static MBeanInfo getMBeanInfo(CharSequence objectName) {
		return getMBeanInfo(getHeliosMBeanServer(), objectName(objectName));
	}

	
	/**
	 * Extracts a composite data field from a CompositeData instance using a compound name.
	 * @param cd The composite data instance
	 * @param delimeter The delimiter used for the compound name
	 * @param name The compound attribute name
	 * @return The extracted object
	 */
	public static Object extractCompositeData(final CompositeData cd, final String delimeter, final String name) {
		String[] fragments = name.split(Pattern.quote(delimeter));
		CompositeData ref = cd;
		Object value = null;
		for(int i = 1; i < fragments.length; i++) {
			value = ref.get(fragments[i]);
			if(value instanceof CompositeData) {
				ref = (CompositeData)value;
			} else {
				break;
			}
		}
		return value;
	}
	
	/**
	 * Indexes the attributes of the passed MBeanInfo by name
	 * @param mbeanInfo The MBeanInfo to index the attributes for
	 * @return A map of MBeanAttributeInfo keyed by name
	 */
	public static Map<String, MBeanAttributeInfo> indexAttributes(final MBeanInfo mbeanInfo) {
		if(mbeanInfo==null) return Collections.emptyMap();
		final MBeanAttributeInfo[] infos = mbeanInfo.getAttributes();
		final Map<String, MBeanAttributeInfo> map = new HashMap<String, MBeanAttributeInfo>(infos.length);
		for(MBeanAttributeInfo info: infos) {
			map.put(info.getName(), info);
		}
		return map;
	}
	
	/**
	 * Indexes the passed OpenData instance
	 * @param name The attribute name
	 * @param openData The OpenData instance
	 * @param delimiter The composite key delimiter
	 * @param attrInfo The MBeanAttributeInfo for the source MBean 
	 * @return a map of values keyed by the composite key
	 */
	public static Map<String, Object> indexOpenData(final String name, final Object openData, String delimiter, final MBeanAttributeInfo attrInfo) {
		if(openData==null) return Collections.emptyMap();
		if(delimiter==null) delimiter = "/";		
		final Map<String, Object> indexMap = new HashMap<String, Object>();
		if(openData instanceof CompositeData) {
			CompositeData cd = (CompositeData)openData;
			CompositeType ct = cd.getCompositeType();
			for(String key: ct.keySet()) {
				indexMap.put(name + delimiter + key , cd.get(key));
			}			
		} else if(openData instanceof TabularData) {
			TabularData td = (TabularData)openData;
			TabularType tt = td.getTabularType();
			CompositeType ct = tt.getRowType();			
			@SuppressWarnings("unchecked")
			Set<List<?>> keySets = (Set<List<?>>) td.keySet();
			for(List<?> keyset: keySets) {
				StringBuilder compositeKey = new StringBuilder(name).append(delimiter);
				for(Object k: keyset) {
					compositeKey.append(k).append(delimiter);
				}
				CompositeData cd = td.get(keyset.toArray());				
				for(String key: ct.keySet()) {
					indexMap.put(compositeKey.toString() + key, cd.get(key));
				}
			}
		} else  {
			System.err.println("\n\t!!!!!!!!!!!!!!!!\n\tUnhandled OpenType for [" + name + "]:" + openData.getClass().getName() + "\n\t!!!!!!!!!!!!!!!!\n");
		}
		return indexMap;
	}
	
	
	
	/**
	 * A regex pattern to parse A[X/Y/Z...] 
	 */
	public static final Pattern OBJECT_NAME_ATTR_PATTERN = Pattern.compile("(\\S+)\\[(\\S+)\\]"); 
	
	/**
	 * Retrieves the named attribute from the MBean with the passed ObjectName in the passed MBeanServerConnection.
	 * If the retrieval results in an exception or a null, the default value is returned 
	 * @param conn The MBeanServerConnection to the MBeanServer where the target MBean is registered
	 * @param objectName The ObjectName  of the target MBean
	 * @param attributeName The attribute name
	 * @param defaultValue The default value
	 * @return The attribute value or the defaut value
	 */
	@SuppressWarnings("unchecked")
	public static <T> T getAttribute(MBeanServerConnection conn, ObjectName objectName, String attributeName, T defaultValue) {
		try {
			T t = (T)conn.getAttribute(objectName, attributeName);
			return t==null ? defaultValue : t;
		} catch (Exception e) {
			return defaultValue;
		}
	}
	
	/**
	 * Retrieves an attribute from an MBeanServer connection. 
	 * The compound name is in the format <b><code>&lt;ObjectName&gt;[&lt;Fragment<i>1</i>&gt;/&lt;Fragment<i>2</i>&gt;/&lt;Fragment<i>n</i>&gt;]</code></b>. 
	 * The multiple fragment names represent support for nested fields in a composite type.
	 * To retrieve a standard "flat" attribute, simply supply one fragment. 
	 * @param conn The MBeanServer connection
	 * @param compoundName The compound name
	 * @return the attribute value or null.
	 */
	public static Object getAttribute(MBeanServerConnection conn, CharSequence compoundName) {
		try {
			Matcher m = OBJECT_NAME_ATTR_PATTERN.matcher(compoundName);
			if(m.find()) {
				String objName = m.group(1);
				String[] fragments = m.group(2).split("/");
				return getAttribute(conn, objName, fragments);
			}
			return null;
		} catch (Exception e) { return null; }
	}
	
	/**
	 * Retrieves an attribute from an MBeanServer connection. 
	 * @param conn The MBeanServer connection
	 * @param objectName The ObjectName
	 * @param attrs the compound attribute name in the format <b><code>&lt;Fragment<i>1</i>&gt;/&lt;Fragment<i>2</i>&gt;/&lt;Fragment<i>n</i>&gt;</code></b>.
	 * @return the attribute value or null.
	 */
	public static Object getAttribute(MBeanServerConnection conn, String objectName, String...attrs) {
		return getAttribute(conn, objectName(objectName), attrs);
	}
	
	/**
	 * Retrieves an attribute from an MBeanServer connection with a default compound delimiter of <code>/</code> 
	 * @param conn The MBeanServer connection
	 * @param objectName The ObjectName
	 * @param attrs the compound attribute name in the format <b><code>&lt;Fragment<i>1</i>&gt;/&lt;Fragment<i>2</i>&gt;/&lt;Fragment<i>n</i>&gt;</code></b>.
	 * @return the attribute value or null.
	 */
	public static Object getAttribute(MBeanServerConnection conn, ObjectName objectName, String...attrs) {
		return getAttribute(conn, "/", objectName, attrs);
	}
	
	/**
	 * Retrieves an attribute from an MBeanServer connection. 
	 * @param conn The MBeanServer connection
	 * @param delimiter The compund opentype delimiter
	 * @param objectName The ObjectName
	 * @param attrs the compound attribute name in the format <b><code>&lt;Fragment<i>1</i>&gt;<b>DELIMITER</b>&lt;Fragment<i>2</i>&gt;<b>DELIMITER</b>&lt;Fragment<i>n</i>&gt;</code></b>.
	 * @return the attribute value or null.
	 */
	public static Object getAttribute(MBeanServerConnection conn, String delimiter, ObjectName objectName, String...attrs) {
		try {
			if(objectName!=null && attrs!=null && attrs.length > 0) {
				ObjectName on = objectName;
				String key = StringHelper.fastConcatAndDelim(delimiter, attrs);
				Map<ObjectName, Map<String, Object>> map = getMBeanAttributeMap(conn, on, delimiter, key);
				return map.get(on).get(key);
			}
		} catch (Exception e) {
		}
		return null;
	}
	
	/**
	 * Retrieves an attribute from an MBeanServer connection. 
	 * @param conn The MBeanServer connection
	 * @param delimiter The compund opentype delimiter
	 * @param objectName The ObjectName
	 * @param attrs the compound attribute name in the format <b><code>&lt;Fragment<i>1</i>&gt;<b>DELIMITER</b>&lt;Fragment<i>2</i>&gt;<b>DELIMITER</b>&lt;Fragment<i>n</i>&gt;</code></b>.
	 * @return the attribute value or null.
	 */
	public static Object getAttribute(MBeanServerConnection conn, String delimiter, String objectName, String...attrs) {
		return getAttribute(conn, delimiter, objectName(objectName), attrs);
	}
	
	
	/**
	 * Adds a listener to a registered MBean.
	 * @param connection The MBeanServer to register the listener with
	 * @param name The name of the MBean on which the listener should be added.
	 * @param listener The listener object which will handle the notifications emitted by the registered MBean.
	 * @param filter The filter object. If filter is null, no filtering will be performed before handling notifications.
	 * @param handback The context to be sent to the listener when a notification is emitted. 
	 */
	public static void addNotificationListener(MBeanServerConnection connection, ObjectName name, NotificationListener listener, NotificationFilter filter, Object handback) {
		try {
			connection.addNotificationListener(name, listener, filter, handback);
		} catch (Exception ex) {
			if(isDebugAgentLoaded()) ex.printStackTrace(System.err);
			throw new RuntimeException("Failed to register JMX Notification Listener", ex);
		}
	}
	
	/**
	 * Adds a listener to a registered MBean in the Helios MBeanServer
	 * @param name The name of the MBean on which the listener should be added.
	 * @param listener The listener object which will handle the notifications emitted by the registered MBean.
	 * @param filter The filter object. If filter is null, no filtering will be performed before handling notifications.
	 * @param handback The context to be sent to the listener when a notification is emitted. 
	 */
	public static void addNotificationListener(ObjectName name, NotificationListener listener, NotificationFilter filter, Object handback) {
		addNotificationListener(getHeliosMBeanServer(), name, listener, filter, handback);
	}
	
	/**
	 * Adds a listener to a registered MBean.
	 * @param connection The MBeanServer to register the listener with
	 * @param name The name of the MBean on which the listener should be added.
	 * @param listener The object name of the listener which will handle the notifications emitted by the registered MBean.
	 * @param filter The filter object. If filter is null, no filtering will be performed before handling notifications.
	 * @param handback The context to be sent to the listener when a notification is emitted. 
	 */
	public static void addNotificationListener(MBeanServerConnection connection, ObjectName name, ObjectName listener, NotificationFilter filter, Object handback) {
		try {
			connection.addNotificationListener(name, listener, filter, handback);
		} catch (Exception ex) {
			if(isDebugAgentLoaded()) ex.printStackTrace(System.err);
			throw new RuntimeException("Failed to register JMX Notification Listener", ex);
		}
	}

	/**
	 * Adds a listener to a registered MBean in the Helios MBeanServer
	 * @param name The name of the MBean on which the listener should be added.
	 * @param listener The object name of the listener which will handle the notifications emitted by the registered MBean.
	 * @param filter The filter object. If filter is null, no filtering will be performed before handling notifications.
	 * @param handback The context to be sent to the listener when a notification is emitted. 
	 */
	public static void addNotificationListener(ObjectName name, ObjectName listener, NotificationFilter filter, Object handback) {
		addNotificationListener(getHeliosMBeanServer(), name, listener, filter, handback);
	}
	
	/**
	 * Registers a listener in the default/Helios MBeanServer to listen on MBean registrations matching the passed ObjectName.
	 * If the passed ObjectName is not a pattern, the listener will be removed once the notification is received.
	 * If the passed ObjectName is a pattern, multiple callbacks will be processed until the number of notifications
	 * is equal to the the passed notification count, at which point the listener will be removed. If the passed notification count
	 * is less than 1, the listener will never be removed.
	 * @param listenFor The ObjectName to listen on registration for. May be a pattern to receive multiple callbacks 
	 * @param callback The notification listener to call back on when a registration event occurs
	 * @param notificationCount The number of notifications to receive before unregistering the listener
	 */
	public static void addMBeanRegistrationListener(final ObjectName listenFor, final NotificationListener callback, final int notificationCount) {
		addMBeanRegistrationListener(getHeliosMBeanServer(), listenFor, callback, notificationCount);
	}
	
	/**
	 * Registers a listener in the passed MBeanServer to listen on MBean registrations matching the passed ObjectName.
	 * If the passed ObjectName is not a pattern, the listener will be removed once the notification is received.
	 * If the passed ObjectName is a pattern, multiple callbacks will be processed until the number of notifications
	 * is equal to the the passed notification count, at which point the listener will be removed. If the passed notification count
	 * is less than 1, the listener will never be removed.
	 * @param server The MBeanServer to register the listener with
	 * @param listenFor The ObjectName to listen on registration for. May be a pattern to receive multiple callbacks 
	 * @param callback The notification listener to call back on when a registration event occurs
	 * @param notificationCount The number of notifications to receive before unregistering the listener
	 */
	public static void addMBeanRegistrationListener(final MBeanServerConnection server, final ObjectName listenFor, final NotificationListener callback, final int notificationCount) {
		if(server==null) throw new IllegalArgumentException("Passed MBeanServer was null");
		if(listenFor==null) throw new IllegalArgumentException("Passed ObjectName was null");
		if(callback==null) throw new IllegalArgumentException("Passed Callback was null");
		final boolean isPattern = listenFor.isPattern();
		final NotificationListener nl = new NotificationListener() {
			/** The number of notifications received */
			final AtomicInteger notificationsReceived = new AtomicInteger(0);
			@Override
			public void handleNotification(final Notification notification, final Object handback) {				
				final MBeanServerNotification msn = (MBeanServerNotification)notification;
				final ObjectName on = msn.getMBeanName();
				final int ncount = notificationsReceived.incrementAndGet();
				SharedNotificationExecutor.getInstance().execute(new Runnable() {
					@Override
					public void run() {
						callback.handleNotification(msn, on);
					}
				});
				if(!isPattern || (notificationCount > 0 && ncount >= notificationCount)) {
					try {
						server.removeNotificationListener(MBeanServerDelegate.DELEGATE_NAME, this);
					} catch (Exception ex) {}					
				}
			}
		};
		final NotificationFilter nf = new NotificationFilter() {
			/**  */
			private static final long serialVersionUID = -6799577777517082076L;
			@Override
			public boolean isNotificationEnabled(final Notification notification) {
				if(!(notification instanceof MBeanServerNotification) || !MBeanServerNotification.REGISTRATION_NOTIFICATION.equals(notification.getType())) return false;
				final MBeanServerNotification msn = (MBeanServerNotification)notification;
				if(isPattern) {
					return listenFor.apply(msn.getMBeanName());
				}
				return msn.getMBeanName().equals(listenFor);								
			}
		};
		try {
			server.addNotificationListener(MBeanServerDelegate.DELEGATE_NAME, nl, nf, null);
		} catch (Exception ex) {
			if(isDebugAgentLoaded()) ex.printStackTrace(System.err);
			throw new RuntimeException("Failed to register notification listener for [" + listenFor + "]", ex);
		}
	}
	
	
	/**
	 * Removes a notification listener
	 * @param connection The MBeanServer to remove the listener from
	 * @param name The ObjectName the listener was registered with
	 * @param listener The listener to remove
	 */
	public static void removeNotificationListener(MBeanServerConnection connection, ObjectName name, NotificationListener listener) {
		try {
			 connection.removeNotificationListener(name, listener);
		} catch (Exception ex) {
			throw new RuntimeException("Failed to remove JMX notification listener", ex);
		}
	}
	
	/**
	 * Removes a notification listener from the Helios MBeanServer
	 * @param name The ObjectName the listener was registered with
	 * @param listener The listener to remove
	 */
	public static void removeNotificationListener(ObjectName name, NotificationListener listener) {
		removeNotificationListener(getHeliosMBeanServer(), name, listener);
	}
	

	/**
	 * Wrapped call to <code>java.beans.Introspector</code>.
	 * Impl. may be swapped out.
	 * @param pojo The object to get the bean info for.
	 * @return A BeanInfo instance.
	 */
	public static BeanInfo getBeanInfo(Object pojo) {
		try {
			return Introspector.getBeanInfo(pojo.getClass());
		} catch (Exception e) {
			throw new RuntimeException("Failed to create bean info", e);
		}
	}
	
	/**
	 * Reregisters mbeans from one MBeanServer to another.
	 * @param query An ObjectName mask.
	 * @param source The source MBeanServer
	 * @param target The target MBeanServer
	 * @return The number of MBeans susccessfully re-registered.
	 */
	public static int remapMBeans(ObjectName query, MBeanServer source, MBeanServer target) {
		int remaps = 0;
		Set<ObjectName> mbeans = target.queryNames(query, null);
		for(ObjectName on: mbeans) {
			try {
				Object proxy = MBeanServerInvocationHandler.newProxyInstance(source, on, DynamicMBean.class, true);
				target.registerMBean(proxy, on);
				remaps++;
			} catch (Exception e) {/* No Op */}
		}
		return remaps;
	}
	/**
	 * Creates, registers and starts a JMXConnectorServer
	 * @param bindInterface The interface to bind to
	 * @param serviceURL The JMXService URL
	 * @param server The MBeanServer to expose
	 */
	public static void fireUpJMXServer(final String bindInterface, final int serverSocketBacklog, CharSequence serviceURL, MBeanServer server) {
		try {
			fireUpJMXServer(bindInterface, serverSocketBacklog, new JMXServiceURL(serviceURL.toString()), server);
		} catch (Exception e) {
			throw new RuntimeException("Failed to start JMXServer on [" + serviceURL + "]", e);
		}
	}
	
	
	/**
	 * Creates, registers and starts a JMXConnectorServer
	 * @param bindInterface The interface to bind to
	 * @param serviceURL The JMXService URL
	 * @param server The MBeanServer to expose
	 */
	public static void fireUpJMXServer(final String bindInterface, final int serverSocketBacklog, JMXServiceURL serviceURL, MBeanServer server) {
		try {
			Map<String, Object> env = Collections.singletonMap("jmx.remote.rmi.server.socket.factory", (Object)new RMISocketFactory(){
				public ServerSocket createServerSocket(int port) throws IOException {
					return new ServerSocket(port, serverSocketBacklog, InetAddress.getByName(bindInterface));
				}
				public Socket createSocket(String host, int port) throws IOException {
					return new Socket(host, port);
				}
			});
			JMXConnectorServer jmxServer = JMXConnectorServerFactory.newJMXConnectorServer(serviceURL, env, server);
			server.registerMBean(jmxServer, JMXHelper.objectName("org.helios.netty:service=JMXConnectorServer,url=" + ObjectName.quote(serviceURL.toString())));
			jmxServer.start();
		} catch (Exception e) {
			throw new RuntimeException("Failed to start JMXServer on [" + serviceURL + "]", e);
		}
	}
	
	public static void fireUpRMIRegistry(final String bindInterface,  final int port)  {
		try {
			LocateRegistry.createRegistry(port);
		} catch (Exception e) {
			throw new RuntimeException("Failed to start RMIRegistry on [" + bindInterface + ":" + port + "]", e);
		}
	}
	
	public static void stopRMIRegistry(final String bindInterface,  final int port) {
		try {
			Registry reg = LocateRegistry.getRegistry(bindInterface, port);
			for(String s: reg.list()) {
				if(s.startsWith("RMIRegistry:") && s.endsWith(String.format(":%s___", port))) {
					Registry x = (Registry)reg.lookup(s);
					UnicastRemoteObject.unexportObject(x, true);
					break;
				}
			}
		} catch (Exception e) {
			throw new RuntimeException("Failed to stop RMIRegistry on [" + bindInterface + ":" + port + "]", e);
		}
	}
	
	public static void main(String[] args) {
		fireUpRMIRegistry("0.0.0.0",  20384);
		LOG.info(String.format("Registry started on [%s:%s]", "0.0.0.0",  20384));
		stopRMIRegistry("localhost", 20384);
		LOG.info("Registry stopped");
	}	
	
	/**
	 * Generates a unique key for an RMI registry end point
	 * @param bindInterface The network interface
	 * @param port The listening port
	 * @return the key
	 */
	public static String registryKey(final String bindInterface,  final int port) {
		return String.format("RMIRegistry:%s:%s___", bindInterface, port);
	}
	
	
	
	/**
	 * Registers a new classloader MBean (an MLet) on the passed MBeanServer
	 * @param server The MBeanServer on which to register
	 * @param objectName The JMX object name of the new MBean
	 * @param delegateToCLR True if, when a class is not found in either the parent ClassLoader or the URLs, the MLet should delegate to its containing MBeanServer's ClassLoaderRepository.
	 * @param privateClassLoader If true, registers a private MLet, otherwise, registers a public one
	 * @param urls The URLs from which to load classes and resources.
	 * @return the ObjectName of the classloader
	 */
	public static ObjectName publishClassLoader(MBeanServerConnection server, CharSequence objectName, boolean delegateToCLR, boolean privateClassLoader, URL...urls) {
		ObjectName on = objectName(objectName);
		String className = privateClassLoader ? "javax.management.loading.PrivateMLet" : "javax.management.loading.MLet"; 
		try {
			server.createMBean(className, on, new Object[]{urls, delegateToCLR}, new String[]{URL[].class.getName(), "boolean"});
			return on;
		} catch (Exception ex) {
			if(isDebugAgentLoaded()) ex.printStackTrace(System.err);
			throw new RuntimeException("Failed to register classloader MBean [" + objectName + "]", ex);
		}
	}
	
	/**
	 * Registers a new classloader MBean (an MLet) on the default MBeanServer
	 * @param objectName The JMX object name of the new MBean
	 * @param delegateToCLR True if, when a class is not found in either the parent ClassLoader or the URLs, the MLet should delegate to its containing MBeanServer's ClassLoaderRepository.
	 * @param privateClassLoader If true, registers a private MLet, otherwise, registers a public one
	 * @param urls The URLs from which to load classes and resources.
	 * @return the ObjectName of the classloader
	 */
	public static ObjectName publishClassLoader(CharSequence objectName, boolean delegateToCLR, boolean privateClassLoader, URL...urls) {
		return publishClassLoader(getHeliosMBeanServer(), objectName, delegateToCLR, privateClassLoader, urls);
	}
	
	/**
	 * Registers a new public classloader MBean (an MLet) on the default MBeanServer
	 * @param objectName The JMX object name of the new MBean
	 * @param delegateToCLR True if, when a class is not found in either the parent ClassLoader or the URLs, the MLet should delegate to its containing MBeanServer's ClassLoaderRepository.
	 * @param urls The URLs from which to load classes and resources.
	 * @return the ObjectName of the classloader
	 */
	public static ObjectName publishClassLoader(CharSequence objectName, boolean delegateToCLR, URL...urls) {
		return publishClassLoader(getHeliosMBeanServer(), objectName, delegateToCLR, false, urls);
	}
	
	/**
	 * Registers a new public and CLR delegating classloader MBean (an MLet) on the default MBeanServer
	 * @param objectName The JMX object name of the new MBean
	 * @param urls The URLs from which to load classes and resources.
	 * @return the ObjectName of the classloader 
	 */
	public static ObjectName publishClassLoader(CharSequence objectName, URL...urls) {
		return publishClassLoader(getHeliosMBeanServer(), objectName, true, false, urls);
	}

	/**
	 * Returns a string representing the passed ObjectName with the properties sorted
	 * alphabetically by the property key
	 * @param on The ObjectName to render
	 * @return the ObjectName string
	 */
	public static String getPropSortedObjectName(ObjectName on) {
		StringBuilder b = new StringBuilder(on.getDomain()).append(":");
		for(Map.Entry<String, String> prop : new TreeMap<String, String>(on.getKeyPropertyList()).entrySet()) {
			b.append(prop.getKey()).append("=").append(prop.getValue()).append(",");
		}
		return b.deleteCharAt(b.length()-1).toString();
	}

	/**
	 * Determines if the passed notification is an MBean Unregistration or Registration Notification
	 * @param notif The notification to test
	 * @param unregistered The optional object name to test against
	 * @param type The notification types to listen on
	 * @return true if the notification was an MBean Unregistration Notification,
	 * and if an ObjectName was supplied,if it matched the unregistered MBean's ObjectName
	 */
	public static boolean isMBeanRegDeregEvent(final Notification notif, final ObjectName unregistered, final String...type) {
		final Set<String> types = new HashSet<String>(Arrays.asList(type));
		return (
				notif != null &&
				notif instanceof MBeanServerNotification &&
				types.contains(notif.getType()) &&
				(
						unregistered == null ||
						(
								unregistered.isPattern() ? unregistered.apply(((MBeanServerNotification)notif).getMBeanName()) 
										:
											unregistered.equals(((MBeanServerNotification)notif).getMBeanName())
								)
						)
				);
	}


	/**
	 * Determines if the passed notification is an MBean Unregistration Notification
	 * @param notif The notification to test
	 * @param unregistered The optional object name to test against
	 * @return true if the notification was an MBean Unregistration Notification,
	 * and if an ObjectName was supplied,if it matched the unregistered MBean's ObjectName
	 */
	public static boolean isUnregistration(final Notification notif, final ObjectName unregistered) {
		return isMBeanRegDeregEvent(notif, unregistered, MBeanServerNotification.UNREGISTRATION_NOTIFICATION);
	}

	/**
	 * Determines if the passed notification is an MBean Registration Notification
	 * @param notif The notification to test
	 * @param registered The optional object name to test against
	 * @return true if the notification was an MBean Registration Notification,
	 * and if an ObjectName was supplied,if it matched the registered MBean's ObjectName
	 */
	public static boolean isRegistration(final Notification notif, final ObjectName registered) {
		return isMBeanRegDeregEvent(notif, registered, MBeanServerNotification.REGISTRATION_NOTIFICATION);
	}

	/**
	 * Registers an action to be excuted when an MBean is unregistered
	 * @param connection The MBeanServer where the MBean is registered
	 * @param objectName The ObjectName of the MBeanServer to fire the action on
	 * @param action The action to execute
	 * @return The created listener/filter
	 */
	public static MBeanRegistrationListener onMBeanUnregistered(final MBeanServerConnection connection, final ObjectName objectName, final MBeanEventHandler action) {
		return new MBeanRegistrationListener(connection, objectName, null, action);
	}

	/**
	 * Registers an action to be excuted when an MBean is unregistered from the default MBeanServer
	 * @param objectName The ObjectName of the MBeanServer to fire the action on
	 * @param action The action to execute
	 * @return The created listener/filter
	 */
	public static MBeanRegistrationListener onMBeanUnregistered(final ObjectName objectName, final MBeanEventHandler action) {
		return new MBeanRegistrationListener(null, objectName, null, action);
	}

	/**
	 * Registers an action to be excuted when an MBean is registered
	 * @param connection The MBeanServer where the MBean is registered
	 * @param objectName The ObjectName of the MBeanServer to fire the action on
	 * @param action The action to execute
	 * @return The created listener/filter
	 */
	public static MBeanRegistrationListener onMBeanRegistered(final MBeanServerConnection connection, final ObjectName objectName, final MBeanEventHandler action) {
		return new MBeanRegistrationListener(connection, objectName, action, null);
	}

	/**
	 * Registers an action to be excuted when an MBean is registered from the default MBeanServer
	 * @param objectName The ObjectName of the MBeanServer to fire the action on
	 * @param action The action to execute
	 * @return The created listener/filter
	 */
	public static MBeanRegistrationListener onMBeanRegistered(final ObjectName objectName, final MBeanEventHandler action) {
		return new MBeanRegistrationListener(null, objectName, action, null);
	}

	/**
	 * <p>Title: MBeanEventHandler</p>
	 * <p>Description: Callback handler for handling an MBeanRegistrationListener event</p> 
	 * <p>Company: Helios Development Group LLC</p>
	 * @author Whitehead (nwhitehead AT heliosdev DOT org)
	 * <p><code>com.heliosapm.jmx.util.helpers.JMXHelper.MBeanEventHandler</code></p>
	 */
	public static interface MBeanEventHandler {
		/**
		 * Fired when an MBeanRegistrationListener event occurs
		 * @param connection The MBeanServer where the event occured
		 * @param objectName The ObjectName of the MBean that triggered the event
		 * @param reg true if a registration, false if an unregistration
		 */
		public void onEvent(MBeanServerConnection connection, ObjectName objectName, boolean reg);
	}
	
	/**
	 * <p>Title: MBeanRegistrationListener</p>
	 * <p>Description: A notification listener that executes a defined action when an MBean is registered/unregistered</p> 
	 * <p>Company: Helios Development Group LLC</p>
	 * @author Whitehead (nwhitehead AT heliosdev DOT org)
	 * <p><code>com.heliosapm.jmx.util.helpers.JMXHelper.MBeanDeregistrationListener</code></p>
	 */
	public static class MBeanRegistrationListener implements NotificationListener, NotificationFilter {
		/**  */
		private static final long serialVersionUID = 5428542937613697900L;
		/** The object name to listen for the deregistration event on */
		protected final ObjectName objectName;
		/** The action to execute when the target object name is unregistered */
		protected final MBeanEventHandler uaction;
		/** The action to execute when the target object name is registered */
		protected final MBeanEventHandler raction;
		
		/** The MBeanServer where the MBean is registered */
		protected final MBeanServerConnection connection;
		/** Indicates if should be fired on registration */
		final boolean reg;
		/** Indicates if should be fired on unregistration */
		final boolean unreg;
		/** Indicates if the listener has been unregistered */
		final AtomicBoolean complete = new AtomicBoolean(false);

		/**
		 * Creates a new MBeanDeregistrationListener
		 * @param connection The MBeanServer where the MBean is registered
		 * @param objectName The object name to listen for the deregistration event on
		 * @param raction The action to execute when the target object name is registered
		 * @param uaction The action to execute when the target object name is unregistered
		 */
		public MBeanRegistrationListener(final MBeanServerConnection connection, final ObjectName objectName, 
				final MBeanEventHandler raction, final MBeanEventHandler uaction) {
			this.objectName = objectName;
			this.raction = raction;
			this.uaction = uaction;
			this.connection = connection!=null ? connection : getHeliosMBeanServer();
			this.reg = raction!=null;
			this.unreg = uaction!=null;
			try {
				this.connection.addNotificationListener(MBeanServerDelegate.DELEGATE_NAME, this, this, null);
			} catch (Exception ex) {
				throw new RuntimeException("Failed to register MBeanDeregistrationListener on [" + objectName + "]", ex);
			}
		}
		
		private static final String[] REG = {MBeanServerNotification.REGISTRATION_NOTIFICATION};
		private static final String[] UNREG = {MBeanServerNotification.UNREGISTRATION_NOTIFICATION};
		private static final String[] REGUNREG = {MBeanServerNotification.REGISTRATION_NOTIFICATION, MBeanServerNotification.UNREGISTRATION_NOTIFICATION};

		@Override
		public boolean isNotificationEnabled(final Notification notification) {
			return isMBeanRegDeregEvent(notification, objectName,
				reg&&unreg ? REGUNREG : reg ? REG : UNREG	
			);
		}		

		@Override
		public void handleNotification(final Notification notification, final Object handback) {
			if(reg && isRegistration(notification, objectName)) {
				try {					
					raction.onEvent(connection, objectName, true);
				} catch (Exception ex) {
					ex.printStackTrace(System.err);
				}				
			} else if(unreg && isUnregistration(notification, objectName)) {				
				try {
					uaction.onEvent(connection, objectName, false);
				} catch (Exception ex) {
					ex.printStackTrace(System.err);
				}					
			}
//			if(!objectName.isPattern() && didAction && ) {
//				try { connection.removeNotificationListener(MBeanServerDelegate.DELEGATE_NAME, this, this, null);
//				} catch (Exception ex) {/* No Op */}
//			}
		}
		
		/**
		 * Unregisters this listener
		 * @return true if successful, false if failed
		 */
		public boolean unregister() {
			if(complete.compareAndSet(false, true)) {
				try {
					connection.removeNotificationListener(MBeanServerDelegate.DELEGATE_NAME, this, this, null);
					return true;
				} catch (Exception ex) {
					return false;
				}				
			} else {
				return true;
			}
		}
	}




	static class NVP {
		String name = null;
		Object value = null;

		public static Collection<NVP> generate(Object...args) {
			List<NVP> list = new ArrayList<NVP>(args.length);
			String name = null;		
			for(int i=0; i<args.length; i++) {
				if(i+1 < args.length) {
					name=args[i].toString();
					i++;
					list.add(new NVP(name, args[i]));
				}
			}
			return list;
		}


		/**
		 * @param name The NVP name
		 * @param value The NVP value
		 */
		public NVP(String name, Object value) {
			super();
			this.name = name;
			this.value = value;
		}
		/**
		 * @return the name
		 */
		public String getName() {
			return name;
		}
		/**
		 * @param name the name to set
		 */
		public void setName(String name) {
			this.name = name;
		}
		/**
		 * @return the value
		 */
		public Object getValue() {
			return value;
		}
		/**
		 * @param value the value to set
		 */
		public void setValue(Object value) {
			this.value = value;
		}

	}
}

