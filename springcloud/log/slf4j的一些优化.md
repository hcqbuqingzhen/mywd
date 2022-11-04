 
# 日志中的一些定制化
>在之前的项目中对于日志的处理,一直没有总结,所以这里做一下总结.大致的需求如下.
>1. 微服务的链路调用日志怎么处理,异步的情况下(线程池)如何传给子线程,如scg本身就是异步的.
>2. 比如我们后台管理的操作日志(也可以叫做审计日志),这部分日志想要入数据库或者es,该怎么操作.
>3. 或者有一些埋点日至,方便我们快速定位出现bug的地方,埋点日志希望按照一定的格式存储.

## 1. 链路日志的处理
>虽然链路日志有Sleuth可以很好的嵌入cloud,但这次先不使用sleuth来处理.

问题如下:
1. API网关中的MDC数据如何传递给下游服务
2. 服务如何接收数据，并且调用其他远程服务时如何继续传递
3. 异步的情况下(线程池)如何传给子线程

### 1.1 API网关中的MDC数据如何传递给下游服务
>mdc是什么:Mapped Diagnostic Contexts ,翻译过来就是：映射的诊断上下文 。意思是：在日志中 （映射的） 请求ID（requestId），可以作为我们定位 （诊断） 问题的关键字 （上下文）。
>Slf4j MDC 内部实现很简单。实现一个单例对应实例，获取具体的MDC实现类，然后其对外接口，就是对参数进行校验，然后调用 MDCAdapter 的方法实现。MDCAdapter 是个接口类，当日志框架使用 Logback 时，对应接口的实现类就是 LogbackMDCAdapter，所以核心的实现类还是它，对于需要子父线程的传递 我们可以重写这个类,来替换.
- 对于scg网关
可以写一个全局过滤器
```java
/**
 * 生成日志链路追踪id，并传入header中
 *
 */
@Component
public class TraceFilter implements GlobalFilter, Ordered {
    @Autowired
    private TraceProperties traceProperties;

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (traceProperties.getEnable()) {
            //链路追踪id
            String traceId = IdUtil.fastSimpleUUID();
            //
            MDC.put(CommonConstant.LOG_TRACE_ID, traceId);
            ServerHttpRequest serverHttpRequest = exchange.getRequest().mutate()
                    .headers(h -> h.add(CommonConstant.TRACE_ID_HEADER, traceId))
                    .build();

            ServerWebExchange build = exchange.mutate().request(serverHttpRequest).build();
            return chain.filter(build);
        }
        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
```

- 对于zuul

```java
/**
 * 生成日志链路追踪id，并传入header中
 *
 */
@Component
public class TraceFilter extends ZuulFilter {
    @Autowired
    private TraceProperties traceProperties;

    @Override
    public String filterType() {
        return FilterConstants.PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return FORM_BODY_WRAPPER_FILTER_ORDER - 1;
    }

    @Override
    public boolean shouldFilter() {
        //根据配置控制是否开启过滤器
        return traceProperties.getEnable();
    }

    @Override
    public Object run() {
        //链路追踪id
        String traceId = IdUtil.fastSimpleUUID();
        MDC.put(CommonConstant.LOG_TRACE_ID, traceId);
        RequestContext ctx = RequestContext.getCurrentContext();
        ctx.addZuulRequestHeader(CommonConstant.TRACE_ID_HEADER, traceId);
        return null;
    }
}
```

上面两个是放在对应的网关的目录下.

- 其他对日志的封装,我们抽取出一个配置包. log-spring-boot-start

