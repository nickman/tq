/**
 * Helios, OpenSource Monitoring
 * Brought to you by the Helios Development Group
 *
 * Copyright 2015, Helios Development Group and individual contributors
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
package tqueue.reactor;

import java.util.concurrent.atomic.AtomicInteger;

import javax.management.ObjectName;

import tqueue.helpers.JMXHelper;

/**
 * <p>Title: TQReactorMBean</p>
 * <p>Description: JMX interface for {@link TQReactor}</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.TQReactorMBean</code></p>
 */

public interface TQReactorMBean {
	/** The TQReactor's JMX ObjectName */
	public static final ObjectName OBJECT_NAME = JMXHelper.objectName("tqueue:service=TQReactor");

	/**
	 * Returns the number of active threads in the thread pool
	 * @return the number of active threads in the thread pool
	 */
	public int getActiveCount();
	
	/**
	 * Returns the number of completed tasks in the thread pool
	 * @return the number of completed tasks in the thread pool
	 */
	public long getCompletedTaskCount();
	
	/**
	 * Returns the number of scheduled tasks in the thread pool
	 * @return the number of scheduled tasks in the thread pool
	 */
	public long getTaskCount();
	
	
	/**
	 * Returns the thread pool's core size
	 * @return the thread pool's core size
	 */
	public int getCorePoolSize();
	
	/**
	 * Returns the thread pool's current size
	 * @return the thread pool's current size
	 */
	public int getPoolSize();
	
	
	/**
	 * Returns the thread pool's highwater mark size
	 * @return the thread pool's highwater mark size
	 */
	public int getLargestPoolSize();
	
	/**
	 * Returns the thread pool's max size
	 * @return the thread pool's max size
	 */
	public int getMaximumPoolSize();
	
	/**
	 * Returns the max number of rows to poll from the DB
	 * @return the maxRows
	 */
	public int getMaxRows();

	/**
	 * Sets the max number of rows to poll from the DB
	 * @param maxRows the maxRows to set
	 */
	public void setMaxRows(final int maxRows);

	/**
	 * Returns the maximum batch size to retrieve from the DB
	 * @return the maxBatchSize
	 */
	public int getMaxBatchSize();

	/**
	 * Sets the maximum batch size to poll from the DB 
	 * @param maxBatchSize the maxBatchSize to set
	 */
	public void setMaxBatchSize(final int maxBatchSize);

	/**
	 * Returns the poller wait time on the DB side in seconds
	 * @return the pollWaitTime
	 */
	public int getPollWaitTime();

	/**
	 * Sets the poller wait time on the DB side in seconds
	 * @param pollWaitTime the pollWaitTime to set in seconds
	 */
	public void setPollWaitTime(final int pollWaitTime);
	
	/**
	 * Returns the number of inflight batches
	 * @return the number of inflight batches
	 */
	public int getInflightBatchCount();
	
	public int getLoopCount();

	/**
	 * Returns 
	 * @return the lastBatchcount
	 */
	public int getLastBatchcount();

	/**
	 * Returns 
	 * @return the batchCount
	 */
	public int getBatchCount();

	/**
	 * Returns 
	 * @return the stubCount
	 */
	public int getStubCount();

	/**
	 * Returns 
	 * @return the dropCount
	 */
	public int getDropCount();
	
	/**
	 * Returns the total number of recoverable TQ exceptions
	 * @return the total number of recoverable TQ exceptions
	 */
	public int getRecovErrs();

	/**
	 * Returns the total number of unrecoverable TQ exceptions
	 * @return the unrecovErrs the total number of unrecoverable TQ exceptions
	 */
	public int getUnrecovErrs();	
	
	/**
	 * Returns the starting range of the next poll
	 * @return the starting range of the next poll
	 */
	public int getNextPollerStart();
	
	public void reset();
	
	public void reset(int nextId);

}
