---
title: Reactive Streams-01
date: 2022-02-13 20:40:19
tags: Reactive
---
 # 002-Project Reactor
 >上一篇文章中，我们介绍了Reactive Streams规范，现在学习一个Reactive Streams规范的流行实现：Project Reactor的核心项目Reactor Core。

 ## 1. Project Reactor 简介

 Project Reactor是一个运行在JVM上的反应式编程基础库，以“背压”的形式管理数据处理，提供了可组合的异步序列APIFlux和Mono。同时，它也实现了Reactive Streams 规范。

 众所周知，I/O阻塞浪费了系统性能，只有纯异步处理才能发挥系统的全部性能，不作丝毫浪费；而JDK的异步API比较难用，成为异步编程的瓶颈，这就是Reactor等其它反应式框架诞生的原因。

Reactor大大降低了异步编码难度(尽管相比同步编码，复杂度仍然是上升的)，变得简单的根本原因，是编码思想的转变。

JDK的异步API使用的是传统的命令式编程，命令式编程是以控制流为核心，通过顺序、分支和循环三种控制结构来完成不同的行为。而Reactor使用反应式编程，应用程序从以逻辑为中心转换为了以数据为中心，这也是命令式到声明式的转换。

### 1.1 从命令式到反应式编程
Reactor反应库旨在解决JVM上“经典”异步方法的缺点，同时还拥有如下特点：

1. 可组合性和可读性，完美规避了Callback Hell
2. 以流的形式进行数据处理时，为流中每个节点提供了丰富的操作符
3. 在Subscribe之前，不会有任何事情发生
4. 支持背压，消费者可以向生产者发出信号表明排放率过高
5. 支持两种反应序列：hot和cold

1.2 子项目列表
Project Reactor试图提供反应式编程相关的各类基础库，它包含了如下子项目：

1. Reactor Core	3.2.11.RELEASE	一个实现了Reactive Streams规范的基础库
2. Reactor Test	3.2.11.RELEASE	测试套件
3. Reactor Extra / Reactor Addons	3.2.3.RELEASE	扩展库，包含reactor-adapter和reactor-extra，增强了Reactor Core的功能
4. Reactor Netty	0.8.10.RELEASE	基于Netty，提供了非阻塞的、支持背压的TCP/HTTP/UDP客户端和服务端
5. Reactor Adapter	3.2.3.RELEASE	支持桥接到其它反应式库，如RxJava
6. Reactor Kafka	1.1.1.RELEASE	桥接到Apache Kafka
7. Reactor Kotlin Extensions	没有发布正式版	为Kotlin语言添加各种扩展和适配器
8. Reactor RabbitMQ	1.2.0.RELEASE	桥接到RabbitMQ
9. BlockHound	没有发布正式版	用于检测来自非阻塞线程的阻塞调用
10. Reactor Core .NET	0.6.1	为.NET孵化反应流基础库
11. Reactor Core JS	0.5.0	为Javascript孵化反应流基础库

除了上述最后三个子项目，其它子项目都是构建于Reactor Core之上

## 2 Flux & Mono
Flux<T>是一个标准的Reactive Streams规范中的Publisher<T>，它代表一个包含了[0…N]个元素的异步序列流。在Reactive Streams规范中，针对流中每个元素，订阅者将会监听这三个事件：onNext、onComplete、onError。

Mono<T>是一个特殊的Flux<T>，它代表一个仅包含1个元素的异步序列流。因为只有一个元素，所以订阅者只需要监听onComplete、onError。

### 2.1 创建并订阅Flux或Mono
创建Flux或Mono的最简单方法，是使用那些工厂方法，如just、fromIterable、empty、range。当需要订阅它们时，可以调用如下几个重载的方法。
```java
subscribe();//仅订阅并触发流，不做其它处理

subscribe(Consumer<? super T> consumer);//处理流中的每个元素

subscribe(Consumer<? super T> consumer,
          Consumer<? super Throwable> errorConsumer);//处理流中的元素、处理相应的异常

subscribe(Consumer<? super T> consumer,
          Consumer<? super Throwable> errorConsumer,
          Runnable completeConsumer);//处理流中的元素、处理相应的异常；当流结束时，可以执行一些内容

subscribe(Consumer<? super T> consumer,
          Consumer<? super Throwable> errorConsumer,
          Runnable completeConsumer,
          Consumer<? super Subscription> subscriptionConsumer);//最后一个参数Subscription，代表处理一个元素的生命周期，也是Reactive Streams规范中定义的
```
### 2.2 编程的方式创建Flux
generate、create、push、handle方法支持以编程的方式创建Flux，使创建方式更加灵活。