pom文件
```xml
<dependencies>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-api</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-context</artifactId>
        </dependency>
        <!--增强thread-local-->
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>transmittable-thread-local</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-configuration-processor</artifactId>
            <optional>true</optional>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-aop</artifactId>
        </dependency>
        <dependency>
            <groupId>cn.hutool</groupId>
            <artifactId>hutool-all</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-web</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>javax.servlet-api</artifactId>
            <optional>true</optional>
        </dependency>
        <!--日至入库-->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
            <optional>true</optional>
        </dependency>
        <!--dubbo 可能会有链路日至相关-->
        <dependency>
            <groupId>org.apache.dubbo</groupId>
            <artifactId>dubbo</artifactId>
            <optional>true</optional>
        </dependency>
        <!--openfeign 也是链路日至相关-->
        <dependency>
            <groupId>io.github.openfeign</groupId>
            <artifactId>feign-core</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.apache.dubbo</groupId>
            <artifactId>dubbo</artifactId>
            <version>2.7.8</version>
        </dependency>
    </dependencies>
```

对应配置类
TraceProperties
```java
package com.rrs.log.properties;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;

@Setter
@Getter
@ConfigurationProperties(prefix = "rrs.trace")
@RefreshScope
public class TraceProperties {
    /**
     * 是否开启日志链路追踪
     */
    private Boolean enable = false;
}

```
LogAutoConfigure

```java
package com.rrs.log.config;

import com.rrs.log.properties.TraceProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties({TraceProperties.class})
public class LogAutoConfigure {
    //可以在这配置
}
```

在网关引入我们的配置包,开启链路日志后就能将tracid传给下游了.
### 1.2 服务如何接收数据，并且调用其他远程服务时如何继续传递

- 对于服务接收tracid,可以加一个过滤器.

```java
package com.rrs.log.filter;

import com.rrs.log.properties.TraceProperties;
import com.rrs.log.util.MDCTraceUtils;
import org.apache.commons.lang3.StringUtils;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.core.annotation.Order;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.annotation.Resource;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 过滤器 接收上游传递过来的traceid
 */
@ConditionalOnClass(value = {HttpServletRequest.class, OncePerRequestFilter.class})
@Order(value = MDCTraceUtils.FILTER_ORDER)
public class WebTraceFilter extends OncePerRequestFilter {

    @Resource
    private TraceProperties traceProperties;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !traceProperties.getEnable();
    }

    //接收traceid 设置到mdc中
    @Override
    protected void doFilterInternal(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, FilterChain filterChain) throws ServletException, IOException {
        try {
            String traceId=httpServletRequest.getHeader(MDCTraceUtils.TRACE_ID_HEADER);
            if(StringUtils.isEmpty(traceId)){
                MDCTraceUtils.addTraceId();
            }else {
                MDCTraceUtils.putTraceId(traceId);
            }
            filterChain.doFilter(httpServletRequest,httpServletResponse);
        }finally {
            //这里为什么要remove呢?
            MDCTraceUtils.removeTraceId();
        }
    }
}

```

- 向下游传递traceid,可以加一个feign的拦截器.

