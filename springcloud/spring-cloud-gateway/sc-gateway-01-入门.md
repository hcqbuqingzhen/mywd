---
title: sc-gateway 入门
date: 2021-12-06 21:39:10
tags: spring-cloud-gateway
---
## sc-gateway 入门
本文中sc-gateway，指的是spring-cloud-gateway  

1.这是一个基于Spring技术栈构建的API网关，涉及到：Spring5、Spring Boot 2、Reactor等，目标是为项目提供简单高效的API路由，以及强大的扩展能力：安全、监控、弹性计算等  
2.官方架构图如下，可见请求到来后，由Handler Mapping决定请求对应的真实目标，然后交给Web Handler，由一系列过滤器(filter)执行链式处理，从红色箭头和注释可以发现，请求前后都有过滤器在运行：  

### 1.启动nacos  
- 启动

```shell
startup.sh -m standalone
```
- 浏览器登录nacos，地址是http://localhost:8848/nacos，账号和密码都是nacos  
  
 ### 2.在父工程中添加以下依赖  
 
 - 本教程的父工程为rrs-人人书平台
  
  ```xml
  <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
        <java.version>1.8</java.version>
        <spring-cloud.version>2020.0.1</spring-cloud.version>
        <spring-cloud-alibaba.version>2021.1</spring-cloud-alibaba.version>
    </properties>

    <packaging>pom</packaging>
    <description>Demo project for Spring Cloud </description>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>com.alibaba.cloud</groupId>
                <artifactId>spring-cloud-alibaba-dependencies</artifactId>
                <version>${spring-cloud-alibaba.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
            <dependency>
                <groupId>com.squareup.okhttp3</groupId>
                <artifactId>okhttp</artifactId>
                <version>3.14.9</version>
                <scope>compile</scope>
            </dependency>
            <dependency>
                <groupId>ch.qos.logback</groupId>
                <artifactId>logback-classic</artifactId>
                <version>1.1.7</version>
            </dependency>
            <dependency>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>1.16.16</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
  ```
  

  ### 3 创建名为common的子工程

  ```java
  public interface Constants {
    String HELLO_PREFIX = "Hello World";
}
  ```  
- 在common工程中添加一个类，用于其他工程使用  

### 4. 创建web应用，作为服务提供方  

- hello是个普通的springboot应用，会在nacos进行注册  

```xml
<dependencies>

        <dependency>
            <groupId>com.bolingcavalry</groupId>
            <artifactId>common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!--nacos:用于服务注册与发现-->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-config</artifactId>
        </dependency>

        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <!-- 如果父工程不是springboot，就要用以下方式使用插件，才能生成正常的jar -->
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <mainClass>com.bolingcavalry.provider.ProviderApplication</mainClass>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>repackage</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```  

- yml

```yml
server:
  #服务端口
  port: 8082

spring:
  application:
    name: rrs-hello
  cloud:
    nacos:
      discovery:
        # nacos服务地址
        server-addr: 127.0.0.1:8848
```  

- 启动类

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
public class ProviderApplication {
    public static void main(String[] args) {
        SpringApplication.run(ProviderApplication.class, args);
    }
}
```

- hello中添加控制器

```java
import com.bolingcavalry.common.Constants;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.text.SimpleDateFormat;
import java.util.Date;

@RestController
@RequestMapping("/hello")
public class Hello {

    private String dateStr(){
        return new SimpleDateFormat("yyyy-MM-dd hh:mm:ss").format(new Date());
    }

    /**
     * 返回字符串类型
     * @return
     */
    @GetMapping("/str")
    public String helloStr() {
        return Constants.HELLO_PREFIX + ", " + dateStr();
    }
}
```  

### 5 创建网关工程

- 新增名为sc-gateway的子工程  

```xml
<dependencies>
        <dependency>
            <groupId>com.bolingcavalry</groupId>
            <artifactId>common</artifactId>
            <version>${project.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>

        <dependency>
            <groupId>io.projectreactor</groupId>
            <artifactId>reactor-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
```  

- yml  

```yml
server:
  #服务端口
  port: 8081
spring:
  application:
    name: sc-gateway
  cloud:
    gateway:
      routes:
        - id: path_route
          # 匹配成功后，会被转发到8082端口，至于端口后面的path，会直接使用原始请求的
          # 例如http://127.0.0.1:8081/hello/str，会被转发到http://127.0.0.1:8082/hello/str
          uri: http://127.0.0.1:8082
          predicates:
            # 根据请求路径中带有"/hello/"，就算匹配成功
          - Path=/hello/**

```

- 启动类

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class HelloGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(HelloGatewayApplication.class,args);
    }
}
```

### 6 实验
- 启动sc-gateway工程
- 启动hello服务
- 浏览器访问8081:/hello/str,会被转发到8082:/hello/str

本文仅仅是启动网关，用默认的路由配置方式实现了路由转发。  

下文将会使用，lb负载均衡更，nacos配置，代码配置来实现路由。