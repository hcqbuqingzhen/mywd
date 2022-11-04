# 5. spring之其他

## 1. FactoryBean


1. 它的作用是用制造创建过程较为复杂的产品, 如 SqlSessionFactory, 但 @Bean 已具备等价功能
2. 使用上较为古怪, 一不留神就会用错
   1. 被 FactoryBean 创建的产品
      * 会认为创建、依赖注入、Aware 接口回调、前初始化这些都是 FactoryBean 的职责, 这些流程都不会走
      * 唯有后初始化的流程会走, 也就是产品可以被代理增强
      * 单例的产品不会存储于 BeanFactory 的 singletonObjects 成员中, 而是另一个 factoryBeanObjectCache 成员中
   2. 按名字去获取时, 拿到的是产品对象, 名字前面加 & 获取的是工厂对象


##  2. @Indexed注解原理

真实项目中，只需要加入以下依赖即可

```xml
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context-indexer</artifactId>
    <optional>true</optional>
</dependency>
```

加入后会将带了component注解的bean写到一个文件中,也就是类似索引的功能.

1. 在编译时就根据 @Indexed 生成 META-INF/spring.components 文件
2. 扫描时
   * 如果发现 META-INF/spring.components 存在, 以它为准加载 bean definition
   * 否则, 会遍历包下所有 class 资源 (包括 jar 内的)
