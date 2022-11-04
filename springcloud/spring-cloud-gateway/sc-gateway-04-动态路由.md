---
title: sc-gateway-04-动态路由
date: 2021-12-07 20:22:45
tags: spring-cloud-gateway
---   
# sc-gateway-04-动态路由
## 1 .nacos方式的动态路由
本节为自己实现一个动态路由，方式为nacos.
思路很明确  
- pom文件中引入依赖
```xml
<!--nacos:配置中心-->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
        </dependency>
        <!--nacos:注册中心-->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>

```
1. 写一个类继承RouteDefinitionRepository，实现其中很重要的方法。
```java
/**
 * nacos动态路由类 ，详细原理见。
 * RouteDefinitionRepository 继承了RouteDefinitionLocator ,
 * 1.因此也会被纳入到CompositeRouteDefinitionLocator中。
 * 2.然后经过RouteDefinitionRouteLocator，最终路由都被集成到CachingRouteLocator
 * 3.被RoutePredicateHandlerMapping所使用
 */
@Slf4j
public class NacosRouteDefinitionRepository implements RouteDefinitionRepository {
    //通过此id和组，获取唯一配置文件，
    private static final String SCG_DATA_ID = "sc-gateway-routes";
    private static final String SCG_GROUP_ID = "DEFAULT_GROUP";
    //NacosConfigService 类，通过此类获取配置中心的路由。
    private  String serverAddr;
    private ConfigService nacosConfigService;
    private ApplicationEventPublisher publisher;

    //构造方法注入
    public NacosRouteDefinitionRepository(ApplicationEventPublisher publisher,String serverAddr)  {
        try {
            this.nacosConfigService= NacosFactory.createConfigService(serverAddr);
        }catch (Exception e){
            throw  new RuntimeException(e);
        }
        this.publisher=publisher;
        addListener();//1
    }
    //给nacosConfigService添加监听器，当配置文件更新时触发。
    private void addListener(){
        try {
            //添加一个Listener，
            nacosConfigService.addListener(SCG_DATA_ID,SCG_GROUP_ID,new Listener(){

                @Override
                public Executor getExecutor() {
                    return null;
                }
                //主要重写的方法，当配置更新后，发布一个事件，此事件会触发更新路由。
                @Override
                public void receiveConfigInfo(String s) {
                    publisher.publishEvent(new RefreshRoutesEvent(this));
                }
            });
        }catch (Exception e){
            log.error("NacosRouteDefinitionRepository|addListener:error",e);
        }


    }
    //重写的主要方法，通过此方法刷新路由。
    @SneakyThrows
    @Override
    public Flux<RouteDefinition> getRouteDefinitions() {
        //构造方法中为ConfigService
        //获取注册中心上的配置。
        String config = nacosConfigService.getConfig(SCG_DATA_ID,SCG_GROUP_ID,5000);
        //解析json JsonUtils是一个工具类，主要是使用了jsckson来将json对象化。
        List<RouteDefinition> list = JsonUtils.getList(config, RouteDefinition.class);
        //返回
        for (RouteDefinition routeDefinition : list) {
            System.out.println(routeDefinition);
        }
        return  Flux.fromIterable(list);
    }

    @Override
    public Mono<Void> save(Mono<RouteDefinition> route) {
        return null;
    }

    @Override
    public Mono<Void> delete(Mono<String> routeId) {
        return null;
    }
}
```

2. 写一个配置类，将上述注入为bean.  
   - 为了更便于管理，使用了注解，可以在配置文件中配置是否开启动态路由。

```java
**
 * 将动态路由实现类注入
 * ConditionalOnProperty 当rrs.sc-gateway.dynamicRoute 的enable值为 true时，此类才有效。
 */
@Configuration
@ConditionalOnProperty(prefix = "rrs.sc-gateway.dynamicRoute", name = "enabled", havingValue = "true")
public class DynamicRouteConfig {
    /**
     * @ConditionalOnProperty 当rrs.sc-gateway.dynamicRoute 的from 值为nacos ，此配置类才有效。
     * nacos动态路由实现
     */
    @Configuration
    @ConditionalOnProperty(prefix = "rrs.sc-gateway.dynamicRoute", name = "from", havingValue = "nacos",matchIfMissing = true)
    public class nacosDynamicRoute{
        //server在这里是因为不能在NacosRouteDefinitionRepository的构造方法中赋值。
        @Value("${spring.cloud.nacos.config.server-addr}")
        private String serverAddr;
        @Bean
        public NacosRouteDefinitionRepository nacosRouteDefinitionRepository(ApplicationEventPublisher publisher ) {
            return new NacosRouteDefinitionRepository(publisher,serverAddr);
        }
    }
}

```

3. 配置文件

- 通用配置文件
```properties
  # 默认开发环境
#spring.profiles.active=native

##### spring-boot-actuator配置 可以http访问网关，获取，修改路由。
management.endpoints.web.exposure.include=*
management.endpoint.gateway.enable=true
management.endpoint.health.show-details=always
##### 允许bean覆盖
spring.main.allow-bean-definition-overriding=true

#nacos config配置
spring.cloud.nacos.config.file-extension=yml
spring.cloud.nacos.config.encode=UTF-8
spring.cloud.nacos.config.server-addr=127.0.0.1:8848
#spring.cloud.nacos.config.namespace=dcd551ee-4c0a-46d4-bc74-7289a32909aa
```
- bootstrap.yml
```yml
server:
  #服务端口
  port: 8081

spring:
  application:
    name: sc-gateway
```

- application.yml
```yml
#项目配置，这一部分放nacos上也行，本地 application.yml也行,bootstrap.yml也行 随意。
# 前面说了可以通过配置开启或者关闭（选择哪一种）动态路由。
#还可以实现redis ，mysql,mongodb等方式存储，通过接口来调用，或定时任务半夜刷新。
#直接给接口传字符串似乎也可以。
rrs:
  sc-gateway:
    dynamicRoute:
      enabled: true
      from: nacos
```
- nacos上路由配置文件 sc-gateway-routes
- 注意名字要和NacosRouteDefinitionRepository的文件id相同。
```json
[
    {
        "id": "addr",
        "uri": "http://127.0.0.1:8082",
        "predicates":[
            {
                "name": "Path",
                "args": {
                    "pattern": "/nacos/**"
                }
            }
        ]
    }
]
```
## 2. 一个问题
- 一般来说，本地配置文件和配置中心的配置不同的项可以组合生效，不会覆盖。
- 在本地配置文件中配置了路由，又在nacos的配置文件上配置了路由，这两个路由不会组合生效，而是只会生效一个。配置中心的优先级要高一点。
- 思考了一下，因为路由是一个配置值，也即是同一个配置项。因此会覆盖。

## 3. 