```java
package com.rrs.log.interceptor;

import com.rrs.log.properties.TraceProperties;
import com.rrs.log.util.MDCTraceUtils;
import feign.RequestInterceptor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.context.annotation.Bean;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;

/**
 * 服务之间调用 拦截增加traceid
 */
@ConditionalOnClass(value = {RequestInterceptor.class})
public class FeignTraceInterceptor {
    @Resource
    private TraceProperties traceProperties;

    @Bean
    public RequestInterceptor feignTraceInterceptor() {
        return template -> {
            if (traceProperties.getEnable()) {
                //传递日志traceId
                String traceId = MDCTraceUtils.getTraceId();
                if (!StringUtils.isEmpty(traceId)) {
                    template.header(MDCTraceUtils.TRACE_ID_HEADER, traceId);
                }
            }
        };
    }
}

```
### 1.3 traceid在父子线程之间的传递
解决父子线程传递问题,重写logback的LogbackMDCAdapte
```java
package org.slf4j;

import com.alibaba.ttl.TransmittableThreadLocal;
import org.slf4j.spi.MDCAdapter;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * TransmittableThreadLocal替换LogbackMDCAdapter中的ThreadLocal
 * 实现子父线程的日志信息传递
 */
public class TtlMDCAdapter implements MDCAdapter {
    private final ThreadLocal<Map<String, String>> copyOnInheritThreadLocal = new TransmittableThreadLocal<>();

    private static final int WRITE_OPERATION = 1;
    private static final int MAP_COPY_OPERATION = 2;

    private static TtlMDCAdapter mtcMDCAdapter;
    /**
     * keeps track of the last operation performed
     */
    private final ThreadLocal<Integer> lastOperation = new ThreadLocal<>();

    static {
        mtcMDCAdapter = new TtlMDCAdapter();
        MDC.mdcAdapter = mtcMDCAdapter;
    }

    public static MDCAdapter getInstance() {
        return mtcMDCAdapter;
    }

    private Integer getAndSetLastOperation(int op) {
        Integer lastOp = lastOperation.get();
        lastOperation.set(op);
        return lastOp;
    }

    private static boolean wasLastOpReadOrNull(Integer lastOp) {
        return lastOp == null || lastOp == MAP_COPY_OPERATION;
    }

    private Map<String, String> duplicateAndInsertNewMap(Map<String, String> oldMap) {
        Map<String, String> newMap = Collections.synchronizedMap(new HashMap<>());
        if (oldMap != null) {
            // we don't want the parent thread modifying oldMap while we are
            // iterating over it
            synchronized (oldMap) {
                newMap.putAll(oldMap);
            }
        }

        copyOnInheritThreadLocal.set(newMap);
        return newMap;
    }

    /**
     * Put a context value (the <code>val</code> parameter) as identified with the
     * <code>key</code> parameter into the current thread's context map. Note that
     * contrary to log4j, the <code>val</code> parameter can be null.
     * <p/>
     * <p/>
     * If the current thread does not have a context map it is created as a side
     * effect of this call.
     *
     * @throws IllegalArgumentException in case the "key" parameter is null
     */
    @Override
    public void put(String key, String val) {
        if (key == null) {
            throw new IllegalArgumentException("key cannot be null");
        }

        Map<String, String> oldMap = copyOnInheritThreadLocal.get();
        Integer lastOp = getAndSetLastOperation(WRITE_OPERATION);

        if (wasLastOpReadOrNull(lastOp) || oldMap == null) {
            Map<String, String> newMap = duplicateAndInsertNewMap(oldMap);
            newMap.put(key, val);
        } else {
            oldMap.put(key, val);
        }
    }

    /**
     * Remove the the context identified by the <code>key</code> parameter.
     * <p/>
     */
    @Override
    public void remove(String key) {
        if (key == null) {
            return;
        }
        Map<String, String> oldMap = copyOnInheritThreadLocal.get();
        if (oldMap == null) {
            return;
        }

        Integer lastOp = getAndSetLastOperation(WRITE_OPERATION);

        if (wasLastOpReadOrNull(lastOp)) {
            Map<String, String> newMap = duplicateAndInsertNewMap(oldMap);
            newMap.remove(key);
        } else {
            oldMap.remove(key);
        }

    }


    /**
     * Clear all entries in the MDC.
     */
    @Override
    public void clear() {
        lastOperation.set(WRITE_OPERATION);
        copyOnInheritThreadLocal.remove();
    }

    /**
     * Get the context identified by the <code>key</code> parameter.
     * <p/>
     */
    @Override
    public String get(String key) {
        final Map<String, String> map = copyOnInheritThreadLocal.get();
        if ((map != null) && (key != null)) {
            return map.get(key);
        } else {
            return null;
        }
    }

    /**
     * Get the current thread's MDC as a map. This method is intended to be used
     * internally.
     */
    public Map<String, String> getPropertyMap() {
        lastOperation.set(MAP_COPY_OPERATION);
        return copyOnInheritThreadLocal.get();
    }

    /**
     * Returns the keys in the MDC as a {@link Set}. The returned value can be
     * null.
     */
    public Set<String> getKeys() {
        Map<String, String> map = getPropertyMap();

        if (map != null) {
            return map.keySet();
        } else {
            return null;
        }
    }

    /**
     * Return a copy of the current thread's context map. Returned value may be
     * null.
     */
    @Override
    public Map<String, String> getCopyOfContextMap() {
        Map<String, String> hashMap = copyOnInheritThreadLocal.get();
        if (hashMap == null) {
            return null;
        } else {
            return new HashMap<>(hashMap);
        }
    }

    @Override
    public void setContextMap(Map<String, String> contextMap) {
        lastOperation.set(WRITE_OPERATION);

        Map<String, String> newMap = Collections.synchronizedMap(new HashMap<>());
        newMap.putAll(contextMap);

        // the newMap replaces the old one for serialisation's sake
        copyOnInheritThreadLocal.set(newMap);
    }
}

```

