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

import tqueue.db.types.TQBATCH;

/**
 * <p>Title: BatchRoutingKey</p>
 * <p>Description: Encapsulates a char ROWID and an account to route a reference to a TQBATCH</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.BatchRoutingKey</code></p>
 */

public class BatchRoutingKey {
	final String rowid;
	final int accountId;
	final int tcount;
	
	/**
	 * Creates a new BatchRoutingKey
	 * @param rowid The char of the ROWID for the batch
	 * @param accountId The account id to route by
	 * @param tcount The stub count
	 */
	public BatchRoutingKey(final String rowid, final int accountId, final int tcount) {
		super();
		this.rowid = rowid;
		this.accountId = accountId;
		this.tcount = tcount;
	}
	
	
	/**
	 * Returns 
	 * @return the rowid
	 */
	public String getRowid() {
		return rowid;
	}
	/**
	 * Returns 
	 * @return the accountId
	 */
	public int getAccountId() {
		return accountId;
	}
	/**
	 * Returns 
	 * @return the tcount
	 */
	public int getTcount() {
		return tcount;
	}
	/**
	 * {@inheritDoc}
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		StringBuilder builder = new StringBuilder();
		builder.append("BatchRoutingKey [accountId=");
		builder.append(accountId);
		builder.append(", tcount=");
		builder.append(tcount);
		builder.append("]");
		return builder.toString();
	}
	/**
	 * {@inheritDoc}
	 * @see java.lang.Object#hashCode()
	 */
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((rowid == null) ? 0 : rowid.hashCode());
		return result;
	}
	/**
	 * {@inheritDoc}
	 * @see java.lang.Object#equals(java.lang.Object)
	 */
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		BatchRoutingKey other = (BatchRoutingKey) obj;
		if (rowid == null) {
			if (other.rowid != null)
				return false;
		} else if (!rowid.equals(other.rowid))
			return false;
		return true;
	}
	
	
}
