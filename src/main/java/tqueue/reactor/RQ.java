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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import reactor.rx.Streams;

/**
 * <p>Title: RQ</p>
 * <p>Description: </p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.RQ</code></p>
 */

public class RQ {

	/**
	 * Creates a new RQ
	 */
	public RQ() {
		final List<String> startWith = new ArrayList<String>(Arrays.asList("Foo", "Bar", "Crumb"));
		Streams.from(startWith)
        .groupBy(s -> s)
        .consume(str -> {
            str.dispatchOn(cachedDispatcher())
               .observeComplete(v -> System.out.println("First expansion complete on " + Thread.currentThread()))
               .consume(s2 -> {
                   Streams.just(s2)
                          .dispatchOn(cachedDispatcher())
                          .observeComplete(v -> System.out.println("Second expansion complete on " + Thread.currentThread()))
                          .consume(s3 -> {
                              Streams.just(s3)
                                     .dispatchOn(cachedDispatcher())
                                     .observeComplete(v -> System.out.println("Third expansion complete on " + Thread.currentThread()))
                                     .consume(s4 -> System.out.println("Expansion result: " + s4));
                          });
               });
        });		
	}

}
