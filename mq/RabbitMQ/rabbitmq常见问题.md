# rabbitmq常见问题

## 1. 不可路由消息
这一部分主要是发送时交换机写错或者(网络堵塞发送不到交换机),交换机写对了,但路由不到对应的队列.
### 1.1 发送不到交换机
我们新建一个工程来实际操作一下.
- application.yml
```yml
server:
  port: 5001
spring:
  rabbitmq:
    host: 127.0.0.1
    port: 5672
    username: hcq
    password: 121056
    virtual-host: /hcq
    #这个配置是保证提供者确保消息推送到交换机中，不管成不成功，都会回调
    publisher-confirm-type: correlated
    #保证交换机能把消息推送到队列中
    publisher-returns: true
    #这个配置是保证消费者会消费消息，手动确认
    listener:
      simple:
        acknowledge-mode: manual
    template:
      mandatory: true

```
- RabbitConfig

```java
/*配置类*/
@Configuration
@Slf4j
public class RabbitConfig {
    /**
     * MQ地址
     */
    @Value("${spring.rabbitmq.host}")
    private String host;
    /**
     * MQ端口
     */
    @Value("${spring.rabbitmq.port}")
    private int port;

    /**
     * 用户名
     */
    @Value("${spring.rabbitmq.username}")
    private String username;

    /**
     * 密码
     */
    @Value("${spring.rabbitmq.password}")
    private String password;
    /**
     * 虚拟主机
     */
    @Value("${spring.rabbitmq.virtual-host}")
    private String virtualHost;

    // 定义一个或多个交换机
    // 用于开发之前测试
    public static final String EXCHANGE_A = "wm.test.topic";

    // 定义队列
    public static final String QUEUE_A = "queue-wm.test";

    // 定义routing-key
    public static final String ROUTING_KEY_A = "routing.wm.test";


    /**
     * 针对消费者配置
     * 1. 设置交换机类型
     * 2. 将队列绑定到交换机
     FanoutExchange: 将消息分发到所有的绑定队列，无routingkey的概念
     HeadersExchange ：通过添加属性key-value匹配
     DirectExchange:按照routingkey分发到指定队列
     TopicExchange:多关键字匹配
     **/
    /*************test-start******************/
    //topic交换机
    @Bean("testExchange")
    public TopicExchange testExchange(){
        return new TopicExchange(EXCHANGE_A);
    }
    //test队列
    @Bean("testQueue")
    public Queue testQueue() {
        return new Queue(QUEUE_A, true); //队列持久
    }
    //绑定
    @Bean
    public Binding binding(@Qualifier("testExchange") TopicExchange topicExchange,@Qualifier("testQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(topicExchange).with(RabbitConfig.ROUTING_KEY_A);
    }
    /*************test-end******************/
    @Bean
    public MessageConverter messageConverter(){
        return new Jackson2JsonMessageConverter();
    }

}
```

- RabbitSend

```java
@Slf4j
@Component
public class RabbitSend {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    /**
     * Confirm模式
     * 没找到交换机
     */
    public void testConfirm(String s){
        CorrelationData correlationData=new CorrelationData();
        correlationData.setId("123");
        //重写没发送到交换机回调的方法,设置进去.
        rabbitTemplate.setConfirmCallback((CorrelationData data,boolean ack,String cause)->{
            if(ack){
                System.out.println("success");
                //数据库执行状态更改
            }else {
                System.out.println("cause:"+cause);
            }
        });

        if(s==null){
            return;
        }
        if(s.contains("1")){
            rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,RabbitConfig.ROUTING_KEY_A,s,correlationData);
        }else {
            rabbitTemplate.convertAndSend("sasasa",RabbitConfig.ROUTING_KEY_A,s,correlationData);
        }
    }

}

```

- TestRabbitController

```java
Slf4j
@RestController
public class TestRabbitController {

    @Autowired
    private RabbitSend msgProducer;


    @GetMapping("/testConfirm/{msg}")
    public void sendMessage(@PathVariable("msg") String msg) throws JsonProcessingException {
        System.out.println("xxxxx");
        msgProducer.testConfirm(msg);
    }

    @GetMapping("/testReturn/{msg}")
    public void sendMessage2(@PathVariable("msg") String msg) throws JsonProcessingException {
        System.out.println("xxxxx");
        msgProducer.testConfirm(msg);
    }
}
```

