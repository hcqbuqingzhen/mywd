# spring之Aop使用

## 1. aop之acj增强

改写class来增强目标方法,算是一种静态代理的增强.

切面类
[![Xfvop8.png](https://s1.ax1x.com/2022/06/14/Xfvop8.png)](https://imgtu.com/i/Xfvop8)


要实现需要在maven中增加一个编译插件 aspectj-maven-plugin

[![XfvsSO.png](https://s1.ax1x.com/2022/06/14/XfvsSO.png)](https://imgtu.com/i/XfvsSO)

与动态代理不同的是可以增强静态方法.

## 2. agent类加载

在类加载阶段一种增强的方式

[![X5qtQe.png](https://s1.ax1x.com/2022/06/14/X5qtQe.png)](https://imgtu.com/i/X5qtQe)

[![X5qcQg.png](https://s1.ax1x.com/2022/06/14/X5qcQg.png)](https://imgtu.com/i/X5qcQg)

需要增加jvm参数

[![X5LiOH.png](https://s1.ax1x.com/2022/06/14/X5LiOH.png)](https://imgtu.com/i/X5LiOH)

同样是也是修改了字节码,不过是在类加载阶段修改的,直接修改的内存.

可以使用阿里的工具arthas来连接程序查看,反编译内存中的字节码.(学到了)

## 3. jdk的proxy

proxy之复习

[![XIkH1J.png](https://s1.ax1x.com/2022/06/14/XIkH1J.png)](https://imgtu.com/i/XIkH1J)

Proxy.newProxyInstance()会生成一个代理对象,这个代理对象调用方法的时候实际上调用的是第三个参数的方法,在这个参数中对被代理类增强.

代理对象和被代理对象是兄弟关系,都实现了同样的接口.

代理原理
先自己手写一个代理类.
[![XIERoV.png](https://s1.ax1x.com/2022/06/14/XIERoV.png)](https://imgtu.com/i/XIERoV)
将行为抽取到接口,targer的具体方法增强.
[![XIZm4K.png](https://s1.ax1x.com/2022/06/14/XIZm4K.png)](https://imgtu.com/i/XIZm4K)

针对多个方法,给接口增加参数,执行原有方法.
[![XI19Cn.png](https://s1.ax1x.com/2022/06/14/XI19Cn.png)](https://imgtu.com/i/XI19Cn)

返回值的处理
对method对象做一下处理,放到静态代码快里.

上述优化实现后,代码如下

[![XIJQFe.png](https://s1.ax1x.com/2022/06/14/XIJQFe.png)](https://imgtu.com/i/XIJQFe)


```java
public interface Foo {
int  foo();
void bar();
}

public class Target implements Foo {
    @Override
    public int foo() {
        System.out.println("target foo方法");
        return 0;
    }

    @Override
    public void bar() {
        System.out.println("target bar方法");
    }
}
```

- InvocationHandler
```java
public interface InvocationHandler {
    Object invoke(Object proxy,Method method, Object[] args) throws InvocationTargetException, IllegalAccessException;
}

```

- $Proxy0

```java
public class $Proxy0 implements Foo{
    private InvocationHandler h;

    public $Proxy0(InvocationHandler h) {
        this.h = h;
    }

    @Override
    public int foo() {
        Method method= foo;
        try {
            Object invoke = h.invoke(this,method, new Object[0]);
            return (int)invoke;
        } catch (RuntimeException e) {
            throw e;
        } catch (Throwable e){
            throw  new RuntimeException("xxxx");
        }
    }

    @Override
    public void bar() {
        Method method= bar;
        try {
            h.invoke(this,method,new Object[0]);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    static Method foo;
    static Method bar;

    static {
        try {
            foo=Foo.class.getMethod("foo");
            bar= Foo.class.getMethod("bar");
        } catch (NoSuchMethodException e) {
            throw  new NoSuchMethodError("xxxxxx");
        }

    }
}
```


如果替换成jdk的InvocationHandler 实际上也能运行.

可以将自己的proxy对象继承jdk的proxy,调用super的构造方法.

查看jdk动态代理生成的源码,使用arthas工具类.

```java
package com.sun.proxy;

import com.spring.aop.proxy.test.Foo;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;

public final class $Proxy0
extends Proxy
implements Foo {
    private static Method m1;
    private static Method m2;
    private static Method m3;
    private static Method m0;

    public $Proxy0(InvocationHandler invocationHandler) {
        super(invocationHandler);
    }

    static {
        try {
            m1 = Class.forName("java.lang.Object").getMethod("equals", Class.forName("java.lang.Object"));
            m2 = Class.forName("java.lang.Object").getMethod("toString", new Class[0]);
            m3 = Class.forName("com.spring.aop.proxy.test.Foo").getMethod("foo", new Class[0]);
            m0 = Class.forName("java.lang.Object").getMethod("hashCode", new Class[0]);
            return;
        }
        catch (NoSuchMethodException noSuchMethodException) {
            throw new NoSuchMethodError(noSuchMethodException.getMessage());
        }
        catch (ClassNotFoundException classNotFoundException) {
            throw new NoClassDefFoundError(classNotFoundException.getMessage());
        }
    }

    public final boolean equals(Object object) {
        try {
            return (Boolean)this.h.invoke(this, m1, new Object[]{object});
        }
        catch (Error | RuntimeException throwable) {
            throw throwable;
        }
        catch (Throwable throwable) {
            throw new UndeclaredThrowableException(throwable);
        }
    }

    public final String toString() {
        try {
            return (String)this.h.invoke(this, m2, null);
        }
        catch (Error | RuntimeException throwable) {
            throw throwable;
        }
        catch (Throwable throwable) {
            throw new UndeclaredThrowableException(throwable);
        }
    }

    public final int hashCode() {
        try {
            return (Integer)this.h.invoke(this, m0, null);
        }
        catch (Error | RuntimeException throwable) {
            throw throwable;
        }
        catch (Throwable throwable) {
            throw new UndeclaredThrowableException(throwable);
        }
    }

    public final void foo() {
        try {
            this.h.invoke(this, m3, null);
            return;
        }
        catch (Error | RuntimeException throwable) {
            throw throwable;
        }
        catch (Throwable throwable) {
            throw new UndeclaredThrowableException(throwable);
        }
    }
}


```

可以看到还对hashcode,tostring,equals 方法做了重新代理.


如何生成代理后的字节码?

注意这里是字节码,jdk使用了一种叫做asm的技术,直接生成字节码.在spring中也有应用.

使用一个插件可以查看asm生成字节码的过程
[![XIwXr9.png](https://s1.ax1x.com/2022/06/14/XIwXr9.png)](https://imgtu.com/i/XIwXr9)


[![XI0kKH.png](https://s1.ax1x.com/2022/06/14/XI0kKH.png)](https://imgtu.com/i/XI0kKH)

实际上是生成class代码,class码是怎样的,就怎样生成.

我们可以推测,jdk加载了字节码后,由这种工具进行字节码的组装生成代理类的字节码.

[![XI0OW8.png](https://s1.ax1x.com/2022/06/14/XI0OW8.png)](https://imgtu.com/i/XI0OW8)

反射的一些优化
在一直反射调用某个某个类的方法之后(16次),jdk会放弃使用本地方法反射,转而使用生成的代理类调用方法.

[![XIrkMF.png](https://s1.ax1x.com/2022/06/14/XIrkMF.png)](https://imgtu.com/i/XIrkMF)


## 4. cglib代理

cglib使用

```java
public class CglibProxyTest {
    public static void main(String[] args) {
        Target o = (Target)Enhancer.create(Target.class, new MethodInterceptor() {
            @Override
            //1 代理类自己 2. 当前代理类执行的方法 3. 方法的参数 4. 一个类似方法对象的对象
            public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
                System.out.println("before");
                Object invoke = method.invoke(new Target(), args);
                System.out.println("after");
                return invoke;
            }
        });

        o.foo();
    }
}
```

cglib是子父关系,代理是子类,目标是父类. 目标加了final就会失败,不管是类还是方法.

MethodProxy可以避免使用反射调用.因为内部没有用反射. spring使用的这一种.

methodProxy.invokeSuper(o,args);可以代理自己


cglib内部实现

自己写一个类似与上面的代理类.

[![XI29i9.png](https://s1.ax1x.com/2022/06/15/XI29i9.png)](https://imgtu.com/i/XI29i9)

实现如下

```java
public class Target {
    public void  save(){
        System.out.println("target ");
    }
    public void  save(int i){
        System.out.println("target :"+i);
    }
    public void  save(long l){
        System.out.println("target "+l);
    }
}


```

- Proxy

```java
public class Proxy extends Target{
    private MethodInterceptor methodInterceptor;

    static Method method1;
    static Method method2;
    static Method method3;
    static {

        try {
            method1=Target.class.getMethod("save");
            method2=Target.class.getMethod("save",int.class);
            method3=Target.class.getMethod("save",long.class);
        } catch (NoSuchMethodException e) {
           throw new RuntimeException("xxxxxx");
        }

    }

    public Proxy(MethodInterceptor methodInterceptor) {
        this.methodInterceptor = methodInterceptor;
    }

    public void  save(){
        try {
            methodInterceptor.intercept(this,method1,new Object[0],null);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
    public void  save(int i){
        try {
            Object [] objects=new Object[1];
            objects[0]=i;
            methodInterceptor.intercept(this,method2,objects,null);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
    public void  save(long l){
        try {
            Object [] objects=new Object[1];
            objects[0]=l;
            methodInterceptor.intercept(this,method3,objects,null);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
}

```

test

```java
public class CglibProxyDemo {
    public static void main(String[] args) {
        Target target=new Target();
        Proxy proxy=new Proxy(new MethodInterceptor() {
            @Override
            public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
                System.out.println("before");
                method.invoke(target,objects);
                return null;
            }
        });

        proxy.save();
        proxy.save(1);
        proxy.save(2l);
    }
}
```


MethodProxy的使用

如果要使用MethodProxy 需要对proxy类以下做出如下改变

```java
package com.spring.aop.cglib.demo;

import org.springframework.cglib.proxy.MethodInterceptor;
import org.springframework.cglib.proxy.MethodProxy;

import java.lang.reflect.Method;

public class Proxy extends Target{
    private MethodInterceptor methodInterceptor;

    static Method method1;
    static Method method2;
    static Method method3;

    static MethodProxy methodProxy1;
    static MethodProxy methodProxy2;
    static MethodProxy methodProxy3;
    static {

        try {
            method1=Target.class.getMethod("save");
            method2=Target.class.getMethod("save",int.class);
            method3=Target.class.getMethod("save",long.class);
            //参数 desc 描述 参数和返回值 . save 增强后的方法  .saveSuper 未增强的方法.
            methodProxy1=MethodProxy.create(Target.class,Proxy.class,"()V","save","saveSuper");
            methodProxy2=MethodProxy.create(Target.class,Proxy.class,"(I)V","save","saveSuper");
            methodProxy3=MethodProxy.create(Target.class,Proxy.class,"(J)V","save","saveSuper");
        } catch (NoSuchMethodException e) {
           throw new RuntimeException("xxxxxx");
        }

    }

    public Proxy(MethodInterceptor methodInterceptor) {
        this.methodInterceptor = methodInterceptor;
    }

    //带原始功能的方法
    public void saveSuper(){
        super.save();
    }

    public void saveSuper(int i){
        super.save(i);
    }

    public void saveSuper(long l){
        super.save(l);
    }
    //带增强功能的方法
    public void  save(){
        try {
            //最后一个参数修改
            methodInterceptor.intercept(this,method1,new Object[0],methodProxy1);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
    public void  save(int i){
        try {
            Object [] objects=new Object[1];
            objects[0]=i;
            //最后一个参数修改
            methodInterceptor.intercept(this,method2,objects,methodProxy2);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
    public void  save(long l){
        try {
            Object [] objects=new Object[1];
            objects[0]=l;
            //最后一个参数修改
            methodInterceptor.intercept(this,method3,objects,methodProxy3);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
    }
}

```

MethodProxy 的原理

上面使用MethodProxy的类实现了可以不经反射调用tager的方法.是如何实现的呢?也就是MethodProxy是如何工作的呢?
实际上还是动态生成了一个FastClass类的子类对象,通过此对象调用tager的方法.

create()方法的时候会生成一个fastclass类 ,不 是两个 针对targer和proxy都生成一个代理类.

[![XIha7T.png](https://s1.ax1x.com/2022/06/15/XIha7T.png)](https://imgtu.com/i/XIha7T)

代理类的功能如下.

```java
public class TargetFastClass extends AbstractFastClass{


    static Signature s0=new Signature("save","()V");
    static Signature s1=new Signature("save","(I)V");
    static Signature s2=new Signature("save","(J)V");

    @Override
    public Object invoke(int i, Object o, Object[] objects) throws InvocationTargetException {
        if(i==0){
            ((Target) o).save();
        }else if(i==1){
            ((Target) o).save((int)objects[0]);
        }else if(i==2){
            ((Target) o).save((long)objects[0]);
        }
        return null;
    }

    @Override
    public int getIndex(Signature signature) {
        if(s0.equals(signature)){
            return 0;
        }else if (s1.equals(signature)){
            return 1;
        }else if(s2.equals(signature)){
            return 2;
        }
        return -1;
    }
}
```

实际上我们去查看源码

[![XI4uvR.png](https://s1.ax1x.com/2022/06/15/XI4uvR.png)](https://imgtu.com/i/XI4uvR)



[![XI4QDx.png](https://s1.ax1x.com/2022/06/15/XI4QDx.png)](https://imgtu.com/i/XI4QDx)

init方法中调用方法生成了fastclass对象

[![XI4DVf.png](https://s1.ax1x.com/2022/06/15/XI4DVf.png)](https://imgtu.com/i/XI4DVf)

余下的更深的源码就不探究了.

fastclass对象结构就类似上面,当调用MethodProxy方法时调用的是动态生成的fastclass对象的invoke方法,invoke又调用了实际的targer的方法.

小结一下:
jdk和cglib都实现了动态代理
jdk的动态代理基于接口,代理类和目标类是兄弟关系.
cglib基于类,代理类和目标类是子父关系,代理类是子.
cglib目标加了final就会失败,不管是类还是方法.
cglib的MethodProxy可以避免使用反射调用.因为内部原理如上所示.
jdk加载了字节码后,字节码的组装生成代理类的字节码.asm技术.
jdk也读反射做了优化,当调用16次之后会生成代理类直接调用对象的方法.

## 5. spring中的代理使用

代理的使用规则 切点实现 通知实现 切面实现

### 5.1 spring默认使用代理的规则

首先使用sping的api进行aop

```java
public class MyTest {
    public static void main(String[] args) {
       /* MyPoint myPoint=new MyPoint();
        myPoint.foo();*/

        //切点
        AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
        pointcut.setExpression("execution(* foo())");

        //通知

        MethodInterceptor advice= methodInvocation -> {
            System.out.println("before");
            Object proceed = methodInvocation.proceed();
            System.out.println("after");
            return proceed;
        };
        //切面
        DefaultPointcutAdvisor advisor=new DefaultPointcutAdvisor(pointcut,advice);
        //代理
        ProxyFactory factory=new ProxyFactory();
        factory.setTarget(new MyPoint());
        factory.addAdvisor(advisor);
        P proxy = (P)factory.getProxy();
        proxy.foo();
        proxy.bar();

    }
}
```

```java
public interface P {
    void foo();
    void bar();
}

public class MyPoint implements P{
    public void foo(){
        System.out.println("foo()");
    }

    @Override
    public void bar() {
        System.out.println("bar ()");
    }
}
```

```txt
class com.spring.aop.aspect.MyPoint$$EnhancerBySpringCGLIB$$7d5a339a
before
foo()
after
bar ()

```

规则如下,spring使用哪种代理.

[![X7CPpQ.png](https://s1.ax1x.com/2022/06/15/X7CPpQ.png)](https://imgtu.com/i/X7CPpQ)

但根据上面的打印很奇怪是使用cglib实现的代理

还需要设置一下interfaces

```java
factory.setInterfaces(Target.class.getInterfaces());
```

切点表达式

原理?
matches方法
```java
 public boolean matches(Method method, Class<?> targetClass) {
        return this.matches(method, targetClass, false);
    }
```

如何匹配加了事务注解的类或方法

[![X7PQ58.png](https://s1.ax1x.com/2022/06/16/X7PQ58.png)](https://imgtu.com/i/X7PQ58)

也是通过matches




### 5.2 @Aspect和Advisor的联系

- @Aspect会被处理成Advisor


[![Xb9pss.png](https://s1.ax1x.com/2022/06/16/Xb9pss.png)](https://imgtu.com/i/Xb9pss)


- bean的生命周期在什么时候处理aop,也是使用后置处理器实现的.
[![X7i2lQ.png](https://s1.ax1x.com/2022/06/16/X7i2lQ.png)](https://imgtu.com/i/X7i2lQ)

```java
package org.springframework.aop.framework.autoproxy;

import com.spring.aop.cglib.demo.Target;
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.aop.Advisor;
import org.springframework.aop.aspectj.AspectJExpressionPointcut;
import org.springframework.aop.aspectj.annotation.AnnotationAwareAspectJAutoProxyCreator;
import org.springframework.aop.support.DefaultPointcutAdvisor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.ConfigurationClassPostProcessor;
import org.springframework.context.support.GenericApplicationContext;

import java.io.IOException;
import java.util.List;

public class TestDemo {
    public static void main(String[] args) throws IOException {
        GenericApplicationContext applicationContext=new GenericApplicationContext();

        applicationContext.registerBean("aspect1",Aspect1.class);
        applicationContext.registerBean("config",Config.class);
        applicationContext.registerBean("target1",Target1.class);

        applicationContext.registerBean(ConfigurationClassPostProcessor.class);

        applicationContext.registerBean(AnnotationAwareAspectJAutoProxyCreator.class);



        applicationContext.refresh();

        //org.springframework.aop.framework.autoproxy
        AnnotationAwareAspectJAutoProxyCreator bean = applicationContext.getBean(AnnotationAwareAspectJAutoProxyCreator.class);
        List<Advisor> target1 = bean.findEligibleAdvisors(Target1.class, "target1");

        for (Advisor advisor : target1) {
            System.out.println(advisor);
        }

        //内部
        Object o = bean.wrapIfNecessary(new Target1(), "target1", "target1");
        Target1 target11=(Target1) o;
        /*for (String beanDefinitionName : applicationContext.getBeanDefinitionNames()) {
            System.out.println(beanDefinitionName);
        }*/
        System.out.println(target11.getClass());
        target11.foo();

        System.in.read();
    }

    static class Target1{
        public void foo(){
            System.out.println("Target1 foo");
        }
    }

    static class Target2{
        public void bar(){
            System.out.println("Target2 bar");
        }
    }

    @Aspect
    static class Aspect1{

        @Before("execution(* foo())")
        public void before(){
            System.out.println("Aspect1 before");
        }

        @After("execution(* foo())")
        public void after(){
            System.out.println("Aspect1 after");
        }
    }

    @Configuration
    static class Config{
        @Bean
        public MethodInterceptor methodInterceptor(){
            return new MethodInterceptor(){

                @Override
                public Object invoke(MethodInvocation methodInvocation) throws Throwable {
                    System.out.println("aspect1 before1");
                    Object proceed = methodInvocation.proceed();
                    return proceed;
                }
            };
        }

        @Bean //低级切面
        public Advisor advisor3(MethodInterceptor methodInterceptor){
            AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
            pointcut.setExpression("execution(* foo())");
            return new DefaultPointcutAdvisor(pointcut,methodInterceptor);
        }
    }
}
```

[![XbFShV.png](https://s1.ax1x.com/2022/06/17/XbFShV.png)](https://imgtu.com/i/XbFShV)

观察输出的图中,查看这个生成的代理类.使用阿尔萨斯

会发现默认使用了cglib生成了代理类.

```java
public class TestDemo$Target1$$EnhancerBySpringCGLIB$$740beadc
        extends TestDemo.Target1
        implements SpringProxy,
        Advised,
        Factory {
    private boolean CGLIB$BOUND;
    public static Object CGLIB$FACTORY_DATA;
    private static final ThreadLocal CGLIB$THREAD_CALLBACKS;
    private static final Callback[] CGLIB$STATIC_CALLBACKS;
    private MethodInterceptor CGLIB$CALLBACK_0;
    private MethodInterceptor CGLIB$CALLBACK_1;
    private NoOp CGLIB$CALLBACK_2;
    private Dispatcher CGLIB$CALLBACK_3;
    private Dispatcher CGLIB$CALLBACK_4;
    private MethodInterceptor CGLIB$CALLBACK_5;
    private MethodInterceptor CGLIB$CALLBACK_6;
    private static Object CGLIB$CALLBACK_FILTER;
    private static final Method CGLIB$foo$0$Method;
    private static final MethodProxy CGLIB$foo$0$Proxy;
    private static final Object[] CGLIB$emptyArgs;
    private static final Method CGLIB$equals$1$Method;
    private static final MethodProxy CGLIB$equals$1$Proxy;
    private static final Method CGLIB$toString$2$Method;
    private static final MethodProxy CGLIB$toString$2$Proxy;
    private static final Method CGLIB$hashCode$3$Method;
    private static final MethodProxy CGLIB$hashCode$3$Proxy;
    private static final Method CGLIB$clone$4$Method;
    private static final MethodProxy CGLIB$clone$4$Proxy;

public final void foo() {
        MethodInterceptor methodInterceptor = this.CGLIB$CALLBACK_0;
        if (methodInterceptor == null) {
            TestDemo$Target1$$EnhancerBySpringCGLIB$$740beadc.CGLIB$BIND_CALLBACKS(this);
            methodInterceptor = this.CGLIB$CALLBACK_0;
        }
        if (methodInterceptor != null) {
            Object object = methodInterceptor.intercept(this, CGLIB$foo$0$Method, CGLIB$emptyArgs, CGLIB$foo$0$Proxy);
            return;
        }
        super.foo();
    }

        }
```

上述只是浅显的讲解

### 5.3 代理对象创建的时机

[![XbF5DJ.png](https://s1.ax1x.com/2022/06/17/XbF5DJ.png)](https://imgtu.com/i/XbF5DJ)


总结一下

如果没有循环依赖,代理在init也就是初始化后被创建

如果有循环依赖,代理在实例化,依赖注入前创建.

order的作用


### 5.4 高级切面转换为低级切面的过程

1. 获取到高级切面类
2. 检查是否标注了切面类注解
3. 通过切点表达式获取一个切点对象

#### 模拟实现

[![XbEABQ.png](https://s1.ax1x.com/2022/06/17/XbEABQ.png)](https://imgtu.com/i/XbEABQ)

各种通知的类型
[![XbEMcT.png](https://s1.ax1x.com/2022/06/17/XbEMcT.png)](https://imgtu.com/i/XbEMcT)


环绕通知

其他通知如何转为环绕通知


[![XbEt41.png](https://s1.ax1x.com/2022/06/17/XbEt41.png)](https://imgtu.com/i/XbEt41)



[![XbEwjO.png](https://s1.ax1x.com/2022/06/17/XbEwjO.png)](https://imgtu.com/i/XbEwjO)


**这种转换过程中采用了适配器模式**

[![XbETEj.png](https://s1.ax1x.com/2022/06/17/XbETEj.png)](https://imgtu.com/i/XbETEj)

随意找一个看一下

```java
public class MethodBeforeAdviceInterceptor implements MethodInterceptor, BeforeAdvice, Serializable {

	private final MethodBeforeAdvice advice;


	/**
	 * Create a new MethodBeforeAdviceInterceptor for the given advice.
	 * @param advice the MethodBeforeAdvice to wrap
	 */
	public MethodBeforeAdviceInterceptor(MethodBeforeAdvice advice) {
		Assert.notNull(advice, "Advice must not be null");
		this.advice = advice;
	}


	@Override
	public Object invoke(MethodInvocation mi) throws Throwable {
		this.advice.before(mi.getMethod(), mi.getArguments(), mi.getThis());
		return mi.proceed();
	}

}
```

MethodBeforeAdviceInterceptor包装了一个MethodBeforeAdvice,使用invoke方法调用了advice.before方法,提供了一种面向MethodBeforeAdviceInterceptor的api.

>注意:在spring中想要让其他通知转为环绕通知需要注册最外层的一个环绕通知
proxyFactory.addAdvice(ExposeInvocationInterceptor.INSTANCE);//准备最外层通知



#### 低级切面的调用链和责任链设计模式

如果使用spring的spi手动的实现aop,类似下面的模式.

```java
public class TestAspect{

    public static void main(String[] args) throws Throwable {
        Method[] declaredMethods = Aspect1.class.getDeclaredMethods();
        AspectInstanceFactory factory= new SingletonAspectInstanceFactory(new Aspect1());

        List<Advisor> list =new ArrayList<>();
        for (Method declaredMethod : declaredMethods) {
            if(declaredMethod.isAnnotationPresent(Before.class)){
                //解析切点
                String value = declaredMethod.getAnnotation(Before.class).value();
                AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
                pointcut.setExpression(value);
                //
                AspectJMethodBeforeAdvice advice=new AspectJMethodBeforeAdvice(declaredMethod,pointcut,factory);

                //低级切面
                Advisor advisor=new DefaultPointcutAdvisor(pointcut,advice);

                list.add(advisor);
            }else if (declaredMethod.isAnnotationPresent(AfterReturning.class)){
                //解析切点
                String value = declaredMethod.getAnnotation(AfterReturning.class).value();
                AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
                pointcut.setExpression(value);
                //
                AspectJAfterReturningAdvice advice=new AspectJAfterReturningAdvice(declaredMethod,pointcut,factory);

                //低级切面
                Advisor advisor=new DefaultPointcutAdvisor(pointcut,advice);

                list.add(advisor);
            }else if (declaredMethod.isAnnotationPresent(Around.class)){
                //解析切点
                String value = declaredMethod.getAnnotation(Around.class).value();
                AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
                pointcut.setExpression(value);
                //
                AspectJAroundAdvice advice = new AspectJAroundAdvice(declaredMethod,pointcut,factory);

                //低级切面
                Advisor advisor=new DefaultPointcutAdvisor(pointcut,advice);

                list.add(advisor);
            }else if(declaredMethod.isAnnotationPresent(After.class)){
                //解析切点
                String value = declaredMethod.getAnnotation(After.class).value();
                AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
                pointcut.setExpression(value);
                //
                AspectJAfterAdvice advice = new AspectJAfterAdvice(declaredMethod,pointcut,factory);

                //低级切面
                Advisor advisor=new DefaultPointcutAdvisor(pointcut,advice);

                list.add(advisor);
            }

        }

        for (Advisor advisor : list) {
            System.out.println(advisor);
        }

        //2 .转换为环绕通知MethodInterceptor
        ProxyFactory proxyFactory=new ProxyFactory();
        Target1 target1=new Target1();
        proxyFactory.setTarget(target1);
        proxyFactory.addAdvice(ExposeInvocationInterceptor.INSTANCE);//准备最外层通知
        proxyFactory.addAdvisors(list);
        System.out.println(">>>>>>>>>>>>>>>>>>>>>>>>>>>");
        List<Object> interceptorsAndDynamicInterceptionAdvice =
                proxyFactory.getInterceptorsAndDynamicInterceptionAdvice(Target1.class.getMethod("foo"),Target1.class);

        for (Object o : interceptorsAndDynamicInterceptionAdvice) {
            System.out.println(o);
        }

        //3 创建调用链条
        MethodInvocation methodInvocation= new ReflectiveMethodInvocation(
                null,
                target1,
                Target1.class.getMethod("foo"),
                new Object[0],
                Target1.class,
                interceptorsAndDynamicInterceptionAdvice){};
        methodInvocation.proceed();
    }

    static class Target1{
        public void foo(){
            System.out.println("Target1 foo");
        }
    }

    static class Target2{
        public void bar(){
            System.out.println("Target2 bar");
        }
    }

    @Aspect
    static class Aspect1{

        @Before("execution(* foo())")
        public void before(){
            System.out.println("Aspect1 before");
        }

        @After("execution(* foo())")
        public void after(){
            System.out.println("Aspect1 after");
        }

        @AfterReturning("execution(* foo())")
        public void aroundReturning(){
            System.out.println("Aspect1 aroundReturning");
        }
        @Around("execution(* foo())")
        public void around(){
            System.out.println("Aspect1 around");
        }
    }

    @Configuration
    static class Config{
        @Bean
        public MethodInterceptor advisor3(){
            return new MethodInterceptor(){

                @Override
                public Object invoke(MethodInvocation methodInvocation) throws Throwable {
                    System.out.println("aspect1 before1");
                    Object proceed = methodInvocation.proceed();
                    return proceed;
                }
            };
        }

        @Bean //低级切面
        public Advisor advisor3(MethodInterceptor advice3){
            AspectJExpressionPointcut pointcut=new AspectJExpressionPointcut();
            pointcut.setExpression("execution(* foo()");
            return new DefaultPointcutAdvisor(pointcut,advice3);
        }
    }
}
```

在  //3 创建调用链条中   将一个interceptorsAndDynamicInterceptionAdvice构造进ReflectiveMethodInvocation

由ReflectiveMethodInvocation的proceed()方法实现责任链模式.

>这种设计模式的好处:
>1. 明确一个点,如果不使用责任链模式,如果要简单的实现,我们要在这个方法中写大量的ifelse,判断某种通知是在切点方法(被增强方法)之前还是之后增强,然后组合他们. 这样做有什么缺点呢? 不够解耦,新的上了就要不断的修改if else.
>2. 或者也可以加入递归,也需要在这个方法中大量的ifelse.
>3. 责任链模式,使用列表中的interceptor的方法,传递Invocation,在interceptor的方法中自己判断在切点方法(被增强方法)之前还是之后增强,这样就与原来方法解耦,需求的改动放到了子类.


#### 动态通知调用

前面讲的例子都是静态通知调用

那动态通知调用是什么,又有什么不同呢.

[![jp5rLR.png](https://s1.ax1x.com/2022/06/22/jp5rLR.png)](https://imgtu.com/i/jp5rLR)

简单来说就是静态通知,不带参数绑定,动态通知,需要处理参数部分.
这里的参数是指被增强方法的参数.

## 小结:
1. 主要先拓展了acj和agent两种代理方式
2. jdk和cglib代理的原理,深入了解,jdk代理主要是使用asm技术,直接生成字节码,代理类和被代理类是父子关系.
cglib使用类来实现,其特点是可以不使用反射调用被代理方法.
3. spring使用反射和动态代理实现了aop,主要是熟悉了spring aop底层的一些api,并使用这些api模拟了spring上层的调用逻辑.
4. 高级切面是如何转为低级切面,以及带参数的和不带参数的通知调用.
5. 主要的一些底层api如 : Pointcut   MethodInterceptor advice advisor ProxyFactory MethodInvocation 
6. MethodInvocation的调用链模式可以组合多个通知增强方法