TtlMDCAdapterInitializer类用于程序启动时加载自己的mdcAdapter实现 

```java
package com.rrs.log.config;

import org.slf4j.TtlMDCAdapter;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;

/**
 * 继承ApplicationContextInitializer spring初始化
 * 初始化TtlMDCAdapter实例，并替换MDC中的adapter对象
 */
public class TtlMDCAdapterInitializer implements ApplicationContextInitializer<ConfigurableApplicationContext> {
    @Override
    public void initialize(ConfigurableApplicationContext applicationContext) {
        //加载TtlMDCAdapter实例
        TtlMDCAdapter.getInstance();
    }
}
```

## 2. 审计日志处理
>对于这种重要的操作日志,我们想要使用一个注解在某一个某个重要的方法上,就可以自动实现操作的入库.

### 2.1 定义审计信息

```java
public class Audit {
    /**
     * 操作时间
     */
    private LocalDateTime timestamp;
    /**
     * 应用名
     */
    private String applicationName;
    /**
     * 类名
     */
    private String className;
    /**
     * 方法名
     */
    private String methodName;
    /**
     * 用户id
     */
    private String userId;
    /**
     * 用户名
     */
    private String userName;
    /**
     * 租户id,可以改为其他字段.
     */
    private String clientId;
    /**
     * 操作信息
     */
    private String operation;
}
```

### 2.2 增加可配置项
```java
package com.rrs.log.properties;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.cloud.context.config.annotation.RefreshScope;

@Setter
@Getter
@ConfigurationProperties(prefix = "rrs.audit-log")
@RefreshScope
public class AuditLogProperties {
    /**
     * 是否开启审计日志
     */
    private Boolean enabled = false;
    /**
     * 日志记录类型(logger/redis/db/es/kafka/mq)
     */
    private String logType;
}
```

```java
/**
 * 日志数据源配置
 * logType=db时生效(非必须)，如果不配置则使用当前数据源
 * 我认为一般要配置,毕竟不希望每个fuwu dou jia yige xin de biao .
 */
@Setter
@Getter
@ConfigurationProperties(prefix = "rrs.audit-log.datasource")
public class LogDbProperties extends HikariConfig {
    /**
     * jdbc url
     * 审计日志需要的配置
     */
    private String jdbcUrl ;
        /**
     * name
     */
    private volatile String username;
    /**
     * password
     */
    private volatile String password;
    /**
     * qudong 
     */
    private String driverClassName;
}

```

此时配置类
LogAutoConfigure
```java
@Configuration
@EnableConfigurationProperties({TraceProperties.class, AuditLogProperties.class, LogDbProperties.class})
public class LogAutoConfigure {
    //可以在这配置
}

```

### 2.3 增加数据库服务类

