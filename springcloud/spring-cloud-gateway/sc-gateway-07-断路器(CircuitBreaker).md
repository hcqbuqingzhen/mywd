---
title: scg断路器(CircuitBreaker) 
date: 2021-12-08 20:22:49
tags: spring-cloud-gateway
---   
# sc-gat
 # scg断路器(CircuitBreaker)
 spring-cloud-gateway的断路器其理论如下。
1. CLOSED状态时，请求正常放行
2. 请求失败率达到设定阈值时，变为OPEN状态，此时请求全部不放行
3. OPEN状态持续设定时间后，进入半开状态（HALE_OPEN），放过部分请求
4. 半开状态下，失败率低于设定阈值，就进入CLOSE状态，即全部放行
5. 半开状态下，失败率高于设定阈值，就进入OPEN状态，即全部不放行
spring-cloud 断路器和spring-cloud-gateway 断路器不同

spring-cloud-gateway使用spring-cloud断路器库，可以在过滤器中使用断路器的功能。  
1. Spring Cloud Gateway内置了断路器filter，
2. 具体做法是使用Spring Cloud断路器的API，将gateway的路由逻辑封装到断路器中
3. 有多个断路器的库都可以用在Spring Cloud Gateway（遗憾的是没有列举是哪些）
4. Resilience4J对Spring Cloud 来说是开箱即用的

## 步骤
1. 增加以下依赖
```xml
<dependency>
	<groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-reactor-resilience4j</artifactId>
</dependency>

```
2. 配置文件
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: circuitbreaker-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/account/**
          filters:
            - name: CircuitBreaker
              args:
                name: myCircuitBreaker
```
3. 配置类如下，这是断路器相关的参数配置：
```java
package com.bolingcavalry.circuitbreakergateway.config;

import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import org.springframework.cloud.circuitbreaker.resilience4j.ReactiveResilience4JCircuitBreakerFactory;
import org.springframework.cloud.circuitbreaker.resilience4j.Resilience4JConfigBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.time.Duration;

@Configuration
public class CustomizeCircuitBreakerConfig {

    @Bean
    public ReactiveResilience4JCircuitBreakerFactory defaultCustomizer() {

        CircuitBreakerConfig circuitBreakerConfig = CircuitBreakerConfig.custom() //
                .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.TIME_BASED) // 滑动窗口的类型为时间窗口
                .slidingWindowSize(10) // 时间窗口的大小为60秒
                .minimumNumberOfCalls(5) // 在单位时间窗口内最少需要5次调用才能开始进行统计计算
                .failureRateThreshold(50) // 在单位时间窗口内调用失败率达到50%后会启动断路器
                .enableAutomaticTransitionFromOpenToHalfOpen() // 允许断路器自动由打开状态转换为半开状态
                .permittedNumberOfCallsInHalfOpenState(5) // 在半开状态下允许进行正常调用的次数
                .waitDurationInOpenState(Duration.ofSeconds(5)) // 断路器打开状态转换为半开状态需要等待60秒
                .recordExceptions(Throwable.class) // 所有异常都当作失败来处理
                .build();

        ReactiveResilience4JCircuitBreakerFactory factory = new ReactiveResilience4JCircuitBreakerFactory();
        factory.configureDefault(id -> new Resilience4JConfigBuilder(id)
                .timeLimiterConfig(TimeLimiterConfig.custom().timeoutDuration(Duration.ofMillis(200)).build())
                .circuitBreakerConfig(circuitBreakerConfig).build());

        return factory;
    }
}
```

4. 增加一个控制器
```java
    @RequestMapping(value = "/account/{id}", method = RequestMethod.GET)
    public String account(@PathVariable("id") int id) throws InterruptedException {
        if(1==id) {
            Thread.sleep(500);
        }

        return Constants.ACCOUNT_PREFIX + dateStr();
    }

```

- 启动网关和hello 工程
- 浏览器访问8081:/account/1,多次刷新。
- 会在控制台看到，返回状态码变成503,这就是网关的短路起作用了。

5. 就是在circuitbreaker-gateway工程中添加一个web接口：作为fallback
```java
RestController
public class Fallback {

    private String dateStr(){
        return new SimpleDateFormat("yyyy-MM-dd hh:mm:ss").format(new Date());
    }

    /**
     * 返回字符串类型
     * @return
     */
    @GetMapping("/myfallback")
    public String helloStr() {
        return "myfallback, " + dateStr();
    }
}
```
application.yml配置如下，可见是给filter增加了fallbackUri属性：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: circuitbreaker-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
            - name: CircuitBreaker
              args:
                name: myCircuitBreaker
                fallbackUri: forward:/myfallback
```
## 原理分析

- gateway 本身没有实现断路器，但可以在过滤器里配置+第三方断路器，实现网关的断路器功能。
- 路由配置中指定了name等于CircuitBreaker，即可对应SpringCloudCircuitBreakerFilterFactory类型的bean
- GatewayResilience4JCircuitBreakerAutoConfiguration中的配置，可以证明SpringCloudCircuitBreakerResilience4JFilterFactory会被实例化并注册到spring：
```java
public class GatewayResilience4JCircuitBreakerAutoConfiguration {

	@Bean
	@ConditionalOnBean(ReactiveResilience4JCircuitBreakerFactory.class)
	@ConditionalOnEnabledFilter
	public SpringCloudCircuitBreakerResilience4JFilterFactory springCloudCircuitBreakerResilience4JFilterFactory(
			ReactiveResilience4JCircuitBreakerFactory reactiveCircuitBreakerFactory,
			ObjectProvider<DispatcherHandler> dispatcherHandler) {
		return new SpringCloudCircuitBreakerResilience4JFilterFactory(
				reactiveCircuitBreakerFactory, dispatcherHandler);
	}

	@Bean
	@ConditionalOnMissingBean
	@ConditionalOnEnabledFilter
	public FallbackHeadersGatewayFilterFactory fallbackHeadersGatewayFilterFactory() {
		return new FallbackHeadersGatewayFilterFactory();
	}

}
```
- 当配置了CircuitBreaker过滤器时，实际上是SpringCloudCircuitBreakerResilience4JFilterFactory类在服务
而关键代码都集中在其父类SpringCloudCircuitBreakerFilterFactory中
-  SpringCloudCircuitBreakerResilience4JFilterFactory