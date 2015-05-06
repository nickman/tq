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

import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.IntUnaryOperator;

/**
 * <p>Title: HighwaterNextId</p>
 * <p>Description: Tracks the next id highwater for polling loops</p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.HighwaterNextId</code></p>
 */

public class HighwaterNextId {
	/** The next ID to start at, assuming no fails */
	protected final AtomicInteger nextId = new AtomicInteger(0);
	/** Indicates if the highwater is in a failed state */
	protected final AtomicBoolean failed = new AtomicBoolean(false);
	
	/**
	 * Updates the highwater next id if: <ol>
	 * 	<li>The value of {@code firstId} is higher than the current highwater</li>
	 *  <li>The highwater is not in a failed state</li>
	 * </ol>
	 * @param firstId
	 */
	public void update(final int firstId) {
		if(!failed.get()) {
			updateIfGt(firstId);
		}
	}
	
	/**
	 * Updates the highwater next id if: <ol>
	 * 	<li>The value of {@code firstId} is lower than the current highwater</li>
	 *  <li>The highwater is in a failed state</li>
	 * </ol>
	 * @param firstId
	 */
	public void fail(final int firstId) {
		if(failed.compareAndSet(false, true)) {
			nextId.set(firstId);
		} else {
			updateIfLt(firstId);
		}
	}
	
	private final void updateIfLt(final int value) {
		nextId.getAndUpdate(new IntUnaryOperator(){
			public int applyAsInt(final int current) {
				return value < current ? value : current;
			}
		});		
	}
	
	private final void updateIfGt(final int value) {
		nextId.getAndUpdate(new IntUnaryOperator(){
			public int applyAsInt(final int current) {
				return value > current ? value : current;
			}
		});		
	}
	
	/**
	 * Returns the current nextId
	 * @return the current nextId
	 */
	public int get() {
		return nextId.get();
	}
	
	/**
	 * Resets the failed state back to false
	 */
	public void reset() {
		failed.set(false);
	}
	
	/**
	 * Resets the failed state back to false
	 * @param startingValue The value to set the next id to
	 */
	public void reset(final int startingValue) {	
		if(failed.compareAndSet(true, false)) {
			nextId.set(startingValue);
		}			
	}
	

	
	/**
	 * {@inheritDoc}
	 * @see java.lang.Object#toString()
	 */
	public String toString() {
		return new StringBuilder("HighwaterNextId [ id:").append(nextId.get()).append(", failed:").append(failed.get()).append("]").toString();
	}
}


/*
public boolean GreaterThanCAS(int newValue) {
    while(true) {
        int local = oldValue.get();
        if(newValue <= local) {
             return false; // swap failed
        }
        if(oldValue.compareAndSwap(local, newValue)) {
             return true;  // swap successful
        }
        // keep trying
    }
}
*/