[![XBB0tf.png](https://s1.ax1x.com/2022/06/07/XBB0tf.png)](https://imgtu.com/i/XBB0tf)

启动服务,当调用不含有1的参数时,会调用ConfirmCallback方法,我们可以在这里记录日志,不过写错交换机这种错误一般很少出现吧,如果网络堵塞还比较有用.

###  1.2 路由不到队列
yml配置文件不变

- RabbitSend

```java
public void testReturn(String s){
        /**
         * 回退模式
         * 没找到queue
         *  1.丢弃
         *  2.返回给发送方
         */
        rabbitTemplate.setMandatory(true);

        rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            @Override
            public void returnedMessage(Message message, int i, String s, String s1, String s2) {
                System.out.println("return 执行");
            }
        });
        if(s.contains("1")){
            rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,RabbitConfig.ROUTING_KEY_A,s);
        }else {
            rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,"sasasa",s);
        }
    }
```

- TestRabbitController

```java
 @GetMapping("/testReturn/{msg}")
    public void sendMessage2(@PathVariable("msg") String msg) throws JsonProcessingException {
        System.out.println("xxxxx");
        msgProducer.testReturn(msg);
    }
```
[![XBrSI0.png](https://s1.ax1x.com/2022/06/07/XBrSI0.png)](https://imgtu.com/i/XBrSI0)

写错路由后,会调用失败的回调函数.

实际上这两种情况比较少见吧,开发中谁会吧路由和队列写错呢?

### 备份交换机
>ReturnCallBack获取到的消息没有机会进入到队列,因此无法使用死信队列来保存消息.我们可以创建备份交换机.
当交换机接收到一条不可路由消息时，将会把这条消息转发到备份交换机中，由备份交换机来进行转发和处理，通常备份交换机的类型为 fanout，这样就能把所有消息都投递到与其绑定的队列中（使用其他类型交换机需要指定路由key，不指定时）然后我们在备份交换机下绑定一个队列，这样所有那些原交换机无法被路由的消息，就会都进入这个队列了。还可以建立一个报警队列，用独立的消费者来进行监测和报警.

一个消息找到了交换机却没有找到对应的路由,因此会被发送到备用交换机.

yml不变

- RabbitConfig

```java
/*配置类*/
@Configuration
@Slf4j
public class RabbitConfig {
    /**
     * MQ地址
     */
    @Value("${spring.rabbitmq.host}")
    private String host;
    /**
     * MQ端口
     */
    @Value("${spring.rabbitmq.port}")
    private int port;

    /**
     * 用户名
     */
    @Value("${spring.rabbitmq.username}")
    private String username;

    /**
     * 密码
     */
    @Value("${spring.rabbitmq.password}")
    private String password;
    /**
     * 虚拟主机
     */
    @Value("${spring.rabbitmq.virtual-host}")
    private String virtualHost;

    // 定义一个或多个交换机
    // 用于开发之前测试
    public static final String EXCHANGE_A = "wm.test.topic";
    public static final String BACKUP_EXCHANGE_NAME = "backup.exchange";

    // 定义队列
    public static final String QUEUE_A = "queue-wm.test";
    public static final String BACKUP_QUEUE_NAME = "backup.queue"; //备份队列
    public static final String WARNING_QUEUE_NAME = "warning.queue";//警告队列
    // 定义routing-key
    public static final String ROUTING_KEY_A = "routing.wm.test";


    /**
     * 针对消费者配置
     * 1. 设置交换机类型
     * 2. 将队列绑定到交换机
     FanoutExchange: 将消息分发到所有的绑定队列，无routingkey的概念
     HeadersExchange ：通过添加属性key-value匹配
     DirectExchange:按照routingkey分发到指定队列
     TopicExchange:多关键字匹配
     **/
    /*************test-start******************/
    //topic交换机
    @Bean("testExchange")
    public TopicExchange testExchange(){
        //alternate-exchange 声明备用交换机
        return ExchangeBuilder.topicExchange(EXCHANGE_A).durable(false).
                withArgument("alternate-exchange",BACKUP_EXCHANGE_NAME).build();
    }
    //备份交换机
    @Bean("testBackExchange")
    public FanoutExchange testBackExchange(){
        return new FanoutExchange(BACKUP_EXCHANGE_NAME,false,false,null);
    }
    //test队列
    @Bean("testQueue")
    public Queue testQueue() {
        return new Queue(QUEUE_A, true); //队列持久
    }
    @Bean
    public Queue testBackupQueue(){
        return QueueBuilder.durable(BACKUP_QUEUE_NAME).build();
    }
    @Bean
    public Queue testWarnQueue(){
        return QueueBuilder.durable(WARNING_QUEUE_NAME).build();
    }
    //绑定
    @Bean
    public Binding binding(@Qualifier("testExchange") TopicExchange topicExchange,@Qualifier("testQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(topicExchange).with(RabbitConfig.ROUTING_KEY_A);
    }
    //备份队列
    public Binding backBinding(@Qualifier("testBackExchange") FanoutExchange fanoutExchange,@Qualifier("testBackupQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(fanoutExchange);
    }
    //警告队列
    public Binding warnBind(@Qualifier("testBackExchange") FanoutExchange fanoutExchange,@Qualifier("testWarnQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(fanoutExchange);
    }
    /*************test-end******************/
    @Bean
    public MessageConverter messageConverter(){
        return new Jackson2JsonMessageConverter();
    }

}

```

配置类增加了备份交换机和备份队列,警告队列.同时将备份交换机在testExchange声明,建立联系.

- RabbitSend

```java
public void testBack(String s){
       rabbitTemplate.setMandatory(true);
        rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            @Override
            public void returnedMessage(Message message, int i, String s, String s1, String s2) {
                System.out.println("return 执行");
            }
        });
        if(s.contains("1")){
            rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,RabbitConfig.ROUTING_KEY_A,s);
        }else {
            rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,"sasasa",s);
        }
    }
```
当127.0.0.1:5001/testReturn/jjsas
[![XDIUe0.png](https://s1.ax1x.com/2022/06/07/XDIUe0.png)](https://imgtu.com/i/XDIUe0)
mq控制台
[![XDI5fe.png](https://s1.ax1x.com/2022/06/07/XDI5fe.png)](https://imgtu.com/i/XDI5fe)
消息被转发到备份队列中

以上三种情况是比较简单的,但是在开发中也比较少见,我们一般不会犯这种错误吧.

## 2. 消费端手动ack

### 2.1 消费端
新建一个消费端项目,配置如下

- yml
  
```yml
server:
  #服务端口
  port: 5002
spring:
  rabbitmq:
    host: 127.0.0.1
    port: 5672
    username: hcq
    password: 121056
    virtual-host: /hcq
    #这个配置是保证消费者会消费消息，手动确认
    listener:
      simple:
        acknowledge-mode: manual
    template:
      mandatory: true
```

- TestListener

```java
package com.wa.consumer01.listener;

import com.rabbitmq.client.Channel;
import com.wa.consumer01.config.RabbitConfig;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitHandler;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.listener.api.ChannelAwareMessageListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;
@Slf4j
@Component
@RabbitListener(queues = RabbitConfig.QUEUE_A)
public class TestListener implements ChannelAwareMessageListener { //实现这个接口
    
    @Override
    @RabbitListener(queues = RabbitConfig.QUEUE_A)
    public void onMessage(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();
        System.out.println(new String(message.getBody()));
        //
        Thread.sleep(1000);
        try {
            System.out.println("处理业务逻辑");
            int i=3/0;
            //手动签收
            channel.basicAck(deliveryTag,true);
        }catch ( Exception e){
            channel.basicNack(deliveryTag,true,true);
        }

    }
}

```
### 2.2 生产端修改

>多次调用中,生产端出现了错误如下.
RabbitTemplate只允许设置一个callback方法，你可以将RabbitTemplate的bean设为单例然后设置回调，但是这样有个缺点是使  用RabbitTemplate的地方都会执行这个回调，如果直接在别的地方设置，会报如下错误

Only one ReturnCallback is supported by each RabbitTemplate] with root cause

解决办法有两种,一是配置RabbitTemplate为多例的每次使用重新创建.二是只设置一次ReturnCallback.于是修改config如下.


```java
/*配置类*/
@Configuration
@Slf4j
public class RabbitConfig {
    /**
     * MQ地址
     */
    @Value("${spring.rabbitmq.host}")
    private String host;
    /**
     * MQ端口
     */
    @Value("${spring.rabbitmq.port}")
    private int port;

    /**
     * 用户名
     */
    @Value("${spring.rabbitmq.username}")
    private String username;

    /**
     * 密码
     */
    @Value("${spring.rabbitmq.password}")
    private String password;
    /**
     * 虚拟主机
     */
    @Value("${spring.rabbitmq.virtual-host}")
    private String virtualHost;

    // 定义一个或多个交换机
    // 用于开发之前测试
    public static final String EXCHANGE_A = "wm.test.topic";
    public static final String BACKUP_EXCHANGE_NAME = "backup.exchange";

    // 定义队列
    public static final String QUEUE_A = "queue-wm.test";
    public static final String BACKUP_QUEUE_NAME = "backup.queue"; //备份队列
    public static final String WARNING_QUEUE_NAME = "warning.queue";//警告队列
    // 定义routing-key
    public static final String ROUTING_KEY_A = "routing.wm.test";


    /**
     * 针对消费者配置
     * 1. 设置交换机类型
     * 2. 将队列绑定到交换机
     FanoutExchange: 将消息分发到所有的绑定队列，无routingkey的概念
     HeadersExchange ：通过添加属性key-value匹配
     DirectExchange:按照routingkey分发到指定队列
     TopicExchange:多关键字匹配
     **/
    /*************test-start******************/
    //备份交换机
    @Bean("testBackExchange")
    public FanoutExchange testBackExchange(){
        return ExchangeBuilder.fanoutExchange(BACKUP_EXCHANGE_NAME).build();
    }
    //topic交换机
    @Bean("testExchange")
    public TopicExchange testExchange(){
        //alternate-exchange 声明备用交换机
        return ExchangeBuilder.topicExchange(EXCHANGE_A).
                withArgument("alternate-exchange",BACKUP_EXCHANGE_NAME).build();
    }
    //test队列
    @Bean("testQueue")
    public Queue testQueue() {
        return new Queue(QUEUE_A, true); //队列持久
    }
    @Bean("testBackupQueue")
    public Queue testBackupQueue(){
        return QueueBuilder.durable(BACKUP_QUEUE_NAME).build();
    }
    @Bean("testWarnQueue")
    public Queue testWarnQueue(){
        return QueueBuilder.durable(WARNING_QUEUE_NAME).build();
    }
    //绑定
    @Bean
    public Binding binding(@Qualifier("testExchange") TopicExchange topicExchange,@Qualifier("testQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(topicExchange).with(RabbitConfig.ROUTING_KEY_A);
    }
    //备份队列
    @Bean
    public Binding backBinding(@Qualifier("testBackExchange") FanoutExchange fanoutExchange,@Qualifier("testBackupQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(fanoutExchange);
    }
    //警告队列
    @Bean
    public Binding warnBind(@Qualifier("testBackExchange") FanoutExchange fanoutExchange,@Qualifier("testWarnQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(fanoutExchange);
    }
    /*************test-end******************/
    @Bean
    public MessageConverter messageConverter(){
        return new Jackson2JsonMessageConverter();
    }


    // 创建连接工厂,获取MQ的连接
    @Bean
    public ConnectionFactory connectionFactory() {
        CachingConnectionFactory connectionFactory = new CachingConnectionFactory(host,port);
        connectionFactory.setUsername(username);
        connectionFactory.setPassword(password);
        connectionFactory.setVirtualHost(virtualHost);
        connectionFactory.setPublisherConfirmType(CachingConnectionFactory.ConfirmType.CORRELATED);
        connectionFactory.setPublisherReturns(true);
        return connectionFactory;
    }

    // 创建rabbitTemplate 主要是修改这个地方
    @Bean(name = "rabbitTemplate")
    public RabbitTemplate rabbitTemplate(@Qualifier("connectionFactory") ConnectionFactory connectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        //默认使用simpleMessageConverter  在此处更改为json序列化方案
        rabbitTemplate.setMessageConverter(messageConverter());
        rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            @Override
            public void returnedMessage(Message message, int i, String s, String s1, String s2) {
                System.out.println("return 执行");
            }
        });

        rabbitTemplate.setConfirmCallback((CorrelationData data, boolean ack, String cause)->{
            if(ack){
                System.out.println("success");
                //数据库执行状态更改
            }else {
                System.out.println("cause:"+cause);
            }
        });
        return rabbitTemplate;
    }

}
```
当消息投递后,客户端出异常,会一直要求重复消费.
[![XDH17q.png](https://s1.ax1x.com/2022/06/07/XDH17q.png)](https://imgtu.com/i/XDH17q)


### 2.3 消费端限流
其实就是配置了一下限流
```java
//测试限流
    @RabbitListener(queues = RabbitConfig.QUEUE_A)
    public void testQos(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();
        System.out.println(new String(message.getBody()));
        /*1.单条
          2.每次多少
          3.channel还是consumer
        * */
        channel.basicQos(0,1,false);
        //业务逻辑
        //签收
        channel.basicAck(message.getMessageProperties().getDeliveryTag(),true);


    }
```
也可以在yml文件中配置

## 3. ttl 死信队列 延迟队列

### 什么是ttl
发送消息的时候可以制定消息多久没被消费就丢弃,或者增加队列的时候增加队列的ttl,当消息进入队列多久没被消费就丢弃.

如下图所示
[![XDL4b9.png](https://s1.ax1x.com/2022/06/07/XDL4b9.png)](https://imgtu.com/i/XDL4b9)

我们可以在控制台新建队列设置ttl,如图新建对列如下,设置ttl为10000毫秒,即10秒
[![XDOsqH.png](https://s1.ax1x.com/2022/06/07/XDOsqH.png)](https://imgtu.com/i/XDOsqH)

当发送消息到此队列,10秒后消息自动被丢弃了.
[![XDOtaR.png](https://s1.ax1x.com/2022/06/07/XDOtaR.png)](https://imgtu.com/i/XDOtaR)

java中

- RabbitConfig 增加如下

```java
    public static final String QUEUE_B = "queue-wm.ttl";
    public static final String ROUTING_KEY_B = "routing.wm.ttl";
    @Bean("testTtlQueue")
    public Queue testTtlQueue(){
        return QueueBuilder.durable(QUEUE_B).ttl(10000).build();
    }
//ttl队列
    @Bean
    public Binding warnBind(@Qualifier("testExchange") TopicExchange topicExchange,@Qualifier("testTtlQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(topicExchange).with(ROUTING_KEY_B);
    }

```

发送消息到队列
```java
/**
     * ttl队列
     * @param s
     */
    public void testTtl(String s){
        rabbitTemplate.setMandatory(true);
        rabbitTemplate.convertAndSend(RabbitConfig.EXCHANGE_A,
                RabbitConfig.ROUTING_KEY_B,s);
        
    }
```

测试 十秒后消息丢弃

[![XDXAW6.png](https://s1.ax1x.com/2022/06/07/XDXAW6.png)](https://imgtu.com/i/XDXAW6)

如果设置了消息的过期时间,也设置了队列的过期时间,以时间短的为准.

### 死信队列
- 死信队列:
  又叫死信交换机.当一个队列中的消息成为死信后,队列会把这个消息发送到配置好的死信交换机和通过死信路由发送到死信队列.

- 什么是死信呢

  1. 消息达到队列最大限制,后续加入的都是死信.
  2. 设置了过期后,消息过期没有被消费,就是死信.
  3. 消费者配置了不消费,返回的也是死信.

[![XDX4t1.png](https://s1.ax1x.com/2022/06/08/XDX4t1.png)](https://imgtu.com/i/XDX4t1)

创建死信交换机和死信队列

- RabbitConfig

增加如下选项

```java
    public static final String EXCHANGE_C = "wm.test.black";
    public static final String QUEUE_C = "queue-wm.dead";

    public static final String ROUTING_KEY_C = "routing.wm.dead";

    //阻塞交换机
    @Bean("testDeadExchange")
    public FanoutExchange testBlackExchange(){
        //alternate-exchange 声明备用交换机
        return ExchangeBuilder.fanoutExchange(EXCHANGE_C).build();
    }

    //死信交换机
    @Bean("testDeadExchange")
    public FanoutExchange testDeadExchange(){
        //alternate-exchange 声明备用交换机
        return ExchangeBuilder.fanoutExchange(EXCHANGE_C).build();
    }

    //死信交换机和死信队列绑定
    @Bean
    public Binding deadBind(@Qualifier("testDeadExchange") DirectExchange directExchange,@Qualifier("testDeadQueue") Queue queue) {
        return BindingBuilder.bind(queue).to(directExchange).with(ROUTING_KEY_C);
    }
```

- 同时对原有的ttl队列配置

```java
    //正常ttl队列配置
    @Bean("testTtlQueue")
    public Queue testTtlQueue(){
        return QueueBuilder.durable(QUEUE_B).deadLetterExchange(EXCHANGE_C).
                deadLetterRoutingKey(ROUTING_KEY_C).ttl(10000).build();
    }
```

测试 首先从控制台删掉之前ttl队列,因为会和之前设置的冲突.

不断添加请求

[![XDvmad.png](https://s1.ax1x.com/2022/06/08/XDvmad.png)](https://imgtu.com/i/XDvmad)

因为没有为ttl配置消费者,消费过期后.消息会全部转发到死信队列

[![XDvnIA.png](https://s1.ax1x.com/2022/06/08/XDvnIA.png)](https://imgtu.com/i/XDvnIA)

当超过设置的最大长度10,或者设置了消费端,却返回拒绝消费.都会加入到死信队列.

### 延时队列

在ttl之上和死信队列之上可以设置延时队列. 一些需求比如十分钟后订单未支付取消,就要使用这种队列,

实际上之前的操作已经实现了延时队列,当把消息发送到ttl队列时,因为ttl队列没有消费者,因此10秒中后转发到死信队列,如果我们对死信队列配置消费者,那么就实现了延迟10秒设置订单未支付取消的情况.

```java
//测试死信
    @RabbitListener(queues = RabbitConfig.QUEUE_C)
    public void testDead(Message message, Channel channel) throws Exception {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();
        System.out.println(new String(message.getBody()));
        //业务逻辑
        //签收
        channel.basicAck(message.getMessageProperties().getDeliveryTag(),true);

    }
```

测试 消息被成功消费

[![XDv0zV.png](https://s1.ax1x.com/2022/06/08/XDv0zV.png)](https://imgtu.com/i/XDv0zV)

## 4. 消息可靠性和幂等性

### 4.1 消息可靠性

办法都是人想出来的,把握住几个重点去思考.
1. 保障消息发送成功
2. 保证mq成功捣消息
3. 确认mq的应答
4. 消息补偿

这里有两种比较成熟的方案.介绍一下.

#### 4.1.1 消息发送两次,二次确认和回调检查.
首先来看这张图,也可以根据这张图自己修改.
[![XDvHdH.png](https://s1.ax1x.com/2022/06/08/XDvHdH.png)](https://imgtu.com/i/XDvHdH)

其实就是消费者消费完后,将确认消息发送到回调检查服务入库
生产者发送延迟二次消息,直接进入回调服务.检查如果没有消息从新发送.
定时检查任务兜底.检测失败的消息.
1. 生产端只有一个,但生产端要对接mq,回调检查,定时检查服务.
2. 这个架构中共有三个队列,q1 生产者发送给消费者,q2 消费者发给回调,q3生产者二次调用发送回调服务.
3. 消费者又作为生产者
4. mdb是用来确认使用的,这个确认一是消息和延迟消息确认,二是定时人物和主数据库确认.


#### 4.1.2 消息落库，对消息状态进行打标

可以参考下图
[![XDvXWt.png](https://s1.ax1x.com/2022/06/08/XDvXWt.png)](https://imgtu.com/i/XDvXWt)

生产者会入两次库,一是biz业务,二是msg信息.发送消息时保证应答,应答失败会重复发送,发送三次以上就不再发送了,记录发送原因.
消费者及时相应应答,应答完毕后入另一个msg库.
定时任务兜底,检查发送失败的和消费失败的,进行重新发送.

1. 生产者和消费者都维护msgdb
2. 都要及时手动相应ack,失败一定次数后不再(生产)消费,而是记录状态
3. 不一致的地方使用手动发现,或者定时任务入库.

### 4.2 消息幂等性-不重复消费

幂等性问题

1. 当生产端发送消息到broke了,broke也给了响应.但是confirm时出现了了闪断,导致发送了两条一样的消息.
2. 消费端故障或者异常.

#### 4.2.1 解决方案之唯一id + 指纹码机制

用唯一id来保证消费的唯一性,如果消费数据库中已经有了本id就不消费了.

但在分库分表的情况下还要做id的hash分库

以下是采用这种方式的架构图
[![XrxGxP.png](https://s1.ax1x.com/2022/06/08/XrxGxP.png)](https://imgtu.com/i/XrxGxP)

#### 4.2.2 解决方案之乐观锁

其实就是加一个字段version,如果消费了字段更改.

当第二次消费的时候字段已经更改,无法update.

如下图所示

[![XrxbqO.png](https://s1.ax1x.com/2022/06/08/XrxbqO.png)](https://imgtu.com/i/XrxbqO)

#### 4.2.3 解决方案之redis原子性

还是利用redis的setnx指令,利用唯一id先将相关数据存储到redis,如果set失败说明已经消费过了,就不需要再做其他操作了.
同时定时同步redis中的数据到数据库中.

## 5. 其他知识点
### 5.1 惰性队列

RabbitMQ 从 3.6.0 版本开始引入了惰性队列的概念。正常消息是保存在内存中，惰性队列是将消息先保存在磁盘再加载在内存中进行消费，因此消费速度比队列的默认模式慢；

适用于以下场景

1. 当消费者由于各种各样的原因(比如消费者下线、宕机亦或者是由于维护而关闭等)而致使长时间内不能消费消息造成堆积
2. 2、消息产生速度远大于消费端，导致消息大量积压

设置方式

```java
#设置惰性队列方式一: 
	Map<String, Object> args = new HashMap<String, Object>();
	args.put("x-queue-mode", "lazy");
	channel.queueDeclare("myqueue", false, false, false, args);


#设置惰性队列方式二(命令行版本):
	rabbitmqctl set_policy Lazy "队列名" '{"queue-mode":"lazy"}' --apply-to queues
```

### 5.2 消息优先级

juc包下的阻塞队列有个优先级队列,mq也可以设置消息的优先级.

正常情况下，消费者将会按照消息进入队列顺序对消息进行消费，如果需要使排在后面的某些特定消息先进行消费，需要对队列和消息设置优先级，没有设置优先级的消息依旧按照进入队列的顺序消费，消费者需要在消息进入队列排序完成后消费才能体现优先级

优先级范围为 0~255，值越高优先级越高，且消息优先级不能超过队列优先级

新建队列在此处配置

[![XseWPP.png](https://s1.ax1x.com/2022/06/08/XseWPP.png)](https://imgtu.com/i/XseWPP)

- 消息发送
  
```java
package com.dmbjz.one;

import com.dmbjz.utils.RabbitUtils;
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.BuiltinExchangeType;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/* 生产者代码 */
public class PriorityProvider {

    private static final String EXCHANGE_NAME = "FanoutExchange";          //交换机名称

    public static void main(String[] args) throws Exception {

        Connection connection = RabbitUtils.getConnection();
        Channel channel = connection.createChannel();

        channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.FANOUT);            //声明交换机


        /* 对队列设置优先级为10,值应该为 0~255 之间 */
        Map<String,Object> map = new HashMap<>(1);
        map.put("x-max-priority",10);
        channel.queueDeclare("KeFuQueue",false,false,false,map);
        channel.queueBind("KeFuQueue",EXCHANGE_NAME,"",null);

        /* 消息发送 */
        for (int i = 0; i < 10; i++) {

            String message = "第"+i+"条消息";
            if( i%5==0 ){
               //主要是在这一步设置优先级
                AMQP.BasicProperties properties = new AMQP.BasicProperties()
                        .builder().priority(5).build();			//设置消息优先级为5
                channel.basicPublish(EXCHANGE_NAME,"",properties,message.getBytes(StandardCharsets.UTF_8));

            }else{
                channel.basicPublish(EXCHANGE_NAME,"",null,message.getBytes(StandardCharsets.UTF_8));
            }

        }

        System.out.println("消息全部发送");

    }
}
```
>注意: 只有消息在队列中排序完成之后再被消费者消费才能体现优先级，如果消费者消费时间小于排序时间不会生效


### 5.3 几个组件

#### 1. AbstractMessageListenerContainer 消费监听容器
是 spring 在 RabbitMQ 原生api基础上封装实现的一个消费工具类。
该类非常强大，可以实现：监听单个或多个队列、自动启动、自动声明，它还支持动态配置，如动态添加监听队列、动态调整并发数等等；基本上对RabbitMQ消费场景这个类都能满足。  
在2.0之前只有一个实现 SimpleMessageListenerContainer
可进行动态设置，在程序运行过程中可以动态修改消费者数量、接收消息的模式等

可以通过配置类来配置.

```java
@Bean
public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

    SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
    container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
    container.setConcurrentConsumers(1);                    //消费者数量
    container.setMaxConcurrentConsumers(10);                //最大消费者
    container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
    container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
    container.setConsumerTagStrategy(new ConsumerTagStrategy() {
       @Override
       public String createConsumerTag(String queue) {
           return queue + "_" + UUID.randomUUID().toString();
       }
    }); //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag


    /* 消息监听器方法一  实际用消息适配器 */
    container.setMessageListener(new ChannelAwareMessageListener() {
        @Override
        public void onMessage(Message message, Channel channel) throws Exception {
           System.out.println("消费者的消息"+new String(message.getBody()));
        }
    }); 

}
```

SimpleMessageListenerContainer可以监听多个队列，
container.setQueueNames的api接收的是一个字符串数组对象。
setQueues 也可以设置监听多个队列.

1. 开发中通过管理控制台,动态添加或者删除客户端监听容器.
   比如说一台机器负载量过大,我们可以先暂时关掉不重要的队列监听,分配给其他机器.

```java
@ComponentScan
public class Application {
   public static void main(String[] args) throws Exception{
       AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(Application.class);
       SimpleMessageListenerContainer container = context.getBean(SimpleMessageListenerContainer.class);
       TimeUnit.SECONDS.sleep(20);
       container.addQueueNames("zhihao.error");
       TimeUnit.SECONDS.sleep(20);
       container.addQueueNames("zhihao.debug");
       TimeUnit.SECONDS.sleep(20);

       context.close();
   }
}
```

2. 后置处理器

```java
 @Bean
    public SimpleMessageListenerContainer messageListenerContainer(ConnectionFactory connectionFactory){
        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.setQueueNames("zhihao.miao.order");
        //后置处理器，接收到的消息都添加了Header请求头
        container.setAfterReceivePostProcessors(message -> {
            message.getMessageProperties().getHeaders().put("desc",10);
            return message;
        });
        container.setMessageListener((MessageListener) message -> {
            System.out.println("====接收到消息=====");
            System.out.println(message.getMessageProperties());
            System.out.println(new String(message.getBody()));
        });
        return container;
    }
```

- 3.setConcurrentConsumers设置并发消费者

setMaxConcurrentConsumers设置最多的并发消费者。

```java
  @Bean
   public SimpleMessageListenerContainer messageListenerContainer(ConnectionFactory connectionFactory){
       SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
       container.setConnectionFactory(connectionFactory);
       container.setQueueNames("zhihao.miao.order");
       container.setConcurrentConsumers(5);
       container.setMaxConcurrentConsumers(10);
       container.setMessageListener((MessageListener) message -> {
           System.out.println("====接收到消息=====");
           System.out.println(message.getMessageProperties());
           System.out.println(new String(message.getBody()));
       });
       return container;
   }
```

设置成功后会有多个消费者,但每次也只有一个能消费到.
[![XsuJbQ.png](https://s1.ax1x.com/2022/06/09/XsuJbQ.png)](https://imgtu.com/i/XsuJbQ)

4. 设置消费者的Consumer_tag和Arguments

```java
 @Bean
    public SimpleMessageListenerContainer messageListenerContainer(ConnectionFactory connectionFactory){
        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.setQueueNames("zhihao.miao.order");
        //设置消费者的consumerTag_tag
        container.setConsumerTagStrategy(queue -> "order_queue_"+(++count));
        //设置消费者的Arguments
        Map<String, Object> args = new HashMap<>();
        args.put("module","订单模块");
        args.put("fun","发送消息");
        container.setConsumerArguments(args);
        container.setMessageListener((MessageListener) message -> {
            System.out.println("====接收到消息=====");
            System.out.println(message.getMessageProperties());
            System.out.println(new String(message.getBody()));
        });
        return container;
    }
```

[![Xsuyb4.png](https://s1.ax1x.com/2022/06/09/Xsuyb4.png)](https://imgtu.com/i/Xsuyb4)

#### 2. MessageListenerAdapter 消息监听适配器

高级消息监听方法，用于自定义消息监听操作，可以设置处理消息的方法、消息转换等  

官网上的解释如下.  

消息监听适配器（adapter），通过反射将消息处理委托给目标监听器的处理方法，并进行灵活的消息类型转换。允许监听器方法对消息内容类型进行操作，完全独立于Rabbit API。

消息类型转换委托给MessageConverter接口的实现类。 默认情况下，将使用SimpleMessageConverter。 （如果您不希望进行这样的自动消息转换，
那么请自己通过#setMessageConverter MessageConverter设置为null）

    //测试限流
    @RabbitListener(queues = RabbitConfig.QUEUE_A)

查看源码维护了四个对象

```java
    private final Map<String, String> queueOrTagToMethodName;
    public static final String ORIGINAL_DEFAULT_LISTENER_METHOD = "handleMessage";
    private Object delegate;
    private String defaultListenerMethod;

```

使用方式

```java
@Bean
    public SimpleMessageListenerContainer messageListenerContainer(ConnectionFactory connectionFactory){
        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        container.setQueueNames("order","pay","zhihao.miao.order");

        MessageListenerAdapter adapter = new MessageListenerAdapter(new MessageHandler());
        //设置处理器的消费消息的默认方法,如果没有设置，那么默认的处理器中的默认方式是handleMessage方法
        adapter.setDefaultListenerMethod("onMessage");
        Map<String, String> queueOrTagToMethodName = new HashMap<>();
        queueOrTagToMethodName.put("order","onorder");
        queueOrTagToMethodName.put("pay","onpay");
        queueOrTagToMethodName.put("zhihao.miao.order","oninfo");
        adapter.setQueueOrTagToMethodName(queueOrTagToMethodName);
        container.setMessageListener(adapter);

        return container;
    }
```

- MessageHandler
 
```java
public class MessageHandler {

    //没有设置默认的处理方法的时候，方法名是handleMessage
    public void handleMessage(byte[] message){
        System.out.println("---------handleMessage-------------");
        System.out.println(new String(message));
    }


    //通过设置setDefaultListenerMethod时候指定的方法名
    public void onMessage(byte[] message){
        System.out.println("---------onMessage-------------");
        System.out.println(new String(message));
    }

    //以下指定不同的队列不同的处理方法名
    public void onorder(byte[] message){
        System.out.println("---------onorder-------------");
        System.out.println(new String(message));
    }

    public void onpay(byte[] message){
        System.out.println("---------onpay-------------");
        System.out.println(new String(message));
    }

    public void oninfo(byte[] message){
        System.out.println("---------oninfo-------------");
        System.out.println(new String(message));
    }

}
```

>使用MessageListenerAdapter处理器进行消息队列监听处理，如果容器没有设置setDefaultListenerMethod，则处理器中默认的处理方法名是handleMessage，如果设置了setDefaultListenerMethod，则处理器中处理消息的方法名就是setDefaultListenerMethod方法参数设置的值。也可以通过setQueueOrTagToMethodName方法为不同的队列设置不同的消息处理方法。

总体上来看:MessageListenerAdapter
1.可以把一个没有实现MessageListener和ChannelAwareMessageListener接口的类适配成一个可以处理消息的处理器
2.默认的方法名称为：handleMessage，可以通过setDefaultListenerMethod设置新的消息处理方法
3.MessageListenerAdapter支持不同的队列交给不同的方法去执行。使用setQueueOrTagToMethodName方法设置，当根据queue名称没有找到匹配的方法的时候，就会交给默认的方法去处理。

#### 3. MessageConverter 消息转换器

我们之前消费者接收到的消息都是byte类型,可以定义自定义的也可以定义一些成熟测消息转换器.

1. 自定义消息转换器

需要实现 MessageConverter 接口,重写 toMessage + fromMessage 方法

```java
package com.dmbjz.converter;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.support.converter.MessageConversionException;
import org.springframework.amqp.support.converter.MessageConverter;

import java.nio.charset.StandardCharsets;

/* 自定义消息转换器 */
public class MyMessageConverter implements MessageConverter {

    /*将 Java 对象转换为 Message 对象 */
    @Override
    public Message toMessage(Object object, MessageProperties messageProperties) throws MessageConversionException {
        return new Message(object.toString().getBytes(StandardCharsets.UTF_8),messageProperties);
    }

    /* 将 Message对象转换为 Java 对象 */
    @Override
    public Object fromMessage(Message message) throws MessageConversionException {
        String contentType = message.getMessageProperties().getContentType();
        /*判断消息类型，这里将JSON消息转换为String格式
        *   String格式数据无法被消息适配器默认的 byte[]参数接收，需要添加String参数方法
        */
        if(null!=contentType && contentType.contains("application/json")){
            return new String(message.getBody());
        }
        return message.getBody();
    }

}
```

配置进消息MessageListenerAdapter

```java
    @Bean
    public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
        container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
        container.setConcurrentConsumers(1);                    //消费者数量
        container.setMaxConcurrentConsumers(10);                //最大消费者
        container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
        container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
        container.setConsumerTagStrategy(new ConsumerTagStrategy() {
            @Override
            public String createConsumerTag(String queue) {
                return queue + "_" + UUID.randomUUID().toString();
            }
        });     //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag


        /*消息监听器使用消息适配器 方案一，通用适配模式 */
        MessageListenerAdapter adapter = new MessageListenerAdapter(new MessageDelegate());
        adapter.setDefaultListenerMethod("consumerMessage");    //自定义消息处理方法名称
        adapter.setMessageConverter(new MyMessageConverter());  //添加消息转换器
        container.setMessageListener(adapter);
        
    }
```

2. 第三方消息转换器  Jackson2JsonMessageConverter

转换为json

```java
  	@Bean
    public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
        container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
        container.setConcurrentConsumers(1);                    //消费者数量
        container.setMaxConcurrentConsumers(10);                //最大消费者
        container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
        container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
        container.setConsumerTagStrategy(new ConsumerTagStrategy() {
            @Override
            public String createConsumerTag(String queue) {
                return queue + "_" + UUID.randomUUID().toString();
            }
        });     //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag

        /*使用默认的JSON格式转换器，消息需要使用Map进行接收*/
        MessageListenerAdapter adapter = new MessageListenerAdapter(new MessageDelegate());
        adapter.setDefaultListenerMethod("consumerMessage");        //消息适配器默认监听方法名称
        Jackson2JsonMessageConverter jsonMessageConverter = new Jackson2JsonMessageConverter();
        adapter.setMessageConverter(jsonMessageConverter);
        container.setMessageListener(adapter);

        return container;

    }
```

转换为实体类
- 实体类
```java
package com.dmbjz.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Accessors(chain = true)
public class Student {

    private String id;              //ID
    private String name;            //名称
    private String content;         //内容

}
```
- 配置类
```java
    /* 消息容器SimpleMessageListenerContainer 配置*/
    @Bean
    public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
        container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
        container.setConcurrentConsumers(1);                    //消费者数量
        container.setMaxConcurrentConsumers(10);                //最大消费者
        container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
        container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
        container.setConsumerTagStrategy(new ConsumerTagStrategy() {
            @Override
            public String createConsumerTag(String queue) {
                return queue + "_" + UUID.randomUUID().toString();
            }
        });     //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag

        
        
        /*使用默认的JSON格式转换器，消息转换为具体的Java对象，需要使用对象进行接收*/
        MessageListenerAdapter adapter = new MessageListenerAdapter(new MessageDelegate());
        adapter.setDefaultListenerMethod("consumerMessage");

        Jackson2JsonMessageConverter jackson2JsonMessageConverter = new Jackson2JsonMessageConverter();
        DefaultJackson2JavaTypeMapper javaTypeMapper = new DefaultJackson2JavaTypeMapper();
        javaTypeMapper.addTrustedPackages("*");             //允许使用所有包进行转换，默认会使用java核心类进行转换
        jackson2JsonMessageConverter.setJavaTypeMapper(javaTypeMapper);

        adapter.setMessageConverter(jackson2JsonMessageConverter);
        container.setMessageListener(adapter);

    }
```

- 重点在这几行

```java
        Jackson2JsonMessageConverter jackson2JsonMessageConverter = new Jackson2JsonMessageConverter();
        DefaultJackson2JavaTypeMapper javaTypeMapper = new DefaultJackson2JavaTypeMapper();
        javaTypeMapper.addTrustedPackages("*");             //允许使用所有包进行转换，
```

3. 配置不同实体类转换

配置类如下 

```java
    @Bean
    public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
        container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
        container.setConcurrentConsumers(1);                    //消费者数量
        container.setMaxConcurrentConsumers(10);                //最大消费者
        container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
        container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
        container.setConsumerTagStrategy(new ConsumerTagStrategy() {
            @Override
            public String createConsumerTag(String queue) {
                return queue + "_" + UUID.randomUUID().toString();
            }
        });     //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag


        /*使用默认的JSON格式转换器，消息转换为具体的Java对象，需要使用对象进行接收,支持多映射*/
        MessageListenerAdapter adapter = new MessageListenerAdapter(new MessageDelegate());
        adapter.setDefaultListenerMethod("consumerMessage");

        Jackson2JsonMessageConverter jackson2JsonMessageConverter = new Jackson2JsonMessageConverter();
        DefaultJackson2JavaTypeMapper javaTypeMapper = new DefaultJackson2JavaTypeMapper();

        Map<String,Class<?>> idClassMap = new HashMap<>();  //创建Map进行多映射指定,KEY为名称，value为类全路径
        idClassMap.put("student",com.dmbjz.entity.Student.class);
        idClassMap.put("packaged",com.dmbjz.entity.Packaged.class);
        javaTypeMapper.setIdClassMapping(idClassMap);
        javaTypeMapper.addTrustedPackages("*");             //允许使用所有包进行转换，默认会使用 java核心类进行转换

        jackson2JsonMessageConverter.setJavaTypeMapper(javaTypeMapper);
        adapter.setMessageConverter(jackson2JsonMessageConverter);
        container.setMessageListener(adapter);

        return container;

    }
```

重点在这里

```java
        Map<String,Class<?>> idClassMap = new HashMap<>();  //创建Map进行多映射指定,KEY为名称，value为类全路径
        idClassMap.put("student",com.dmbjz.entity.Student.class);
        idClassMap.put("packaged",com.dmbjz.entity.Packaged.class);
        javaTypeMapper.setIdClassMapping(idClassMap);
        javaTypeMapper.addTrustedPackages("*");             //允许使用所有包进行转换，默认会使用 java核心类进行转换
```

以上我们做了很多工作,但是联想到之前加了一个注解就解决了.
```java
    bbitHandler
    public void process(@Payload RabbitMessage rabbitMessage) {
        //String body = new String(message.getBody());
        System.out.println("接收处理队列A当中的消息： " + rabbitMessage.toString());
    }
```
因此猜想是否加了这个注解后生成了代理类配置进了adapter?

3. 多消息类型转换器

我们可以为adapter配置多个消息转换器.

不同的消息配置不同的消息转换类型 

```java
    @Bean
    public SimpleMessageListenerContainer messageListenerContainer(CachingConnectionFactory cachingConnectionFactory){

        SimpleMessageListenerContainer container = new SimpleMessageListenerContainer(cachingConnectionFactory);        //设置连接池
        container.setQueues(topicQueue1(),topicQueue2(),directQueue1(),directQueue2());        //设置监听队列
        container.setConcurrentConsumers(1);                    //消费者数量
        container.setMaxConcurrentConsumers(10);                //最大消费者
        container.setDefaultRequeueRejected(false);             //是否设置重回队列，一般都为false，相当于 channel.basicReject(message.getEnvelope().getDeliveryTag(),false);
        container.setAcknowledgeMode(AcknowledgeMode.AUTO);     //消息应答方式,自动/手动/拒绝
        container.setConsumerTagStrategy(new ConsumerTagStrategy() {
            @Override
            public String createConsumerTag(String queue) {
                return queue + "_" + UUID.randomUUID().toString();
            }
        });     //消费端的标签策略，每个消费端都有独立的标签，可在控制台的 channel > consumer 中查看 对应tag


        
        /*多类型消息转换器，不同消息类型使用不同类型转换器进行转换*/
        MessageListenerAdapter adapter =new MessageListenerAdapter(new MessageDelegate());
        adapter.setDefaultListenerMethod("extComsumeMessage");

        ContentTypeDelegatingMessageConverter converter = new ContentTypeDelegatingMessageConverter();  //复杂消息转换器

        TextMessageConverter textConvert = new TextMessageConverter();  //文本转换器
        converter.addDelegate("text",textConvert);
        converter.addDelegate("html/text",textConvert);
        converter.addDelegate("xml/text",textConvert);
        converter.addDelegate("text/plain",textConvert);

        Jackson2JsonMessageConverter jsonConverter = new Jackson2JsonMessageConverter();    //JSON转换器
        converter.addDelegate("json",jsonConverter);
        converter.addDelegate("application/json",jsonConverter);

        ImageMessageConverter imageConverter = new ImageMessageConverter();     //图片转换器
        converter.addDelegate("image/png",imageConverter);
        converter.addDelegate("image",imageConverter);

        PDFMessageConverter pdfConverter = new PDFMessageConverter();           //PDF转换器
        converter.addDelegate("application/pdf",pdfConverter);

        adapter.setMessageConverter(converter);
        container.setMessageListener(adapter);

        return container;

    }
```

#### 组件小结:
1. 可以为mq配置SimpleMessageListenerContainer,此组件可以动态修改一些消费者的配置如消费者数量、接收消息的模式,监听的队列增删等等.
2. MessageListenerContainer配置MessageListenerAdapter,MessageListenerAdapter配置处理器,当消息到来的时候,可以走处理器默认的方法,也可以根据配置,让不同队列走不同方法.
3. MessageListenerAdapter可以配置MessageConverter,转换不同的消息
4. 以上转换配置在消费端可以通过注解完成,原理应该还是动态代理.
5. 比较实用一点应该还是在生产端配置消息转换器,然后通过对容器参数动态修改.



## 小结

主要总结了如下内容 
1. 不可路由消息,有两类,一类找不到交换机,一类找不到队列,找不到队列的可以发送到备份交换机.
2. 消费端手动ack,保证消息的不会失效.消费点做限流,降低负载.
3. ttl和死信队列,消息设置ttl,当消息过期后,或队列满了成为死信.两者配合可做延迟队列.
4. 如何保证消息可靠性和幂等性.可靠性可以二次发送也可以二次入库.幂等性根据唯一id和reids来做.
5. 一些组件的封装,可以见上面的.

参考:
[简书:MessageListenerAdapter详解](https://www.jianshu.com/p/d21bafe3b9fd)
[掘金:消息适配器 - MessageListenerAdapter](https://juejin.cn/post/6844903776545931272)