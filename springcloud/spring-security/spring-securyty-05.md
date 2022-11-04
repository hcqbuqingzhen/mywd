---
title: spring-security-05 核心配置解读 
date: 2022-01-29 23:22:03
tags: spring-security
---  
 # spring-security-05-核心配置解读 
 

 ## 1.如何配置   

 例子：
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
          .formLogin()
              .loginPage("/login")
              .permitAll()
              .and()
          .logout()
              .permitAll();
  }

  @Autowired
  public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
      auth
          .inMemoryAuthentication()
              .withUser("admin").password("admin").roles("USER");
  }
}
 ```

- 当配置了上述的javaconfig之后，我们的应用便具备了如下的功能：
>1. 除了“/”,”/home”(首页),”/login”(登录),”/logout”(注销),之外，其他路径都需要认证。
指定“/login”该路径为登录页面，当未认证的用户尝试访问任何受保护的资源时，都会跳转到“/login”。
>2. 默认指定“/logout”为注销页面
>3. 配置一个内存中的用户认证器，使用admin/admin作为用户名和密码，具有USER角色
防止CSRF攻击
>4. Session Fixation protection
>5. Security Header(添加一系列和Header相关的控制)

其他的高级配法还需要多多研究。

## 2. 注解探究

@EnableWebSecurity
```java
@Import({ WebSecurityConfiguration.class, // <2>
      SpringWebMvcImportSelector.class }) // <1>
@EnableGlobalAuthentication // <3>
@Configuration
public @interface EnableWebSecurity {
   boolean debug() default false;
}
```
1. SpringWebMvcImportSelector的作用是判断当前的环境是否包含springmvc，因为spring security可以在非spring环境下使用，为了避免DispatcherServlet的重复配置，所以使用了这个注解来区分。
2. WebSecurityConfiguration顾名思义，是用来配置web安全的，下面的小节会详细介绍。
3. @EnableGlobalAuthentication注解的源码如下：

```java
@Import(AuthenticationConfiguration.class)
@Configuration
public @interface EnableGlobalAuthentication {
}
```

注意点同样在@Import之中，它实际上激活了AuthenticationConfiguration这样的一个配置类，用来配置认证相关的核心类。

也就是说：@EnableWebSecurity完成的工作便是加载了WebSecurityConfiguration，AuthenticationConfiguration这两个核心配置类，也就此将spring security的职责划分为了配置安全信息，配置认证信息两部分。

### 2.1 WebSecurityConfiguration
```java
@Configuration
public class WebSecurityConfiguration {

	//DEFAULT_FILTER_NAME = "springSecurityFilterChain"
	@Bean(name = AbstractSecurityWebApplicationInitializer.DEFAULT_FILTER_NAME)
    public Filter springSecurityFilterChain() throws Exception {
    	...
    }

 }
```
WebSecurityConfiguration中完成了声明springSecurityFilterChain的作用，并且最终交给DelegatingFilterProxy这个代理类，负责拦截请求（注意DelegatingFilterProxy这个类不是spring security包中的，而是存在于web包中，spring使用了代理模式来实现安全过滤的解耦）

声明了安全相关的过滤器

### 2.2 AuthenticationConfiguration

```java
@Configuration
@Import(ObjectPostProcessorConfiguration.class)
public class AuthenticationConfiguration {

  	@Bean
	public AuthenticationManagerBuilder authenticationManagerBuilder(
			ObjectPostProcessor<Object> objectPostProcessor) {
		return new AuthenticationManagerBuilder(objectPostProcessor);
	}

  	public AuthenticationManager getAuthenticationManager() throws Exception {
    	...
    }

}
```
AuthenticationConfiguration的主要任务，便是负责生成全局的身份认证管理者AuthenticationManager。

我们之前探究的AuthenticationManager认证管理器就是在这初始化

### 2.3 WebSecurityConfigurerAdapter
>适配器模式在spring中被广泛的使用，在配置中使用Adapter的好处便是，我们可以选择性的配置想要修改的那一部分配置，而不用覆盖其他不相关的配置。WebSecurityConfigurerAdapter中我们可以选择自己想要修改的内容，来进行重写，而其提供了三个configure重载方法
[![7Ns6j1.png](https://s4.ax1x.com/2022/01/16/7Ns6j1.png)](https://imgtu.com/i/7Ns6j1)
由参数就可以知道，分别是对AuthenticationManagerBuilder，WebSecurity，HttpSecurity进行个性化的配置。

1. HttpSecurity常用配置

```java
@Configuration
@EnableWebSecurity
public class CustomWebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .authorizeRequests()
                .antMatchers("/resources/**", "/signup", "/about").permitAll()
                .antMatchers("/admin/**").hasRole("ADMIN")
                .antMatchers("/db/**").access("hasRole('ADMIN') and hasRole('DBA')")
                .anyRequest().authenticated()
                .and()
            .formLogin()
                .usernameParameter("username")
                .passwordParameter("password")
                .failureForwardUrl("/login?error")
                .loginPage("/login")
                .permitAll()
                .and()
            .logout()
                .logoutUrl("/logout")
                .logoutSuccessUrl("/index")
                .permitAll()
                .and()
            .httpBasic()
                .disable();
    }
}
```

他们配置的含义也非常容易通过变量本身来推测，
- authorizeRequests()配置路径拦截，表明路径访问所对应的权限，角色，认证信息。
- formLogin()对应表单认证相关的配置
- logout()对应了注销相关的配置
- httpBasic()可以配置basic登录

2. WebSecurityBuilder

这一部分比较少配置
```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    public void configure(WebSecurity web) throws Exception {
        web
            .ignoring()
            .antMatchers("/resources/**");
    }
}
```

3. AuthenticationManagerBuilder

```java
	/**
	 * 全局用户信息 比如增加验证器。
	 */
	@Override
	public void configure(AuthenticationManagerBuilder auth) {
		PasswordAuthenticationProvider provider = new PasswordAuthenticationProvider();
		provider.setPasswordEncoder(passwordEncoder);
		provider.setUserDetailsServiceFactory(userDetailsServiceFactory);
		auth.authenticationProvider(provider);
	}
```
