 # java中的log
 >我们知道现在spring中默认推荐的log组件是logback,对于java中log的发展历史个使用应该是怎样的呢.

## 1. log的发展史

### 第一阶段
 2001年以前，Java是没有日志库的，打印日志全凭System.out和System.err
### 第二阶段
2001年，一个ceki Gulcü的大佬搞了一个日志框架 log4j后来( log4j成为Apache项目，Ceki加入Apache组织
Apache还曾经建议Sun引入Log4j到Java的标准库中，但Sun拒绝了.
### 第三阶段
sun有自己的小心思，2002年2月JDK1.4发布，Sun推出了自己的日志标准库JUL(Java Util Logging)，其实是照着Log4j抄的，而且还没抄好，还是在JDK1.5以后性能和可用性才有所提升。由于Log4j比JUL好用，并且成熟，所以Log4j在选择上占据了一定的优势
### 第四阶段
2002年8月Apache推出了JCL(Jakarta Commons Logging)，也就是日志抽象层，支持运行时动态加载日志组件的实现，当然也提供一个默认实现Simple Log(在 ClassLoader 中进行查找，如果能找到Log4j则默认使用llog4j实现，如果没有则使用JUL实现，再没有则使用JCL内部提供的 Simple Log实现)
### 第五阶段
 2006年巨佬Ceki( Log4j的作者）因为一些原因离开了Apache组织，之后Ceki觉得JCL不好用，自己搀了一套新的日志标准接口规范Slf4j (Simple Logging Facacfor Java)，也可以称为日志门面，很明显Slf4j是对标JCL，后面也证明了Slf4j比JCL更优秀。
巨佬Ceki提供了一系列的桥接包来帮助Slf4j接口与其他日志库建立关系，这种方式称桥接设计模式。
代码使用Slf4j接口，就可以实现日志的统一标准化，后续如果想要更换日志实现，只需引入Slf4j与相关的桥接包，再引入具体的日志标准库即可。
### 第六阶段
 Ceki巨佬觉得市场上的日志标准库都是间接实现Slf4j接口，也就是说每次都需要配合桥接包，因此在2006年，Ceki巨佬基于Slf4j接口写出了Logback日志标准库，做为Slf4j接口的默认实现，Logback 也十分给力，在功能完整度和性能上超越了所有已有的日志标准库。
### 第七阶段
2012年，Apache直接推出新项目Log4j2(不兼容Log4j) , Log4j2全面借鉴Slf4j+Logback 。
Log4j2不仅仅具有Logback的所有特性，还做了分离设计，分为log4j-api和log4j-core，log4j-api是日志接口，log4j-core是日志标准库，并且Apache也为Log4j2提供了各种桥接包。

画一张图大概如下

[![XC80bj.png](https://s1.ax1x.com/2022/05/24/XC80bj.png)](https://imgtu.com/i/XC80bj)

## 2. 各种日至框架的基本使用
>项目中主要是logback,但是之前的怎么使用这里做个简单总结,至于原理,可以看代码,也可以在网上找一些视频.

### jul
>JUL全称Java util Logging是java原生的日志框架,使用时不需要另外引用第三方类库,相对其他日志框
架使用方便,学习简单,能够在小型应用中灵活使用。

1. 基本入门
```java
public static void main(String[] args) throws IOException {
        // 1.创建日志记录器对象
        Logger logger = Logger.getLogger("com.cq.jul.test.Test");
        // 2.日志记录输出
        logger.info("hello jul");
        logger.log(Level.INFO, "info msg");

        String name = "jack";
        Integer age = 18;
        logger.log(Level.INFO, "用户信息:{0},{1}", new Object[]{name, age});

        testLogConfig();
    }

//日至级别配置
    public static void testLogConfig() throws IOException {
        // 1.创建日志记录器对象
        Logger logger = Logger.getLogger("com.cq.jul.test.Test");

        //关闭默认
        logger.setUseParentHandlers(false);
        //控制台
        ConsoleHandler handler=new ConsoleHandler();

        SimpleFormatter simpleFormatter=new SimpleFormatter();

        handler.setFormatter(simpleFormatter);

        logger.addHandler(handler);
        logger.setLevel(Level.ALL);
        handler.setLevel(Level.ALL);

        //输出放到文件
        File file=new File("/home/hcq/logs/jultest.log");
        if(!file.exists()){
            file.createNewFile();
        }
        FileHandler fileHandler=new FileHandler("/home/hcq/logs/jultest.log");

        fileHandler.setFormatter(simpleFormatter);
        logger.addHandler(fileHandler);

        logger.severe("severe");
        logger.warning("warning");
        logger.info("info");
        logger.config("config");
        logger.fine("fine");
        logger.finer("finer");
        logger.finest("finest");
    }

//日至对象的父子关系
     public static void testLogParent(){
        // 日志记录器对象父子关系
        Logger logger1 = Logger.getLogger("com.itheima.log");
        Logger logger2 = Logger.getLogger("com.itheima");
        System.out.println(logger1.getParent() == logger2);
// 所有日志记录器对象的顶级父元素class为java.util.logging.LogManager$RootLogger
        System.out.println("logger2 parent:" + logger2.getParent() + ",name:" +
                logger2.getParent().getName());


        // 一、自定义日志级别
// a.关闭系统默认配置
        logger2.setUseParentHandlers(false);
// b.创建handler对象
        ConsoleHandler consoleHandler = new ConsoleHandler();
// c.创建formatter对象
        SimpleFormatter simpleFormatter = new SimpleFormatter();
// d.进行关联
        consoleHandler.setFormatter(simpleFormatter);
        logger2.addHandler(consoleHandler);
// e.设置日志级别
        logger2.setLevel(Level.ALL);
        consoleHandler.setLevel(Level.ALL);

        // 测试日志记录器对象父子关系
        logger1.severe("severe");
        logger1.warning("warning");
        logger1.info("info");
        logger1.config("config");
        logger1.fine("fine");
        logger1.finer("finer");
        logger1.finest("finest");
    }
```

2. 配置文件
默认配置文件路径$JAVAHOME\jre\lib\logging.properties
也可以自己写配置文件读取

```java
public static void testProperties() throws IOException {
        // 读取自定义配置文件
        InputStream in =
                JulTest.class.getClassLoader().getResourceAsStream("logging.properties");
// 获取日志管理器对象
        LogManager logManager = LogManager.getLogManager();
// 通过日志管理器加载配置文件
        logManager.readConfiguration(in);

            Logger logger = Logger.getLogger("com.itheima.log.JULTest");
        logger.severe("severe");
        logger.warning("warning");
        logger.info("info");
        logger.config("config");
        logger.fine("fine");
        logger.finer("finer");
        logger.finest("finest");
    }
```

```properties
## RootLogger使用的处理器(获取时设置)
handlers= java.util.logging.ConsoleHandler
# RootLogger日志等级
.level= INFO
## 自定义Logger
com.cq.handlers= java.util.logging.FileHandler
# 自定义Logger日志等级
com.itheima.level= INFO
# 忽略父日志设置
com.cq.useParentHandlers=false
## 控制台处理器
# 输出日志级别
java.util.logging.ConsoleHandler.level = INFO
# 输出日志格式
java.util.logging.ConsoleHandler.formatter = java.util.logging.SimpleFormatter
## 文件处理器
# 输出日志级别
java.util.logging.FileHandler.level=INFO
# 输出日志格式
java.util.logging.FileHandler.formatter = java.util.logging.SimpleFormatter
# 输出日志文件路径
java.util.logging.FileHandler.pattern = /java%u.log
# 输出日志文件限制大小(50000字节)
java.util.logging.FileHandler.limit = 50000
# 输出日志文件限制个数
java.util.logging.FileHandler.count = 10
# 输出日志文件 是否是追加
java.util.logging.FileHandler.append=true
```

### log4j
Log4j是Apache下的一款开源的日志框架,通过在项目中使用 Log4J,我们可以控制日志信息输出到控
制台、文件、甚至是数据库中。我们可以控制每一条日志的输出格式,通过定义日志的输出级别,可以
更灵活的控制日志的输出过程。方便项目的调试。

1. log4j中的抽象组件

Log4J 主要由 Loggers (日志记录器)、Appenders(输出端)和 Layout(日志格式化器)组成。其中
Loggers 控制日志的输出级别与日志是否输出;Appenders 指定日志的输出方式(输出到控制台、文件
等);Layout 控制日志信息的输出格式。

Log4J中有一个特殊的logger叫做“root”,他是所有logger的根,也就意味着其他所有的logger都会直接
或者间接地继承自root。root logger可以用Logger.getRootLogger()方法获取。
但是,自log4j 1.2版以来, Logger 类已经取代了 Category 类。对于熟悉早期版本的log4j的人来说,
Logger 类可以被视为 Category 类的别名。

Appender 用来指定日志输出到哪个地方,可以同时指定日志的输出目的地。

布局器 Layouts用于控制日志输出内容的格式,让我们可以使用各种需要的格式输出日志。

2. 组件在配置文件中的映射
log4j.properties

```properties
#指定日志的输出级别与输出端
log4j.rootLogger=INFO,Console
# 控制台输出配置
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=%d [%t] %-5p [%c] - %m%n
# 文件输出配置
log4j.appender.dailyFile = org.apache.log4j.DailyRollingFileAppender
#指定日志的输出路径
log4j.appender.dailyFile.File = /home/hcq/logs/log.txt
log4j.appender.dailyFile.Append = true
#使用自定义日志格式化器
log4j.appender.dailyFile.layout = org.apache.log4j.PatternLayout
#指定日志的输出格式
log4j.appender.dailyFile.layout.ConversionPattern = %-d{yyyy-MM-dd-HH-mm-ss} [%t:%r] -[%p]%m%n
#指定日志的文件编码
log4j.appender.dailyFile.encoding=UTF-8
#mysql
log4j.appender.logDB=org.apache.log4j.jdbc.JDBCAppender
log4j.appender.logDB.layout=org.apache.log4j.PatternLayout
log4j.appender.logDB.Driver=com.mysql.jdbc.Driver
log4j.appender.logDB.URL=jdbc:mysql://localhost:3306/test
log4j.appender.logDB.User=root
log4j.appender.logDB.Password=root123
log4j.appender.logDB.Sql=INSERT INTO log (project_name,create_date,level,category,file_name,thread_name,line,all_category,message) values('itcast','%d{yyyy-MM-dd HH-mm-ss}','%p','%c','%F','%t','%L','%l','%m')
```

### jcl
>全称为Jakarta Commons Logging,是Apache提供的一个通用日志API。
它是为 "所有的Java日志实现"提供一个统一的接口,它自身也提供一个日志的实现,但是功能非常常弱
(SimpleLog)。所以一般不会单独使用它。他允许开发人员使用不同的具体日志实现工具: Log4j, Jdk
自带的日志(JUL)
JCL 有两个基本的抽象类:Log(基本记录器)和LogFactory(负责创建Log实例)。

1. 导入jar包

```xml
<dependency>
<groupId>commons-logging</groupId>
<artifactId>commons-logging</artifactId>
<version>1.2</version>
</dependency>
```
2. test
```java
public class JULTest {
}
@Test
public void testQuick() throws Exception {
// 创建日志对象
Log log = LogFactory.getLog(JULTest.class);
// 日志记录输出
log.fatal("fatal");
log.error("error");
log.warn("warn");
log.info("info");
log.debug("debug");
}
```

### slf4j
>简单日志门面(Simple Logging Facade For Java) SLF4J主要是为了给Java日志访问提供一套标准、规范
的API框架,其主要意义在于提供接口,具体的实现可以交由其他日志框架,例如log4j和logback等。
当然slf4j自己也提供了功能较为简单的实现,但是一般很少用到。对于一般的Java项目而言,日志框架
会选择slf4j-api作为门面,配上具体的实现框架(log4j、logback等),中间使用桥接器完成桥接。

SLF4J是目前市面上最流行的日志门面。现在的项目中,基本上都是使用SLF4J作为我们的日志系统。

1. 添加依赖
```xml
<!--slf4j core 使用slf4j必須添加-->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>slf4j-api</artifactId>
<version>1.7.27</version>
</dependency>
<!--slf4j 自带的简单日志实现 -->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>slf4j-simple</artifactId>
<version>1.7.27</version>
</dependency>
```

2 .代码

```java
public class Slf4jTest {
// 声明日志对象
public final static Logger LOGGER =
LoggerFactory.getLogger(Slf4jTest.class);
@Test
public void testQuick() throws Exception {
//打印日志信息
LOGGER.error("error");
LOGGER.warn("warn");
LOGGER.info("info");
LOGGER.debug("debug");
LOGGER.trace("trace");
// 使用占位符输出日志信息
String name = "jack";
Integer age = 18;
LOGGER.info("用户:{},{}", name, age);
}
}
// 将系统异常信息写入日志
try {
int i = 1 / 0;
} catch (Exception e) {
// e.printStackTrace();
LOGGER.info("出现异常:", e);
}
```

3. slf4j对其他日至实现的绑定

   1. 添加slf4j-api的依赖
   2. 使用slf4j的API在项目中进行统一的日志记录
   3. 绑定具体的日志实现框架
      1. 绑定已经实现了slf4j的日志框架,直接添加对应依赖
      2. 绑定没有实现slf4j的日志框架,先添加日志的适配器,再添加实现类的依赖
   4. slf4j有且仅有一个日志实现框架的绑定(如果出现多个默认使用第一个依赖日志实现)

4. slf4j的桥接器

slf4j-api出现的时候,logback还没有实现,接入其他的日至实现需要桥接器.

如果我们要使用SLF4J的桥接器,替换原有的日志框架,那么我们需要做的第一件事情,就是删除掉原
有项目中的日志框架的依赖。然后替换成SLF4J提供的桥接器。

```xml
<!-- log4j-->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>log4j-over-slf4j</artifactId>
<version>1.7.27</version>
</dependency>
<!-- jul
 -->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>jul-to-slf4j</artifactId>
<version>1.7.27</version>
</dependency>
<!--jcl -->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>jcl-over-slf4j</artifactId>
<version>1.7.27</version>
</dependency>
```

### logbcak

Logback主要分为三个模块:
logback-core:其它两个模块的基础模块
logback-classic:它是log4j的一个改良版本,同时它完整实现了slf4j API
logback-access:访问模块与Servlet容器集成提供通过Http来访问日志的功能

1. 入门

```xml
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>slf4j-api</artifactId>
<version>1.7.25</version>
</dependency>
<dependency>
<groupId>ch.qos.logback</groupId>
<artifactId>logback-classic</artifactId>
<version>1.2.3</version>
</dependency>
```

```java
//定义日志对象
public final static Logger LOGGER =
LoggerFactory.getLogger(LogBackTest.class);
@Test
public void testSlf4j(){
//打印日志信息
LOGGER.error("error");
LOGGER.warn("warn");
LOGGER.info("info");
LOGGER.debug("debug");
LOGGER.trace("trace");
}
```
2. logbcak的配置

logbcak使用xml配置

logback组件之间的关系
1. Logger:日志的记录器,把它关联到应用的对应的context上后,主要用于存放日志对象,也
可以定义日志类型、级别。
2. Appender:用于指定日志输出的目的地,目的地可以是控制台、文件、数据库等等。
3. Layout:负责把事件转换成字符串,格式化的日志信息的输出。在logback中Layout对象被封
装在encoder中。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false">
    <!--定义日志文件的存储地址 勿在 LogBack 的配置中使用相对路径-->
    <property name="LOG_HOME" value="/home/hcq/logs"/>
    <property name="APP_NAME" value="logback-test"/>

    <!-- 控制台输出 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg %n</pattern>
        </encoder>
    </appender>

    <!-- 按照每天生成日志文件 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_HOME}/${APP_NAME}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_HOME}/${APP_NAME}.log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>15</maxHistory>
        </rollingPolicy>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- 应用的日志(错误级别)文件 -->
    <appender name="ERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_HOME}/${APP_NAME}-error.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_HOME}/${APP_NAME}-error-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>15</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%date %level [%thread] %logger{40}[%file-%M %line] %msg%n
            </pattern>
        </encoder>

        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>ERROR</level>
            <onMatch>ACCEPT</onMatch><!-- 只接收错误级别的日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>
    <root level="ALL">
        <appender-ref ref="STDOUT"/>
        <appender-ref ref="ERROR"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```

3. logbcak-access

ogback-access模块与Servlet容器(如Tomcat和Jetty)集成,以提供HTTP访问日志功能。我们可以使
用logback-access模块来替换tomcat的访问日志。
- 将logback-access.jar与logback-core.jar复制到$TOMCAT_HOME/lib/目录下
- 修改$TOMCAT_HOME/conf/server.xml中的Host元素中添加:
```xml
<Valve className="ch.qos.logback.access.tomcat.LogbackValve" />
```
- logback默认会在$TOMCAT_HOME/conf下查找文件 logback-access.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
<!-- always a good activate OnConsoleStatusListener -->
<statusListener
class="ch.qos.logback.core.status.OnConsoleStatusListener"/>
<property name="LOG_DIR" value="${catalina.base}/logs"/>
<appender name="FILE"
class="ch.qos.logback.core.rolling.RollingFileAppender">
<file>${LOG_DIR}/access.log</file>
<rollingPolicy
class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
<fileNamePattern>access.%d{yyyy-MM-dd}.log.zip</fileNamePattern>
</rollingPolicy>
<encoder>
<!-- 访问日志的格式 -->
<pattern>combined</pattern>
</encoder>
</appender>
<appender-ref ref="FILE"/>
</configuration>
```

### log4j2
Apache Log4j 2是对Log4j的升级版,参考了logback的一些优秀的设计,并且修复了一些问题,因此带
来了一些重大的提升

我认为最重要的是两个
1. 异步日至
2. 无垃圾机制

1. 入门

```xml
<!-- Log4j2 门面API-->
<dependency>
<groupId>org.apache.logging.log4j</groupId>
<artifactId>log4j-api</artifactId>
<version>2.11.1</version>
</dependency>
<!-- Log4j2 日志实现 -->
<dependency>
<groupId>org.apache.logging.log4j</groupId>
<artifactId>log4j-core</artifactId>
<version>2.11.1</version>
</dependency>
```

```java

public class Log4j2Test {
// 定义日志记录器对象
public static final Logger LOGGER =
LogManager.getLogger(Log4j2Test.class);
}
@Test
public void testQuick() throws Exception {
LOGGER.fatal("fatal");
LOGGER.error("error");
LOGGER.warn("warn");
LOGGER.info("info");
LOGGER.debug("debug");
LOGGER.trace("trace");
}
```

当我们使用slf4j门面的时候

```xml
<!-- Log4j2 日志实现 -->
<dependency>
<groupId>org.apache.logging.log4j</groupId>
<artifactId>log4j-core</artifactId>
<version>2.11.1</version>
</dependency>
<!--使用slf4j作为日志的门面,使用log4j2来记录日志 -->
<dependency>
<groupId>org.slf4j</groupId>
<artifactId>slf4j-api</artifactId>
<version>1.7.25</version>
</dependency>
<!--为slf4j绑定日志实现
 log4j2的适配器 -->
<dependency>
<groupId>org.apache.logging.log4j</groupId>
<artifactId>log4j-slf4j-impl</artifactId>
<version>2.10.0</version>
</dependency>
```
2. 配置
log4j2.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn" monitorInterval="5">
<properties>
<property</properties>
name="LOG_HOME">D:/logs</property>
<Appenders>
<Console name="Console" target="SYSTEM_OUT">
<PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] [%-5level] %c{36}:%L --- %m%n" />
</Console>
<File name="file" fileName="${LOG_HOME}/myfile.log">
<PatternLayout pattern="[%d{yyyy-MM-dd HH:mm:ss.SSS}] [%-5level] %l%c{36} - %m%n" />
</File>
<RandomAccessFile name="accessFile" fileName="${LOG_HOME}/myAcclog.log">
<PatternLayout pattern="[%d{yyyy-MM-dd HH:mm:ss.SSS}] [%-5level] %l%c{36} - %m%n" />
</RandomAccessFile>
<RollingFile name="rollingFile" fileName="${LOG_HOME}/myrollog.log"
filePattern="D:/logs/$${date:yyyy-MM-dd}/myrollog-%d{yyyy-MM-dd-HH-mm}-%i.log">
<ThresholdFilter level="debug" onMatch="ACCEPT" onMismatch="DENY" />
<PatternLayout pattern="[%d{yyyy-MM-dd HH:mm:ss.SSS}] [%-5level] %l%c{36} - %msg%n" />
<Policies>
<OnStartupTriggeringPolicy />
<SizeBasedTriggeringPolicy size="10 MB" />
<TimeBasedTriggeringPolicy />
</Policies>
<DefaultRolloverStrategy max="30" />
</RollingFile>
</Appenders>
<Loggers>
<Root level="trace">
<AppenderRef ref="Console" />
</Root>
</Loggers>
</Configuration>
```

3. 异步日志
```xml
<!--异步日志依赖-->
<dependency>
<groupId>com.lmax</groupId>
<artifactId>disruptor</artifactId>
<version>3.3.4</version>
</dependency>
```

- AsyncAppender方式

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn">
    <properties>
        <property name="LOG_HOME">D:/logs</property>
    </properties>
    <Appenders>
        <File name="file" fileName="${LOG_HOME}/myfile.log">
            <PatternLayout>
                <Pattern>%d %p %c{1.} [%t] %m%n</Pattern>
            </PatternLayout>
        </File>
        <Async name="Async">
            <AppenderRef ref="file"/>
        </Async>
    </Appenders>
    <Loggers>
        <Root level="error">
            <AppenderRef ref="file"/>
        </Root>
    </Loggers>
</Configuration>

```

- AsyncLogger方式

    - 全局异步就是,所有的日志都异步的记录,在配置文件上不用做任何改动,只需要添加一个
log4j2.component.properties 配置;
Log4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerCon
textSelector
    - 混合异步

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="WARN">
    <properties>
        <property name="LOG_HOME">D:/logs</property>
    </properties>
    <Appenders>
        <File name="file" fileName="${LOG_HOME}/myfile.log">
            <PatternLayout>
                <Pattern>%d %p %c{1.} [%t] %m%n</Pattern>
            </PatternLayout>
        </File>
        <Async name="Async">
            <AppenderRef ref="file"/>
        </Async>
    </Appenders>
    <Loggers>
        <AsyncLogger name="com.cq" level="trace"
                     includeLocation="false" additivity="false">
            <AppenderRef ref="file"/>
        </AsyncLogger>
        <Root level="info" includeLocation="true">
            <AppenderRef ref="file"/>
        </Root>
    </Loggers>
</Configuration>
```
如上配置: com.cq 日志是异步的,root日志是同步的。


## 3. 在springboot中使用日志

>springboot框架在企业中的使用越来越普遍,springboot日志也是开发中常用的日志系统。springboot
默认就是使用SLF4J作为日志门面,logback作为日志实现来记录日志。

```xml
<dependency>
<artifactId>spring-boot-starter-logging</artifactId>
<groupId>org.springframework.boot</groupId>
</dependency>
```

1. 入门

```java
@SpringBootTest
class SpringbootLogApplicationTests {
//记录器
public static final Logger LOGGER =
LoggerFactory.getLogger(SpringbootLogApplicationTests.class);
@Test
public void contextLoads() {
// 打印日志信息
LOGGER.error("error");
LOGGER.warn("warn");
LOGGER.info("info"); // 默认日志级别
LOGGER.debug("debug");
LOGGER.trace("trace");
}
}
```

2. 修改日至配置

```
logging.level.com.cq=trace
#
 在控制台输出的日志的格式
 同logback
logging.pattern.console=%d{yyyy-MM-dd} [%thread] [%-5level] %logger{50} -
%msg%n
# 指定文件中日志输出的格式
logging.file=D:/logs/springboot.log
logging.pattern.file=%d{yyyy-MM-dd} [%thread] %-5level %logger{50} - %msg%n
```

3. xml配置文件

logback-spring.xml:由SpringBoot解析日志配置
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false">
    <!--定义日志文件的存储地址 勿在 LogBack 的配置中使用相对路径-->
    <property name="LOG_HOME" value="/home/hcq/logs"/>
    <springProperty scope="context" name="APP_NAME" source="spring.application.name"/>

    <!-- 控制台输出 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg %n</pattern>
        </encoder>
    </appender>

    <!-- 按照每天生成日志文件 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_HOME}/${APP_NAME}.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_HOME}/${APP_NAME}.log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>15</maxHistory>
        </rollingPolicy>
        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
        </encoder>
    </appender>

    <!-- 应用的日志(错误级别)文件 -->
    <appender name="ERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>${LOG_HOME}/${APP_NAME}-error.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_HOME}/${APP_NAME}-error-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>15</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>%date %level [%thread] %logger{40}[%file-%M %line] %msg%n
            </pattern>
        </encoder>

        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>ERROR</level>
            <onMatch>ACCEPT</onMatch><!-- 只接收错误级别的日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
    </appender>

    <springProfile name="dev">
        <root level="INFO">
            <appender-ref ref="STDOUT"/>
            <appender-ref ref="FILE"/>
            <appender-ref ref="ERROR"/>
        </root>
    </springProfile>

    <springProfile name="test,prod">
        <root level="INFO">
            <appender-ref ref="FILE"/>
            <appender-ref ref="ERROR"/>
        </root>
    </springProfile>

</configuration>
```

4. 修改为默认的为log4j2

 ```xml
 <dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-starter-web</artifactId>
<exclusions>
<!--排除logback-->
<exclusion>
<artifactId>spring-boot-starter-logging</artifactId>
<groupId>org.springframework.boot</groupId>
</exclusion>
</exclusions>
</dependency>
<!-- 添加log4j2 -->
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>
 ```



 ## 小结
 1. java中log的发展历程是log4j->jul->jcl->slf4j->logbcak->log4j2
 2. 现在常用的是slf4j+logback,在springboot项目中通过logback-spring.xml修改配置
 3. log4j2性能有很大提升,主要是由于异步日至和无垃圾机制
 4. 以后的项目中log4j2可能成为主流,要多加关注,自己的项目中也可以尝试使用.在spring项目中log4j2-spring.xml 为默认的配置.