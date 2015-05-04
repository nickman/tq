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
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.atomic.AtomicInteger;

import org.cliffc.high_scale_lib.NonBlockingHashMapLong;

import reactor.Environment;
import reactor.core.config.DispatcherType;
import reactor.fn.Consumer;
import reactor.rx.Streams;
import reactor.rx.broadcast.Broadcaster;

/**
 * <p>Title: RQ</p>
 * <p>Description: </p> 
 * <p>Company: Helios Development Group LLC</p>
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 * <p><code>tqueue.reactor.RQ</code></p>
 */

public class RQ {

	final NonBlockingHashMapLong<List<Integer>> complete = new NonBlockingHashMapLong<List<Integer>>(24);
	final AtomicInteger c = new AtomicInteger(10);
	/**
	 * Creates a new RQ
	 */
	public RQ() {
		
		final Random r = new Random(System.currentTimeMillis());
		final List<Integer> numbers = new ArrayList<Integer>(100);
		for(int i = 0; i < 100; i++) {
			numbers.add(r.nextInt(101));
		}
		
		Broadcaster<Integer> completionBroadcast = Broadcaster.create(Environment.cachedDispatcher());
		Streams.wrap(completionBroadcast).observeComplete(v -> System.out.println("DONE"));
		
		System.out.println("STARTING:" + c);
		Streams.from(numbers)
        .groupBy(s -> s%10)
        .consume(str -> {        	
            str.dispatchOn(Environment.newDispatcher("loop", 2, 1, DispatcherType.MPSC))
               
               .consume(
            		   v -> {
            			   if(33==v || 43==v || 53==v) throw new RuntimeException();
            			   System.out.println("[" + Thread.currentThread().getId() + "] Consumed: " + v);
            			   List<Integer> list = complete.get(Thread.currentThread().getId());
            			   if(list==null) {
            				   synchronized(complete) {
            					   list = complete.get(Thread.currentThread().getId());
                    			   if(list==null) {
                    				   list = new ArrayList<Integer>();
                    				   complete.put(Thread.currentThread().getId(), list);
                    			   }
            				   }
            			   }
            			   list.add(v);               			  
            		   },
            		   t -> System.err.println("[" + Thread.currentThread().getId() + "] FAILED:" + t),
            		   d ->  {
            			   final int k = c.decrementAndGet();
            			   System.out.println("[" + Thread.currentThread().getId() + "] Complete:" + k);
            			   
            		   }
            	);        
        });		
	}
	
	public static void main(String[] args) {
		Environment.initializeIfEmpty();	

//		Environment.initializeIfEmpty().assignErrorJournal(new Consumer<Throwable>(){
//			@Override
//			public void accept(final Throwable t) {
//				System.err.println("Untrapped exception");
//				t.printStackTrace(System.err);
//			}
//		});		
		RQ r = new RQ();
		while(r.c.get()!=0) {
			Thread.yield();
		}
		System.out.println("DONE:" + r.c);
		for(Map.Entry<Long, List<Integer>> entry: r.complete.entrySet()) {
			System.out.println("\n\tThread:" + entry.getKey() + ":  " + entry.getValue()); 
		}
		
	}

}
