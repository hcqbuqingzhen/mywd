# springboot相关

## 1. springboot执行流程



[![jccgpt.png](https://s1.ax1x.com/2022/07/11/jccgpt.png)](https://imgtu.com/i/jccgpt)

### 1.1. SpringApplication 构造

#### 1. 记录 BeanDefinition 源

最简单的
```java

@Configuration
public class TestBoot {
    public static void main(String[] args) {
//        1. 记录 BeanDefinition 源
        SpringApplication application=new SpringApplication(TestBoot.class);
//        2. 推断应用类型
//        3. 记录 ApplicationContext 初始化器
//        4. 记录监听器
//        5. 推断主启动类

        ConfigurableApplicationContext context = application.run();

        for (String beanDefinitionName : context.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
            System.out.println("-----"+context.getBeanFactory().getBeanDefinition(beanDefinitionName).getResourceDescription()+"-----");
        }

    }

    //以此来推断是什么应用
    @Bean
    public TomcatServletWebServerFactory tomcatServletWebServerFactory(){
        return new TomcatServletWebServerFactory();
    }

}

```

#### 2. 推断应用类型

[![jcR211.png](https://s1.ax1x.com/2022/07/11/jcR211.png)](https://imgtu.com/i/jcR211)

[![jcWU4H.png](https://s1.ax1x.com/2022/07/11/jcWU4H.png)](https://imgtu.com/i/jcWU4H)

这个推断的逻辑是

若有dispatcherhandler且五dispatcherservlet 则认为是webflax应用

若都没有则为普通应用

否则为servlet应用

#### 3. 记录 ApplicationContext 初始化器

[![jcf8Rs.png](https://s1.ax1x.com/2022/07/11/jcf8Rs.png)](https://imgtu.com/i/jcf8Rs)


#### 4. 记录监听器
[![jcfGzn.png](https://s1.ax1x.com/2022/07/11/jcfGzn.png)](https://imgtu.com/i/jcfGzn)

#### 5. 推断主启动类
[![jcfszR.png](https://s1.ax1x.com/2022/07/11/jcfszR.png)](https://imgtu.com/i/jcfszR)

对应测试文件

- TestBoot

```java

@Configuration
public class TestBoot {
    public static void main(String[] args) throws Exception {
//        1. 记录 BeanDefinition 源
        SpringApplication application=new SpringApplication(TestBoot.class);
//        2. 推断应用类型
        Method deduceFromClasspath = WebApplicationType.class.getDeclaredMethod("deduceFromClasspath");
        deduceFromClasspath.setAccessible(true);
        System.out.println("leixing:"+deduceFromClasspath.invoke(null));

//        3. 记录 ApplicationContext 初始化器
            //添加一个初始化器 在这个初始化器中做些操作
        application.addInitializers(applicationContext -> {
            if(applicationContext instanceof GenericApplicationContext){
                GenericApplicationContext gac=(GenericApplicationContext)applicationContext;
                gac.registerBean(Bean3.class);
            }
        });
//        4. 记录监听器
        application.addListeners(new ApplicationListener<ApplicationEvent>() {
            @Override
            public void onApplicationEvent(ApplicationEvent event) {
                System.out.println(" 自定义监听器"+event.getClass());
            }
        });
//        5. 推断主启动类
        Method deduceMainApplicationClass = SpringApplication.class.getDeclaredMethod("deduceMainApplicationClass");
        deduceMainApplicationClass.setAccessible(true);
        System.out.println("主类:"+deduceMainApplicationClass.invoke(application));

        ConfigurableApplicationContext context = application.run();

        for (String beanDefinitionName : context.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
            System.out.println("-----"+context.getBeanFactory().getBeanDefinition(beanDefinitionName).getResourceDescription()+"-----");
        }

    }


    @Bean
    public TomcatServletWebServerFactory tomcatServletWebServerFactory(){
        return new TomcatServletWebServerFactory();
    }

   static class Bean3{

   }

}

```

### 1.2 执行 run 方法

1. 得到 SpringApplicationRunListeners，名字取得不好，实际是事件发布器

发布 application starting 事件1️⃣

[![jc4j2j.png](https://s1.ax1x.com/2022/07/12/jc4j2j.png)](https://imgtu.com/i/jc4j2j)

2. 封装启动 args  

3. 准备 Environment 添加命令行参数（*）

[![j2n3jO.png](https://s1.ax1x.com/2022/07/12/j2n3jO.png)](https://imgtu.com/i/j2n3jO)

4. ConfigurationPropertySources 处理（*）

   * 发布 application environment 已准备事件2️⃣

[![j2uPVH.png](https://s1.ax1x.com/2022/07/12/j2uPVH.png)](https://imgtu.com/i/j2uPVH)

因为配置有些键写的不规范,主要是处理这个.

5. 通过 EnvironmentPostProcessorApplicationListener 进行 env 后处理（*）
   * application.properties，由 StandardConfigDataLocationResolver 解析
   * spring.application.json
[![j2ucQK.png](https://s1.ax1x.com/2022/07/12/j2ucQK.png)](https://imgtu.com/i/j2ucQK)

这一步主要是增强处理一些默认的配置文件

还是由事件机制做的,4中会发布环境准备好事件,然后第五步增强.

6. 绑定 spring.main 到 SpringApplication 对象（*）

[![j2Ma59.png](https://s1.ax1x.com/2022/07/12/j2Ma59.png)](https://imgtu.com/i/j2Ma59)

绑定配置文件中对应的参数到容器中的对象

7. 打印 banner（*）

[![j23PZ8.png](https://s1.ax1x.com/2022/07/12/j23PZ8.png)](https://imgtu.com/i/j23PZ8)

banner也可以在配置文件中配置

8. 创建容器

9.  准备容器

   * 发布 application context 已初始化事件3️⃣

10. 加载 bean 定义

    * 发布 application prepared 事件4️⃣

11. refresh 容器

    * 发布 application started 事件5️⃣


[![j2V9SS.png](https://s1.ax1x.com/2022/07/12/j2V9SS.png)](https://imgtu.com/i/j2V9SS)


12. 执行 runner

    * 发布 application ready 事件6️⃣

    * 这其中有异常，发布 application failed 事件7️⃣

[![j2eSKg.png](https://s1.ax1x.com/2022/07/12/j2eSKg.png)](https://imgtu.com/i/j2eSKg)



## 2. tomcat组件

Tomcat 基本结构

```
Server
└───Service
    ├───Connector (协议, 端口)
    └───Engine
        └───Host(虚拟主机 localhost)
            ├───Context1 (应用1, 可以设置虚拟路径, / 即 url 起始路径; 项目磁盘路径, 即 docBase )
            │   │   index.html
            │   └───WEB-INF
            │       │   web.xml (servlet, filter, listener) 3.0
            │       ├───classes (servlet, controller, service ...)
            │       ├───jsp
            │       └───lib (第三方 jar 包)
            └───Context2 (应用2)
                │   index.html
                └───WEB-INF
                        web.xml
```


### 2.1 内嵌tomcat
```java
public static void main(String[] args) throws LifecycleException, IOException {
    // 1.创建 Tomcat 对象
    Tomcat tomcat = new Tomcat();
    tomcat.setBaseDir("tomcat");

    // 2.创建项目文件夹, 即 docBase 文件夹
    File docBase = Files.createTempDirectory("boot.").toFile();
    docBase.deleteOnExit();

    // 3.创建 Tomcat 项目, 在 Tomcat 中称为 Context
    Context context = tomcat.addContext("", docBase.getAbsolutePath());

    // 4.编程添加 Servlet
    context.addServletContainerInitializer(new ServletContainerInitializer() {
        @Override
        public void onStartup(Set<Class<?>> c, ServletContext ctx) throws ServletException {
            HelloServlet helloServlet = new HelloServlet();
            ctx.addServlet("aaa", helloServlet).addMapping("/hello");
        }
    }, Collections.emptySet());

    // 5.启动 Tomcat
    tomcat.start();

    // 6.创建连接器, 设置监听端口
    Connector connector = new Connector(new Http11Nio2Protocol());
    connector.setPort(8080);
    tomcat.setConnector(connector);
}
```
### 2.2 整合spring

[![j2JWex.png](https://s1.ax1x.com/2022/07/12/j2JWex.png)](https://imgtu.com/i/j2JWex)

```java
WebApplicationContext springContext = getApplicationContext();

// 4.编程添加 Servlet
context.addServletContainerInitializer(new ServletContainerInitializer() {
    @Override
    public void onStartup(Set<Class<?>> c, ServletContext ctx) throws ServletException {
        // ⬇️通过 ServletRegistrationBean 添加 DispatcherServlet 等
        for (ServletRegistrationBean registrationBean : 
             springContext.getBeansOfType(ServletRegistrationBean.class).values()) {
            registrationBean.onStartup(ctx);
        }
    }
}, Collections.emptySet());
```

## 3. 自动装配

### 3.0 自动装配原理
一种自动配置方式

[![j2yfv6.png](https://s1.ax1x.com/2022/07/12/j2yfv6.png)](https://imgtu.com/i/j2yfv6)

[![j2y7UH.png](https://s1.ax1x.com/2022/07/12/j2y7UH.png)](https://imgtu.com/i/j2y7UH)

配置的优先级

[![j2c8Yj.png](https://s1.ax1x.com/2022/07/12/j2c8Yj.png)](https://imgtu.com/i/j2c8Yj)

[![j2cDk4.png](https://s1.ax1x.com/2022/07/12/j2cDk4.png)](https://imgtu.com/i/j2cDk4)

### 3.1 aop自动装配
Spring Boot 是利用了自动配置类来简化了 aop 相关配置

* AOP 自动配置类为 `org.springframework.boot.autoconfigure.aop.AopAutoConfiguration`
* 可以通过 `spring.aop.auto=false` 禁用 aop 自动配置
* AOP 自动配置的本质是通过 `@EnableAspectJAutoProxy` 来开启了自动代理，如果在引导类上自己添加了 `@EnableAspectJAutoProxy` 那么以自己添加的为准
* `@EnableAspectJAutoProxy` 的本质是向容器中添加了 `AnnotationAwareAspectJAutoProxyCreator` 这个 bean 后处理器，它能够找到容器中所有切面，并为匹配切点的目标类创建代理，创建代理的工作一般是在 bean 的初始化阶段完成的

[![j2fvfe.png](https://s1.ax1x.com/2022/07/12/j2fvfe.png)](https://imgtu.com/i/j2fvfe)

[![j2hmlj.png](https://s1.ax1x.com/2022/07/12/j2hmlj.png)](https://imgtu.com/i/j2hmlj)

### 3.2 自动配置类

#### 1. datasource

* 对应的自动配置类为：org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
* 它内部采用了条件装配，通过检查容器的 bean，以及类路径下的 class，来决定该 @Bean 是否生效

简单说明一下，Spring Boot 支持两大类数据源：

* EmbeddedDatabase - 内嵌数据库连接池
* PooledDataSource - 非内嵌数据库连接池

PooledDataSource 又支持如下数据源

* hikari 提供的 HikariDataSource
* tomcat-jdbc 提供的 DataSource
* dbcp2 提供的 BasicDataSource
* oracle 提供的 PoolDataSourceImpl

如果知道数据源的实现类类型，即指定了 `spring.datasource.type`，理论上可以支持所有数据源，但这样做的一个最大问题是无法订制每种数据源的详细配置（如最大、最小连接数等）


#### 2. mybatis

* MyBatis 自动配置类为 `org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration`
* 它主要配置了两个 bean
  * SqlSessionFactory - MyBatis 核心对象，用来创建 SqlSession
  * SqlSessionTemplate - SqlSession 的实现，此实现会与当前线程绑定
  * 用 ImportBeanDefinitionRegistrar 的方式扫描所有标注了 @Mapper 注解的接口
  * 用 AutoConfigurationPackages 来确定扫描的包
* 还有一个相关的 bean：MybatisProperties，它会读取配置文件中带 `mybatis.` 前缀的配置项进行定制配置

@MapperScan 注解的作用与 MybatisAutoConfiguration 类似，会注册 MapperScannerConfigurer 有如下区别

* @MapperScan 扫描具体包（当然也可以配置关注哪个注解）
* @MapperScan 如果不指定扫描具体包，则会把引导类范围内，所有接口当做 Mapper 接口
* MybatisAutoConfiguration 关注的是所有标注 @Mapper 注解的接口，会忽略掉非 @Mapper 标注的接口

这里有同学有疑问，之前介绍的都是将具体类交给 Spring 管理，怎么到了 MyBatis 这儿，接口就可以被管理呢？

* 其实并非将接口交给 Spring 管理，而是每个接口会对应一个 MapperFactoryBean，是后者被 Spring 所管理，接口只是作为 MapperFactoryBean 的一个属性来配置


#### 3. 事务

* 事务自动配置类有两个：
  * `org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration`
  * `org.springframework.boot.autoconfigure.transaction.TransactionAutoConfiguration`

* 前者配置了 DataSourceTransactionManager 用来执行事务的提交、回滚操作
* 后者功能上对标 @EnableTransactionManagement，包含以下三个 bean
  * BeanFactoryTransactionAttributeSourceAdvisor 事务切面类，包含通知和切点
  * TransactionInterceptor 事务通知类，由它在目标方法调用前后加入事务操作
  * AnnotationTransactionAttributeSource 会解析 @Transactional 及事务属性，也包含了切点功能
* 如果自己配置了 DataSourceTransactionManager 或是在引导类加了 @EnableTransactionManagement，则以自己配置的为准


#### 4. mvc相关

1. ServletWebServerFactoryAutoConfiguration
提供 ServletWebServerFactory

2. DispatcherServletAutoConfiguration
提供 DispatcherServlet
提供 DispatcherServletRegistrationBean

3. WebMvcAutoConfiguration

* 配置 DispatcherServlet 的各项组件，提供的 bean 见过的有
  * 多项 HandlerMapping
  * 多项 HandlerAdapter
  * HandlerExceptionResolver

4. ErrorMvcAutoConfiguration
 提供的 bean 有 BasicErrorController

5. MultipartAutoConfiguration
它提供了 org.springframework.web.multipart.support.StandardServletMultipartResolver
该 bean 用来解析 multipart/form-data 格式的数据

6.  HttpEncodingAutoConfiguration
* POST 请求参数如果有中文，无需特殊设置，这是因为 Spring Boot 已经配置了 org.springframework.boot.web.servlet.filter.OrderedCharacterEncodingFilter
* 对应配置 server.servlet.encoding.charset=UTF-8，默认就是 UTF-8
* 当然，它只影响非 json 格式的数据


### 3.3 自定义自动配置类

1. 假设已有第三方的两个自动配置类

```java
@Configuration // ⬅️第三方的配置类
static class AutoConfiguration1 {
    @Bean
    public Bean1 bean1() {
        return new Bean1();
    }
}

@Configuration // ⬅️第三方的配置类
static class AutoConfiguration2 {
    @Bean
    public Bean2 bean2() {
        return new Bean2();
    }
}
```


2. 提供一个配置文件 META-INF/spring.factories，key 为导入器类名，值为多个自动配置类名，用逗号分隔

```properties
MyImportSelector=\
AutoConfiguration1,\
AutoConfiguration2
```

> ***注意***
>
> * 上述配置文件中 MyImportSelector 与 AutoConfiguration1，AutoConfiguration2 为简洁均省略了包名，自己测试时请将包名根据情况补全

3. 引入自动配置

```java
@Configuration // ⬅️本项目的配置类
@Import(MyImportSelector.class)
static class Config { }

static class MyImportSelector implements DeferredImportSelector {
    // ⬇️该方法从 META-INF/spring.factories 读取自动配置类名，返回的 String[] 即为要导入的配置类
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        return SpringFactoriesLoader
            .loadFactoryNames(MyImportSelector.class, null).toArray(new String[0]);
    }
}
```

spring底层也是这么做的,我们经常会把spring.factories的key为EnableAutoConfiguration ,其底层也是这么做的.


#### 自动装配小结:
1. 自动配置类本质上就是一个配置类而已，只是用 META-INF/spring.factories 管理，与应用配置类解耦
2. @Enable 打头的注解本质是利用了 @Import
3. @Import 配合 DeferredImportSelector 即可实现导入，selectImports 方法的返回值即为要导入的配置类名
4. DeferredImportSelector 的导入会在最后执行，为的是让其它配置优先解析


### 3.4 条件装配 

#### 1 条件装配底层使用
条件装配的底层是本质上是 @Conditional 与 Condition，这两个注解。引入自动配置类时，期望满足一定条件才能被 Spring 管理，不满足则不管理，怎么做呢？


比如条件是【类路径下必须有 德鲁伊dataSource】这个 bean ，怎么做呢？

首先编写条件判断类，它实现 Condition 接口，编写条件判断逻辑

```java
static class MyCondition1 implements Condition { 
    // ⬇️如果存在 Druid 依赖，条件成立
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        return ClassUtils.isPresent("com.alibaba.druid.pool.DruidDataSource", null);
    }
}
```

其次，在要导入的自动配置类上添加 `@Conditional(MyCondition1.class)`，将来此类被导入时就会做条件检查

```java
@Configuration // 第三方的配置类
@Conditional(MyCondition1.class) // ⬅️加入条件
static class AutoConfiguration1 {
    @Bean
    public Bean1 bean1() {
        return new Bean1();
    }
}
```


分别测试加入和去除 druid 依赖，观察 bean1 是否存在于容器

```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>druid</artifactId>
    <version>1.1.17</version>
</dependency>
```

#### 2. 自定义高级条件注解

[![j2IuXd.png](https://s1.ax1x.com/2022/07/13/j2IuXd.png)](https://imgtu.com/i/j2IuXd)

## 小结

主要讲了springboot相关的一些知识

1. springboot启动时的构造执行的步骤
2. run方法的12个步骤,各有那些扩展点
3. tomcat是如何加入到springboot中的
4. 自动装配的一些底层api和一些典型自动装配类
5. 条件注解的底层使用,和如何自定义一个高级条件注解.