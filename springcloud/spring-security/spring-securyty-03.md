---
title: spring-securyty-03 过滤器和核心过滤器
date: 2022-01-29 22:40:19
tags: spring-security
---  
# spring-securyty-03 过滤器和核心过滤器
>前面的部分，我们关注了Spring Security是如何完成认证工作的，但是另外一部分核心的内容：过滤器，一直没有提到，我们已经知道Spring Security使用了springSecurityFilterChain作为了安全过滤的入口，这一节主要分析一下这个过滤器链都包含了哪些关键的过滤器，并且各自的使命是什么。

## 1. 核心过滤器概述

```java
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

从第一大节里已经从控制台发现了过滤器链，除去项目中添加的两个过滤器5,6，默认的有十一个过滤器，主要是摸清这十一个中重点过滤器的作用。

1. **SecurityContextPersistenceFilter** 两个主要职责：请求来临时，创建SecurityContext安全上下文信息，请求结束时清空SecurityContextHolder。
2. HeaderWriterFilter (文档中并未介绍，非核心过滤器) 用来给http响应添加一些Header,比如X-Frame-Options, X-XSS-Protection*，X-Content-Type-Options.
3. CsrfFilter 在spring4这个版本中被默认开启的一个过滤器，用于防止csrf攻击，了解前后端分离的人一定不会对这个攻击方式感到陌生，前后端使用json交互需要注意的一个问题。
4. LogoutFilter 顾名思义，处理注销的过滤器
5. **UsernamePasswordAuthenticationFilter** 这个会重点分析，表单提交了username和password，被封装成token进行一系列的认证，便是主要通过这个过滤器完成的，在表单认证的方法中，这是最最关键的过滤器。
6. RequestCacheAwareFilter (文档中并未介绍，非核心过滤器) 内部维护了一个RequestCache，用于缓存request请求
7. SecurityContextHolderAwareRequestFilter 此过滤器对ServletRequest进行了一次包装，使得request具有更加丰富的API
8. **AnonymousAuthenticationFilter** 匿名身份过滤器，这个过滤器个人认为很重要，需要将它与UsernamePasswordAuthenticationFilter 放在一起比较理解，spring security为了兼容未登录的访问，也走了一套认证流程，只不过是一个匿名的身份。
9. SessionManagementFilter 和session相关的过滤器，内部维护了一个SessionAuthenticationStrategy，两者组合使用，常用来防止session-fixation protection attack，以及限制同一用户开启多个会话的数量
10. **ExceptionTranslationFilter** 直译成异常翻译过滤器，还是比较形象的，这个过滤器本身不处理异常，而是将认证过程中出现的异常交给内部维护的一些类去处理，具体是那些类下面详细介绍
11. **FilterSecurityInterceptor** 这个过滤器决定了访问特定路径应该具备的权限，访问的用户的角色，权限是什么？访问的路径需要什么样的角色和权限？这些判断和处理都是由该类进行的。

其中加粗的过滤器可以被认为是Spring Security的核心过滤器，将在下面，一个过滤器对应一个小节来讲解。

## 2. SecurityContextPersistenceFilter
>- 试想一下，如果我们不使用Spring Security，如果保存用户信息呢，大多数情况下会考虑使用Session对吧？在Spring Security中也是如此，用户在登录过一次之后，后续的访问便是通过sessionId来识别，从而认为用户已经被认证。
>- 具体在何处存放用户信息，便是第一篇文章中提到的SecurityContextHolder；认证相关的信息是如何被存放到其中的，便是通过SecurityContextPersistenceFilter。
>- 在第一节中提到了，SecurityContextPersistenceFilter的两个主要作用便是请求来临时，创建SecurityContext安全上下文信息和请求结束时清空SecurityContextHolder。
>- 顺带提一下：微服务的一个设计理念需要实现服务通信的无状态，而http协议中的无状态意味着不允许存在session，这可以通过setAllowSessionCreation(false) 实现，这并不意味着SecurityContextPersistenceFilter变得无用，因为它还需要负责清除用户信息。在Spring Security中，虽然安全上下文信息被存储于Session中，但我们在实际使用中不应该直接操作Session，而应当使用SecurityContextHolder。

源码如下
```java
public class SecurityContextPersistenceFilter extends GenericFilterBean {

