---
title: Task Based Threading
date: 2013-06-29T12:00:00
comments: false
sharing: false
categories:
  - java
  - threading
---

Task based thread execution is a great way to do threading in an application.
Taking the same idea that is used in web development can be applied directly to
any application that can utilize threads.

When working with a web application, often the application will need to send an
email to a customer without slowing down the user's request. Background jobs are
typically used for slow; long running tasks that can be processed later.

These background jobs are normally added to queue and multiple workers are
processing them simultaneously. Often I have been guilty of writing baddly
threaded Java applications (C is not exempt from this either). I would make a
few `Runnable` tasks that would have an infinite loop and just spawn threads to
process the tasks. This was my naive way of thinking.

```java
// SomeBadJob.java
public class SomeBadJob implements Runnable {
    public void run() {
        while(true) {
            // Some loop to crunch numbers
        }
    }
}
```

In reality, the maximum number of threads running concurrently is based on the
number of cores available on the CPU. So if I spawned five threads, one of them
will be context switching and that is not free.

## Solution

Stop writing individual tasks and break it down to a smaller tasks. Each
runnable task should be executed once, and then return. For example:

```java
// MovePlayerTask.java
public class MovePlayerTask implements Runnable {
    private Player player;

    public MovePlayerTask(Player player) {
        this.player = player;
    }

    public void run() {
        player.move(Direction.SOUTH, 1);
    }
}
```

Testing these runnable tasks becomes very easy and the overall complexity of the
runnable job has been reduced significantly.

How this task can be rans is by wrapping Java's `ThreadPoolExecutor` into a
class called `Scheduler` and is setup as a singleton. This is because there is
no need to have multiple schedulers around.

```java
// Scheduler.java
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * A very thin wrapper around ThreadPoolExecutor
 *
 * @author Matthew A. Johnston
 */
public class Scheduler {
    private static Scheduler instance;

    private ThreadPoolExecutor executor;
    private LinkedBlockingQueue<Runnable> queue;

    public Scheduler() {
        int processors = Runtime.getRuntime().availableProcessors();
        queue = new LinkedBlockingQueue<Runnable>();
        executor = new ThreadPoolExecutor(processors, 10, 10, TimeUnit.SECONDS, queue);
    }

    public void schedule(Runnable runnable) {
        executor.execute(runnable);
    }

    public static void scheduleTask(Runnable runnable) {
        getInstance().schedule(runnable);
    }

    public static Scheduler getInstance() {
        if (instance == null) {
            instance = new Scheduler();
        }
        return instance;
    }
}
```

To execute the `MovePlayerTask` all that is necessary is the following:

```java
player = Game.getPlayer();
Scheduler.scheduleTask(new MovePlayerTask(player));
```

The `MovePlayerTask` will be executed once and to execute it again, all that is
necessary is to re-enqueue the task. I have found that this approach will scale
very well as computer hardware progresses. As the number of cores available
increases, so will the number of workers.

## Limitations

It is possible to fill the `Scheduler` queue up with jobs faster than it can
process. Though I have not run into this issue yet, however the
`LinkedBlockingQueue` that the `ThreadPoolExecutor` uses will not allow an new
task to be scheduled until it is able to do so. If the application is time
critical, a time delta should be used in the task's `run()` method.

## Resources

  * [Task-based Multithreading - How to Program for 100 cores](http://www.gdcvault.com/play/1012321/-Sponsored-Task-based-Multithreading)
  * [“implements Runnable” vs. “extends Thread”](http://stackoverflow.com/questions/541487/implements-runnable-vs-extends-thread)
  * [Thread Pool Pattern](http://en.wikipedia.org/wiki/Thread_pool_pattern)
  * [Scheduler Pattern](http://en.wikipedia.org/wiki/Scheduler_pattern)
