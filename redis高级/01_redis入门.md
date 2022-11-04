# redis基础 #
## 1.redis入门 ##
### 1. redis简介 ###
是什么,主要用来干什么,解决什么问题.
缓存,存放热点信息,解决热点信息的高并发磁盘io问题.
消息队列
### 2. redis下载安装 ###
windows 下 去github下载windows版本
linux 官网下载源码,编译,安装.

### 3. redis入门使用 ###
入门使用get命令 set命令
使用help命令查看get命令

## 2.数据类型
redis常用五种不同的数据类型,每一种数据类型的命令 都被官方分为一组,
redis官方共有14组命令.

redis存储的是：key,value格式的数据，其中key都是字符串，value有5种不同的数据结构
    * value的数据类型有如下五种：
        1) 字符串类型 string
        2) 哈希类型 hash ： map格式  
        3) 列表类型 list ： linkedlist格式。支持重复元素
        4) 集合类型 set  ： 不允许重复元素
        5) 有序集合类型 sortedset：不允许重复元素，且元素有顺序

### 1. 字符串类型 string

    基本
    1. 存储： set key value   
        127.0.0.1:6379> set username zhangsan  
        OK  
    2. 获取： get key  
        127.0.0.1:6379> get username  
        "zhangsan"  
    3. 删除： del key  
        127.0.0.1:6379> del age  
        (integer) 1  
    
    单指令多指令
    4. 存储多个： mset key1 value1 key2 value2 ....   
        127.0.0.1:6379> set username zhangsan  
        OK  
    5. 获取多个： key1 value1 key2 value2 ....   
        127.0.0.1:6379> get username  
        "zhangsan"  
    6. 获取数据字符个数： strlen key  
        127.0.0.1:6379> del age  
        (integer) 1  
    
    追加
    7. 追加信息到原信息后面： append key  value
        127.0.0.1:6379> del age  
        (integer) 1  
    
    自增自减
    8. 设置数据指定增加 : 数据库集群自增
        incr key  
        incr key increment  
        incrbyfloat key increment   
    9. 设置数据指定减少
        decr key  
        decr key increment 
    
    设置key超时
    10. 设置key value 并设置超时时间
        setex key seconds value 秒
        psetex key milliseconds value 毫秒
    
    注意事项:
    操作后返回值
    1 表示成功还是失败
    (integer) 0  false
    (integer) 1 true
    2 结果
    (integer) 1 1
    数据未获取到 nil = null
    数据最大存储量 512Mb
    数值最大计算范围 long

### 2. 哈希类型 hash

    基本
    1. 存储： hset key field value
        127.0.0.1:6379> hset myhash username lisi
        (integer) 1
        127.0.0.1:6379> hset myhash password 123
        (integer) 1 
    2. 获取： 
        * hget key field: 获取指定的field对应的值
            127.0.0.1:6379> hget myhash username
            "lisi"
        * hgetall key：获取所有的field和value
            127.0.0.1:6379> hgetall myhash
            1) "username"
            2) "lisi"
            3) "password"
            4) "123" 
    3. 删除： hdel key field
            127.0.0.1:6379> hdel myhash username
            (integer) 1 
    
    单指令多指令
    4. 存储多个： hmset key field value1 field value2 ....   
        
    5. 获取多个： hmget key field value1 field value2 ....   
        
    6. 获取数据字段个数： hlen key  
        
    7. 获取表中是否有字段： hexists key field  


    扩展操作
    8. 获取表中所有字段名火字段值：
        hkeys key
        hvals key   
    
    自增自减
    9. 设置数据指定增加 : 数据库集群自增
        hincrby key  field   increment  
        hincrbyfloat key  field   increment 
    
        hdecrby key field increment 


​        
​    注意事项:
​    hash的value只允许存字符串,不允许存其他的.
​    每个hash可以存2的32次方-1个键值对
​    不可将hash作为对象列表.
​    
    购物车实现:
    设计一个购物车在redis中的存储模型
    
    hsetex key field value 
    设置一个key仅当 key不在的时候才去存,如果已经有key,则不存.
    
    抢购 秒杀:


### 3. 列表 list


    基本
    1. 添加：
        1. lpush key value: 将元素加入列表左表
           lpushx key value :当存在时
            
        2. rpush key value：将元素加入列表右边
            rpushx key value :当存在时
        3. lset key index value: 设置某索引下的值 
           
    2. 获取： 
        * lrange key start end ：范围获取
        * lindex key index :获取某个index下的值
        * llen key :list的长度
        * ltrim key start stop:修剪列表到指定范围
            
    3. 删除： 
        * lpop key： 删除列表最左边的元素，并将元素返回
    	* rpop key： 删除列表最右边的元素，并将元素返回
        * lrem key index value :删除某个索引元素
        * blpop key1 [key2] timeout： 删除列表最左边的元素，并将元素返回,阻塞,直到有一个可用.
    	* brpop key1 [key2] timeout： 删除列表最右边的元素，并将元素返回阻塞,直到有一个可用.  消息队列
    4. 插入元素:
        * linsert key befor|after pivot value
    注意事项  
    list存的数据都是string,最多lang
    有索引,但一般以栈的思想操作
    获取全部索引设置为-1
    可以对数据分页,通常第一页来自list,第二页加载时查找数据库.
    
    业务
    关注列表是新的在前 blpop ==  block lpop
    多路消息汇总合并 服务器日志汇总
    消息队列 日志汇总