   static final String FILTER_APPLIED = "__spring_security_scpf_applied";
   //安全上下文存储的仓库
   private SecurityContextRepository repo;

   public SecurityContextPersistenceFilter() {
      //HttpSessionSecurityContextRepository是SecurityContextRepository接口的一个实现类
      //使用HttpSession来存储SecurityContext
      this(new HttpSessionSecurityContextRepository());
   }

   public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
         throws IOException, ServletException {
      HttpServletRequest request = (HttpServletRequest) req;
      HttpServletResponse response = (HttpServletResponse) res;

      if (request.getAttribute(FILTER_APPLIED) != null) {
         // ensure that filter is only applied once per request
         chain.doFilter(request, response);
         return;
      }
      request.setAttribute(FILTER_APPLIED, Boolean.TRUE);
      //包装request，response
      HttpRequestResponseHolder holder = new HttpRequestResponseHolder(request,
            response);
      //从Session中获取安全上下文信息
      SecurityContext contextBeforeChainExecution = repo.loadContext(holder);
      try {
         //请求开始时，设置安全上下文信息，这样就避免了用户直接从Session中获取安全上下文信息
         SecurityContextHolder.setContext(contextBeforeChainExecution);
         chain.doFilter(holder.getRequest(), holder.getResponse());
      }
      finally {
         //请求结束后，清空安全上下文信息
         SecurityContext contextAfterChainExecution = SecurityContextHolder
               .getContext();
         SecurityContextHolder.clearContext();
         repo.saveContext(contextAfterChainExecution, holder.getRequest(),
               holder.getResponse());
         request.removeAttribute(FILTER_APPLIED);
         if (debug) {
            logger.debug("SecurityContextHolder now cleared, as request processing completed");
         }
      }
   }

}
```

> 过滤器一般负责核心的处理流程，而具体的业务实现，通常交给其中聚合的其他实体类，这在Filter的设计中很常见，同时也符合职责分离模式。例如存储安全上下文和读取安全上下文的工作完全委托给了HttpSessionSecurityContextRepository去处理，而这个类中也有几个方法可以稍微解读下，方便我们理解内部的工作流程

**org.springframework.security.web.context.HttpSessionSecurityContextRepository**
```java
public class HttpSessionSecurityContextRepository implements SecurityContextRepository {
   // 'SPRING_SECURITY_CONTEXT'是安全上下文默认存储在Session中的键值
   public static final String SPRING_SECURITY_CONTEXT_KEY = "SPRING_SECURITY_CONTEXT";
   ...
   private final Object contextObject = SecurityContextHolder.createEmptyContext();
   private boolean allowSessionCreation = true;
   private boolean disableUrlRewriting = false;
   private String springSecurityContextKey = SPRING_SECURITY_CONTEXT_KEY;

   private AuthenticationTrustResolver trustResolver = new AuthenticationTrustResolverImpl();

   //从当前request中取出安全上下文，如果session为空，则会返回一个新的安全上下文
   public SecurityContext loadContext(HttpRequestResponseHolder requestResponseHolder) {
      HttpServletRequest request = requestResponseHolder.getRequest();
      HttpServletResponse response = requestResponseHolder.getResponse();
      HttpSession httpSession = request.getSession(false);
      SecurityContext context = readSecurityContextFromSession(httpSession);
      if (context == null) {
         context = generateNewContext();
      }
      ...
      return context;
   }

   ...

   public boolean containsContext(HttpServletRequest request) {
      HttpSession session = request.getSession(false);
      if (session == null) {
         return false;
      }
      return session.getAttribute(springSecurityContextKey) != null;
   }

