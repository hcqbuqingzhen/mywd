---
title: sc-gateway-06-filters 
date: 2021-12-08 20:22:48
tags: spring-cloud-gateway
---   
# sc-gateway-06-filters 
- 在本系列三中，已经得到了。
- RouteDefinitionRouteLocator核心方法中会获取配置文件中的FilterDefinition，转换成 GatewayFilter。
- 过滤器有两类，一种是默认的，所有的都的走。一种是给路由定义的。如下面所示的过程。
>1. 处理 GatewayProperties 中定义的默认的 FilterDefinition，转换成 GatewayFilter。
> >  转换逻辑
> >1. 根据 filter 名称获取对应的 filter factory。
> >2. 创建一个 config 类对象,产生的参数绑定到 config 对象上。
> >3. 将 cofing 作参数代入，调用 factory 的 applyAsync 方法创建 GatewayFilter 对象。
>2. 将 RouteDefinition 中定义的 FilterDefinition 转换成 GatewayFilter。
>3. 对 GatewayFilter 进行排序。

## 内置的定义过滤器
1. AddRequestHeader
- AddRequestHeader过滤器顾名思义，就是在请求头部添加指定的内容
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
            - AddRequestHeader=x-request-foo, bar-config

```
json
```json
[
    {
        "id": "path_route_addr",
        "uri": "http://127.0.0.1:8082",
        "predicates": [
            {
                "name": "Path",
                "args": {
                    "pattern": "/hello/**"
                }
            }
        ],
        "filters": [
            {
                "name": "AddRequestHeader",
                "args": {
                    "name": "x-request-foo",
                    "value": "bar-dynamic"
                }
            }
        ]
    }
]
```
2. AddRequestParameter
- AddRequestParameter过滤器顾名思义，就是添加请求参数
- 配置如下，服务提供方收到的请求中会多一个参数，名为foo，值为bar-config

```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
            - AddRequestParameter=foo, bar-config

```
json
```json
[
    {
        "id": "path_route_addr",
        "uri": "http://127.0.0.1:8082",
        "predicates": [
            {
                "name": "Path",
                "args": {
                    "pattern": "/hello/**"
                }
            }
        ],
        "filters": [
            {
                "name": "AddRequestParameter",
                "args": {
                    "name": "foo",
                    "value": "bar-dynamic"
                }
            }
        ]
    }
]
```

3. AddResponseHeader
- AddResponseHeader过滤器就是在响应的header中添加参数
- 配置如下，客户端收到的响应，其header中会多一个参数，名为foo，值为bar-config-response：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - AddResponseHeader=foo, bar-config-response
```
json
```json
[
    {
        "id": "path_route_addr",
        "uri": "http://127.0.0.1:8082",
        "predicates": [
            {
                "name": "Path",
                "args": {
                    "pattern": "/hello/**"
                }
            }
        ],
        "filters": [
            {
                "name": "AddResponseHeader",
                "args": {
                    "name": "foo",
                    "value": "bar-dynamic-response"
                }
            }
        ]
    }
]
```
4. DedupeResponseHeader
- 服务提供方返回的response的header中，如果有的key出线了多个value（例如跨域场景下的Access-Control-Allow-Origin），DedupeResponseHeader过滤器可以将重复的value剔除调，剔除策略有三种：RETAIN_FIRST (保留第一个，默认), RETAIN_LAST（保留最后一个）, RETAIN_UNIQUE（去重）
- 配置如下，指定了两个header key的去重，策略是保留最后一个：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin, RETAIN_LAST
```
json
```json

```

5. MapRequestHeader  
MapRequestHeader用于header中的键值对复制，如下配置的意思是：如果请求header中有Blue就新增名为X-Request-Red的key，其值和Blue的值一样  
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - MapRequestHeader=Blue, X-Request-Red

```

6. PrefixPath
- PrefixPath很好理解，就是转发到服务提供者的时候，给path加前缀
- 例如我这边服务提供者原始地址是http://127.0.0.1:8082/hello/str配置如下，如果我给网关配置PrefixPath=hello，那么访问网关的时候，请求路径中就不需要hello了，配置如下：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/str
          filters:
          - PrefixPath=/hello
