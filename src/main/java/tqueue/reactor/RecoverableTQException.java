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
package tqueue.reactor;

/**
 * <p>Title: RecoverableTQException</p>
 * <p>Description: Recoverable TQ processing excetion</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.RecoverableTQException</code></p>
 */

public class RecoverableTQException extends TQException {

	/**  */
	private static final long serialVersionUID = 941659130305111817L;

	/**
	 * Creates a new RecoverableTQException
	 * @param batch The batch routing key that caused the exception
	 * @param message The error message
	 * @param cause the underlying cause
	 */
	public RecoverableTQException(final BatchRoutingKey batch, final String message, final Throwable cause) {
		super(batch, message, cause);
	}
	
	/**
	 * Creates a new RecoverableTQException
	 * @param batch The batch routing key that caused the exception
	 * @param message The error message
	 */
	public RecoverableTQException(final BatchRoutingKey batch, final String message) {
		super(batch, message, null);
	}
	





}