### 4. 集合 set 

    不可重复  
    基础
    1. 存储：sadd key value1 value2
       
    2. 获取：smembers key:获取set集合中所有元素
        
    3. 删除：srem key value1 value2:删除set集合中的某个元素	
            
    4. scard key :获取集合总量
    
    5. sismember key member :是否包含指定数据 
    
    随机获取
    6. srandmember key [count]: 随机获取指定数据
       spop key 删除并随机获取一个集合中的元素
    
        可应用于随机推荐信息
    
    集合计算
    7. 交并差
        sinter key1 [key2]
        sunion key1 [key2]
        sdiff key1 [key2]
    8.求交并差并存储到指定
        sinterstore destination key1 [key2]
        sunionstore destination key1 [key2]
        sdiffstore destination key1 [key2]
    9. 将制定数据从原始集合中移动到目标集合中
        smove source destination member
    
        同类关键信息检索
    
    注意事项:
        不允许重读,添加的已有会失败
        不能当成hash来用
    应用场景:
        权限校验 交并
        网站访问量统计 pv uv ip  pv=string 自增  uv ip =set的 scard key
        黑名单 加入到set
        用户标签
        随机抽奖
        求共同关注的人


### 5. 有序集合 sortedset 

    基础
    1. 存储：zadd key score member
        
    2. 获取：zrange key start end  小->大 [withrank]
            zrevrange key start end  大->小 [withrank]
        条件获取 
            zrangebyscore key min  max [withscores] 小->大
            zrevrangebyscore key max min [withscores] 大->小
    3. 删除：zrem key member
            zremrangebyrank key start stop
            zremrangebyscore key min max
    4. zcard key :获取集合总量
    
    5. zcount key min max :获取数量
    
    交并差
    6.  sinterstore destination numkeys key1 [key2]
        sunionstore destination numkeys key1 [key2] 
    
    7. 获取索引
        zrank key member 
        zrevrank key member 
    8. score值获取
        zscore key member
        zincrby key increment member 
    
    注意事项:
    score 是double值,有范围,也可能丢失精度.
    set结构+索引+score
    
    实现排行榜
        top系列 score
        投票排行
        好友亲密度排行
    时效管理
        投票失效
        vip到期
    带有权重的消息队列


**实例方案**
计次器   妙用最大值抛出异常，减少业务层运算量。
微信接收消息


## 3.通用命令

### 1.key 命令
    基础
    1. keys * : 查询所有的键
    2. type key ： 获取键对应的value的类型
    3. del key：删除指定的key value
    4. exist key: key是否存在
    randomkey:返回一个随机key
    
    时效性
    5. 设置过期
        expire key seconds :设置过期秒数
        pexpire key millisseconds:设置过期毫秒数
        expireat key timsramp:设置过期时间戳
        pexpireat key timsramp:设置过期时间戳 毫秒
    6. 移除过期
        persist key : 移除过期时间 变为永久性
    7. 获取有效时间
        ttl key :秒
        pttl key : 毫秒
    
    查询key
    8.匹配key
        keys pattern 按匹配字符匹配
    
    其他
    9.重命名
        rename key newkey : 重命名
        renamenx key newkey :重命名 newkey必须不存在
    10.排序
        sort key pattern ,对key的内容排序

### 2.db 命令
db是操作库的命令

    redis提供16个数据库,从0-15.  
    每个数据库是相互独立的.
    
    db基本操作
    1. 切换数据库 
        select index
    2. 其他
        quit :退出
        ping :pang 测试服务器链接
        each message  
    
    与db相关操作
    1. 数据移动
        move key db :移动key
    2. 数据清除
        dbsize :获取大小
        flushdb : 刷新清除当前db
        flushall : 刷新清除所有db

## 4.jedis
* Jedis: 一款java操作redis数据库的工具. 
* 使用步骤：  
1. 下载jedis的jar包  
2. 使用  
````java
        //1. 获取连接
        Jedis jedis = new Jedis("localhost",6379);
        //2. 操作
        jedis.set("username","zhangsan");
        //3. 关闭连接
        jedis.close();

````
* Jedis操作各种redis中的数据结构

   1) 字符串类型 string
            
