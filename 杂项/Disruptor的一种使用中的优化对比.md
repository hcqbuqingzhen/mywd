# Disruptor的一种使用中的优化对比
最近接收到的一个项目中使用到了Disruptor,在优化的过程中发现了一点问题.
## 什么是Disruptor
Disruptor 由 LMAX 开发，用于改进 Java 线程间通信，主要适用于对延迟敏感度高到极端的应用程序，在保持高吞吐量的同时确保非常高的响应时间。通常，此类服务旨在将消费者和生产者之间的响应时间缩短至 1 毫秒或更短，在最极端的情况下会缩短至数百微秒。
基于Disruptor开发的系统单线程能支撑每秒600万订单，2010年在QCon演讲后，获得了业界关注。 2011年，企业应用软件专家Martin Fowler专门撰写长文介绍Disruptor。同年Disruptor还获得了 Oracle官方的Duke大奖。
Disruptor 被提议作为 Java 中传统队列（例如 ）的替代方案ArrayBlockingQueue，同时提供类似的有序和多播类型语义来支持多个生产者和消费者。
Disruptor 针对 Java 进程中的内部延迟问题。它不是持久存储，消息完全存储在内存中，主要用于改善两个或多个充当生产者或消费者的工作线程之间的延迟。

所以可以认为这个队列比jdk自带的队列性能更加好,且提供了生产者消费者模式

## 背景
原本这个项目的架构是sqlite+Disruptor 消费netty解码的数据,一直使用的是单线程架构.生产和消费都是单线程的.项目运行一段时间后会有消费丢失的问题,生产堵塞导致设备掉线. 这个原因很多,包括使用了单线程的sqlite,其性能是有不高的上限的.解决方案比较好的一点是改造成多线程消费.当然数据库也要改成mysql等.