3. 解决的问题，在编译期就找到 @Component 组件，节省运行期间扫描 @Component 的时间
[![jRK9v6.png](https://s1.ax1x.com/2022/07/13/jRK9v6.png)](https://imgtu.com/i/jRK9v6)

[![jRKEUH.png](https://s1.ax1x.com/2022/07/13/jRKEUH.png)](https://imgtu.com/i/jRKEUH)




## 3. 代理进一步理解

1. spring 代理的设计特点

   * 依赖注入和初始化影响的是原始对象
     * 因此 cglib 不能用 MethodProxy.invokeSuper()

   * 代理与目标是两个对象，二者成员变量并不共用数据

2. static 方法、final 方法、private 方法均无法增强

   * 进一步理解代理增强基于方法重写

[![jRKxeS.png](https://s1.ax1x.com/2022/07/13/jRKxeS.png)](https://imgtu.com/i/jRKxeS)


## 4. @Value 装配底层

1. 查看需要的类型是否为 Optional，是，则进行封装（非延迟），否则向下走
2. 查看需要的类型是否为 ObjectFactory 或 ObjectProvider，是，则进行封装（延迟），否则向下走
3. 查看需要的类型（成员或参数）上是否用 @Lazy 修饰，是，则返回代理，否则向下走
4. 解析 @Value 的值
   1. 如果需要的值是字符串，先解析 ${ }，再解析 #{ }
   2. 不是字符串，需要用 TypeConverter 转换
5. 看需要的类型是否为 Stream、Array、Collection、Map，是，则按集合处理，否则向下走
6. 在 BeanFactory 的 resolvableDependencies 中找有没有类型合适的对象注入，没有向下走
7. 在 BeanFactory 及父工厂中找类型匹配的 bean 进行筛选，筛选时会考虑 @Qualifier 及泛型
8. 结果个数为 0 抛出 NoSuchBeanDefinitionException 异常 
9. 如果结果 > 1，再根据 @Primary 进行筛选
10. 如果结果仍 > 1，再根据成员名或变量名进行筛选
11. 结果仍 > 1，抛出 NoUniqueBeanDefinitionException 异常


## 5. @Autowired 装配底层

1. @Autowired 本质上是根据成员变量或方法参数的类型进行装配

[![jR3T29.png](https://s1.ax1x.com/2022/07/13/jR3T29.png)](https://imgtu.com/i/jR3T29)

2. 如果待装配类型是 Optional，需要根据 Optional 泛型找到 bean，再封装为 Optional 对象装配

[![jR3Lb6.png](https://s1.ax1x.com/2022/07/13/jR3Lb6.png)](https://imgtu.com/i/jR3Lb6)

3. 如果待装配的类型是 ObjectFactory，需要根据 ObjectFactory 泛型创建 ObjectFactory 对象装配
   * 此方法可以延迟 bean 的获取

[![jR3jUO.png](https://s1.ax1x.com/2022/07/13/jR3jUO.png)](https://imgtu.com/i/jR3jUO)

4. 如果待装配的成员变量或方法参数上用 @Lazy 标注，会创建代理对象装配
   * 此方法可以延迟真实 bean 的获取
   * 被装配的代理不作为 bean

[![jR8VIS.png](https://s1.ax1x.com/2022/07/13/jR8VIS.png)](https://imgtu.com/i/jR8VIS)

5. 如果待装配类型是数组，需要获取数组元素类型，根据此类型找到多个 bean 进行装配

[![jR1Ltg.png](https://s1.ax1x.com/2022/07/13/jR1Ltg.png)](https://imgtu.com/i/jR1Ltg)

6. 如果待装配类型是 Collection 或其子接口，需要获取 Collection 泛型，根据此类型找到多个 bean

[![jR1TnP.png](https://s1.ax1x.com/2022/07/13/jR1TnP.png)](https://imgtu.com/i/jR1TnP)

7. 如果待装配类型是 ApplicationContext 等特殊类型
   * 会在 BeanFactory 的 resolvableDependencies 成员按类型查找装配
   * resolvableDependencies 是 map 集合，key 是特殊类型，value 是其对应对象
   * 不能直接根据 key 进行查找，而是用 isAssignableFrom 逐一尝试右边类型是否可以被赋值给左边的 key 类型

[![jR8sIO.png](https://s1.ax1x.com/2022/07/13/jR8sIO.png)](https://imgtu.com/i/jR8sIO)

8. 如果待装配类型有泛型参数
   * 需要利用 ContextAnnotationAutowireCandidateResolver 按泛型参数类型筛选

[![jR8hLt.png](https://s1.ax1x.com/2022/07/13/jR8hLt.png)](https://imgtu.com/i/jR8hLt)

9.  如果待装配类型有 @Qualifier
   * 需要利用 ContextAnnotationAutowireCandidateResolver 按注解提供的 bean 名称筛选

[![jR8OQs.png](https://s1.ax1x.com/2022/07/13/jR8OQs.png)](https://imgtu.com/i/jR8OQs)

在这个判断中解析


10. 有 @Primary 标注的 @Component 或 @Bean 的处理

[![jRGCYF.png](https://s1.ax1x.com/2022/07/13/jRGCYF.png)](https://imgtu.com/i/jRGCYF)


11. 与成员变量名或方法参数名同名 bean 的处理

[![jRGMfe.png](https://s1.ax1x.com/2022/07/13/jRGMfe.png)](https://imgtu.com/i/jRGMfe)

这是处理的最后一道防线

## 6 事件相关

### 6.1 事件监听器

1. 实现 ApplicationListener 接口
   * 根据接口泛型确定事件类型

三个元素 

事件

发布者

监听者

[![jRG5c9.png](https://s1.ax1x.com/2022/07/13/jRG5c9.png)](https://imgtu.com/i/jRG5c9)


2. @EventListener 标注监听方法
   * 根据监听器方法参数确定事件类型
   * 解析时机：在 SmartInitializingSingleton（所有单例初始化完成后），解析每个单例 bean


3. @EventListener原理
还是根据注解做了反射来运行的  
在反射中筛选事件类型.



### 6.2 事件发布器

继承一个事件发布器,重写一些方法.

事件发布也采用了模板方法

子类中重写一些方法,父类中的步骤是确定的.


## 小结

- 主要是讲了一些之前注解的底层原理如value autowired,另一种创建bean的方式--factorybean
- 还有一些新的注解Indexed等
- 代理的的一些新的理解
- 事件监听器的使用和如何自定义事件发布器和事件监听器
