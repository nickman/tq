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
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.atomic.AtomicInteger;

import org.cliffc.high_scale_lib.NonBlockingHashMapLong;

import reactor.Environment;
import reactor.core.config.DispatcherType;
import reactor.fn.Consumer;
import reactor.fn.Function;
import reactor.rx.Stream;
import reactor.rx.StreamUtils;
import reactor.rx.Streams;
import reactor.rx.action.Control;
import reactor.rx.broadcast.Broadcaster;

/**
 * <p>
 * Title: RQ
 * </p>
 * <p>
 * Description:
 * </p>
 * <p>
 * Company: Helios Development Group LLC
 * </p>
 * 
 * @author Whitehead (nwhitehead AT heliosdev DOT org)
 *         <p>
 *         <code>tqueue.reactor.RQ</code>
 *         </p>
 */

public class RQ implements Iterable<Integer>, Iterator<Integer> {

	final NonBlockingHashMapLong<List<Integer>> complete = new NonBlockingHashMapLong<List<Integer>>(24);
	final NonBlockingHashMapLong<Set<String>> concurrentThreads = new NonBlockingHashMapLong<Set<String>>(24);
	final AtomicInteger c = new AtomicInteger(10);
	final Set<Stream<Integer>> taps = new CopyOnWriteArraySet<Stream<Integer>>();
	final AtomicInteger lastValue = new AtomicInteger(-1);
	final Control ctx;
	final Stream<Integer> rootStream;

	/**
	 * Creates a new RQ
	 */
	public RQ() {

		Broadcaster<Integer> broadcaster = Broadcaster.create(Environment.get(), Environment.get().newDispatcher(32, 1, DispatcherType.RING_BUFFER));
		
		System.out.println("STARTING:" + c);
		reset(false);
		Streams.from(taps).consume(str -> {
			str.consume(i -> lastValue.set(i));
		});
		rootStream = Streams.wrap(broadcaster);		
		ctx = rootStream
				.groupBy(s -> s % 10)
				.consume(
						str -> {
							str.capacity(20)
							  .dispatchOn(
									Environment.newDispatcher("loop", 1, 1, DispatcherType.MPSC))
										.observe(i -> {
											lastValue.set(i);
										})
										.consume(v -> process(v),
											t -> {
												final int k = c.decrementAndGet();
												System.err.println("["+ Thread.currentThread().getId()+ "] FAILED:"+ t + " / " + k);
												if(!RuntimeException.class.equals(t.getClass())) {
													t.printStackTrace(System.err);
//													ctx.cancel();
												}
												reset(true);
											},
											d -> {
												final int k = c.decrementAndGet();
												System.out.println("[" + Thread.currentThread().getId()	+ "] Complete:" + k);
											});
						});
		while(true) {
			broadcaster.onNext(this.next());
		}
	}
	
	private static final ThreadLocal<Boolean> threadNameInited = new ThreadLocal<Boolean>();
	
	public void process(final int v) {
		try { Thread.sleep(10);} catch (Exception x) {/* No Op */}
		final long t = Thread.currentThread().getId();
		if(threadNameInited.get()==null) {
			char[] chars = Integer.toString(v).toCharArray();
			Thread.currentThread().setName("ModThread-" + chars[chars.length-1]);
			threadNameInited.set(true);
		}
		if (v == nextFail) throw new RuntimeException();
		List<Integer> list = complete.get(t);
		if (list == null) {
			synchronized (complete) {
				list = complete.get(t);
				if (list == null) {
					list = new ArrayList<Integer>();
					complete.put(t,list);
				}
			}
		}
		list.add(v);
		Set<String> cthreads = concurrentThreads.get(t);
		if(cthreads==null) {
			synchronized(concurrentThreads) {
				cthreads = concurrentThreads.get(t);
				if(cthreads==null) {
					cthreads = new HashSet<String>();
					concurrentThreads.put(t, cthreads);
					log("Recorded thread: [%s]", Thread.currentThread());
				}
			}
		}
		cthreads.add(Thread.currentThread().getName());
	}

	public void reset(final boolean dump) {
		if (dump && ctx != null) {
			final Map<Object, Object> streamMap = StreamUtils.browse(rootStream).toMap();
			log("StreamMap:\n%s", ctx.debug().toString());
		}
		final int lastVal = lastValue.get();
		iterBase.set(lastVal + (dump ? -1 : 0));
		nextFail = lastVal + Math.abs(R.nextInt(1001));
		log("Base iterator reset. Last Value was [%s]. Next fail at %s", lastVal, nextFail);
		lastValue.set(-1);
		if (dump) {
			TreeMap<Long, List<Integer>> sortedComplete = new TreeMap<Long, List<Integer>>(complete);
			complete.clear();
			for (Map.Entry<Long, List<Integer>> entry : sortedComplete.entrySet()) {
				log("\tThread:" + entry.getKey() + ":  " + entry.getValue() + "\tCThreads:" + concurrentThreads.get(entry.getKey()));
			}
			
		}

	}

	public static void log(final Object fmt, final Object... args) {
		System.out.println(String.format("[" + Thread.currentThread() + "]:"
				+ fmt.toString(), args));
	}

	public static void main(String[] args) {
		Environment.initializeIfEmpty();

		// Environment.initializeIfEmpty().assignErrorJournal(new
		// Consumer<Throwable>(){
		// @Override
		// public void accept(final Throwable t) {
		// System.err.println("Untrapped exception");
		// t.printStackTrace(System.err);
		// }
		// });
		RQ r = new RQ();
		while (r.c.get() != 0) {
			Thread.yield();
		}
		System.out.println("DONE:" + r.c);
		for (Map.Entry<Long, List<Integer>> entry : r.complete.entrySet()) {
			System.out.println("\n\tThread:" + entry.getKey() + ":  "
					+ entry.getValue() + "\tCThreads:" + r.concurrentThreads.get(entry.getKey()));
		}

	}

	protected final AtomicInteger iterBase = new AtomicInteger(0);
	protected final Random R = new Random(System.currentTimeMillis());
	protected int nextFail = Math.abs(R.nextInt(101));

	@Override
	public boolean hasNext() {
		return iterBase.get() < Integer.MAX_VALUE;
	}

	@Override
	public Integer next() {		
//		try { Thread.currentThread().join(10);} catch (Exception x) {/* No Op */}
		return iterBase.incrementAndGet();
	}

	@Override
	public Iterator<Integer> iterator() {
		return this;
	}

}