   private SecurityContext readSecurityContextFromSession(HttpSession httpSession) {
      if (httpSession == null) {
         return null;
      }
      ...
      // Session存在的情况下，尝试获取其中的SecurityContext
      Object contextFromSession = httpSession.getAttribute(springSecurityContextKey);
      if (contextFromSession == null) {
         return null;
      }
      ...
      return (SecurityContext) contextFromSession;
   }

   //初次请求时创建一个新的SecurityContext实例
   protected SecurityContext generateNewContext() {
      return SecurityContextHolder.createEmptyContext();
   }

}
```

>SecurityContextPersistenceFilter和HttpSessionSecurityContextRepository配合使用，构成了Spring Security整个调用链路的入口，为什么将它放在最开始的地方也是显而易见的，后续的过滤器中大概率会依赖Session信息和安全上下文信息。

## 3.UsernamePasswordAuthenticationFilter

[![7tLrHU.png](https://s4.ax1x.com/2022/01/16/7tLrHU.png)](https://imgtu.com/i/7tLrHU)

> 上述的时序图，可以看出UsernamePasswordAuthenticationFilter主要肩负起了调用身份认证器，校验身份的作用，至于认证的细节，在前面几章花了很大篇幅进行了介绍，到这里，其实Spring Security的基本流程就已经走通了。

源码
```java
public Authentication attemptAuthentication(HttpServletRequest request,
      HttpServletResponse response) throws AuthenticationException {
   //获取表单中的用户名和密码
   String username = obtainUsername(request);
   String password = obtainPassword(request);
   ...
   username = username.trim();
   //组装成username+password形式的token
   UsernamePasswordAuthenticationToken authRequest = new UsernamePasswordAuthenticationToken(
         username, password);
   // Allow subclasses to set the "details" property
   setDetails(request, authRequest);
   //交给内部的AuthenticationManager去认证，并返回认证信息
   return this.getAuthenticationManager().authenticate(authRequest);
}
```

其实大部分逻辑是其父类完成的
```java
public abstract class AbstractAuthenticationProcessingFilter extends GenericFilterBean
      implements ApplicationEventPublisherAware, MessageSourceAware {
	//包含了一个身份认证器
	private AuthenticationManager authenticationManager;
	//用于实现remeberMe
	private RememberMeServices rememberMeServices = new NullRememberMeServices();
	private RequestMatcher requiresAuthenticationRequestMatcher;
	//这两个Handler很关键，分别代表了认证成功和失败相应的处理器
	private AuthenticationSuccessHandler successHandler = new SavedRequestAwareAuthenticationSuccessHandler();
	private AuthenticationFailureHandler failureHandler = new SimpleUrlAuthenticationFailureHandler();

	public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
			throws IOException, ServletException {

		HttpServletRequest request = (HttpServletRequest) req;
		HttpServletResponse response = (HttpServletResponse) res;
		...
		Authentication authResult;
		try {
			//此处实际上就是调用UsernamePasswordAuthenticationFilter的attemptAuthentication方法
			authResult = attemptAuthentication(request, response);
			if (authResult == null) {
				//子类未完成认证，立刻返回
				return;
			}
			sessionStrategy.onAuthentication(authResult, request, response);
		}
		//在认证过程中可以直接抛出异常，在过滤器中，就像此处一样，进行捕获
		catch (InternalAuthenticationServiceException failed) {
			//内部服务异常
			unsuccessfulAuthentication(request, response, failed);
			return;
		}
		catch (AuthenticationException failed) {
			//认证失败
			unsuccessfulAuthentication(request, response, failed);
			return;
		}
		//认证成功
		if (continueChainBeforeSuccessfulAuthentication) {
			chain.doFilter(request, response);
		}
		//注意，认证成功后过滤器把authResult结果也传递给了成功处理器
		successfulAuthentication(request, response, chain, authResult);
	}

}
```

可以看到只要是login就会进行身份的验证
[![7tvXFS.png](https://s4.ax1x.com/2022/01/16/7tvXFS.png)](https://imgtu.com/i/7tvXFS)

## 4.AnonymousAuthenticationFilter
>匿名认证过滤器，可能有人会想：匿名了还有身份？我自己对于Anonymous匿名身份的理解是Spirng Security为了整体逻辑的统一性，即使是未通过认证的用户，也给予了一个匿名身份。而AnonymousAuthenticationFilter该过滤器的位置也是非常的科学的，它位于常用的身份认证过滤器（如UsernamePasswordAuthenticationFilter、BasicAuthenticationFilter、RememberMeAuthenticationFilter）之后，意味着只有在上述身份过滤器执行完毕后，SecurityContext依旧没有用户信息，AnonymousAuthenticationFilter该过滤器才会有意义—-基于用户一个匿名身份。

**org.springframework.security.web.authentication.AnonymousAuthenticationFilter**
```java
public class AnonymousAuthenticationFilter extends GenericFilterBean implements
      InitializingBean {

   private AuthenticationDetailsSource<HttpServletRequest, ?> authenticationDetailsSource = new WebAuthenticationDetailsSource();
   private String key;
   private Object principal;
   private List<GrantedAuthority> authorities;


   //自动创建一个"anonymousUser"的匿名用户,其具有ANONYMOUS角色
   public AnonymousAuthenticationFilter(String key) {
      this(key, "anonymousUser", AuthorityUtils.createAuthorityList("ROLE_ANONYMOUS"));
   }

   /**
    *
    * @param key key用来识别该过滤器创建的身份
    * @param principal principal代表匿名用户的身份
    * @param authorities authorities代表匿名用户的权限集合
    */
   public AnonymousAuthenticationFilter(String key, Object principal,
         List<GrantedAuthority> authorities) {
      Assert.hasLength(key, "key cannot be null or empty");
      Assert.notNull(principal, "Anonymous authentication principal must be set");
      Assert.notNull(authorities, "Anonymous authorities must be set");
      this.key = key;
      this.principal = principal;
      this.authorities = authorities;
   }

   ...

   public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
         throws IOException, ServletException {
      //过滤器链都执行到匿名认证过滤器这儿了还没有身份信息，塞一个匿名身份进去
      if (SecurityContextHolder.getContext().getAuthentication() == null) {
         SecurityContextHolder.getContext().setAuthentication(
               createAuthentication((HttpServletRequest) req));
      }
      chain.doFilter(req, res);
   }

   protected Authentication createAuthentication(HttpServletRequest request) {
     //创建一个AnonymousAuthenticationToken
      AnonymousAuthenticationToken auth = new AnonymousAuthenticationToken(key,
            principal, authorities);
      auth.setDetails(authenticationDetailsSource.buildDetails(request));

      return auth;
   }
   ...
}
```

## 5. ExceptionTranslationFilter

>1. ExceptionTranslationFilter异常转换过滤器位于整个springSecurityFilterChain的后方，用来转换整个链路中出现的异常，将其转化，顾名思义，转化以意味本身并不处理。一般其只处理两大类异常：AccessDeniedException访问异常和AuthenticationException认证异常。
>2. 这个过滤器非常重要，因为它将Java中的异常和HTTP的响应连接在了一起，这样在处理异常时，我们不用考虑密码错误该跳到什么页面，账号锁定该如何，只需要关注自己的业务逻辑，抛出相应的异常便可。
>3. 如果该过滤器检测到AuthenticationException，则将会交给内部的AuthenticationEntryPoint去处理，如果检测到AccessDeniedException，需要先判断当前用户是不是匿名用户，如果是匿名访问，则和前面一样运行AuthenticationEntryPoint，否则会委托给AccessDeniedHandler去处理，而AccessDeniedHandler的默认实现，是AccessDeniedHandlerImpl。所以ExceptionTranslationFilter内部的AuthenticationEntryPoint是至关重要的，顾名思义：认证的入口点。

```java
public class ExceptionTranslationFilter extends GenericFilterBean {
  //处理异常转换的核心方法
  private void handleSpringSecurityException(HttpServletRequest request,
        HttpServletResponse response, FilterChain chain, RuntimeException exception)
        throws IOException, ServletException {
     if (exception instanceof AuthenticationException) {
       	//重定向到登录端点
        sendStartAuthentication(request, response, chain,
              (AuthenticationException) exception);
     }
     else if (exception instanceof AccessDeniedException) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authenticationTrustResolver.isAnonymous(authentication) || authenticationTrustResolver.isRememberMe(authentication)) {
		  //重定向到登录端点
           sendStartAuthentication(
                 request,
                 response,
                 chain,
                 new InsufficientAuthenticationException(
                       "Full authentication is required to access this resource"));
        }
        else {
           //交给accessDeniedHandler处理
           accessDeniedHandler.handle(request, response,
                 (AccessDeniedException) exception);
        }
     }
  }
}
```
那么什么是AuthenticationEntryPoint，认证实例端点。

之前配置springSecurity时，去探究如何配置。
formLogin()配置了之后最起码做了两件事，其一，为UsernamePasswordAuthenticationFilter设置了相关的配置，其二配置了AuthenticationEntryPoint。
```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
                .antMatchers("/", "/home").permitAll()
                .anyRequest().authenticated()
                .and()
            .formLogin()//FormLoginConfigurer
                .loginPage("/login")
                .permitAll()
                .and()
            .logout()
                .permitAll();
    }
}