```java
/**
 * 审计日志接口
 *
 */
public interface IAuditService {
    void save(Audit audit);
}
```
DbAuditServiceImpl
```java
package com.rrs.log.service.impl;

import com.rrs.log.model.Audit;
import com.rrs.log.properties.LogDbProperties;
import com.rrs.log.service.IAuditService;
import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Async;

import javax.annotation.PostConstruct;
import javax.sql.DataSource;

/**
 * 审计日志实现类-数据库
 */
@Slf4j
@ConditionalOnProperty(name = "rrs.audit-log.log-type", havingValue = "db")
@ConditionalOnClass(JdbcTemplate.class)
public class DbAuditServiceImpl implements IAuditService {
    private static final String INSERT_SQL = " insert into sys_logger " +
            " (application_name, class_name, method_name, user_id, user_name, client_id, operation, timestamp) " +
            " values (?,?,?,?,?,?,?,?)";

    private final JdbcTemplate jdbcTemplate;

    public DbAuditServiceImpl(@Autowired(required = false) LogDbProperties logDbProperties, DataSource dataSource) {
        //优先使用配置的日志数据源，否则使用默认的数据源
        if (logDbProperties != null && StringUtils.isNotEmpty(logDbProperties.getJdbcUrl())) {
            dataSource = new HikariDataSource(logDbProperties);
        }
        this.jdbcTemplate = new JdbcTemplate(dataSource);
    }

    @PostConstruct
    public void init() {
        String sql = "CREATE TABLE IF NOT EXISTS `sys_logger`  (\n" +
                "  `id` int(11) NOT NULL AUTO_INCREMENT,\n" +
                "  `application_name` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '应用名',\n" +
                "  `class_name` varchar(128) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '类名',\n" +
                "  `method_name` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '方法名',\n" +
                "  `user_id` int(11) NULL COMMENT '用户id',\n" +
                "  `user_name` varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '用户名',\n" +
                "  `client_id` varchar(32) CHARACTER SET utf8 COLLATE utf8_general_ci NULL COMMENT '租户id',\n" +
                "  `operation` varchar(1024) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '操作信息',\n" +
                "  `timestamp` varchar(30) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '创建时间',\n" +
                "  PRIMARY KEY (`id`) USING BTREE\n" +
                ") ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;";
        this.jdbcTemplate.execute(sql);
    }

    @Async
    @Override
    public void save(Audit audit) {
        this.jdbcTemplate.update(INSERT_SQL
                , audit.getApplicationName(), audit.getClassName(), audit.getMethodName()
                , audit.getUserId(), audit.getUserName(), audit.getClientId()
                , audit.getOperation(), audit.getTimestamp());
    }
}

```
- 增加打印到文件实现类

```java
/**
 * 审计日志实现类-打印日志
 */
@Slf4j
@ConditionalOnProperty(name = "rrs.audit-log.log-type", havingValue = "logger", matchIfMissing = true)
public class LoggerAuditServiceImpl implements IAuditService {
    private static final String MSG_PATTERN = "{}|{}|{}|{}|{}|{}|{}|{}";

    /**
     * 格式为：{时间}|{应用名}|{类名}|{方法名}|{用户id}|{用户名}|{租户id}|{操作信息}
     * 例子：2020-02-04 09:13:34.650|user-center|com.central.user.controller.SysUserController|saveOrUpdate|1|admin|webApp|新增用户:admin
     */
    @Override
    public void save(Audit audit) {
        log.debug(MSG_PATTERN
                , audit.getTimestamp().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS"))
                , audit.getApplicationName(), audit.getClassName(), audit.getMethodName()
                , audit.getUserId(), audit.getUserName(), audit.getClientId()
                , audit.getOperation());
    }
}
```
注解类
```java
package com.rrs.log.annotation;

import java.lang.annotation.*;

/**
 * 
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface AuditLog {
    /**
     * 操作信息
     */
    String operation();
}

```
### 2.4 切面类
>实现加注解自动将审计日志入库.

