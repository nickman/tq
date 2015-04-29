package tqueue.db.types;

public class A {

    Stream<Expansion> expansionStream = Streams
            .from(expansionProvider.getList())
            .dispatchOn(Environment.cachedDispatcher()) 
            .observeComplete(completed -> {
                System.out.println("All the expansion works were launched. / " + Thread.currentThread().getName());
            });


        expansionStream.observe(expansion -> {
            // register expansion
            Streams
                .just(expansion)
                /////\\\///.dispatchOn(Environment.cachedDispatcher()) if we enable this, there is a race condition happening (projectreactor bug?)
                .observeComplete(completed -> {
                    System.out.println("Expansion completed. / " + Thread.currentThread().getName());
                })
                .observe(exp -> {
                    try {
                        System.out.println("Launching work for expanding " + expansion + " / " + Thread.currentThread().getName());
                        Thread.sleep(100);
                        Stream<MyItem> expansionCollectionStream = Streams
                            .from(items)
                            .dispatchOn(Environment.cachedDispatcher());
                        expansionCollectionStream
                            .observe(myItem -> {
                                Streams.just(myItem)
                                       .dispatchOn(Environment.cachedDispatcher())
                                       .observeComplete(completed -> {
                                           System.out.println("=== Expansion completed. / " + Thread.currentThread().getName());
                                       })
                                       .observe(anItem -> {
                                            try {
                                                Thread.sleep(100);
                                            } catch (InterruptedException e) {
                                                e.printStackTrace();
                                            }
                                            System.out.println("\tb) Adding to the item " + myItem.getId() +
                                                               " the expanded item " +
                                                               expansion + " / " + Thread.currentThread().getName());

                                        })
                                       .consume(anItem -> {
                                           System.out.println("# Deregister expansionCollectionStream " + count.get() + " / " + Thread.currentThread().getName());
                                       });
                                })
                            .consume();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    System.out.println("(end of launching works for expanding)" + " / " + Thread.currentThread().getName());
                })
                .consume(exp -> {
                    System.out.println("(confirming end of launching works for expanding)" + " / " + Thread.currentThread().getName());
                });
        }).consume();


        Truth be told I had a little trouble following what was supposed to happen in your example code. Here's a shorter version I tried to put together that I *think* approaches what you're trying to do.

        Notice that I used .groupBy(s -> s) first, which gives me one Stream per unique element in the initial List<String> I started with:

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

        When I run this in the console I get output on 6 different threads, as I would expect given I started with a List of 2 elements and there are 3 separate thread hops happening.

        Just keep in mind: excessive context-switching can be very expensive. Have you benchmarked it to see how much of that is really required? I ask because our testing resulted in a surprising number of times that the less concurrency we had going on the better. The only exception to that was IO, where threads were being blocked. But in CPU-intensive tasks, the bare minimum of context-switching is generally preferable.

        The only way to really know is to benchmark with various levels of concurrency. We generally baseline with the single-threaded RingBufferDispatcher first, then maybe go to a parallel Stream by using .partition() (or .partition(NUM_OF_THREADS)). But take it in baby steps. I rarely was able to exceed the throughput of a 2 or 4 thread processor by using more. It can be deceptive because what I often found in microbenchmarks is that I *wasn't* maxing out the CPU with my tasks, but with context switching. In general, the fewer threads I had doing work, the higher the throughput. That held true no matter the make-up of the tasks (e.g. whether they were unrelated to one another or not).        
        
        
        If you replace "groupBy()" in my example with "partition()" you'll get 1 Stream per CPU on which you can set the dispatcher via .dispatchOn(cachedDispatcher()). I just tried it and see log output on all the threads, not just one. 

}
