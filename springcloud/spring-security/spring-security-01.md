---
title: spring-security-01-介绍
date: 2022-01-28 20:40:19
tags: spring-security
---
# spring-security-介绍
>spring-security这个认证框架从我一开始学习java就知道了,但工作中也一直没用到，直到现在有个需求让我解决微服务中使用oauth2统一认证，发现spring-oauth2是基于spring-security的。但做的时候没有认真来看spring-security，只是使用网上的办法解决了统一认证的问题，但每每想起建立的基础还不了解，就心里面不踏实，因此静下心来看看security。

## 01 security是什么  

>安全方面的两个主要区域是“认证”和“授权”（或者访问控制），一般来说，Web 应用的安全性包括用户认证（Authentication）和用户授权（Authorization）两个部分，这两点也是 Spring Security 重要核心功能。

- 用户认证指的是：验证某个用户是否为系统中的合法主体，也就是说用户能否访问该系统。用户认证一般要求用户提供用户名和密码。系统通过校验用户名和密码来完成认证过程。通俗点说就是系统认为用户是否能登录

- 用户授权指的是验证某个用户是否有权限执行某个操作。
>在一个系统中，不同用户所具有的权限是不同的。比如对一个文件来说，有的用户只能进行读取，而有的用户可以进行修改。一般来说，系统会为不同的用户分配不同的角色，而每个角色则对应一系列的权限。通俗点讲就是系统判断用户是否有权限去做某些事情。  


初学java的时候，如果解决认证登陆，一般最简单的是写个servlet来认证，后来又学习了filter,知道了可以在filter中校验，对于访问权限也可以简单的使用filter实现。但这样只是最简单的做法，真实项目中需要解决的与认证和权限以及攻击防护相关的内容很复杂。   

spring-security就是这样一个认证和授权的框架，同时也包含了其他的一些强大的功能。    

在实现上是一系列的过滤器加核心认证类。
https://www.springcloud.cc/spring-security-zhcn.html
官方网站有很全面的使用介绍。

## 02 过滤器链

```txt
o.s.security.web.DefaultSecurityFilterChain - Creating filter chain: any request,  
[
1
org.springframework.security.web.context.request.async.WebAsyncManagerIntegrationFilter@22781286, 
2
org.springframework.security.web.context.SecurityContextPersistenceFilter@5aa026e9,
3
 org.springframework.security.web.header.HeaderWriterFilter@42365c82, 
4
 org.springframework.security.web.authentication.logout.LogoutFilter@7e474bd, 
5
 com.xsyw.oauth.filter.LoginProcessSetTenantFilter@11564455, 
6
 com.xsyw.oauth.tenant.TenantUsernamePasswordAuthenticationFilter@3bc6c10f, 
7
 org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter@1ae8556c, 
8
 org.springframework.security.web.savedrequest.RequestCacheAwareFilter@499f9003, 
9
 org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter@39bd07fe, 
10
 org.springframework.security.web.authentication.AnonymousAuthenticationFilter@173c0722, 
11
 org.springframework.security.web.session.SessionManagementFilter@46c47690, 
12
 org.springframework.security.web.access.ExceptionTranslationFilter@1c61f9bf, 
13
 org.springframework.security.web.access.intercept.FilterSecurityInterceptor@5f7dbdfa] 
```

上面是引入了spring-security的项目启动时打印的日志，除了5和6是自定义的过滤器，其他为框架内置的过滤器。每一种过滤器都有其作用，我们将在后面逐一讲解。

因为这是个oauth2统一认证的项目，在引入了oauth2后会打印如下另一条过滤器链条。  

```shell
[requestMatchers=[Ant [pattern='/oauth/token'], Ant [pattern='/oauth/token_key'], Ant [pattern='/oauth/check_token']]],   
[
1
org.springframework.security.web.context.request.async.WebAsyncManagerIntegrationFilter@20f94e9a, 
2
org.springframework.security.web.context.SecurityContextPersistenceFilter@54af9cce, 
3
org.springframework.security.web.header.HeaderWriterFilter@7c59f315, 
4
org.springframework.security.web.authentication.logout.LogoutFilter@35129b9e, 
5
org.springframework.security.oauth2.provider.client.ClientCredentialsTokenEndpointFilter@704ca8a8, 
6
org.springframework.security.web.authentication.www.BasicAuthenticationFilter@17a756db, 
7
org.springframework.security.web.savedrequest.RequestCacheAwareFilter@6cb1da13, 
8
org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter@539953af, 
9
org.springframework.security.web.authentication.AnonymousAuthenticationFilter@3f213e97,
10
org.springframework.security.web.session.SessionManagementFilter@65689000, 
11 
org.springframework.security.web.access.ExceptionTranslationFilter@2bd67cf9, 
12
org.springframework.security.web.access.intercept.FilterSecurityInterceptor@7926d092] 
```

上面的不出意外都是内置的过滤器。  

简单的认识之后
接下来就是springsecurity的源码探究，包括以下几点。
- 认证流程
- 过滤器和核心过滤器
- 过滤器链的加载流程和原理
- 实现一个过滤器
- 如何配置，配置的原理。
- oauth2认证，在oauth2之前走了哪些过滤器。