```java
package com.rrs.log.aspect;

import com.rrs.log.annotation.AuditLog;
import com.rrs.log.model.Audit;
import com.rrs.log.properties.AuditLogProperties;
import com.rrs.log.service.IAuditService;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.core.DefaultParameterNameDiscoverer;
import org.springframework.expression.EvaluationContext;
import org.springframework.expression.Expression;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.expression.spel.support.StandardEvaluationContext;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.time.LocalDateTime;

/**
 * 审计日志切面
 */
@Slf4j
@Aspect
@ConditionalOnClass({HttpServletRequest.class, RequestContextHolder.class})
public class AuditLogAspect {
    @Value("${spring.application.name}")
    private String applicationName;

    private AuditLogProperties auditLogProperties;
    private IAuditService auditService;
    public AuditLogAspect(AuditLogProperties auditLogProperties, IAuditService auditService) {
        this.auditLogProperties = auditLogProperties;
        this.auditService = auditService;
    }

    /**
     * 用于SpEL表达式解析.
     */
    private SpelExpressionParser spelExpressionParser = new SpelExpressionParser();
    /**
     * 用于获取方法参数定义名字.
     */
    private DefaultParameterNameDiscoverer nameDiscoverer = new DefaultParameterNameDiscoverer();

    //这里使用@within是可以通过aop拦截类上的注解。而@annotation是通过aop拦截方法上的注解。
    @Before("@within(auditLog) || @annotation(auditLog)")
    public void beforeMethod(JoinPoint joinPoint, AuditLog auditLog) {
        //判断功能是否开启
        if (auditLogProperties.getEnabled()) {
            if (auditService == null) {
                log.warn("AuditLogAspect - auditService is null");
                return;
            }
            if (auditLog == null) {
                // 获取类上的注解
                auditLog = joinPoint.getTarget().getClass().getDeclaredAnnotation(AuditLog.class);
            }
            Audit audit = getAudit(auditLog, joinPoint);
            auditService.save(audit);
        }
    }


    /**
     * 解析spEL表达式
     */
    private String getValBySpEL(String spEL, MethodSignature methodSignature, Object[] args) {
        //获取方法形参名数组
        String[] paramNames = nameDiscoverer.getParameterNames(methodSignature.getMethod());
        if (paramNames != null && paramNames.length > 0) {
            Expression expression = spelExpressionParser.parseExpression(spEL);
            // spring的表达式上下文对象
            EvaluationContext context = new StandardEvaluationContext();
            // 给上下文赋值
            for(int i = 0; i < args.length; i++) {
                context.setVariable(paramNames[i], args[i]);
            }
            return expression.getValue(context).toString();
        }
        return null;
    }


    /**
     * 构建审计对象
     */
    private Audit getAudit(AuditLog auditLog, JoinPoint joinPoint) {
        Audit audit = new Audit();
        audit.setTimestamp(LocalDateTime.now());
        audit.setApplicationName(applicationName);
        MethodSignature methodSignature = (MethodSignature)joinPoint.getSignature();
        audit.setClassName(methodSignature.getDeclaringTypeName());
        audit.setMethodName(methodSignature.getName());

        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = attributes.getRequest();
        String userId = request.getHeader("x-userid-header");
        String userName = request.getHeader("x-user-header");
        String clientId = request.getHeader("x-tenant-header");
        audit.setUserId(userId);
        audit.setUserName(userName);
        audit.setClientId(clientId);

        String operation = auditLog.operation();
        //一般我们没有加# 里面就是自定义的操作描述.如果加了# 说明审计日志中需要包含方法参数.
        if (operation.contains("#")) {
            //获取方法的参数
            Object[] args = joinPoint.getArgs();
            //使用spel表达式构建字符串
            operation = getValBySpEL(operation, methodSignature, args);
        }
        audit.setOperation(operation);

        return audit;
    }
}
```

当然我们也可以实现es存储,直接发送到卡夫卡,mq,es聚合队列等.

## 3. 埋点日志工具类