```
7. PreserveHostHeader
- PreserveHostHeader在转发请求到服务提供者的时候，会保留host信息（否则就只能由HTTP client来决定了）

8. RedirectTo
- RedirectTo的功能简单直白：跳转到指定位置，下面的配置中，uri字段明显是一个无效的地址，但请求还是会被RedirectTo转发到指定位置去：  
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.1.1.1:11111
          predicates:
          - Path=/hello/**
          filters:
          - RedirectTo=302, http://127.0.0.1:8082/hello/str

```
9. RemoveRequestHeader
- RemoveRequestHeader很好理解，删除请求header中的指定值 
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - RemoveRequestHeader=foo

```

10. RemoveResponseHeader
- RemoveResponseHeader删除响应header中的指定值
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - RemoveResponseHeader=foo
```

11. RemoveRequestParameter
- RemoveRequestParameter 删除请求参数中的指定参数
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - RemoveRequestParameter=foo1

```

12. RewritePath
- RewritePath非常实用，将请求参数中的路径做变换
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/test/**
          filters:
          - RewritePath=/test/?(?<segment>.*), /hello/$\{segment}

```

13. RewriteLocationResponseHeader
- RewriteLocationResponseHeader用于改写response中的location信息
- 配置如下，一共是四个参数：stripVersionMode、locationHeaderName、hostValue、protocolsRegex
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: rewritelocationresponseheader_route
        uri: http://example.org
        filters:
        - RewriteLocationResponseHeader=AS_IN_REQUEST, Location, ,