- generate方法创建的流是同步的，流内元素是有序的，依次被订阅者消费。

- create方法以异步、多线程的方式创建流。

- push方法以异步、单线程的方式创建流。

- handle方法是一个示例方法，它类似于generate，将一个已经存在的流，转换成同步的流。

以下是generate方法的一个简单示例：

```java
Flux<String> flux = Flux.generate(
    () -> 0,
    (state, sink) -> {
      sink.next("3 x " + state + " = " + 3 * state);
      if (state == 5) sink.complete();
      return state + 1;
    });

/** 流中的元素依次是：
3 x 0 = 0
3 x 1 = 3
3 x 2 = 6
3 x 3 = 9
3 x 4 = 12
3 x 5 = 15
**/
```

## 3. 使用示例
使用静态工厂方法fromIterable创建一个Flux对象，而flatMap、filter等非静态方法即所谓操作符，多种操作符组合使用，可以对数据流的元素进行复杂处理。

```java
List<String> words = Arrays.asList("th", "qu");
Flux<String> manyLetters = Flux
        .fromIterable(words)
        .flatMap(word -> {
            System.out.println("Step1=" + word);
            return Flux.fromArray(word.split(""));})
        .filter(s -> {
            System.out.println("Step2=" + s);
            return true;
        }).filter(s -> {
            System.out.println("Step3=" + s);
            return true;
        });
manyLetters.subscribe(s -> System.out.println("Result=" + s + "\n"));

/** 输出结果：
Step1=th
Step2=t
Step3=t
Result=t

Step2=h
Step3=h
Result=h

Step1=qu
Step2=q
Step3=q
Result=q

Step2=u
Step3=u
Result=u
**/
```

如果仅看上面这种使用方式，看起来与Java 8的Stream差不多，并没有体现异步的特性，数据流在一开始就是确定的。假如不存在异步处理，使用Reactor就没有什么意义了。

与Java 8的Stream不同，Reactor支持以异步的方式创建Flux，看如下代码片段，MongoDB与Reactor结合使用：

```java
private MongoCollection<Document> collection;

public Flux<Restaurant> findAll() {
    return Flux.from(collection.find())
            .map(RestaurantTransfer::toDomainObject)
            .filter(Optional::isPresent)
            .map(Optional::get);
}

public static void main(String[] args) {
    ReactiveRestaurantRepository repository = new ReactiveRestaurantRepository();
    Flux<Restaurant> flux = repository.findAll();
    flux.subscribe(System.out::println);
}
```

public static <T> Flux<T> from(Publisher<? extends T> source)方法接收一个org.reactivestreams.Publisher参数，该对象是由MongoDB的Reactive客户端API创建的，MongoDB通过该对象，将DB中的数据，链接到Reactor的流中。

当调用subscribe方法后，一个发布-订阅的机制形成，只有当对象被从DB中取出并放入内存后，JVM才会占用线程资源，将消息发送给订阅者；从阻塞等待转变为了被动接收，因此节省了资源。

>由此可见，只有流中的数据全部是反应式的，Reactor才能发挥最大作用，一旦有节点被阻塞，就达不到节省资源的目的了。

>正是由于MongoDB和Reactor Core都实现了Reactive Streams规范，它们才能相互沟通交互，Reactive Streams规范在反应式编程的推广过程中，起着至关重要的作用。
当反应式编程的生态越来越完整，将会有更多的人考虑使用这种编程方式。

## 4. 与Spring的关系

Reactor是Spring整个生态系统的基础，特别是Spring Framework 5和 Spring Data “kay”。

这两个项目的Reactive版本是非常有意义的，我们可以基于此开发出完全Reactive的Web应用：支持对请求的全链路异步处理，一直到数据库，最后异步地返回结果。

Spring项目因此可以更有效地利用资源，避免为每个请求单独分配一个线程，产生I/O阻塞


## 5.学习目标

作为一名普通的程序员(专注业务开发)，我们接触最多的可能是WebFlux框架，以及Flux、Mono这些基础对象，在理解Project Reactor基本思想的基础上，再使用上层框架，将会更加得心应手。

