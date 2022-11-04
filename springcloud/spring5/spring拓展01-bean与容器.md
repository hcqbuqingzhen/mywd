
# spring之容器与bean

## 1. BeanFactory和applicationcontext使用
如果我们使用springboot,run会返回一个容器.类图如下.

```java
ConfigurableApplicationContext run = SpringApplication.run(Application.class);
```

[![Xco5fP.png](https://s1.ax1x.com/2022/06/11/Xco5fP.png)](https://imgtu.com/i/Xco5fP)

### BeanFactory功能

顶层容器是BeanFactory,那么什么是BeanFactory呢.如下图.

[![XcTCXF.png](https://s1.ax1x.com/2022/06/11/XcTCXF.png)](https://imgtu.com/i/XcTCXF)

[![Xc7XR0.png](https://s1.ax1x.com/2022/06/11/Xc7XR0.png)](https://imgtu.com/i/Xc7XR0)

BeanFactory内部函数

[![XgpnIK.png](https://s1.ax1x.com/2022/06/11/XgpnIK.png)](https://imgtu.com/i/XgpnIK)

[![XgpVq1.png](https://s1.ax1x.com/2022/06/11/XgpVq1.png)](https://imgtu.com/i/XgpVq1)

其实现类DefaultListableBeanFactory实现了大部分功能.

[![XgpGqI.png](https://s1.ax1x.com/2022/06/11/XgpGqI.png)](https://imgtu.com/i/XgpGqI)

### applicationcontext 功能
applicationcontext相比BeanFactory多了那些功能

[![XgFT5q.png](https://s1.ax1x.com/2022/06/11/XgFT5q.png)](https://imgtu.com/i/XgFT5q)

如图 分别为
国际化,读取资源,环境相关,事件发布.

1. 国际化

[![XgEIVH.png](https://s1.ax1x.com/2022/06/11/XgEIVH.png)](https://imgtu.com/i/XgEIVH)

```java
//1. 国际化
        System.out.println(run.getMessage("hi", null, Locale.CHINA));
        System.out.println(run.getMessage("hi", null, Locale.JAPANESE));
        System.out.println(run.getMessage("hi", null, Locale.ENGLISH));
```


2. 资源获取

```java
        //2.资源获取
        Resource resource = run.getResource("classpath:application.properties");
        System.out.println(resource);

        Resource[] resources = run.getResources("classpath*:META-INF/spring.factories");
        //找到
        for (Resource resource1 : resources) {
            System.out.println(resource1);
        }
```

3. 环境获取

```java
        //3.环境
        System.out.println(run.getEnvironment().getProperty("server.port"));
```

4. 发布事件,事件 就是一种解耦方式.

发
```java
//4. 事件
        run.publishEvent(new ApplicationEvent(run) {

        });
```

收

```java
@Component
public class Component01 {
    @EventListener
    public void aaa(ApplicationEvent event){
        System.out.println("asasa");
    }
}
```


##  2.BeanFactory实现和application实现

### BeanFactory处理器和bean处理器.

- BeanFactory可以简单的加载bean,但有些处理器不会主动加载如处理@bean注解,处理依赖注入的注解,且默认是延迟加载bean.

- @Autowired和@Resource的顺序问题

- @Autowired如果有两个一样的类型会失效,此时如果发现类型一样,会按bean的名字注入.
- @Resource如果指定了名字,就会名字优先.

>@Autowired和@Resource都加入的话,@Autowired先生效.
>这是因为后置处理器有优先级,internalAutowiredAnnotationProcessor在前.

处理器的顺序可以排序,我们可以加入比较器来排序,形式上后置处理器通过实现getOrder()接口.返回的值越小,越在前.


```java
package com.spring.bean.beanfactory;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.beans.factory.support.AbstractBeanDefinition;
import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.context.annotation.AnnotationConfigUtils;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.annotation.Resource;


public class TestBeanBeanFactory {
    public static void main(String[] args) {
        DefaultListableBeanFactory beanFactory=new DefaultListableBeanFactory();
        //添加bean定义 描述bean的特征 class scope 初始化方法 销毁方法
        AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.
                genericBeanDefinition(Config.class).setScope("singleton").getBeanDefinition();

        beanFactory.registerBeanDefinition("config",beanDefinition);

        String[] beanDefinitionNames = beanFactory.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            System.out.println(beanDefinitionName);
        }

        //@Bean注解不生效 给其添加
        AnnotationConfigUtils.registerAnnotationConfigProcessors(beanFactory);
        //BeanFactoryPostProcessor是函数式接口
        beanFactory.getBeansOfType(BeanFactoryPostProcessor.class).values().stream().
                sorted(beanFactory.getDependencyComparator()).forEach(
                beanFactoryPostProcessor->{
                    beanFactoryPostProcessor.postProcessBeanFactory(beanFactory);
                }
        );
        //@Autowired不生效
        //bean后处理器,针对bean生命周期各个阶段提供扩展 如依赖注入
        beanFactory.getBeansOfType(BeanPostProcessor.class).values().stream().forEach(
                beanFactory::addBeanPostProcessor);

        String[] beanDefinitionNames1 = beanFactory.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames1) {
            System.out.println(beanDefinitionName);
        }

        //获取bean 默认是延迟创建对象
        //关闭延迟
        beanFactory.preInstantiateSingletons();
        System.out.println(beanFactory.getBean(Bean1.class).getBean2());
        System.out.println(beanFactory.getBean(Bean1.class).getBean3());
        System.out.println(beanFactory.getBean(Bean1.class).getBean4());

    }

    @Configuration
    static class Config{
        @Bean
        public Bean1 bean1(){
            return new Bean1();
        }

        @Bean
        public Bean2 bean2(){
            return new Bean2();
        }

        @Bean
        public Bean3 bean3(){
            return new Bean3();
        }
        @Bean
        public Bean4 bean4(){
            return new Bean4();
        }
    }

    static class Bean1{
        private static final Logger log= LoggerFactory.getLogger(Bean1.class);

        public Bean1() {
            log.debug("构造bean1");
        }

        @Autowired
        private Bean2 bean2;

        @Autowired
        private inter bean3;

        @Autowired
        @Resource(name = "bean3")
        private inter bean4;

        public Bean2 getBean2() {
            return bean2;
        }

        public inter getBean3() {
            return bean3;
        }

        public inter getBean4() {
            return bean4;
        }
    }
    static class Bean2{
        private static final Logger log= LoggerFactory.getLogger(Bean2.class);

        public Bean2() {
            log.debug("构造bean2");
        }
    }

    static interface  inter{

    }
    static class Bean3 implements inter{
        private static final Logger log= LoggerFactory.getLogger(Bean2.class);

        public Bean3() {
            log.debug("构造bean3");
        }
    }

    static class Bean4 implements inter{
        private static final Logger log= LoggerFactory.getLogger(Bean2.class);

        public Bean4() {
            log.debug("构造bean4");
        }
    }
}
```

[![XgYIcF.png](https://s1.ax1x.com/2022/06/11/XgYIcF.png)](https://imgtu.com/i/XgYIcF)



### application实现

1. 基于 classpath下的xml容器 
2. 基于磁盘的xml容器

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">
    <bean name="bean1" class="com.spring.bean.application.TestApplicationContext.Bean1">
        <!--setter注入-->
        <property name="bean2" ref="bean2"/>
    </bean>
    <bean name="bean2" class="com.spring.bean.application.TestApplicationContext.Bean2">

    </bean>
    <!--开启注解注入后处理器-->
    <context:annotation-config/>
</beans>
```

```java
//1. classpath下的xml容器 经典容器
    private static void testClassPathXmlApplicationContext(){
        ClassPathXmlApplicationContext context=
                new ClassPathXmlApplicationContext("bean.xml");
        String[] beanDefinitionNames = context.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            System.out.println(beanDefinitionName);
        }
        System.out.println(context.getBean(Bean1.class).getBean2());
    }

    //2. 基于磁盘的xml容器
    private static void testFileSystemXmlApplicationContext(){
        FileSystemXmlApplicationContext context=
                new FileSystemXmlApplicationContext("springuse/src/main/resources/bean.xml");
        String[] beanDefinitionNames = context.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            System.out.println(beanDefinitionName);
        }
        System.out.println(context.getBean(Bean1.class).getBean2());
    }
```
基本原理是读取xml加载bean

```java
DefaultListableBeanFactory beanFactory=new DefaultListableBeanFactory();
        System.out.println("读取之前");
        for (String beanDefinitionName : beanFactory.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
        }
        System.out.println("读取之后");
        XmlBeanDefinitionReader reader=new XmlBeanDefinitionReader(beanFactory);
        reader.loadBeanDefinitions(new ClassPathResource("bean.xml"));
        for (String beanDefinitionName : beanFactory.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
        }
```

3. 基于java配置类

```java
//3. java配置类容器
    private static void testAnnotationConfigApplicationContext(){
        AnnotationConfigApplicationContext context=
                new AnnotationConfigApplicationContext(TestApplicationContext.Config.class);
        String[] beanDefinitionNames = context.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            System.out.println(beanDefinitionName);
        }
        System.out.println(context.getBean(Bean1.class).getBean2());
    }


    @Configuration
    static class Config{
        @Bean
        public Bean2 bean2(){
            Bean2 bean2=new Bean2();
            return bean2;
        }
        @Bean
        public Bean1 bean1(Bean2 bean2){
            Bean1 bean1=new Bean1();
            bean1.setBean2(bean2);
            return bean1;
        }

    }
    static class Bean1{
        private static final Logger log= LoggerFactory.getLogger(Bean1.class);

        public Bean1() {
            log.debug("构造bean1");
        }

        private Bean2 bean2;

        public Bean2 getBean2() {
            return bean2;
        }

        public void setBean2(Bean2 bean2) {
            this.bean2 = bean2;
        }
    }
    static class Bean2{
        private static final Logger log= LoggerFactory.getLogger(Bean2.class);

        public Bean2() {
            log.debug("构造bean2");
        }
    }
```


4. java配置类容器 用于web环境

```java
//4. java配置类容器 用于web环境
    private static void testAnnotationConfigServletWebServerApplicationContext(){
        AnnotationConfigServletWebServerApplicationContext context =
                new AnnotationConfigServletWebServerApplicationContext(WebConfig.class);


    }

    @Configuration
    static class WebConfig{
        //注册tomcat
        @Bean
        public ServletWebServerFactory servletWebServerFactory(){
            return new TomcatServletWebServerFactory();
        }
        //注册servlet
        @Bean
        public DispatcherServlet dispatcherServlet(){
            return new DispatcherServlet();
        }
        //将servlet注册到tomcat容器
        @Bean
        public DispatcherServletRegistrationBean registrationBean(DispatcherServlet dispatcherServlet){
            return new DispatcherServletRegistrationBean(dispatcherServlet,"/");
        }
        @Bean("/hello")
        public Controller controller1(){
            return (requerst,response)->{
                response.getWriter().write("hello");
                return null;
            };
        }
    }
```

会发现相对与xml不同,注解的容器会多出几个处理器,这几个处理器就是处理注解用的.
application仍然是组合了DefaultListableBeanFactory实现的.

web环境下基于注解的容器实现,就是对@Controller注解自动注入,和自动注入了服务器容器和mvc的DispatcherServlet,并将DispatcherServlet注册到服务器容器.

## 3. bean的生命周期和bean的后处理器

大致分为 

1. 实例化 

2. 依赖注入 

3. 初始化 

4. 销毁,

   bean方法的增强是由各种PostProcessor完成的.

```java
package com.spring.bean.life;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

@Component
public class LifeCycleBean {
    private static final Logger logger=LoggerFactory.getLogger(LifeCycleBean.class);

    public LifeCycleBean() {
        logger.info("LifeCycleBean构造");
    }

    @Autowired
    public void autowire(@Value("${server.port}") String home){
        logger.info("注入:{}",home);
    }

    @PostConstruct
    public void init(){
        logger.info("初始化");
    }
    @PreDestroy
    public void destroy(){
        logger.info("销毁");
    }
}

```
我们自定义一个PostProcessor
```java
package com.spring.bean.life;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.BeansException;
import org.springframework.beans.PropertyValues;
import org.springframework.beans.factory.config.DestructionAwareBeanPostProcessor;
import org.springframework.beans.factory.config.InstantiationAwareBeanPostProcessor;
import org.springframework.stereotype.Component;

@Component
public class MyBeanPostProcessor implements InstantiationAwareBeanPostProcessor, DestructionAwareBeanPostProcessor {
    private static final Logger logger= LoggerFactory.getLogger(MyBeanPostProcessor.class);


    @Override
    public Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 初始化之前执行,若返回object会替换掉原来的bean 如 @PostConstruct");
        }
        return bean;
    }

    @Override
    public Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 初始化之后执行,若返回object会替换掉原来的bean 如 @PostConstruct");
        }
        return bean;
    }

    @Override
    public Object postProcessBeforeInstantiation(Class<?> beanClass, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 实例化之前执行 这里返回的对象会替换到原来的bean,如代理增强等");
        }
        return null;
    }

    @Override
    public boolean postProcessAfterInstantiation(Object bean, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 实例化之后执行 返回false会跳过依赖注入的阶段");
        }
        return true;
    }

    @Override
    public PropertyValues postProcessProperties(PropertyValues pvs, Object bean, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 依赖注入阶段执行 @Autowired等");
        }
        return null;
    }

    @Override
    public void postProcessBeforeDestruction(Object bean, String beanName) throws BeansException {
        if (beanName.equals("lifeCycleBean")){
            logger.info("<<<<<< 销毁之前执行 如在加了@PreDestroy注解之前");
        }
    }
}

```

[![X2VzKf.png](https://s1.ax1x.com/2022/06/12/X2VzKf.png)](https://imgtu.com/i/X2VzKf)

这个过程中使用了模板方法
大的流程设计好了,只负责写我们需要拓展的部分即可.

[![X28tV1.png](https://s1.ax1x.com/2022/06/12/X28tV1.png)](https://imgtu.com/i/X28tV1)


如果不使用模板方法,该怎样实现呢?也就是说我们调用本就有的api如何实现.



[![X20eQx.png](https://s1.ax1x.com/2022/06/12/X20eQx.png)](https://imgtu.com/i/X20eQx)

实现如下

```java
public class DigInAutowired {
    public static void main(String[] args) throws Throwable {
        DefaultListableBeanFactory beanFactory =new DefaultListableBeanFactory();

        beanFactory.registerSingleton("bean2",new Bean2());
        beanFactory.registerSingleton("bean3",new Bean3());
        beanFactory.setAutowireCandidateResolver(new ContextAnnotationAutowireCandidateResolver());//@value

        //1.查找那些属性加了@autowired 包装进一个新对象 injectionMetadata
        AutowiredAnnotationBeanPostProcessor processor=new AutowiredAnnotationBeanPostProcessor();
        processor.setBeanFactory(beanFactory);
        Bean1 bean1=new Bean1();

//        System.out.println(bean1);
//        //注册
//        processor.postProcessProperties(null,bean1,"bean1");
//
//        System.out.println(bean1);

        //2. 调用 injectionMetadata 来依赖注入,注入时按照类型查找.
        Method findAutowiringMetadata = processor.getClass().getDeclaredMethod("findAutowiringMetadata", String.class, Class.class, PropertyValues.class);
        findAutowiringMetadata.setAccessible(true);
        InjectionMetadata injectionMetadata = (InjectionMetadata)
                findAutowiringMetadata.invoke(processor, "bean1", Bean1.class, null);

        //System.out.println(injectionMetadata);
        //injectionMetadata.inject(bean1,"bean1",null);
        //System.out.println(bean1);

        //3. 如何按照类型查找 注入的过程
        //injectionMetadata.inject(bean1,"bean1",null)的过程
        Field bean3 = Bean1.class.getDeclaredField("bean3");

        //构造了一个依赖描述对象
        DependencyDescriptor dd1=new DependencyDescriptor(bean3,false);

        Object o = beanFactory.doResolveDependency(dd1, null, null, null);
        System.out.println(o);

        Method setBean2 = Bean1.class.getDeclaredMethod("setBean2", Bean2.class);

        //构造了一个依赖描述对象
        DependencyDescriptor dd2=new DependencyDescriptor(new MethodParameter(setBean2,0),false);

        Object o1 = beanFactory.doResolveDependency(dd2, null, null, null);

        System.out.println(o1);
    }
}
```
- bean的大致生命流程如下
[![XfWob4.jpg](https://s1.ax1x.com/2022/06/13/XfWob4.jpg)](https://imgtu.com/i/XfWob4)
## 4. beanfactory 的后置处理器

可以模拟spring的实现,是如何将加了注解的类注册为bean的.

1.  @ComponentScan("com.spring.bean.beanfactorypost.component") 和  @Component

[![X2yqoT.png](https://s1.ax1x.com/2022/06/12/X2yqoT.png)](https://imgtu.com/i/X2yqoT)


[![X22Pwq.png](https://s1.ax1x.com/2022/06/13/X22Pwq.png)](https://imgtu.com/i/X22Pwq)

实际上是由PostProcessor完成的,我们也可以模仿这个过程写一个这样的处理器.

```java
public class ComponentScanPostProcessor implements BeanFactoryPostProcessor {
    @SneakyThrows
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        //1 组件注入之 @Component
        ComponentScan annotation = AnnotationUtils.findAnnotation(Config.class, ComponentScan.class);
        AnnotationBeanNameGenerator generator=new AnnotationBeanNameGenerator(); //名字生成
        CachingMetadataReaderFactory readerFactory=new CachingMetadataReaderFactory();//读取元信息
        if(annotation!=null){
            for (String s : annotation.basePackages()) {
                System.out.println(s);
                //解析
                String path="classpath*:"+s.replace(".","/")+"/**/*.class";
                PathMatchingResourcePatternResolver resolver=new PathMatchingResourcePatternResolver();
                Resource[] resources = resolver.getResources(path);
                for (Resource resource : resources) {
                    //读取信息
                    MetadataReader metadataReader = readerFactory.getMetadataReader(resource);

                    AnnotationMetadata annotationMetadata = metadataReader.getAnnotationMetadata();
                    if(annotationMetadata.hasAnnotation(Component.class.getName())||
                            annotationMetadata.hasMetaAnnotation(Component.class.getName())){
                        AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder.genericBeanDefinition(metadataReader.getClassMetadata().
                                getClassName()).getBeanDefinition();


                        //注册bean
                        if(beanFactory instanceof DefaultListableBeanFactory ){
                            DefaultListableBeanFactory context=(DefaultListableBeanFactory)beanFactory;
                            String name = generator.generateBeanName(beanDefinition, context);
                            context.registerBeanDefinition(name,beanDefinition);
                        }
                    }
                }

            }
            
        }
    }
}

```


```java
public class A05Application {
    public static void main(String[] args) throws IOException {
        //干净的容器
        GenericApplicationContext context=new GenericApplicationContext();

        //原始方法注册
        context.registerBean("config", Config.class);
        //context.registerBean(ConfigurationClassPostProcessor.class);
        //自定义解析ComponentScan Component处理器
        context.registerBean(ComponentScanPostProcessor.class);
        //context.registerBean();
        //初始化容器
        context.refresh();

        for (String beanDefinitionName : context.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
        }
        //销毁
        context.close();0
    }
}
```


2. @bean注解

@bean是用工厂方法构建的
[![XRZ2HU.png](https://s1.ax1x.com/2022/06/13/XRZ2HU.png)](https://imgtu.com/i/XRZ2HU)

这个处理器也可以抽取成一个类

```java
public class AtBeanPostProcess implements BeanFactoryPostProcessor {
    @SneakyThrows
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        //读取@bean
        CachingMetadataReaderFactory readerFactory=new CachingMetadataReaderFactory();//读取元信息
        MetadataReader metadataReader = readerFactory.getMetadataReader("com/spring/bean/beanfactorypost/Config");
        AnnotationMetadata annotationMetadata = metadataReader.getAnnotationMetadata();
        //
        Set<MethodMetadata> annotatedMethods = annotationMetadata.getAnnotatedMethods(Bean.class.getName());

        for (MethodMetadata annotatedMethod : annotatedMethods) {
            //@bean是由工厂方法创建的
            BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.genericBeanDefinition();
            beanDefinitionBuilder.setFactoryMethodOnBean(annotatedMethod.getMethodName(),"config");
            //构造方法自动注入
            beanDefinitionBuilder.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_CONSTRUCTOR);
            //如果有init方法设置init方法
            String string = annotatedMethod.getAnnotationAttributes(Bean.class.getName()).get("initMethod").toString();


            if(string.length()>0){
                beanDefinitionBuilder.setInitMethodName("init");
            }
            AbstractBeanDefinition beanDefinition = beanDefinitionBuilder.getBeanDefinition();


            //注册bean
            if(beanFactory instanceof DefaultListableBeanFactory){
                DefaultListableBeanFactory context=(DefaultListableBeanFactory)beanFactory;
                context.registerBeanDefinition(annotatedMethod.getMethodName(),beanDefinition);
            }

        }

    }
}
```

将这个处理器加入到容器就会自动起作用

3. @mapper mybatis的实现 模仿

同样也是写个处理器

```java
public class MapperPostProcess implements BeanDefinitionRegistryPostProcessor {
    @SneakyThrows
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {

    }

    @SneakyThrows
    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) throws BeansException {
        //1 组件注入之 @Component
        MapperScan annotation = AnnotationUtils.findAnnotation(Config.class, MapperScan.class);
        AnnotationBeanNameGenerator generator=new AnnotationBeanNameGenerator(); //名字生成
        CachingMetadataReaderFactory readerFactory=new CachingMetadataReaderFactory();//读取元信息
        //解析
        if(annotation!=null) {
            for (String s : annotation.value()) {
                String path = "classpath*:" + s.replace(".", "/") + "/**/*.class";
                PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
                Resource[] resources = resolver.getResources(path);
                for (Resource resource : resources) {
                    MetadataReader metadataReader = readerFactory.getMetadataReader(resource);
                    ClassMetadata classMetadata = metadataReader.getClassMetadata();
                    //是接口
                    if(classMetadata.isInterface()){
                        //通过genericBeanDefinition来创建bean定义
                        BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.
                                genericBeanDefinition(MapperFactoryBean.class).
                                addConstructorArgValue(classMetadata.getClassName()).
                                setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
                        AbstractBeanDefinition beanDefinition = beanDefinitionBuilder.getBeanDefinition();

                        AbstractBeanDefinition bd2=BeanDefinitionBuilder.genericBeanDefinition(classMetadata.getClassName()).getBeanDefinition();
                        //名字
                        String name = generator.generateBeanName(bd2, registry);
                        registry.registerBeanDefinition(name,beanDefinition);

                    }
                }
            }
        }
    }
}
```


## 5. aware接口和initalizingbean接口

### 作用

[![XRBRln.png](https://s1.ax1x.com/2022/06/13/XRBRln.png)](https://imgtu.com/i/XRBRln)

[![XRrfaT.png](https://s1.ax1x.com/2022/06/13/XRrfaT.png)](https://imgtu.com/i/XRrfaT)

有些功能用处理器也能实现,但aware是内置接口,不会失效.
也即 
1. 要配置处理器,但用aware实现aware接口即可.


context 的流程

### @autowired失效问题

[![XRga4K.png](https://s1.ax1x.com/2022/06/13/XRga4K.png)](https://imgtu.com/i/XRga4K)

[![XR2OeA.png](https://s1.ax1x.com/2022/06/13/XR2OeA.png)](https://imgtu.com/i/XR2OeA)

其实主要是他们执行的时机不同



## 6.初始化和销毁

- 初始化

@PostConstruct
实现InitializingBean的方法
注入的时候指定init方法

- 销毁
@PreDestroy
实现disposablebean的方法
注入的时候指定Destroy方法


## 7. bean的scope

### bean的scope分几种类型
单例
每次访问都创建新的
针对web环境有request,session,aplication 
与之相对是每次请求,每个会话,每个服务器容器.

jdk8 以上版本的一个问题.反射调用jdk的类,会出现没有权限的问题.

[![Xf1x2T.png](https://s1.ax1x.com/2022/06/13/Xf1x2T.png)](https://imgtu.com/i/Xf1x2T)


```java
@Controller
@RequestMapping("/test")
public class TestController {
    @Lazy
    @Autowired
    private BeanForRequest beanForRequest;
    @Lazy
    @Autowired
    private BeanForSession beanForSession;
    @Lazy
    @Autowired
    private BeanForContext beanForContext;

    @GetMapping("/testScope")
    public void testScope(HttpServletRequest request , HttpServletResponse response) throws IOException {

        response.getWriter().write("beanForRequest = " +beanForRequest+"<br/>"+
                                        "beanForSession = " +beanForSession+"<br/>"+
                                        "beanForContext = " +beanForContext+"<br/>"

        );

        response.getWriter().close();
    }
}
```

自己测验不同的scope
每次刷新 request的都会变化
新开会话session的会变化
服务器重启application会变化

### bean的scope失效 

失效之
[![Xf0cq0.png](https://s1.ax1x.com/2022/06/13/Xf0cq0.png)](https://imgtu.com/i/Xf0cq0)

- 解决 使用代理

[![Xf0LdK.png](https://s1.ax1x.com/2022/06/13/Xf0LdK.png)](https://imgtu.com/i/Xf0LdK)

- 或者 设置一个属性

[![XfBuyn.png](https://s1.ax1x.com/2022/06/13/XfBuyn.png)](https://imgtu.com/i/XfBuyn)

- 或者 使用对象工厂

[![XfDV76.png](https://s1.ax1x.com/2022/06/13/XfDV76.png)](https://imgtu.com/i/XfDV76)

- 或者使用容器 application

[![XfyStf.png](https://s1.ax1x.com/2022/06/13/XfyStf.png)](https://imgtu.com/i/XfyStf)


## 小结

1. 主要讲了Beanfactory和Application的功能
2. Beanfactory和Application的几种实现类,和使用方法.
3. bean的生命周期和常见后处理器,以及这个过程采用的模板方法.
4. Beanfactory的生命周期和工厂处理器
5. aware相关接口和与初始化相关的接口inteializingbean接口. aware可以解决一些情况下beanpostprosser失效的问题.aware主要是实现了接口就要执行对应的方法.虽然他的功能呢刚也可以通过后处理器实现.
6. 初始化和销毁的几种方式和排序
7. scope和scope失效的几种解决办法,本质上仍然是延迟获取bean.

