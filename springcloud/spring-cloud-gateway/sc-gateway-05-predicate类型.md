---
title: sc-gateway-05-predicate种类
date: 2021-12-08 20:22:45
tags: spring-cloud-gateway
---   
# sc-gateway-05-predicate类型
- RouteDefinitionRouteLocator 中 根据 predicate 名称获取对应的 predicate factory，使用各种工厂类获取predicate。  
```java
private AsyncPredicate<ServerWebExchange> lookup(RouteDefinition route, PredicateDefinition predicate) {
		RoutePredicateFactory<Object> factory = this.predicates.get(predicate.getName());//1
		if (factory == null) {
			throw new IllegalArgumentException("Unable to find RoutePredicateFactory with name " + predicate.getName());
		}
		if (logger.isDebugEnabled()) {
			logger.debug("RouteDefinition " + route.getId() + " applying " + predicate.getArgs() + " to "
					+ predicate.getName());
		}

		// @formatter:off
		Object config = this.configurationService.with(factory)
				.name(predicate.getName())
				.properties(predicate.getArgs())
				.eventFunction((bound, properties) -> new PredicateArgsEvent(
						RouteDefinitionRouteLocator.this, route.getId(), properties))
				.bind();//2
		// @formatter:on

		return factory.applyAsync(config);//3
```
- 上面代码中，1处就是获取工厂类的过程。方法的最后获取AsyncPredicate 对象，然后组成route。  

## predicate类型
1. After  
- 对应工厂类 AfterRoutePredicateFactory
- 以下的工厂类都类似，只是前缀不同。  
- After表示路由在指定时间之后才生效  
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: after_route
        uri: http://127.0.0.1:8082
        predicates:
        - After=2021-08-16T07:36:00.000+08:00[Asia/Shanghai]
```
对应json
```json
[
    {
        "id": "after_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "After",
                "args": {
                    "datetime": "2021-08-16T07:36:00.000+08:00[Asia/Shanghai]"
                }
            }
        ]
    }
]
```

2. Before 
- Before表示路由在指定时间之前才生效
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: before_route
        uri: http://127.0.0.1:8082
        predicates:
        - Before=2021-08-16T07:36:00.000+08:00[Asia/Shanghai]
```
json
```json
[
    {
        "id": "before_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Before",
                "args": {
                    "datetime": "2021-08-16T07:36:00.000+08:00[Asia/Shanghai]"
                }
            }
        ]
    }
]
```

3. Between
- Between表示路由在指定时间段之内才生效，既然是时间段就是两个参数，注意它们的写法
```yml
spring:
  application:
    name: hello-gateway
  cloud:
    gateway:
      routes:
        - id: between_route
          uri: http://127.0.0.1:8082
          predicates:
            - Between=2021-08-16T07:36:00.000+08:00[Asia/Shanghai], 2021-08-16T08:15:00.000+08:00[Asia/Shanghai]
```

json
```json
[
    {
        "id": "path_route_addr",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Between",
                "args": {
                    "datetime1": "2021-08-16T07:36:00.000+08:00[Asia/Shanghai]",
                    "datetime2": "2021-08-16T08:18:00.000+08:00[Asia/Shanghai]"
                }
            }
        ]
    }
]
```

4. Cookie
- Cookie表示cookie存在指定名称，并且对应的值符合指定正则表达式，才算匹配成功
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: cookie_route
        uri: https://example.org
        predicates:
        - Cookie=chocolate, ch.p
```
json
```json

[
    {
        "id": "cookie_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Cookie",
                "args": {
                	"name": "chocolate",
                    "regexp": "ch.p"
                }
            }
        ]
    }
]

```
5. Header
- Header表示header存在指定名称，并且对应的值符合指定正则表达式，才算匹配成功
- 下面的例子要求header中必须存在X-Request-Id，并且值一定要是数字
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: header_route
        uri: https://example.org
        predicates:
        - Header=X-Request-Id, \d+

```
json
```json
[
    {
        "id": "header_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Header",
                "args": {
                    "header": "X-Request-Id",
                    "regexp": "\\d+"
                }
            }
        ]
    }
]

```
6. Host
- Host表示请求的host要和指定的字符串匹配，并且对应的值符合指定正则表达式，才算匹配成功，可以同时指定多个host匹配表达式，下面的例子给了两个，其中第一个指定了端口

```yml
spring:
  cloud:
    gateway:
      routes:
      - id: host_route
        uri: http://127.0.0.1:8082
        predicates:
        - Host=test.com:8081,**.anotherhost.org
```
json
```json
[
    {
        "id": "header_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Host",
                "args": {
                    "regex": "test.com:8086"
                }
            }
        ]
    }
]

```

7. Method
- Method非常好理解，匹配指定的方法类型（可以有多个）
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: method_route
        uri: http://127.0.0.1:8082
        predicates:
        - Method=GET,POST
```
json
```json
[
    {
        "id": "method_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Method",
                "args": { 
                    "methods": "GET"
                }
            }
        ]
    }
]
```
8. Path
- Path很常用，匹配指定的方法类型（可以有多个）
- 配置文件，注意{segment}，表示该位置的真实值可以被提取出来，在filter中可以使用，这在后续的filter文章中会有说明：
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: path_route
        uri: http://127.0.0.1:8082
        predicates:
        - Path=/hello/{segment},/lbtest/{segment}
```
json
```json
[
    {
        "id": "path_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Path",
                "args": { 
                    "pattern": "/hello/{segment}"
                }
            }
        ]
    }
]

```
9. Query
- Query匹配的是请求中是否带有指定的参数，也能要求该参数等于指定的值（正则表达式）才被匹配上  
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: query_route
        uri: http://127.0.0.1:8082
        predicates:
        - Query=name

```
json
```json
spring:
  cloud:
    gateway:
      routes:
      - id: query_route
        uri: http://127.0.0.1:8082
        predicates:
        - Query=name
```
json
```json
[
    {
        "id": "query_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Query",
                "args": { 
                    "param": "name",
                    "regexp": "aaa."
                }
            }
        ]
    }
]
```
10. RemoteAddr
- RemoteAddr很好理解，匹配的指定来源的请求
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: remoteaddr_route
        uri: http://127.0.0.1:8082
        predicates:
        - RemoteAddr=192.168.50.134/24
```
json
```json
[
    {
        "id": "remoteaddr_route",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "RemoteAddr",
                "args": { 
                    "sources": "192.168.50.134/24"
                }
            }
        ]
    }
]
```
11. Weight
- Weight顾名思义，按照权重将请求分发到不同位置
```yml
spring:
  cloud:
    gateway:
      routes:
      - id: weight_high
        uri: http://192.168.50.134:8082
        predicates:
        - Weight=group1, 8
      - id: weight_low
        uri: http://192.168.50.135:8082
        predicates:
        - Weight=group1, 2

```
json 
```json

```