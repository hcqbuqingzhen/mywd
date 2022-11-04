## Sa-Token搭建认证和鉴权

### sa-token是什么

**Sa-Token** 是一个轻量级 Java 权限认证框架，主要解决：**登录认证**、**权限认证**、**单点登录**、**OAuth2.o0**、**分布式Session会话**、**微服务网关鉴权** 等一系列权限相关问题。

[sa-token](https://sa-token.dev33.cn/)  官网在此.

在之前的项目中.主要是使用了spring-oauth2来解决了认证和鉴权的问题.有许多公司认证和鉴权这快是自己造轮子.

前几天发现一个新的框架,这两年的使用量还是挺大的,所以搭建一下使用. 具体的使用方法在官网很详细,这里不再手动去一项一项测试了.旨在使用这个东西搭建一套适合微服务使用的认证中心.



### 搭建过程

#### 1. 集成redis

这里先不引入注册中心,整体搭建完成后会在github上传.

##### - 引入依赖

```xml
 <dependencies>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>cn.dev33</groupId>
            <artifactId>sa-token-spring-boot-starter</artifactId>
        </dependency>
        <!-- Sa-Token 整合 Redis （使用 jackson 序列化方式） -->
        <dependency>
            <groupId>cn.dev33</groupId>
            <artifactId>sa-token-dao-redis-jackson</artifactId>
        </dependency>
        <!-- 提供Redis连接池 -->
        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-pool2</artifactId>
        </dependency>
        <!--nacos:用于服务注册与发现-->
        <!--<dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
        </dependency>

        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>-->

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.platform</groupId>
            <artifactId>junit-platform-launcher</artifactId>
            <scope>test</scope>
        </dependency>

    </dependencies>
```



##### - 配置文件

```yml
server:
	# 端口
  port: 9100
spring: 
    # redis配置 
    redis:
        # Redis数据库索引（默认为0）
        database: 1
        # Redis服务器地址
        host: 127.0.0.1
        # Redis服务器连接端口
        port: 6379
        # Redis服务器连接密码（默认为空）
        # password: 
        # 连接超时时间
        timeout: 10s
        lettuce:
            pool:
                # 连接池最大连接数
                max-active: 200
                # 连接池最大阻塞等待时间（使用负值表示没有限制）
                max-wait: -1ms
                # 连接池中的最大空闲连接
                max-idle: 10
                # 连接池中的最小空闲连接
                min-idle: 0
```