````java
        //1. 获取连接
        Jedis jedis = new Jedis();//如果使用空参构造，默认值 "localhost",6379端口
        //2. 操作
        //存储
        jedis.set("username","zhangsan");
        //获取
        String username = jedis.get("username");
        System.out.println(username);

        //可以使用setex()方法存储可以指定过期时间的 key value
        jedis.setex("activecode",20,"hehe");//将activecode：hehe键值对存入redis，并且20秒后自动删除该键值对

        //3. 关闭连接
        jedis.close();
````
2) 哈希类型 

````java
        //1. 获取连接
        Jedis jedis = new Jedis();//如果使用空参构造，默认值 "localhost",6379端口
        //2. 操作
        // 存储hash
        jedis.hset("user","name","lisi");
        jedis.hset("user","age","23");
        jedis.hset("user","gender","female");

        // 获取hash
        String name = jedis.hget("user", "name");
        System.out.println(name);


        // 获取hash的所有map中的数据
        Map<String, String> user = jedis.hgetAll("user");

        // keyset
        Set<String> keySet = user.keySet();
        for (String key : keySet) {
            //获取value
            String value = user.get(key);
            System.out.println(key + ":" + value);
        }

        //3. 关闭连接
        jedis.close();

````
3) 列表类型   
list ： linkedlist格式。支持重复元素  
            lpush / rpush  
            lpop / rpop  
            lrange start end : 范围获取   
````java
            //1. 获取连接
        Jedis jedis = new Jedis();//如果使用空参构造，默认值 "localhost",6379端口
        //2. 操作
        // list 存储
        jedis.lpush("mylist","a","b","c");//从左边存
        jedis.rpush("mylist","a","b","c");//从右边存

        // list 范围获取
        List<String> mylist = jedis.lrange("mylist", 0, -1);
        System.out.println(mylist);
        
        // list 弹出
        String element1 = jedis.lpop("mylist");//c
        System.out.println(element1);

        String element2 = jedis.rpop("mylist");//c
        System.out.println(element2);

        // list 范围获取
        List<String> mylist2 = jedis.lrange("mylist", 0, -1);
        System.out.println(mylist2);

        //3. 关闭连接
        jedis.close();
````

4) 集合类型  
set  ： 不允许重复元素  
sadd  
smembers:获取所有元素  
````java
        //1. 获取连接
        Jedis jedis = new Jedis();//如果使用空参构造，默认值 "localhost",6379端口
        //2. 操作


        // set 存储
        jedis.sadd("myset","java","php","c++");

        // set 获取
        Set<String> myset = jedis.smembers("myset");
        System.out.println(myset);

        //3. 关闭连接
        jedis.close();
````
5) 有序集合类型   
sortedset：不允许重复元素，且元素有顺序  
            zadd  
            zrange  
````java
        //1. 获取连接
        Jedis jedis = new Jedis();//如果使用空参构造，默认值 "localhost",6379端口
        //2. 操作
        // sortedset 存储
        jedis.zadd("mysortedset",3,"亚瑟");
        jedis.zadd("mysortedset",30,"后裔");
        jedis.zadd("mysortedset",55,"孙悟空");

        // sortedset 获取
        Set<String> mysortedset = jedis.zrange("mysortedset", 0, -1);

        System.out.println(mysortedset);


        //3. 关闭连接
        jedis.close();

````

* jedis连接池： JedisPool  
* 使用：    
            1. 创建JedisPool连接池对象  
            2. 调用方法 getResource()方法获取Jedis连接  
````java
        //0.创建一个配置对象
        JedisPoolConfig config = new JedisPoolConfig();
        config.setMaxTotal(50);
        config.setMaxIdle(10);

        //1.创建Jedis连接池对象
        JedisPool jedisPool = new JedisPool(config,"localhost",6379);

        //2.获取连接
        Jedis jedis = jedisPool.getResource();
        //3. 使用
        jedis.set("hehe","heihei");


        //4. 关闭 归还到连接池中
        jedis.close();
````
* 连接池工具类  
````java
            public class JedisPoolUtils {

                private static JedisPool jedisPool;
            
                static{
                    //读取配置文件
                    InputStream is = JedisPoolUtils.class.getClassLoader().getResourceAsStream("jedis.properties");
                    //创建Properties对象
                    Properties pro = new Properties();
                    //关联文件
                    try {
                        pro.load(is);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    //获取数据，设置到JedisPoolConfig中
                    JedisPoolConfig config = new JedisPoolConfig();
                    config.setMaxTotal(Integer.parseInt(pro.getProperty("maxTotal")));
                    config.setMaxIdle(Integer.parseInt(pro.getProperty("maxIdle")));
            
                    //初始化JedisPool
                    jedisPool = new JedisPool(config,pro.getProperty("host"),Integer.parseInt(pro.getProperty("port")));
            
            
            
                }
            
            
                /**
                    * 获取连接方法
                    */
                public static Jedis getJedis(){
                    return jedisPool.getResource();
                }
            }
````

​    

