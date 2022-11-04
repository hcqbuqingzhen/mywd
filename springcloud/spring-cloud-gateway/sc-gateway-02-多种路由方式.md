---
title: spring-cloud-gateway的多种路由实现方式
date: 2021-12-07 20:01:11
tags: spring-cloud-gateway
--- 
## 02 spring-cloud-gateway的多种路由实现方式
我们已经实现了sc-gateway的基本路由方式，在这种方式中：如下。
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: sc-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          # 匹配成功后，会被转发到8082端口，至于端口后面的path，会直接使用原始请求的
          # 例如http://127.0.0.1:8081/hello/str，会被转发到http://127.0.0.1:8082/hello/str
          uri: http://127.0.0.1:8082
          predicates:
            # 根据请求路径中带有"/hello/"，就算匹配成功
          - Path=/hello/**

```  
我们把uri,和对应路由的规则写死了，如果只有几台机器这很好管理。但在微服务中，一个服务有很多实例，同时又有很多服务运行。服务的扩容缩容，又会让url变化。因此这种方式在生产中是是很难去配置的。好在我们有注册中心来帮我们实现服务的注册和发现。uri可以用服务名来代替，服务消费之从注册中心得到实时的服务地址（scgateway可以看作其他服务的消费者）。   

### 1.使用服务名来配置
- 在hello工程中添加一个控制器

```java
import com.bolingcavalry.common.Constants;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.text.SimpleDateFormat;
import java.util.Date;

@RestController
@RequestMapping("/lbtest")
public class LBTest {

    private String dateStr(){
        return new SimpleDateFormat("yyyy-MM-dd hh:mm:ss").format(new Date());
    }

    /**
     * 返回字符串类型
     * @return
     */
    @GetMapping("/str")
    public String helloStr() {
        return Constants.LB_PREFIX + ", " + dateStr();
    }
}
```

- common模块下的常量

```java
public interface Constants {
    String HELLO_PREFIX = "Hello World";
    String LB_PREFIX = "Load balance";
}
```

- sc-gateway yml

```yml
server:
  #服务端口
  port: 8082
spring:
  application:
    name: sc-gateway
  cloud:
    nacos:
      # 注册中心的配置
      discovery:
        server-addr: 127.0.0.1:8848
    gateway:
      routes:
        - id: path_route_lb
          uri: lb://provider-hello
          predicates:
          - Path=/lbtest/**
```  

- 启动nacos,同时启动sc-gateway和hello   
  访问8081:/lbtest/str 会被转发到 8082:/lbtest/str  


### 2. nacos配置实现

我们在nacos中建立一个配置，名字和和网关服务的名字相同，加上对应的后缀。  

- 配置如下  
```yml
spring:
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            # 根据请求路径中带有"/hello/"，就算匹配成功
            - Path=/hello/**

```
- 同时本地增加 bootstrap.yml

```yml
spring:
  application:
    name: sc-gateway
  cloud:
    nacos:
      config:
        server-addr: 127.0.0.1:8848
        file-extension: yml
        group: DEFAULT_GROUP

```

tips：spring 启动时读取的顺序为 
- 1.bootstrap.yml
- 2 nacos上同名的配置 
- 3 本地application.yml


现在访问8081:/hello/str 会被转发到 8082:/hello/str 


### 3.写代码的方式配置

- 可以在sc-gateway中添加如下配置类，返回一个routeLocator类
```java
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RouteConfig {

    @Bean
    public RouteLocator customizeRoute(RouteLocatorBuilder builder) {
        return builder
                .routes()
                .route(
                            // 第一个参数是路由的唯一身份
                        "path_route_lb",
                            // 第二个参数是个lambda实现，
                            // 设置了配套条件是按照请求路径匹配，以及转发地址，
                            // 注意lb://表示这是个服务名，要从
                            r -> r.path("/lbtest/**").uri("lb://provider-hello")
                )
                .build();
    }
}
```

我们删掉nacos中的配置，然后重启，会发现也会转发成功。

缺陷 
- 不管我们怎么配置，这些配置都不能热更新。
- 所以要解决这个问题就要使用动态路由。