配置类
public abstract class AbstractAuthenticationFilterConfigurer extends ...{
   ...
   //formLogin不出所料配置了AuthenticationEntryPoint
   private LoginUrlAuthenticationEntryPoint authenticationEntryPoint;
   //认证失败的处理器
   private AuthenticationFailureHandler failureHandler;
   ...
}
```

EntryPoint就可以理解为某一个端点，比如登陆的端点，登陆失败的端点。当我们在认证过程中，抛出异常类，当过滤器走到这里，会自动帮我们转到定义的端点。

## 6.FilterSecurityInterceptor

>1. 想想整个认证安全控制流程还缺了什么？我们已经有了认证，有了请求的封装，有了Session的关联…还缺一个：由什么控制哪些资源是受限的，这些受限的资源需要什么权限，需要什么角色…这一切和访问控制相关的操作，都是由FilterSecurityInterceptor完成的。
>2. FilterSecurityInterceptor的工作流程用笔者的理解可以理解如下：FilterSecurityInterceptor从SecurityContextHolder中获取Authentication对象，然后比对用户拥有的权限和资源所需的权限。前者可以通过Authentication对象直接获得，而后者则需要引入我们之前一直未提到过的两个类：SecurityMetadataSource，AccessDecisionManager。理解清楚决策管理器的整个创建流程和SecurityMetadataSource的作用需要花很大一笔功夫，这里，暂时只介绍其大概的作用。

在JavaConfig的配置中，我们通常如下配置路径的访问控制：
```java
@Override
protected void configure(HttpSecurity http) throws Exception {
	http
		.authorizeRequests()
			.antMatchers("/resources/**", "/signup", "/about").permitAll()
             .antMatchers("/admin/**").hasRole("ADMIN")
             .antMatchers("/db/**").access("hasRole('ADMIN') and hasRole('DBA')")
             .anyRequest().authenticated()
			.withObjectPostProcessor(new ObjectPostProcessor<FilterSecurityInterceptor>() {
				public <O extends FilterSecurityInterceptor> O postProcess(
						O fsi) {
					fsi.setPublishAuthorizationSuccess(true);
					return fsi;
				}
			});
}
```