```
- stripVersionMode的策略一共三种：
NEVER_STRIP：不执行
AS_IN_REQUEST ：原始请求没有vesion，就执行
ALWAYS_STRIP ：固定执行
- Location用于替换host:port部分，如果没有就是用Request中的host
- protocolsRegex用于匹配协议，如果匹配不上，name过滤器啥都不做

14. RewriteResponseHeader
- RewriteResponseHeader很好理解：修改响应header，参数有三个：header的key，匹配value的正则表达式，修改value的结果  
- 下面的配置表示修改响应header中X-Response-Red这个key的value，找到password=xxx的内容，改成password=***
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/test/**
          filters:
          - RewriteResponseHeader=X-Response-Red, , password=[^&]+, password=***

```
15. SecureHeaders
SecureHeaders会在响应的header中添加很多和安全相关的内容，配置如下：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
          - Path=/hello/**
          filters:
          - SecureHeaders
```
16. SetPath
- SetPath配合predicates使用，下面的配置会将请求/test/str改成/hello/str，可见这个segment是在predicates中赋值的，然后再filters中拿来用：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      filter:
        secure-headers:
          disable:
            - x-frame-options
            - strict-transport-security
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/test/{segment}
          filters:
            - SetPath=/hello/{segment}
```

17. SetRequestHeader
- SetRequestHeader顾名思义，就是改写请求的header，将指定key改为指定value，如果该key不存在就创建：
- 和SetPath类似，SetRequestHeader也可以和predicates配合，在predicates中定义的变量可以用在SetRequestHeader中，如下所示，当请求是/hello/str的时候，header中X-Request-Red的值就是Blue-str：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      filter:
        secure-headers:
          disable:
            - x-frame-options
            - strict-transport-security
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/{segment}
          filters:
            - SetRequestHeader=X-Request-Red, Blue-{segment}

```
18. SetResponseHeader
- SetResponseHeader顾名思义，就是改写响应的header，将指定key改为指定value，如果该key不存在就创建：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      filter:
        secure-headers:
          disable:
            - x-frame-options
            - strict-transport-security
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
            - SetResponseHeader=X-Request-Red, Blue

```
19. SetStatus
- SetStatus很好理解：控制返回code，下面的设置会返回500：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
            - SetStatus=500

```
20. StripPrefix
- StripPrefix是个很常用的filter，例如请求是/aaa/bbb/hello/str，我们要想将其转为/hello/str，用StripPrefix=2即可，前面两级path都被删掉了：
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      set-status:
        original-status-header-name: aaabbbccc
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/aaa/**
          filters:
            - StripPrefix=2

```
21. Retry
- 顾名思义，Retry就是重试，需要以下参数配合使用：
> retries：重试次数
statuses：遇到什么样的返回状态才重试，取值参考：org.springframework.http.HttpStatus
methods：那些类型的方法会才重试（GET、POST等），取值参考：org.springframework.http.HttpMethod
series：遇到什么样的series值才重试，取值参考：org.springframework.http.HttpStatus.Series
exceptions：遇到什么样的异常才重试
backoff：重试策略，由多个参数构成，例如firstBackoff

```yml
spring:
  cloud:
    gateway:
      routes:
      - id: retry_test
        uri: http://localhost:8080/flakey
        predicates:
        - Host=*.retry.com
        filters:
        - name: Retry
          args:
            retries: 3
            statuses: BAD_GATEWAY
            methods: GET,POST
            backoff:
              firstBackoff: 10ms
              maxBackoff: 50ms
              factor: 2
              basedOnPreviousValue: false

```
22. RequestSize
- RequestSize也很常用：控制请求大小，可以使用KB或者MB等单位，超过这个大小就会返回413错误(Payload Too Large)，
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: request_size_route
        uri: http://localhost:8080/upload
        predicates:
        - Path=/upload
        filters:
        - name: RequestSize
          args:
            maxSize: 5000000
```
23. SetRequestHostHeader
- SetRequestHostHeader会修改请求header中的host值
```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          uri: http://127.0.0.1:8082
          predicates:
            - Path=/hello/**
          filters:
        - name: SetRequestHostHeader
        args:
          host: aaabbb
```
24. ModifyRequestBody
- ModifyRequestBody用于修改请求的body内容，这里官方推荐用代码来配置，如下所示，请求body中原本是字符串，结果被改成了Hello对象的实例：

```java
@Bean
public RouteLocator routes(RouteLocatorBuilder builder) {
    return builder.routes()
        .route("rewrite_request_obj", r -> r.host("*.rewriterequestobj.org")
            .filters(f -> f.prefixPath("/httpbin")
                .modifyRequestBody(String.class, Hello.class, MediaType.APPLICATION_JSON_VALUE,
                    (exchange, s) -> return Mono.just(new Hello(s.toUpperCase())))).uri(uri))
        .build();
}

static class Hello {
    String message;

    public Hello() { }

    public Hello(String message) {
        this.message = message;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
```
25. ModifyResponseBody
- ModifyResponseBody与前面的ModifyRequestBody类似，官方建议用代码实现，下面的代码作用是将响应body的内容改为全部大写：
```java
@Bean
public RouteLocator routes(RouteLocatorBuilder builder) {
    return builder.routes()
        .route("rewrite_response_upper", r -> r.host("*.rewriteresponseupper.org")
            .filters(f -> f.prefixPath("/httpbin")
                .modifyResponseBody(String.class, String.class,
                    (exchange, s) -> Mono.just(s.toUpperCase()))).uri(uri))
        .build();
}
```

26. TokenRelay 这个比较有用
- 在使用第三方鉴权的时候，如OAuth2，用TokenRelay可以将第三方的token转发到服务提供者那里去： 
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: resource
        uri: http://localhost:9000
        predicates:
        - Path=/resource
        filters:
        - TokenRelay=
```
- 记得还要添加jar包依赖org.springframework.boot:spring-boot-starter-oauth2-client
27. 设置全局filter
- 前面的例子中，所有filter都放在路由策略中，配合predicates一起使用的，如果您想配置全局生效的filter，可以在配置文件中做以下设置，下面的配置表示AddResponseHeader和PrefixPath会处理所有请求，和路由设置无关：
```yml
spring:
  cloud:
    gateway:
      default-filters:
      - AddResponseHeader=X-Response-Default-Red, Default-Blue
      - PrefixPath=/httpbin

```
-------------
28. CircuitBreaker
- CircuitBreaker即断路器，咱们在单独的一篇中深入体验这个强大的功能吧
29. FallbackHeaders
- FallbackHeaders一般和CircuitBreaker配合使用，来看下面的配置，发生断路后，请求会被转发FallbackHeaders去处理，此时FallbackHeaders会在header中指定的key上添加异常信息：

```yml
spring:
  cloud:
    gateway:
      routes:
      - id: ingredients
        uri: lb://ingredients
        predicates:
        - Path=//ingredients/**
        filters:
        - name: CircuitBreaker
          args:
            name: fetchIngredients
            fallbackUri: forward:/fallback
      - id: ingredients-fallback
        uri: http://localhost:9994
        predicates:
        - Path=/fallback
        filters:
        - name: FallbackHeaders
          args:
            executionExceptionTypeHeaderName: Test-Header

```