```java
package com.rrs.log.util;

import cn.hutool.core.util.ReflectUtil;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.ObjectUtils;

import java.lang.reflect.Field;
import java.util.Iterator;
import java.util.Map;

/**
 * 日志埋点工具类
 */
@Slf4j
public class PointUtil {
    private static final String MSG_PATTERN = "{}|{}|{}";
    private static final String PROPERTIES_SPLIT = "&";
    private static final String PROPERTIES_VALUE_SPLIT = "=";

    private final PointEntry pointEntry;

    private PointUtil() {
        pointEntry = new PointEntry();
    }

    @Setter
    @Getter
    private class PointEntry {
        String id;
        String type;
        Object properties;
    }

    /**
     * 格式为：{时间}|{来源}|{对象id}|{类型}|{对象属性(以&分割)}
     * 例子1：2016-07-27 23:37:23|business-center|1|user-login|ip=xxx.xxx.xx&userName=张三&userType=后台管理员
     * 例子2：2016-07-27 23:37:23|file-center|c0a895e114526786450161001d1ed9|file-upload|fileName=xxx&filePath=xxx
     *
     * @param id      对象id
     * @param type    类型
     * @param message 对象属性
     */
    public static void info(String id, String type, String message) {
        log.info(MSG_PATTERN, id, type, message);
    }

    public static void debug(String id, String type, String message) {
        log.debug(MSG_PATTERN, id, type, message);
    }

    public static PointUtil builder() {
        return new PointUtil();
    }

    /**
     * @param businessId 业务id/对象id
     */
    public PointUtil id(Object businessId) {
        this.pointEntry.setId(String.valueOf(businessId));
        return this;
    }

    /**
     * @param type 类型
     */
    public PointUtil type(String type) {
        this.pointEntry.setType(type);
        return this;
    }

    /**
     * @param properties 对象属性
     */
    public PointUtil properties(Object properties) {
        this.pointEntry.setProperties(properties);
        return this;
    }

    private String getPropertiesStr() {
        Object properties = this.pointEntry.getProperties();
        StringBuilder result = new StringBuilder();
        if (!ObjectUtils.isEmpty(properties)) {
            //解析map
            if (properties instanceof Map) {
                Map proMap = (Map)properties;
                Iterator<Map.Entry> ite = proMap.entrySet().iterator();
                while (ite.hasNext()) {
                    Map.Entry entry = ite.next();
                    if (result.length() > 0) {
                        result.append(PROPERTIES_SPLIT);
                    }
                    result.append(entry.getKey()).append(PROPERTIES_VALUE_SPLIT).append(entry.getValue());
                }
            } else {//解析对象
                Field[] allFields = ReflectUtil.getFields(properties.getClass());
                for (Field field : allFields) {
                    String fieldName = field.getName();
                    Object fieldValue = ReflectUtil.getFieldValue(properties, field);
                    if (result.length() > 0) {
                        result.append(PROPERTIES_SPLIT);
                    }
                    result.append(fieldName).append(PROPERTIES_VALUE_SPLIT).append(fieldValue);
                }
            }
        }
        return result.toString();
    }

    public void build() {
        PointUtil.debug(this.pointEntry.getId(), this.pointEntry.getType(), this.getPropertiesStr());
    }
}
```

