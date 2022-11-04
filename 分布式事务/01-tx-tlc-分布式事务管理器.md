 
# tx-lcn分布式事务管理器

> 分布式事务是什么和分布式事务的cap,base理论这里不做讨论，网上的文章有很多，视频也很多。只记录如何搭建tx-lcn和如何使用。

## 1. tx-lcn是什么

LCN框架在2017年6月发布第一个版本，目前最新已经达到5.0版本。
LCN早期设计时，1.0版本和2.0版本设计步骤如下：
- 锁定事务单元（Lock）

- 确认事务模块状态（Confirm）

- 通知事务（Notify）

取各自首字母后名称为LCN。
LCN框架从5.0开始兼容了LCN、TCC、TXC三种事务模式，为了和LCN框架区分，从5.0开始把LCN框架更名为：TX-LCN分布式事务框架。

[tx-lcn官网](https://www.codingapi.com/docs/)
## 2. 分布式事务中lcn模式的工作场景和原理

### 2.1 组件和概念

> TX-LCN由两大模块组成，TxClient、TxManager。
> TxClient作为模块的依赖框架，提供了TX-LCN的标准支持，事务发起方和参与方都属于TxClient。
> TxManager作为分布式事务的控制方，控制整个事务。
- 创建事务组
是指在事务发起方开始执行业务代码之前先调用TxManager创建事务组对象，然后拿到事务标识GroupId的过程。

- 加入事务组
添加事务组是指参与方在执行完业务方法以后，将该模块的事务信息通知给TxManager的操作。

- 通知事务组
是指在发起方执行完业务代码以后，将发起方执行结果状态通知给TxManager,TxManager将根据事务最终状态和事务组的信息来通知相应的参与模块提交或回滚事务，并返回结果给事务发起方。 
### 2.2 典型场景
1. 
>1. 发起方创建事务
>2. 发起方调用a
>3. 发起方调用b
>4. 发起方提交事务 

[![OywNS1.png](https://s1.ax1x.com/2022/05/13/OywNS1.png)](https://imgtu.com/i/OywNS1)  

2. 
>1. 发起方创建事务
>2. 发起方调用a
>3. a调用b
>4. 发起方提交事务

[![Oy0q4H.png](https://s1.ax1x.com/2022/05/13/Oy0q4H.png)](https://imgtu.com/i/Oy0q4H)


### 2.3 工作原理

1. 当事务发起方创建事务时，我们可以理解为在tx-manager中创建了一个事务组
2. a服务被调用时，a执行完毕会进行一个提交，**注意这里并不是真的向数据库提交了事务，而是对commit进行了代理**，此时会占用连接，等待tx-manager服务通知真提交还是回滚。
3. 当所有的事务都没有出错时，事务发起方会提交事务，由事务管理对子事务进行通知，让其真正提交事务。
4. 当有事务出错时，比如b服务中抛出了异常，事务发起方知道了异常，会让tx-manager通知子事务回滚。

>从这个原理可以看出，lcn模式是很占用数据库连接，因为子事务不会真正提交，会等待所有事务完毕后才提交或回滚。
>同时lcn也是只支持jdbc的连接的回滚

## 3. 实战搭建

### 3.1  事务管理器（tx-manager）搭建
>tx-manager是一个服务器，也是基于springboot的。

1. 创建项目springboot项目，引入pom文件，添加配置文件

```xml
    <dependency>
            <groupId>com.xsyw</groupId>
            <artifactId>xsyw-log-spring-boot-starter</artifactId>
        </dependency>
<!--nacos配置  ：： 可有可无-->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>
        <!--tx-lcn管理器-->
        <dependency>
            <groupId>com.codingapi.txlcn</groupId>
            <artifactId>txlcn-tm</artifactId>
        </dependency>
    </dependencies>
```

- 配置文件如下,如果需要nacos加入需要bootstrap.properties，不知为何
  
bootstrap.properties

```properties
## 此处如果不在application配置，会启动不起来。
spring.application.name=TX-Manager
server.port=7970

xsyw.nacos.server-addr=192.168.28.130:8848
spring.cloud.nacos.discovery.server-addr=${xsyw.nacos.server-addr}
```
application.properties 

```properties
##################
# 你可以在 https://txlcn.org/zh-cn/docs/setting/manager.html 看到所有的个性化配置
#################

spring.application.name=TX-Manager
server.port=7970
spring.profiles.active=dev

#####db配置 tx-manager
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.datasource.url=jdbc:mysql://${rrs.datasource.ip}:3306/tx-manager?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&useSSL=false&zeroDateTimeBehavior=convertToNull
spring.datasource.username=${rrs.datasource.username}
spring.datasource.password=${rrs.datasource.password}
spring.jpa.database-platform=org.hibernate.dialect.MySQL5InnoDBDialect
spring.jpa.hibernate.ddl-auto=update

### tx-lcn logger配置
tx-lcn.logger.enabled=true
tx-lcn.logger.driver-class-name=com.mysql.cj.jdbc.Driver
tx-lcn.logger.jdbc-url=jdbc:mysql://${rrs.datasource.ip}:3306/tx_logger?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&useSSL=false&zeroDateTimeBehavior=convertToNull
tx-lcn.logger.username=${rrs.datasource.username}
tx-lcn.logger.password=${rrs.datasource.password}

# redis 的设置信息. 线上请用Redis Cluster
spring.redis.host=${rrs.redis.host}
spring.redis.port=${rrs.redis.port}
spring.redis.password=

# TM后台登陆密码，默认值为codingapi
tx-lcn.manager.admin-key=admin

# 分布式事务执行总时间(ms). 默认为8000
tx-lcn.manager.dtx-time=15000

```
将文件中 rrs.datasource.username 等换成自己的数据库地址，数据库密码等。

至于为什么要用peoperties,是因为tx-lcn默认采用的peoperties文件配置的，如果我们采用yml文件会不生效。

2. 执行sql语句

tx-lcn依赖mysql和redis，所以需要在mysql中建立对应的库。  
tx-lcn将此sql文件放在txlcn-tm-5.0.2.RELEASE.jar包根目录下。当然也可以到官网查看。
```sql
/*
 Navicat Premium Data Transfer

 Source Server         : local
 Source Server Type    : MySQL
 Source Server Version : 100309
 Source Host           : localhost:3306
 Source Schema         : tx-manager

 Target Server Type    : MySQL
 Target Server Version : 100309
 File Encoding         : 65001

 Date: 29/12/2018 18:35:59
*/
CREATE DATABASE IF NOT EXISTS  `tx-manager` DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
USE `tx-manager`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_tx_exception
-- ----------------------------
DROP TABLE IF EXISTS `t_tx_exception`;
CREATE TABLE `t_tx_exception`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `group_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `unit_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `mod_id` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `transaction_state` tinyint(4) NULL DEFAULT NULL,
  `registrar` tinyint(4) NULL DEFAULT NULL,
  `ex_state` tinyint(4) NULL DEFAULT NULL COMMENT '0 待处理 1已处理',
  `remark` varchar(10240) NULL DEFAULT NULL COMMENT '备注',
  `create_time` datetime(0) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 967 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;



CREATE DATABASE IF NOT EXISTS `tx_logger` DEFAULT CHARACTER SET = utf8;
Use `tx_logger`;

-- ----------------------------
-- Table structure for t_logger
-- ----------------------------
DROP TABLE IF EXISTS `t_logger`;
CREATE TABLE `t_logger`  (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `group_id` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `unit_id` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `tag` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `content` varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `create_time` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `app_name` varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 19 CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;




```

3. 启动redis， 并将配置文件中地址改为自己的redis地址。

4. 编写启动类
TransactionManagerApplication.java
```java
/**
 * @author hcq
 */
@SpringBootApplication
//@EnableDiscoveryClient
@EnableTransactionManagerServer
public class TransactionManagerApplication {
    public static void main(String[] args) {
        SpringApplication.run(TransactionManagerApplication.class, args);
    }
}
```

5. 保证redis和mysql启动且配置正确，启动启动类，访问服务端口进入控制台。

### 3.2  tx-client的搭建和使用
>即为我们客户端服务发起者和服务调用者 

[tx-demo模块](https://github.com/hcqbuqingzhen/rrs-platform/tree/master/demo/tx-demo) 搭建的demo,可下载查看运行。
#### 3.2.1 common模块，服务公共模块。

[![O2Jhxx.png](https://s1.ax1x.com/2022/05/15/O2Jhxx.png)](https://imgtu.com/i/O2Jhxx)

项目类图，主要封装了公共的dao操作，和feign的客户端供其他demo模块调用。

#### 3.2.2 其他服务模块

[![O2YkJs.png](https://s1.ax1x.com/2022/05/15/O2YkJs.png)](https://imgtu.com/i/O2YkJs)

服务a,b,c的内容相似，不同的是服务之间方法的不同

1.  服务a,service方法。
```java
@LcnTransaction
    @Transactional(rollbackFor = Exception.class)
    @Override
    public String execute(String value, String exFlag, String flag) {
        String dResp = serviceBClient.rpc(value);
        // step2. call remote ServiceB
        String eResp = serviceCClient.rpc(value);
        // step3. execute local transaction
        Demo demo = new Demo();
        demo.setGroupId(TracingContext.tracing().groupId());
        demo.setDemoField(value);
        demo.setCreateTime(new Date());
        demo.setAppName(Transactions.getApplicationId());
        demoMapper.save(demo);

        // 置异常标志，DTX 回滚
        if (Objects.nonNull(exFlag)) {
            throw new IllegalStateException("by exFlag");
        }

        return dResp + " > " + eResp + " > " + "ok-service-a";
    }
```

2. 服务b,service方法。
```java
@Override
    @LcnTransaction
    @Transactional(rollbackFor = Exception.class)
    public String rpc(String value) {
        Demo demo = new Demo();
        demo.setGroupId(TracingContext.tracing().groupId());
        demo.setDemoField(value);
        demo.setAppName(Transactions.getApplicationId());
        demo.setCreateTime(new Date());
        demoMapper.save(demo);
        return "ok-service-b";
    }
```
3. 服务c,service方法。
```java
@Override
    @LcnTransaction
    @Transactional(rollbackFor = Exception.class)
    public String rpc(String value) {
        Demo demo = new Demo();
        demo.setDemoField(value);
        demo.setCreateTime(new Date());
        demo.setAppName(Transactions.getApplicationId());
        demo.setGroupId(TracingContext.tracing().groupId());
        demoMapper.save(demo);
        if ("456".equals(value)) {
            throw new IllegalStateException("by test");
        }
        return "ok-service-c";
    }
```

### 3.3 测试lcn分布式事务
1. 我们先开启tx-manager，同时开启啊a,b,c服务。
> 可以下载我搭建的项目运行
- tx-manager为transaction模块下的tx-lcn模块，配置好数据库，redis，直接运行即可。

[![O2YvtJ.png](https://s1.ax1x.com/2022/05/15/O2YvtJ.png)](https://imgtu.com/i/O2YvtJ)

- demo模块在demo下

[![O2tGNQ.png](https://s1.ax1x.com/2022/05/15/O2tGNQ.png)](https://imgtu.com/i/O2tGNQ)

2. 数据库建好库和表

```sql
create database txlcn_demo;

use txlcn_demo;

create table t_demo(
    id int(10) primary key  auto_increment,
    kid varchar(255),
    demo_field varchar(255),
    group_id varchar(255),
    create_time datetime,
    app_name varchar(255)
);
```

3. 调用服务a测试
- 其中参数ex有值会让服务a抛出异常   
[![O2t2g1.png](https://s1.ax1x.com/2022/05/15/O2t2g1.png)](https://imgtu.com/i/O2t2g1)

4. 测试结果

- 当不传ex字段时，数据都会成功写入。

[![O2tT4H.png](https://s1.ax1x.com/2022/05/15/O2tT4H.png)](https://imgtu.com/i/O2tT4H)

- 当传入ex字段时，数据库中不会写入数据，观察b,c控制台如下。

[![O2NNIe.png](https://s1.ax1x.com/2022/05/15/O2NNIe.png)](https://imgtu.com/i/O2NNIe)

我们可以发现这一套分布式事务可以正常运行。

## 4. tx-lcn使用tcc模式的分布式事务
> 我们上面使用的是lcn模式，lcn模式的原理在第二节中有描述，其实在电商的场景中还有一种tcc的模式也很常用，tx-lcn也支持了这种模式。

### 4.1 tcc模式的原理
- TCC的核心思想是：针对每个操作，都要注册一个与其对应的确认和补偿（撤销）操作，分为三个阶段：
- Try：这个阶段对各个服务的资源做检测以及对资源进行锁定或者预留；
- Confirm ：执行真正的业务操作，不作任何业务检查，只使用Try阶段预留的业务资源，Confirm操作要求具备幂等设计，Confirm失败后需要进行重试；
- Cancel：如果任何一个服务的业务方法执行出错，那么这里就需要进行补偿，即执行回滚操作，释放Try阶段预留的业务资源 ，Cancel操作要求具备幂等设计，Cancel失败后需要进行重试

**假设我们的分布式系统一共包含4个服务：订单服务、库存服务、积分服务、仓储服务，每个服务有自己的数据库，如下图：**

[![O2UawT.png](https://s1.ax1x.com/2022/05/15/O2UawT.png)](https://imgtu.com/i/O2UawT)

1. try阶段
- Try阶段一般用于锁定某个资源，设置一个预备状态或冻结部分数据。对于示例中的每一个服务，Try阶段所做的工作如下：
- 订单服务：先置一个中间状态“UPDATING，支付中”，而不是直接设置“支付成功”状态；
- 库存服务：先用一个冻结库存字段保存冻结库存数，而不是直接扣掉库存，大致意思是冻结库存两个；
- 积分服务：预增加会员积分；
- 仓储服务：创建销售出库单，但状态是UNKONWN，出单中。

[![O2aucR.png](https://s1.ax1x.com/2022/05/15/O2aucR.png)](https://imgtu.com/i/O2aucR)

2. Confirm

- 根据Try阶段的执行情况，Confirm分为两种情况：
  - 理想情况下，所有Try全部执行成功，则执行各个服务的Confirm逻辑；
  - 部分服务Try执行失败，则执行第三阶段——Cancel。
- Confirm阶段一般需要各个服务自己实现Confirm逻辑：
  - 订单服务：confirm逻辑可以是将订单的中间状态变更为PAYED-支付成功；
  - 库存服务：将冻结库存数清零，同时扣减掉真正的库存；
  - 积分服务：将预增加积分清零，同时增加真实会员积分；
  - 仓储服务：修改销售出库单的状态为已创建-CREATED。

  **Confirm阶段的各个服务本身可能出现问题，这时候一般就需要TCC框架了（比如ByteTCC，tcc-transaction，himly），TCC事务框架一般会记录一些分布式事务的活动日志，保存事务运行的各个阶段和状态，从而保证整个分布式事务的最终一致性。**
3. Cancel
- 如果Try阶段执行异常，就会执行Cancel阶段。比如：
  - 对于订单服务，可以实现的一种Cancel逻辑就是：将订单的状态设置为“CANCELED”；
  - 对于库存服务，Cancel逻辑就是：将冻结库存扣减掉，加回到可销售库存里去。

[![O2aoUU.png](https://s1.ax1x.com/2022/05/15/O2aoUU.png)](https://imgtu.com/i/O2aoUU)

- 框架选型
  - TCC框架的可供选择余地比较少，目前相对比较成熟的是阿里开源的分布式事务框架seata（https://github.com/seata/seata），这个框架是经历过阿里生产环境的大量考验，同时也支持dubbo、spring cloud。
- 优点
  - 跟2PC比起来，实现以及流程相对简单了一些，但数据的一致性比2PC也要差一些，当然性能也可以得到提升。
- 缺点
  - TCC模型对业务的侵入性太强，事务回滚实际上就是自己写业务代码来进行回滚和补偿，改造的难度大。一般来说支付、交易等核心业务场景，可能会用TCC来严格保证分布式事务的一致性，要么全部成功，要么全部自动回滚。这些业务场景都是整个公司的核心业务有，比如银行核心主机的账务系统，不容半点差池。
  - 但是，在一般的业务场景下，尽量别没事就用TCC作为分布式事务的解决方案，因为自己手写回滚/补偿逻辑，会造成业务代码臃肿且很难维护。

### 4.2 tx-lcn测试tcc模式
1.  增加方法

- servera
```java
    @TccTransaction(confirmMethod = "confirmExecuteTcc",cancelMethod ="confirmExecuteTcc" )
    @Transactional(rollbackFor = Exception.class)
    @Override
    public String executeTcc(String value, String exFlag, String flag) {
        //tcc模式下增加一个用于判断的字段，当try阶段是这个字段的含义是 增加中。
        String dResp = serviceBClient.rpcTcc(value);
        // step2. call remote ServiceB
        String eResp = serviceCClient.rpcTcc(value);
        // step3. execute local transaction
        Demo demo = new Demo();
        demo.setGroupId(TracingContext.tracing().groupId());
        demo.setDemoField(value);
        demo.setCreateTime(new Date());
        demo.setAppName(Transactions.getApplicationId());
        demo.setStatus(0);
        demoMapper.save(demo);

        // 置异常标志，DTX 回滚
        if (Objects.nonNull(exFlag)) {
            throw new IllegalStateException("by exFlag");
        }

        return dResp + " > " + eResp + " > " + "ok-service-a";
    }

    public void confirmExecuteTcc(String value, String exFlag, String flag){
        //确认方法 需要自己手动修改业务逻辑
        //我们确认字段增加成功
        String applicationId = Transactions.getApplicationId();
        demoMapper.updateById(value,applicationId);

    }

    public void cancelExecuteTcc(String value, String exFlag, String flag){
        //确认方法 需要自己手动修改业务逻辑
        //我们修改字段为增加失败

        String applicationId = Transactions.getApplicationId();
        demoMapper.deleteById(value,applicationId);
    }
```
- serverb
```java
 @TccTransaction(confirmMethod = "confirmRpcTcc",cancelMethod ="cancelRpcTcc" )
    @Transactional(rollbackFor = Exception.class)
    @Override
    public String rpcTcc(String value) {
        Demo demo = new Demo();
        demo.setGroupId(TracingContext.tracing().groupId());
        demo.setDemoField(value);
        demo.setAppName(Transactions.getApplicationId());
        demo.setCreateTime(new Date());
        demo.setStatus(0);
        demoMapper.save(demo);
        return "ok-service-b";
    }


    public void confirmRpcTcc(String value){
        //确认方法 需要自己手动修改业务逻辑
        //我们确认字段增加成功
        System.out.println("confirm 运行了");
        String applicationId = Transactions.getApplicationId();
        demoMapper.updateById(value,applicationId);
    }

    public void cancelRpcTcc(String value){
        //确认方法 需要自己手动修改业务逻辑
        //我们修改字段为增加失败
        System.out.println("cancl 运行了");
        String applicationId = Transactions.getApplicationId();
        demoMapper.deleteById(value,applicationId);
    }
```

- serverc
```java
@Override
    @TccTransaction(confirmMethod = "confirmRpcTcc",cancelMethod ="cancelRpcTcc" )
    @Transactional(rollbackFor = Exception.class)
    public String rpcTcc(String value) {
        Demo demo = new Demo();
        demo.setDemoField(value);
        demo.setCreateTime(new Date());
        demo.setAppName(Transactions.getApplicationId());
        demo.setGroupId(TracingContext.tracing().groupId());
        demo.setStatus(0);
        demoMapper.save(demo);
        if ("456".equals(value)) {
            throw new IllegalStateException("by test");
        }
        return "ok-service-c";
    }

    public void confirmRpcTcc(String value){
        //确认方法 需要自己手动修改业务逻辑
        //我们确认字段增加成功
        System.out.println("confirm 执行了");
        String applicationId = Transactions.getApplicationId();
        demoMapper.updateById(value,applicationId);
    }

    public void cancelRpcTcc(String value){
        //确认方法 需要自己手动修改业务逻辑
        //我们修改字段为增加失败
        System.out.println("cancel 执行了");
        String applicationId = Transactions.getApplicationId();
        demoMapper.deleteById(value,applicationId);
    }
```
**对应的contrller中要添加对应的方法。**
**注意 confirmRpcTcc cancelRpcTcc 等方法，参数要和原方法一致，tx-lcn框架会在分布式事务有一个失败时，调用我们写的业务方法**

2. 使用方法
- 也可以下载此demo模块
[tx-demo模块](https://github.com/hcqbuqingzhen/rrs-platform/tree/master/demo/tx-demo)

- 当调用txlcn-tcc 时，方法失败，且数据库中数据回滚。

  
调用 且让其抛异常
[![O2LcvQ.png](https://s1.ax1x.com/2022/05/15/O2LcvQ.png)](https://imgtu.com/i/O2LcvQ)

控制台输出，回滚方法运行，且数据库中数据无增加。

[![O2LLr9.png](https://s1.ax1x.com/2022/05/15/O2LLr9.png)](https://imgtu.com/i/O2LLr9)

## 总结
1. tx-lcn是lcn模式的一个实现：
   其原理是对数据库连接进行代理，当commit时并没有真正的提交，当所有事务都没有出错时，事务管理器会下达提交的命令，此时才会提交，当有一个事务出现异常时，执行回滚。
2. tx-lcn通过注解来开发，当我们配置好时，开发起来比较简单。
3. tx-lcn也支持了tcc模式，4小结节进行了实现。
4. tx-lcn的lcn模式可用在资源较多的情况，如果资源比较少，或者不仅仅是jdbc,如mongodb,redis，可采用tcc模式。
5. tcc模式的缺点是代码侵入性高，且业务代码需要重写。

**资源** ：数据库连接。