# springmvc相关


## 1. DispatcherServlet初始化

DispatcherServlet由spring创建,初始化由tomcat容器完成.

[![j93jC4.png](https://s1.ax1x.com/2022/06/22/j93jC4.png)](https://imgtu.com/i/j93jC4)

当然也可以自己制定什么时候初始化,也可以在配置文件中配置,入上图所示.

初始化过程

```java
 */
	@Override
	protected void onRefresh(ApplicationContext context) {
		initStrategies(context);
	}

	/**
	 * Initialize the strategy objects that this servlet uses.
	 * <p>May be overridden in subclasses in order to initialize further strategy objects.
	 */
	protected void initStrategies(ApplicationContext context) {
		initMultipartResolver(context); //文件上传解析器
		initLocaleResolver(context); //国际化解析器
		initThemeResolver(context);  //
		initHandlerMappings(context); // *1 路径映射
		initHandlerAdapters(context);  // *2  处理请求(请求入口)
		initHandlerExceptionResolvers(context); //  *3 异常处理
		initRequestToViewNameTranslator(context);
		initViewResolvers(context); //*4 视图解析器
		initFlashMapManager(context);
	}
```

### 1.1 initHandlerMappings过程 

RequestMappingHandlerMappings基本用途
初始化的时候就将RequestMappingHandlerMappings扫描到容器中
RequestMappingHandlerMappings是HandlerMapping子类


[![j9yaLT.png](https://s1.ax1x.com/2022/06/22/j9yaLT.png)](https://imgtu.com/i/j9yaLT)


因为默认RequestMappingHandlerMapping是不会加入spring容器的

所以需要在容器中加入RequestMappingHandlerMappings

Controller1
```java
@Controller
public class Controller1 {

    @GetMapping("/method1")
    public void method1(){
        System.out.println("method1");
    }
}

```

WebConfig
```java
@Configuration
@ComponentScan
public class WebConfig {
    //1. 内置web容器工厂
    @Bean
    public TomcatServletWebServerFactory tomcatServletWebServerFactory(){
        return new TomcatServletWebServerFactory(8080);
    }

    //2. DispatcherServlet
    @Bean
    public DispatcherServlet dispatcherServlet(){
        return  new DispatcherServlet();
    }

    //注册到服务器容器
    @Bean
    public DispatcherServletRegistrationBean dispatcherServletRegistrationBean(DispatcherServlet dispatcherServlet){
        return new DispatcherServletRegistrationBean(dispatcherServlet,"/");
    }


    //加入RequestMappingHandlerMappings //因为默认RequestMappingHandlerMapping是不会加入spring容器的
    @Bean
    public RequestMappingHandlerMapping requestMappingHandlerMapping(){
        return  new RequestMappingHandlerMapping();
    }

}
```

TestDemo

```java
public class TestDemo {
    public static void main(String[] args) throws Exception {
        AnnotationConfigServletWebServerApplicationContext context=
                new AnnotationConfigServletWebServerApplicationContext(WebConfig.class);
        //解析@RequestMapping 及派生注解,生成路径与控制器方法的映射关系. 初始化时就生成
        RequestMappingHandlerMapping bean = context.getBean(RequestMappingHandlerMapping.class);
        //查看
        Map<RequestMappingInfo, HandlerMethod> handlerMethods = bean.getHandlerMethods();

        handlerMethods.forEach((k,v)->{
            System.out.println(k+"="+v);
        });
        //如何根据请求获取方法
        HandlerExecutionChain get = bean.getHandler(new MockHttpServletRequest("GET", "/method1"));
        //HandlerExecutionChain 除了本身之外还有一些拦截器

        System.out.println(get);

    }
}

```


### 1.2 RequestMappingHandlerAdapter
是HandlerAdapter的子类

1. RequestMappingHandlerAdapter使用

MyRequestMappingHandlerAdapter
```java
@Component
public class MyRequestMappingHandlerAdapter extends RequestMappingHandlerAdapter {

    public ModelAndView invokeHandlerMethod(HttpServletRequest request,
                                            HttpServletResponse response, HandlerMethod handlerMethod) throws Exception {
        return super.invokeHandlerMethod(request,response,handlerMethod);
    }
}
```
RequestMappingHandlerAdapter的invokeHandlerMethod方法是protected 因此需要这样

WebConfig 增加
```java
//HandlerAdapter
    @Bean
    public RequestMappingHandlerAdapter requestMappingHandlerAdapter(){
        return new RequestMappingHandlerAdapter();
    }
```

```java
public class TestDemo {
    public static void main(String[] args) throws Exception {
        AnnotationConfigServletWebServerApplicationContext context=
                new AnnotationConfigServletWebServerApplicationContext(WebConfig.class);
        //解析@RequestMapping 及派生注解,生成路径与控制器方法的映射关系. 初始化时就生成
        RequestMappingHandlerMapping bean = context.getBean(RequestMappingHandlerMapping.class);
        //查看
        Map<RequestMappingInfo, HandlerMethod> handlerMethods = bean.getHandlerMethods();

        handlerMethods.forEach((k,v)->{
            System.out.println(k+"="+v);
        });
        //如何根据请求获取方法
        HandlerExecutionChain chain = bean.getHandler(new MockHttpServletRequest("GET", "/method1"));
        //HandlerExecutionChain 除了本身之外还有一些拦截器

        System.out.println(chain);

        System.out.println(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        //测试 HandlerAdapter
        MyRequestMappingHandlerAdapter handlerAdapter = context.getBean(MyRequestMappingHandlerAdapter.class);

        handlerAdapter.invokeHandlerMethod(new MockHttpServletRequest("GET", "/method1"),
                new MockHttpServletResponse(),(HandlerMethod) chain.getHandler());

    }
}

```

### 1.3 参数解析器和返回值解析器初识

```java
//参数解析器
        List<HandlerMethodArgumentResolver> argumentResolvers = handlerAdapter.getArgumentResolvers();
        for (HandlerMethodArgumentResolver argumentResolver : argumentResolvers) {
            System.out.println(argumentResolver);
        }
        //返回值解析器
        System.out.println(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        List<HandlerMethodReturnValueHandler> returnValueHandlers = handlerAdapter.getReturnValueHandlers();
        for (HandlerMethodReturnValueHandler returnValueHandler : returnValueHandlers) {
            System.out.println(returnValueHandler);
        }
```

### 1.4 自定义参数解析器

1. 自定义注解
[![j9h0PO.png](https://s1.ax1x.com/2022/06/22/j9h0PO.png)](https://imgtu.com/i/j9h0PO)

2. 自定义注解解析器
[![j9hyMd.png](https://s1.ax1x.com/2022/06/22/j9hyMd.png)](https://imgtu.com/i/j9hyMd)

3. 将参数解析器配置进
[![j9hRdP.png](https://s1.ax1x.com/2022/06/22/j9hRdP.png)](https://imgtu.com/i/j9hRdP)

4. 使用注解
[![j9hlPU.png](https://s1.ax1x.com/2022/06/22/j9hlPU.png)](https://imgtu.com/i/j9hlPU)


5. 测试注解
[![j9hUVx.png](https://s1.ax1x.com/2022/06/22/j9hUVx.png)](https://imgtu.com/i/j9hUVx)

自定义返回值处理器

例如想要让返回值是yml格式

1. 自定义注解
[![j94ZWD.png](https://s1.ax1x.com/2022/06/22/j94ZWD.png)](https://imgtu.com/i/j94ZWD)

2. 自定义注解

[![j94QeI.png](https://s1.ax1x.com/2022/06/22/j94QeI.png)](https://imgtu.com/i/j94QeI)

3. 配置注解

[![j94tSg.png](https://s1.ax1x.com/2022/06/22/j94tSg.png)](https://imgtu.com/i/j94tSg)


4. 使用注解

[![j94mSe.png](https://s1.ax1x.com/2022/06/22/j94mSe.png)](https://imgtu.com/i/j94mSe)

5. 测试注解

[![j94v7t.png](https://s1.ax1x.com/2022/06/22/j94v7t.png)](https://imgtu.com/i/j94v7t)



**参数解析器原理**

## 2 参数解析器相关

### 2.1 常见参数解析器

[![jmAYV0.png](https://s1.ax1x.com/2022/06/28/jmAYV0.png)](https://imgtu.com/i/jmAYV0)

如上图所示
注意一点,有时不加注解也能解析.
ModelAttribute  key=value这种
User  key=value这种
RequestBody  json数据


- ArgController

```java
public class ArgController {
    public void test(
            @RequestParam("age") int age,
            @RequestParam("name") String name1,
            String name2,
            @RequestParam(name="home",defaultValue = "ssss") String home1,
            @RequestParam("file")MultipartFile file,
            @PathVariable("id") String id,
            @RequestHeader("Content-Type") String header,
            @CookieValue("token") String token,
            @Value("${server.port}") int port,
            HttpServletRequest request,
            @ModelAttribute User user1,
            User user2,
            @RequestBody User user3
            ){

    }
}
```

- User

```java
public class User {
    private String name;
    private int age;
    private String id;
    private String home;
}
class WebConfig {

}
```
- TestArgRes

```java
public class TestArgRes {
    public static void main(String[] args) throws Exception {
        AnnotationConfigApplicationContext context=new AnnotationConfigApplicationContext(WebConfig.class);
        DefaultListableBeanFactory defaultListableBeanFactory = context.getDefaultListableBeanFactory();
        //测试request
        HttpServletRequest request=mockRequest();

        //1控制器方法转为handlermethod
        HandlerMethod handlerMethod=new HandlerMethod(new ArgController(),
                ArgController.class.getMethod("test",int.class,String.class,
                        String.class,String.class, MultipartFile.class,String.class,
                        String.class,String.class,String.class,HttpServletRequest.class,
                        User.class,User.class,User.class));

        //2.准备对象帮顶与类型转换
        DefaultDataBinderFactory factory=new ServletRequestDataBinderFactory(null,null);
        //3.准备mv容器对象.
        ModelAndViewContainer container =new ModelAndViewContainer();

        //4.解析参数
        for (MethodParameter methodParameter : handlerMethod.getMethodParameters()) {
            //defaultListableBeanFactory可以解析参数中的spring el表达式  第二个蚕食是否必须requestparam注解
            //RequestParamMethodArgumentResolver resolver=new RequestParamMethodArgumentResolver(defaultListableBeanFactory,false);
            //组合模式的应用
            List<HttpMessageConverter<?>> list=new ArrayList<>();
            list.add(new MappingJackson2HttpMessageConverter());
            HandlerMethodArgumentResolverComposite composite=new HandlerMethodArgumentResolverComposite();
            composite.addResolvers(
                    new RequestParamMethodArgumentResolver(defaultListableBeanFactory,false),
                    new PathVariableMethodArgumentResolver(),
                    new RequestHeaderMethodArgumentResolver(defaultListableBeanFactory),
                    new ServletCookieValueMethodArgumentResolver(defaultListableBeanFactory),
                    new ExpressionValueMethodArgumentResolver(defaultListableBeanFactory),
                    new ServletRequestMethodArgumentResolver(),
                    new ServletModelAttributeMethodProcessor(false), //spring中是这样处理的
                    new RequestResponseBodyMethodProcessor(list),
                    new ServletModelAttributeMethodProcessor(true), //弄了两个分别处理
                    new RequestParamMethodArgumentResolver(defaultListableBeanFactory,true)

            );
            //参数名解析器
            methodParameter.initParameterNameDiscovery(new DefaultParameterNameDiscoverer());
            //查看注解
            String ann = Arrays.stream(methodParameter.getParameterAnnotations()).map(a -> a.annotationType().getSimpleName()).
                    collect(Collectors.joining());
            if(ann.length()>0){
                ann="@"+ann;
            }else {
                ann="@"+"null";
            }
            if(composite.supportsParameter(methodParameter)){
                //支持此参数
                Object o = composite.resolveArgument(methodParameter, container, new ServletWebRequest(request), factory);
                System.out.println(ann + ":" + methodParameter.getParameterIndex() + ":" +
                        methodParameter.getParameterType() + "+" + methodParameter.getParameterName()+"->"+o);
            }else {
                System.out.println(ann + ":" + methodParameter.getParameterIndex() + ":" +
                        methodParameter.getParameterType() + "+" + methodParameter.getParameterName());
            }
        }

    }
    public static  HttpServletRequest mockRequest(){
        MockHttpServletRequest request=new MockHttpServletRequest();
        request.setAttribute("name1","zhangsan");
        request.setParameter("name2","lisi");
        request.addPart(new MockPart("file","file","hello".getBytes(StandardCharsets.UTF_8)));
        //下面这个参数应当是handlemapping来做的,实际上.在这里手动实现,内部也是按照这种方式吧url放到Attribute中
        Map<String,String>  pathVariable=new AntPathMatcher().
                extractUriTemplateVariables("/test/{id}","/test/123");
        request.setAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE,pathVariable);

        request.setCookies(new Cookie("token","123456"));
        request.setParameter("name","张三");
        request.setParameter("age","18");
        request.setParameter("id","12345678");
        //request.setParameter("home","sijiapo");
        request.setContentType("multipart/form-data");
        request.setContent("\\\"{ \\\"name\\\": \\\"lisi\\\",\\\"age\\\": 20,\\\"id\\\": \\\"1213244\\\",\\\"home\\\": \\\"riben\\\"}\\\"".getBytes());
        return request;
    }
}

```

运行打印如下

[![jmu76O.png](https://s1.ax1x.com/2022/06/29/jmu76O.png)](https://imgtu.com/i/jmu76O)


上面中
HandlerMethodArgumentResolverComposite composite=new HandlerMethodArgumentResolverComposite();

HandlerMethodArgumentResolverComposite组合了其他的Resolver.使用了组合模式.

[![jM1fyR.png](https://s1.ax1x.com/2022/06/30/jM1fyR.png)](https://imgtu.com/i/jM1fyR)
如上图
ModelAttribute解析器解析完后会将数据放到ModelAndViewContainer

**上述过程中的细节**

### 2.2 获取参数名的过程

**参数名的的获取并不是那么简单.**

[![jM3Ijs.png](https://s1.ax1x.com/2022/06/30/jM3Ijs.png)](https://imgtu.com/i/jM3Ijs)

如上图编译完后变量为var1,var2.

如何让方法的变量名保存到class文件中

[![jM37Bq.png](https://s1.ax1x.com/2022/06/30/jM37Bq.png)](https://imgtu.com/i/jM37Bq)

1. 是可以加编译参数,反射获取得到,

[![jM3jCF.png](https://s1.ax1x.com/2022/06/30/jM3jCF.png)](https://imgtu.com/i/jM3jCF)

2. 是可以加-g的参数,反射不可以获取到方法的参数名.但可以通过asm api获取参数名.

3. 总结如下

[![jM8CHx.png](https://s1.ax1x.com/2022/06/30/jM8CHx.png)](https://imgtu.com/i/jM8CHx)

上面是前置知识点

spring可以获取1中的参数名,有他自己的api.可以访问本地变量表,通过
[![jM8abq.png](https://s1.ax1x.com/2022/06/30/jM8abq.png)](https://imgtu.com/i/jM8abq)

[![jM8rPU.png](https://s1.ax1x.com/2022/07/01/jM8rPU.png)](https://imgtu.com/i/jM8rPU)

本地变量表通过接口是获取不到方法的参数名的


### 2.3 对象绑定和类型转换

这里实际上是mvc将http中数据拿来组装为对象,或者转换为java数据类型的原理.

两套底层转换接口

一套高层转换接口

底层1 

[![jMGz01.png](https://s1.ax1x.com/2022/07/01/jMGz01.png)](https://imgtu.com/i/jMGz01)

底层2 

[![jMJaNV.png](https://s1.ax1x.com/2022/07/01/jMJaNV.png)](https://imgtu.com/i/jMJaNV)

第二套是jdk实现的,spring最开始的版本是按照jdk的接口实现的,后来改用自己设计的.

高层接口

[![jMJv8S.png](https://s1.ax1x.com/2022/07/01/jMJv8S.png)](https://imgtu.com/i/jMJv8S)


类型转换示例
[![jGnGSe.png](https://s1.ax1x.com/2022/07/03/jGnGSe.png)](https://imgtu.com/i/jGnGSe)

基本上就是这四种接口的简单使用.

其中mvc将数据转换为bean是由以下的类实现的

```java
public class TestServletDateBinder {
    public static void main(String[] args) {
        MyBean bean=new MyBean();
        ServletRequestDataBinder dataBinder=new ServletRequestDataBinder(bean);
        MockHttpServletRequest request=new MockHttpServletRequest();
        request.setParameter("a","10");
        request.setParameter("b","server");
        request.setParameter("c","1990/08/18");

        dataBinder.bind(new ServletRequestParameterPropertyValues(request));
        System.out.println(bean);
    }

    static class MyBean{
        private int a;
        private String b;
        private Date c;

        @Override
        public String toString() {
            return "MyBean{" +
                    "a=" + a +
                    ", b='" + b + '\'' +
                    ", c=" + c +
                    '}';
        }

        public int getA() {
            return a;
        }

        public void setA(int a) {
            this.a = a;
        }

        public String getB() {
            return b;
        }

        public void setB(String b) {
            this.b = b;
        }

        public Date getC() {
            return c;
        }

        public void setC(Date c) {
            this.c = c;
        }
    }
}

```


#### 2.3.1 绑定器工厂

属性为自定义格式,往往会失败.
属性有子父结构,是可以自动转换的.
[![jG8lxf.png](https://s1.ax1x.com/2022/07/03/jG8lxf.png)](https://imgtu.com/i/jG8lxf)

这时候就需要自定义绑定器工厂来实现
有几种选择

首先是使用工厂,但无转换功能

>一是@initbinder来实现.---jdk的接口
>一种是使用conversionservice 实现----spring的接口
>若两个都加,默认使用spring的

1. 实例使用@initbinder
用ConversionService实现

都在下面代码示例中

```java
public class TestServletDateBinderFactory {
    public static void main(String[] args) throws Exception {
        MyBean bean=new MyBean();
        MyBean bean1=new MyBean();
        //ServletRequestDataBinder dataBinder=new ServletRequestDataBinder(bean);
        MockHttpServletRequest request=new MockHttpServletRequest();
        request.setParameter("a","10");
        request.setParameter("b.d","server");
        request.setParameter("c","1990|8|18");
        //无扩展
        //ServletRequestDataBinderFactory factory=new ServletRequestDataBinderFactory(null,null);
        //WebDataBinder dataBinder = factory.createBinder(new ServletWebRequest(request), bean, "user");
        //2  @initbinder
//        InvocableHandlerMethod method=new InvocableHandlerMethod(new MyController(),MyController.class.getMethod("aaa",WebDataBinder.class));
//        List<InvocableHandlerMethod> list=new ArrayList<>();
//        list.add(method);
//        ServletRequestDataBinderFactory factory=new ServletRequestDataBinderFactory(list,null);
        //3  ConversionService
        //4 工厂中既有@initbinder也有ConversionService @initbinder优先级更高
        FormattingConversionService service=new FormattingConversionService();
        service.addFormatter(new MYDataFormatter("用ConversionService扩展"));
        ConfigurableWebBindingInitializer initializer=new ConfigurableWebBindingInitializer();
        initializer.setConversionService(service);
        ServletRequestDataBinderFactory factory=new ServletRequestDataBinderFactory(null,initializer);
        WebDataBinder dataBinder = factory.createBinder(new ServletWebRequest(request), bean, "user");
        dataBinder.bind(new ServletRequestParameterPropertyValues(request));
        System.out.println(bean);

        //5 默认的ConversionService转换
        DefaultFormattingConversionService service1=new DefaultFormattingConversionService();
        ConfigurableWebBindingInitializer initializer1=new ConfigurableWebBindingInitializer();
        initializer1.setConversionService(service1);
        ServletRequestDataBinderFactory factory1=new ServletRequestDataBinderFactory(null,initializer1);
        WebDataBinder dataBinder1 = factory1.createBinder(new ServletWebRequest(request), bean1, "user");
        dataBinder1.bind(new ServletRequestParameterPropertyValues(request));
        System.out.println(bean1);

    }
    static class MyController{
        @InitBinder
        public void aaa(WebDataBinder dataBinder){
            //扩展
            dataBinder.addCustomFormatter(new MYDataFormatter("用@initbinder扩展"));

        }
    }
    static class MyBean{
        private int a;
        private MyBean1 b;
        //默认的转换器要加上这个注解
        @DateTimeFormat(pattern = "yyyy|MM|dd")
        private Date c;

        @Override
        public String toString() {
            return "MyBean{" +
                    "a=" + a +
                    ", b='" + b + '\'' +
                    ", c=" + c +
                    '}';
        }

        public int getA() {
            return a;
        }

        public void setA(int a) {
            this.a = a;
        }

        public MyBean1 getB() {
            return b;
        }

        public void setB(MyBean1 b) {
            this.b = b;
        }

        public Date getC() {
            return c;
        }

        public void setC(Date c) {
            this.c = c;
        }
    }

    static class MyBean1{
        private String d;

        public String getD() {
            return d;
        }

        public void setD(String d) {
            this.d = d;
        }

        @Override
        public String toString() {
            return "MyBean1{" +
                    "d='" + d + '\'' +
                    '}';
        }
    }
}


```
- MYDataFormatter
```java
@Slf4j
public class MYDataFormatter implements Formatter<Date> {
    private  final String desc;

    public MYDataFormatter(String desc) {
        this.desc = desc;
    }

    @Override
    public Date parse(String text, Locale locale) throws ParseException {
        log.debug("ggggg:"+desc);
        SimpleDateFormat sdf=new SimpleDateFormat("yyyy|MM|dd");
        return sdf.parse(text);
    }

    @Override
    public String print(Date object, Locale locale) {
        SimpleDateFormat sdf=new SimpleDateFormat("yyyy|MM|dd");
        return sdf.format(object);
    }
}

```


#### 2.3.2 获取泛型类型

[![jGdU29.png](https://s1.ax1x.com/2022/07/04/jGdU29.png)](https://imgtu.com/i/jGdU29)

如上图 java提供的api较为复杂
spring提供了简单的api


### 2.4 ControllerAdvice介绍

Advice增强的意思,对Controller进行增强.加在类上

[![jGdhrt.png](https://s1.ax1x.com/2022/07/04/jGdhrt.png)](https://imgtu.com/i/jGdhrt)


第一个是@initbinder 可以增加一个类型转换器
第二个是@exception 用来处理异常
第三个是@ModelAttribute 补充模型数据


@initbinder介绍

[![jGdq2j.png](https://s1.ax1x.com/2022/07/04/jGdq2j.png)](https://imgtu.com/i/jGdq2j)

初始化时机

[![jGwpIU.png](https://s1.ax1x.com/2022/07/04/jGwpIU.png)](https://imgtu.com/i/jGwpIU)

[![jGwMJe.png](https://s1.ax1x.com/2022/07/04/jGwMJe.png)](https://imgtu.com/i/jGwMJe)

如上图此方法是实现了InitializingBean后必须要实现的 在这个方法中调用了初始化advice的方法

所以在@ControllerAdvice的类中注解会在bean加载的时候初始化
加在普通Controller的注解方法会在第一次调用本类方法的时候初始化


## 3 控制器方法执行流程

经过上面学习我们知道了一些组件,如参数解析,类型转换对象绑定,参数名解析,返回值解析等.

这些组件是控制器方法执行流程的基础,所以接下来要看看控制器中方法是如何执行的.

[![jGw6e0.png](https://s1.ax1x.com/2022/07/04/jGw6e0.png)](https://imgtu.com/i/jGw6e0)


[![jJcNp6.png](https://s1.ax1x.com/2022/07/04/jJcNp6.png)](https://imgtu.com/i/jJcNp6)

会先处理好绑定工厂,模型工厂,和模型容器.总的来说是对之前介绍的注解做一个操作.


[![jJgBvT.png](https://s1.ax1x.com/2022/07/04/jJgBvT.png)](https://imgtu.com/i/jJgBvT)

接下来就是请求进来之后的执行流程 当通过handlemapping定位到对应的adapter后,
首先是参数解析,反射调用method方法,参数解析中有的涉及requestbodyAdvice,有的涉及数据绑定生成模型.
接下来得到returnvalue,对returnvalue有的涉及responsebodyAdvice,之后再将model添加到mav容器中.
再从modelandviewcontainer中获取modelandview返回.


上述源码解析

[![jJ5CZT.png](https://s1.ax1x.com/2022/07/04/jJ5CZT.png)](https://imgtu.com/i/jJ5CZT)

一个handlermethod对象包括的东西需要那么多,我们逐一将这些对象set进去. 若一个请求进来基本上就是按照图3中的流程执行的.

### 3.1 @ModelAttribute注解的作用
上面讲了基本的流程
@ModelAttribute注解的作用还没讲

@ModelAttribute可以加在参数中,也可以加在方法上.

重点讨论一下加在方法上的作用,他的作用也是相似的不过解析这个注解的不是参数解析器,而是RequestMappingHandleAdapter,解析完了,会把返回结果作为model存入modelandviewcontainer.

[![jJTnLq.png](https://s1.ax1x.com/2022/07/04/jJTnLq.png)](https://imgtu.com/i/jJTnLq)

RequestMappingHandleAdapter初始化的时候解析并记录,当调用的时候吧返回的model装入modelandviewcontainer
[![jJTwTK.png](https://s1.ax1x.com/2022/07/04/jJTwTK.png)](https://imgtu.com/i/jJTwTK)

### 3.2 返回值处理器的讲解

我们还差返回值处理器的讲解

```java
public static HandlerMethodReturnValueHandlerComposite getReturnValueHandler(){
        HandlerMethodReturnValueHandlerComposite composite=new HandlerMethodReturnValueHandlerComposite();
        composite.addHandler(new ModelAndViewMethodReturnValueHandler()); //返回值为ModelAndView
        composite.addHandler(new ViewNameMethodReturnValueHandler());//返回值类型为 String 时
        composite.addHandler(new ServletModelAttributeMethodProcessor(false)); //返回值添加了 @ModelAttribute 注解时
        List<HttpMessageConverter<?>> list=new ArrayList();
        list.add(new MappingJackson2HttpMessageConverter());
        composite.addHandler(new HttpEntityMethodProcessor(list)); //返回值类型为 ResponseEntity 时
        composite.addHandler(new HttpHeadersReturnValueHandler()); //返回值类型为 HttpHeaders 时
        composite.addHandler(new RequestResponseBodyMethodProcessor(list)); //返回值添加了 @ResponseBody 注解时
        composite.addHandler(new ServletModelAttributeMethodProcessor(true));//返回值省略 @ModelAttribute 注解且返回非简单类型时，
        return composite;
    }
```

[![jJxWvT.png](https://s1.ax1x.com/2022/07/04/jJxWvT.png)](https://imgtu.com/i/jJxWvT)

- 返回值为ModelAndView，分别获取其模型和视图名，放入 ModelAndViewContainer
- 返回值类型为 String 时，把它当做视图名，放入 ModelAndViewContainer
- 返回值添加了 @ModelAttribute 注解时，将返回值作为模型，放入 ModelAndViewContainer
此时需找到默认视图名
- 返回值省略 @ModelAttribute 注解且返回非简单类型时，将返回值作为模型，放入 ModelAndViewContainer
此时需找到默认视图名(路径的名字).

下面的几种和上面的不同了,不走视图的响应.
- 返回值类型为 ResponseEntity 时,此时走 MessageConverter，并设置 ModelAndViewContainer.requestHandled 为 true
- 返回值类型为 HttpHeaders 时,会设置 ModelAndViewContainer.requestHandled 为 true.
- 返回值添加了 @ResponseBody 注解时,此时走 MessageConverter，并设置 ModelAndViewContainer.requestHandled 为 true.


### 3.3 MessageConverter

上面的后三种都使用了MessageConverter

1. 作用
* @ResponseBody 是返回值处理器解析的
* 但具体转换工作是 MessageConverter 做的
[![jYCM0U.png](https://s1.ax1x.com/2022/07/04/jYCM0U.png)](https://imgtu.com/i/jYCM0U)
2. 如何选择 MediaType

如果不设置,按照先后顺序.

* 首先看 @RequestMapping 上有没有指定
* 其次看 request 的 Accept 头有没有指定
* 最后按 MessageConverter 的顺序, 谁能谁先转换
如下所示

[![jYPZUe.png](https://s1.ax1x.com/2022/07/04/jYPZUe.png)](https://imgtu.com/i/jYPZUe)


### 3.4 ResponseBodyAdvice

前面已经讲了几个@ControllerAdvice

 ResponseBodyAdvice 返回响应体前包装

 就比如我们想要返回前端统一的数据格式.可以这么做
 [![jYk0KI.png](https://s1.ax1x.com/2022/07/04/jYk0KI.png)](https://imgtu.com/i/jYk0KI)



## 4 异常处理

### 4.1 @ExceptionHandler的异常处理
先是由这个方法处理

[![jULURx.png](https://s1.ax1x.com/2022/07/06/jULURx.png)](https://imgtu.com/i/jULURx)
里面有多个异常处理器,逐一循环,遍历处理.

[![jUL2Wt.png](https://s1.ax1x.com/2022/07/06/jUL2Wt.png)](https://imgtu.com/i/jUL2Wt)
一般由这个处理器处理,若有异常交给这个方法处理

[![jUV4HA.png](https://s1.ax1x.com/2022/07/06/jUV4HA.png)](https://imgtu.com/i/jUV4HA)

解释:调用resolve方法会找加了@ExceptionHandler的方法来处理
[![jULlsU.png](https://s1.ax1x.com/2022/07/06/jULlsU.png)](https://imgtu.com/i/jULlsU)

### 4.2 异常嵌套

[![jUOemD.png](https://s1.ax1x.com/2022/07/06/jUOemD.png)](https://imgtu.com/i/jUOemD)

是因为会记录所有的层级异常
[![jUOcBF.png](https://s1.ax1x.com/2022/07/06/jUOcBF.png)](https://imgtu.com/i/jUOcBF)

ControllerAdvice的@ExceptionHandler

[![jUjGdg.png](https://s1.ax1x.com/2022/07/06/jUjGdg.png)](https://imgtu.com/i/jUjGdg)

初始化的时候会吧ControllerAdvice的@ExceptionHandler放到一个集合,如果找不到就去这里面找.

同样的,其他ControllerAdvice的方法也会按照这种方式初始化,不过是由requestmappinghandleradapter所做的.

[![jUjBLT.png](https://s1.ax1x.com/2022/07/06/jUjBLT.png)](https://imgtu.com/i/jUjBLT)


### 4.3 tomcat的异常处理

 @ExceptionHandler 只能处理发生在 mvc 流程中的异常，例如控制器内、拦截器内，那么如果是 Filter 出现了异常，如何进行处理呢？
    先通过 ErrorPageRegistrarBeanPostProcessor 这个后处理器配置错误页面地址，默认为 `/error` 也可以通过 `${server.error.path}` 进行配置
 [![jaSWND.png](https://s1.ax1x.com/2022/07/06/jaSWND.png)](https://imgtu.com/i/jaSWND)

 上图中ErrorPageRegistrarBeanPostProcessor会调用ErrorPageRegistrarBean添加error页面

 当 Filter 发生异常时，不会走 Spring 流程，但会走 Tomcat 的错误处理，于是就希望转发至 `/error` 这个地址
 当然，如果没有 @ExceptionHandler，那么最终也会走到 Tomcat 的错误处理


Spring Boot 又提供了一个 BasicErrorController，它就是一个标准 @Controller，@RequestMapping 配置为 `/error`，所以处理异常的职责就又回到了 Spring

 [![jdNZOH.png](https://s1.ax1x.com/2022/07/06/jdNZOH.png)](https://imgtu.com/i/jdNZOH)

具体异常信息会由 DefaultErrorAttributes 封装好

[![jdNr1U.png](https://s1.ax1x.com/2022/07/06/jdNr1U.png)](https://imgtu.com/i/jdNr1U)

BasicErrorController 通过 Accept 头判断需要生成哪种 MediaType 的响应


* 如果要的不是 text/html，走 MessageConverter 流程
* 如果需要 text/html，走 mvc 流程，此时又分两种情况
  * 配置了 ErrorViewResolver，根据状态码去找 View
  * 没配置或没找到，用 BeanNameViewResolver 根据一个固定为 error 的名字找到 View，即所谓的 WhitelabelErrorView



## 5.HandlerMapping和HandlerAdapter相关知识

### 5.1. BeanNameUrlHandlerMapping 与 SimpleControllerHandlerAdapter
 
BeanNameUrlHandlerMapping，以 / 开头的 bean 的名字会被当作映射路径
这些 bean 本身当作 handler，要求实现 Controller 接口
SimpleControllerHandlerAdapter，调用 handler

如下图所示

[![jda4yD.png](https://s1.ax1x.com/2022/07/07/jda4yD.png)](https://imgtu.com/i/jda4yD)


模拟实现这组映射器和适配器

要重写写 HandlerMapping 和 HandlerAdapter的实现类.模仿他的功能.

[![jdd3p6.png](https://s1.ax1x.com/2022/07/07/jdd3p6.png)](https://imgtu.com/i/jdd3p6)


[![jddZXF.png](https://s1.ax1x.com/2022/07/07/jddZXF.png)](https://imgtu.com/i/jddZXF)

### 5.2. RouterFunctionMapping 与 HandlerFunctionAdapter

RouterFunctionMapping, 通过 RequestPredicate 条件映射

[![jyJGIH.png](https://s1.ax1x.com/2022/07/10/jyJGIH.png)](https://imgtu.com/i/jyJGIH)
handler 要实现 HandlerFunction 接口

```java
@Bean
public RouterFunctionMapping routerFunctionMapping() {
    return new RouterFunctionMapping();
}

@Bean
public HandlerFunctionAdapter handlerFunctionAdapter() {
    return new HandlerFunctionAdapter();
}

@Bean
public RouterFunction<ServerResponse> r1() {
    //           ⬇️映射条件   ⬇️handler
    return route(GET("/r1"), request -> ok().body("this is r1"));
}
```
HandlerFunctionAdapter, 调用 handler

### 5.3. SimpleUrlHandlerMapping 与 HttpRequestHandlerAdapter

这组用来匹配静态资源

SimpleUrlHandlerMapping 不会在初始化时收集映射信息，需要手动收集

[![jyYv3n.png](https://s1.ax1x.com/2022/07/10/jyYv3n.png)](https://imgtu.com/i/jyYv3n)

SimpleUrlHandlerMapping 映射路径


ResourceHttpRequestHandler 作为静态资源 handler

[![jyt9BT.png](https://s1.ax1x.com/2022/07/10/jyt9BT.png)](https://imgtu.com/i/jyt9BT)

HttpRequestHandlerAdapter, 调用此 handler

上述静态资源解析可以优化

```java
@Bean("/**")
public ResourceHttpRequestHandler handler1() {
    ResourceHttpRequestHandler handler = new ResourceHttpRequestHandler();
    handler.setLocations(List.of(new ClassPathResource("static/")));
    handler.setResourceResolvers(List.of(
        	// ⬇️缓存优化
            new CachingResourceResolver(new ConcurrentMapCache("cache1")),
        	// ⬇️压缩优化
            new EncodedResourceResolver(),
        	// ⬇️原始资源解析
            new PathResourceResolver()
    ));
    return handler;
}
```

读取缓存图示
[![jyt8Cd.png](https://s1.ax1x.com/2022/07/10/jyt8Cd.png)](https://imgtu.com/i/jyt8Cd)

开启压缩

[![jytab8.png](https://s1.ax1x.com/2022/07/10/jytab8.png)](https://imgtu.com/i/jytab8)

会在初始化时压缩html

### 5.4. 欢迎页处理器

```java
@Bean
public WelcomePageHandlerMapping welcomePageHandlerMapping(ApplicationContext context) {
    Resource resource = context.getResource("classpath:static/index.html");
    return new WelcomePageHandlerMapping(null, context, resource, "/**");
}

@Bean
public SimpleControllerHandlerAdapter simpleControllerHandlerAdapter() {
    return new SimpleControllerHandlerAdapter();
}
```


1. 欢迎页支持静态欢迎页与动态欢迎页
2. WelcomePageHandlerMapping 映射欢迎页（即只映射 '/'）
   * 它内置的 handler ParameterizableViewController 作用是不执行逻辑，仅根据视图名找视图
   * 视图名固定为 forward:index.html
3. SimpleControllerHandlerAdapter, 调用 handler
   * 转发至 /index.html
   * 处理 /index.html 又会走上面的静态资源处理流程


总结为转发至 /index.html 走静态资源处理

### 5.5. 映射器与适配器小结

1. HandlerMapping 负责建立请求与控制器之间的映射关系
   * RequestMappingHandlerMapping (与 @RequestMapping 匹配)
   * WelcomePageHandlerMapping    (/)
   * BeanNameUrlHandlerMapping    (与 bean 的名字匹配 以 / 开头)
   * RouterFunctionMapping        (函数式 RequestPredicate, HandlerFunction)
   * SimpleUrlHandlerMapping      (静态资源 通配符 /** /img/**)
   * 之间也会有顺序问题, boot 中默认顺序如上
2. HandlerAdapter 负责实现对各种各样的 handler 的适配调用
   * RequestMappingHandlerAdapter 处理：@RequestMapping 方法
     * 参数解析器、返回值处理器体现了组合模式
   * SimpleControllerHandlerAdapter 处理：Controller 接口
   * HandlerFunctionAdapter 处理：HandlerFunction 函数式接口
   * HttpRequestHandlerAdapter 处理：HttpRequestHandler 接口 (静态资源处理)
   * 这也是典型适配器模式体现


## 6. 小结 + mvc 处理流程 

当浏览器发送一个请求 `http://localhost:8080/hello` 后，请求到达服务器，其处理流程是：

1. 服务器提供了 DispatcherServlet，它使用的是标准 Servlet 技术
* 路径：默认映射路径为 `/`，即会匹配到所有请求 URL，可作为请求的统一入口，也被称之为**前控制器**
     * jsp 不会匹配到 DispatcherServlet
     * 其它有路径的 Servlet 匹配优先级也高于 DispatcherServlet
   * 创建：在 Boot 中，由 DispatcherServletAutoConfiguration 这个自动配置类提供 DispatcherServlet 的 bean
   [![jyNQs0.png](https://s1.ax1x.com/2022/07/11/jyNQs0.png)](https://imgtu.com/i/jyNQs0)
   * 初始化：DispatcherServlet 初始化时会优先到容器里寻找各种组件，作为它的成员变量
     * HandlerMapping，初始化时记录映射关系
     * HandlerAdapter，初始化时准备参数解析器、返回值处理器、消息转换器
     * HandlerExceptionResolver，初始化时准备参数解析器、返回值处理器、消息转换器
     * ViewResolver

2. DispatcherServlet 会利用 RequestMappingHandlerMapping 查找控制器方法

   * 例如根据 /hello 路径找到 @RequestMapping("/hello") 对应的控制器方法

   * 控制器方法会被封装为 HandlerMethod 对象，并结合匹配到的拦截器一起返回给 DispatcherServlet 

   * HandlerMethod 和拦截器合在一起称为 HandlerExecutionChain（调用链）对象

3. DispatcherServlet 接下来会：

   1. 调用拦截器的 preHandle 方法 拦截器
   2. RequestMappingHandlerAdapter 调用 handle 方法，准备数据绑定工厂、模型工厂、ModelAndViewContainer、将 HandlerMethod 完善为 ServletInvocableHandlerMethod
      * @ControllerAdvice 全局增强点1️⃣：补充模型数据
      * @ControllerAdvice 全局增强点2️⃣：补充自定义类型转换器
      * 使用 HandlerMethodArgumentResolver 准备参数
        * @ControllerAdvice 全局增强点3️⃣：RequestBody 增强
      * 调用 ServletInvocableHandlerMethod 
      * 使用 HandlerMethodReturnValueHandler 处理返回值
        * @ControllerAdvice 全局增强点4️⃣：ResponseBody 增强
      * 根据 ModelAndViewContainer 获取 ModelAndView
        * 如果返回的 ModelAndView 为 null，不走第 4 步视图解析及渲染流程
          * 例如，有的返回值处理器调用了 HttpMessageConverter 来将结果转换为 JSON，这时 ModelAndView 就为 null
        * 如果返回的 ModelAndView 不为 null，会在第 4 步走视图解析及渲染流程
   3. 调用拦截器的 postHandle 方法
   4. 处理异常或视图渲染
      * 如果 1~3 出现异常，走 ExceptionHandlerExceptionResolver 处理异常流程
        * @ControllerAdvice 全局增强点5️⃣：@ExceptionHandler 异常处理
      * 正常，走视图解析及渲染流程
   5. 调用拦截器的 afterCompletion 方法