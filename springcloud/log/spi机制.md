# jdk的spi机制
>前面学习日志门面时了解到slf4j使用了spi机制,联想到之前数据库链接也是spi机制.包括java定义了很多接口,如xml的接口,servlet接口,都是用spi机制实现的.因此有必要对这一部分进行学习.

本节先自己实现一个简单的spi,然后再看一下原理.
## 1.什么是SPI
SPI 的全称为 (Service Provider Interface)，是 JDK 内置的一种服务提供发现机制。主要由工具类 java.util.ServiceLoader 提供相应的支持。
SPI是一种动态替换发现的机制， 比如有个接口，想运行时动态的给它添加实现，你只需要添加一个实现。我们经常遇到的就是java.sql.Driver接口，其他不同厂商可以针对同一接口做出不同的实现，mysql和postgresql都有不同的实现提供给用户，而Java的SPI机制可以为某个接口寻找服务实现。

SPI 将服务接口和具体的服务实现分离开来，将服务调用方和服务实现者解耦，能够提升程序的扩展性、可维护性。修改或者替换服务实现并不需要修改调用方。

**api和spi的区别**
当实现方提供了接口和实现，我们可以通过调用实现方的接口从而拥有实现方给我们提供的能力，这就是 API ，这种接口和实现都是放在实现方的。

当接口存在于调用方这边时，就是 SPI ，由接口调用方确定接口规则，然后由不同的厂商去根绝这个规则对这个接口进行实现，从而提供服务，举个通俗易懂的例子：公司 H 是一家科技公司，新设计了一款芯片，然后现在需要量产了，而市面上有好几家芯片制造业公司，这个时候，只要 H 公司指定好了这芯片生产的标准（定义好了接口标准），那么这些合作的芯片公司（服务提供者）就按照标准交付自家特色的芯片（提供不同方案的实现，但是给出来的结果是一样的）。

## 2.spi实现
>我设想有一种技术叫做mogo(其实这种技术并不存在),因为这项技术很火暴(假的),java定义了mogo服务的接口.然后其他mogo技术的实现提供了被调用方.
项目图如下
- spi定义方 

[![XwAU4H.png](https://s1.ax1x.com/2022/06/05/XwAU4H.png)](https://imgtu.com/i/XwAU4H)

- spi提供方

[![XwAsDf.png](https://s1.ax1x.com/2022/06/05/XwAsDf.png)](https://imgtu.com/i/XwAsDf)

- spi使用方

[![XwAyb8.png](https://s1.ax1x.com/2022/06/05/XwAyb8.png)](https://imgtu.com/i/XwAyb8)
### 2.1. 服务定义

- 其实就是定义一个接口,定义一个工厂类.
MogoServer
```java
package org.spi.mogo.service;

import org.spi.mogo.core.Mogo;

public interface MogoServer {
    Mogo getMogo();
}
```

MogoFactory
```java
public class MogoFactory {
    public static MogoServer getMogo(){
        ServiceLoader<MogoServer> load = ServiceLoader.load(MogoServer.class); //java实现
        for (MogoServer mogoServer : load) {
            return mogoServer;
        }
        return null;
    }
}
```

### 2.2 服务提供
其实就是实现定义方实现的接口
NiceMogoServer

```java
public class NiceMogoServer implements MogoServer {

    @Override
    public Mogo getMogo() {
        System.out.println("找到我了");
        return null;
    }
}
```
Resource下面创建META-INF/services 目录里创建一个以服务接口命名的文件
服务名为: org.spi.mogo.service.MogoServer
里面的值为: org.spi.nicemogo.service.NiceMogoServer

### 2.3 测试类
新建一个模块,将这两个项目在pom文件中引入.

```xml
<dependencies>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>spidef</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
        <dependency>
            <groupId>org.example</groupId>
            <artifactId>spipro</artifactId>
            <version>1.0-SNAPSHOT</version>
        </dependency>
    </dependencies>
```
SpiTest
```java
package org.spi.test;

import org.spi.mogo.MogoFactory;
import org.spi.mogo.service.MogoServer;

public class SpiTest {
    public static void main(String[] args) {
        MogoServer mogo = MogoFactory.getMogo();
        mogo.getMogo();
    }
}
```

运行这个测试类,会发现服务会自动加载了.
[![XwATbT.png](https://s1.ax1x.com/2022/06/05/XwATbT.png)](https://imgtu.com/i/XwATbT)

## 3. spi原理浅析

大致浏览一下源码

1. 首先构造了了一个ServiceLoader对象.这个过程中并没有其他操作,那肯定是在迭代中进行了加载.
[![XwV9ln.png](https://s1.ax1x.com/2022/06/05/XwV9ln.png)](https://imgtu.com/i/XwV9ln)
2. 要加载肯定要加载我们自己写的类 META-INF/services/肯定会用到

```java
    private static final String PREFIX = "META-INF/services/";
```
3. 搜索PREFIX

[![XwVgpj.png](https://s1.ax1x.com/2022/06/05/XwVgpj.png)](https://imgtu.com/i/XwVgpj)

会发现在这里会尝试通过目录获取信息,存到一个中间枚举中.

4. nextService会将这个类反射获取一个对象返回.同时自己维护了Providers,存储所有服务.
[![XwVhn0.png](https://s1.ax1x.com/2022/06/05/XwVhn0.png)](https://imgtu.com/i/XwVhn0)



## 小结

1. spi是一种一种服务发现机制,与spi项目,接口定义于服务调用者.
2. spi实现: 1. 定义方提供接口,使用ServiceLoader.load()方法加载服务 2. 服务提供者实现接口类,并于META-INF/services中增加一个名为接口名,内容为实现者的文件.
3. 源码方面,ServiceLoader.load()采用了懒加载,当调用服务时才加载,并通过ClassLoader.getSystemResources(fullName)加载文件.反射获取对象.
4. spring也实现了spi,与jdk的不同.它们的基本原理都是一样的，都是通过 ClassLoader.getResources 方法找到相应的配置文件，然后解析文件得到服务提供者的全限定名。