与整体相配的log. xml文件如下.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <contextName>${APP_NAME}</contextName>
    <springProperty name="APP_NAME" scope="context" source="spring.application.name"/>
    <springProperty name="LOG_FILE" scope="context" source="logging.file" defaultValue="../logs/application/${APP_NAME}"/>
    <springProperty name="LOG_POINT_FILE" scope="context" source="logging.file" defaultValue="../logs/point"/>
    <springProperty name="LOG_AUDIT_FILE" scope="context" source="logging.file" defaultValue="../logs/audit"/>
    <springProperty name="LOG_MAXFILESIZE" scope="context" source="logback.filesize" defaultValue="50MB"/>
    <springProperty name="LOG_FILEMAXDAY" scope="context" source="logback.filemaxday" defaultValue="7"/>
    <springProperty name="ServerIP" scope="context" source="spring.cloud.client.ip-address" defaultValue="0.0.0.0"/>
    <springProperty name="ServerPort" scope="context" source="server.port" defaultValue="0000"/>

    <!-- 彩色日志 -->
    <!-- 彩色日志依赖的渲染类 -->
    <conversionRule conversionWord="clr" converterClass="org.springframework.boot.logging.logback.ColorConverter" />
    <conversionRule conversionWord="wex" converterClass="org.springframework.boot.logging.logback.WhitespaceThrowableProxyConverter" />
    <conversionRule conversionWord="wEx" converterClass="org.springframework.boot.logging.logback.ExtendedWhitespaceThrowableProxyConverter" />

    <!-- 彩色日志格式 -->
    <property name="CONSOLE_LOG_PATTERN"
              value="[${APP_NAME}:${ServerIP}:${ServerPort}] %clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} %clr(%level){blue} %clr(${PID}){magenta} %clr([%X{traceId}]){yellow} %clr([%thread]){orange} %clr(%-40.40logger{39}){cyan} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}" />
    <property name="CONSOLE_LOG_PATTERN_NO_COLOR" value="[${APP_NAME}:${ServerIP}:${ServerPort}] %d{yyyy-MM-dd HH:mm:ss.SSS} %level ${PID} [%X{traceId}] [%thread] %-40.40logger{39} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}" />

    <!-- 控制台日志 -->
    <appender name="StdoutAppender" class="ch.qos.logback.core.ConsoleAppender">
        <withJansi>true</withJansi>
        <encoder>
            <pattern>${CONSOLE_LOG_PATTERN}</pattern>
            <charset>UTF-8</charset>
        </encoder>
    </appender>
    <!-- 按照每天生成常规日志文件 -->
    <appender name="FileAppender" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_FILE}/${APP_NAME}.log</file>
        <encoder>
            <pattern>${CONSOLE_LOG_PATTERN_NO_COLOR}</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <!-- 基于时间的分包策略 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_FILE}/${APP_NAME}.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!--保留时间,单位:天-->
            <maxHistory>${LOG_FILEMAXDAY}</maxHistory>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>${LOG_MAXFILESIZE}</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>INFO</level>
        </filter>
    </appender>

    <appender name="point_log" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_POINT_FILE}/point.log</file>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS}|${APP_NAME}|%msg%n</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <!-- 基于时间的分包策略 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_POINT_FILE}/point.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!--保留时间,单位:天-->
            <maxHistory>${LOG_FILEMAXDAY}</maxHistory>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>${LOG_MAXFILESIZE}</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
    </appender>

    <appender name="audit_log" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_AUDIT_FILE}/audit.log</file>
        <encoder>
            <pattern>%msg%n</pattern>
            <charset>UTF-8</charset>
        </encoder>
        <!-- 基于时间的分包策略 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_AUDIT_FILE}/audit.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <!--保留时间,单位:天-->
            <maxHistory>${LOG_FILEMAXDAY}</maxHistory>
            <timeBasedFileNamingAndTriggeringPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedFNATP">
                <maxFileSize>${LOG_MAXFILESIZE}</maxFileSize>
            </timeBasedFileNamingAndTriggeringPolicy>
        </rollingPolicy>
    </appender>

    <appender name="point_log_async" class="ch.qos.logback.classic.AsyncAppender">
        <discardingThreshold>0</discardingThreshold>
        <appender-ref ref="point_log"/>
    </appender>
    <appender name="file_async" class="ch.qos.logback.classic.AsyncAppender">
        <discardingThreshold>0</discardingThreshold>
        <appender-ref ref="FileAppender"/>
    </appender>
    <appender name="audit_log_async" class="ch.qos.logback.classic.AsyncAppender">
        <discardingThreshold>0</discardingThreshold>
        <appender-ref ref="audit_log"/>
    </appender>
    <logger name="com.rrs.log.util" level="debug" addtivity="false">
        <appender-ref ref="point_log_async" />
    </logger>
    <logger name="com.rrs.log.service.impl.LoggerAuditServiceImpl" level="debug" addtivity="false">
        <appender-ref ref="audit_log_async" />
    </logger>

    <root level="INFO">
        <appender-ref ref="StdoutAppender"/>
        <appender-ref ref="file_async"/>
    </root>
</configuration>

```

## 小结
1. 以上实现了链路日志在服务中传递链路id,这部分链路日志因为数据量很大一般是要入es的,具体怎么入es思路是不是很清晰,在上个项目中这部分也没有开始做.等我下一篇文章来解决吧.
2. 操作日志的注解化,操作日志的入数据库.入es和卡夫卡还待做.
3. 埋点日志的工具类