Disruptor本身支持多线程消费,见这个比较详尽的博客,只需要注册多个EventHandle,每个EventHandle是并行消费的 类似于广播模式. 见下面这个详尽的链接
!([http://www.enmalvi.com/2023/03/22/disruptor/#Disruptor_shi_shen_me])
项目需要单设备的消费是有序的,可以在每个EventHandle设置不同的变量,触发消费的时候,根据hash值来判断是由哪一个设备是由哪一个EventHandle消费.

当然也可以只注册一个EventHandle,在这个单一的消费端,分发到不同的队列中再多线程消费.

在实现上因为我比较熟悉后面的这一种,因此线上使用自定义队列然后多线程消费

这两种方式的性能差距有多大呢.我做了一个实验来观察.

## 实验内容

直接贴代码吧

- 下面采用的是Disruptor多handle方式

```java
package disruptor.pack01;

import com.lmax.disruptor.*;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.dsl.ProducerType;

import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

public class DisruptorTest {
    static int messageCount = 5000;
    static int deviceCount = 200;
    static int handlerCount = 64;
    static int bufferSize = 1024 * 1024;
    static AtomicInteger counter = new AtomicInteger(0);
    static int total = messageCount;

    public static void main(String[] args) throws Exception {
        Disruptor<DeviceEvent> disruptor = new Disruptor<>(
                DeviceEvent::new,
                bufferSize,
                Executors.defaultThreadFactory(),
                ProducerType.SINGLE,
                new BusySpinWaitStrategy()
        );

        for (int i = 0; i < handlerCount; i++) {
            disruptor.handleEventsWith(new DeviceEventHandler(i, handlerCount));
        }

        disruptor.start();
        RingBuffer<DeviceEvent> ringBuffer = disruptor.getRingBuffer();
        long start = System.currentTimeMillis();
        for (int i = 0; i < messageCount; i++) {
            String key = "device-" + (i % deviceCount);
            long seq = ringBuffer.next();
            DeviceEvent event = ringBuffer.get(seq);
            event.deviceKey = key;
            ringBuffer.publish(seq);
        }
        while (counter.get() < total) {
            // busy spin 等待所有消息处理完
        }
        long cost = System.currentTimeMillis() - start;
        System.out.println("Disruptor 总耗时: " + cost + "ms, 吞吐: " +
                (messageCount * 1000L / cost) + " msg/s");

        //disruptor.shutdown();
    }

    static class DeviceEvent {
        String deviceKey;
    }

    static class DeviceEventHandler implements EventHandler<DeviceEvent> {
        private final int idx, total;
        public DeviceEventHandler(int idx, int total) {
            this.idx = idx;
            this.total = total;
        }

        @Override
        public void onEvent(DeviceEvent event, long sequence, boolean endOfBatch) {
            if (Math.abs(event.deviceKey.hashCode() % total) == idx) {
                fibonacci(30);
                counter.incrementAndGet();
            }

        }
    }

    private static long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }
}

```

- 下面采用了一个自定义的线程池map来有序消费

```java
package disruptor.pack02;

import com.lmax.disruptor.BusySpinWaitStrategy;
import com.lmax.disruptor.EventHandler;
import com.lmax.disruptor.RingBuffer;
import com.lmax.disruptor.dsl.Disruptor;
import com.lmax.disruptor.dsl.ProducerType;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.atomic.AtomicInteger;

public class ThreadPoolTest {
    static int messageCount = 5000;
    static int deviceCount = 200;

    static int bufferSize = 1024 * 1024;
    private static int workerCount = 128;

    static AtomicInteger counter = new AtomicInteger(0);
    static int total = messageCount;

    private static final Map<Integer, ThreadPoolExecutor> executorMap = new ConcurrentHashMap<>();
    public static void main(String[] args) throws Exception {


        //构建环境
        for (int i = 0; i < workerCount; i++) {
            executorMap.put(i, new ThreadPoolExecutor(1, 1,
                    Integer.MAX_VALUE, java.util.concurrent.TimeUnit.SECONDS,
                    new java.util.concurrent.ArrayBlockingQueue<>(100000),
                    new ThreadPoolExecutor.AbortPolicy()));
        }


        Disruptor<DeviceEvent> disruptor = new Disruptor<>(
                DeviceEvent::new,
                bufferSize,
                Executors.defaultThreadFactory(),
                ProducerType.SINGLE,
                new BusySpinWaitStrategy()
        );
        disruptor.handleEventsWith(new DeviceEventHandler());
        RingBuffer<DeviceEvent> ringBuffer = disruptor.getRingBuffer();

        long start = System.currentTimeMillis();
        for (int i = 0; i < messageCount; i++) {
            String key = "device-" + (i % deviceCount);
            long seq = ringBuffer.next();
            DeviceEvent event = ringBuffer.get(seq);
            event.deviceKey = key;
            ringBuffer.publish(seq);
        }
        disruptor.start();
        while (counter.get() < total) {
            // busy spin 等待所有消息处理完
        }
        long cost = System.currentTimeMillis() - start;
        System.out.println("线程池分拨 总耗时: " + cost + "ms, 吞吐: " +
                (messageCount * 1000L / cost) + " msg/s");

        //disruptor.shutdown();

    }

    static class DeviceEvent {
        String deviceKey;
    }

    static class DeviceEventHandler implements EventHandler<DeviceEvent> {
        @Override
        public void onEvent(DeviceEvent event, long sequence, boolean endOfBatch) {
            executorMap.get(Math.abs(event.deviceKey.hashCode() % workerCount)).execute(() -> {
                fibonacci(30);
                counter.incrementAndGet();
            });
            //fibonacci(30);

        }
    }

    private static long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

}
```

修改线程数量,各自运行,可以发现有以下输出

Disruptor的handle消费 5000条数据
Disruptor 总耗时: 7146ms, 吞吐: 699 msg/s。 单线程
Disruptor 总耗时: 2254ms, 吞吐: 2218 msg/s  4线程
Disruptor 总耗时: 1479ms, 吞吐: 3380 msg/s  8线程
Disruptor 总耗时: 1413ms, 吞吐: 3538 msg/s  10线程
Disruptor 总耗时: 1511ms, 吞吐: 3309 msg/s  12线程
Disruptor 总耗时: 1864ms, 吞吐: 2682 msg/s  16线程
Disruptor 总耗时: 3788ms, 吞吐: 1319 msg/s  32线程
Disruptor 总耗时: 4222ms, 吞吐: 1184 msg/s  64线程



队列拿出后线程池分拨 5000条数据
线程池分拨 总耗时: 7330ms, 吞吐: 682 msg/s  单线程
线程池分拨 总耗时: 2348ms, 吞吐: 2129 msg/s 4线程
线程池分拨 总耗时: 1744ms, 吞吐: 2866 msg/s 6线程
线程池分拨 总耗时: 1586ms, 吞吐: 3152 msg/s 8线程
线程池分拨 总耗时: 1406ms, 吞吐: 3556 msg/s 10线程
线程池分拨 总耗时: 1396ms, 吞吐: 3581 msg/s 16线程
线程池分拨 总耗时: 1363ms, 吞吐: 3668 msg/s  32线程
线程池分拨 总耗时: 1246ms, 吞吐: 4012 msg/s  64线程
线程池分拨 总耗时: 1205ms, 吞吐: 4149 msg/s  128线程


## 分析
1. 线程数少于 CPU 核心数时,
吞吐随线程数增加线性增长,CPU 核心未充分利用

2. 线程数 ≥ CPU 核心数
吞吐趋于饱和,多余线程不会带来明显提升（但由于线程池可阻塞等待任务，调度有优化）,线程池吞吐增长比 Disruptor 更缓慢,原因是每个任务都要经过 Runnable 封装 + BlockingQueue + 上下文切换
所以 CPU 核心数达到瓶颈前，线程池效率略低于 Disruptor

线程池分发在高并发小任务下会受到调度和队列开销限制，但多线程扩展性更好（特别是任务量大时）
---
- Disruptor 对 CPU-bound 高吞吐任务最优线程数 ≈ 核心数
- 线程池分发对 CPU-bound 任务也可以接近饱和，但效率略低于 Disruptor
- 当线程数大大超过 CPU 核心时，Disruptor 由于 busy-spin 会被 CPU 争抢严重影响吞吐，而线程池因阻塞机制下降不那么快


## 结论

我的电脑是10核心10线程
大概10线程就是上限了,可以给出一个结论,若一般的cpu密集型任务 这两者的差距并不明显. 但是如果计算型任务加上io型任务混合的,使用后者可以更好,因为这意味着可以有更多的数据库连接.