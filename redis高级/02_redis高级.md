# redis高级 #
## 1. redis持久化 ##
redis的持久化的方式有两种,rdb和aof,对应的是快照和日志,前者侧重内容,后者侧重记录方式.
### 1.rdb持久化 ###
rdb方式:做的操作的步骤 ,存的快照.

    1.save命令 
     主动将快照保存
     工作原理:会阻塞所有进程,不对外提供服务.
    2. bgsave
     后台将快照保存,不会阻塞.
     会生成子进程保存,不会使用主进程.
    
    3.持久化相关配置文件
    save seconds change
    如 save 300 1;
    表示300秒内1个发生了变化就持久化.
    save配置后是bgsave命令
    
    4. rdb的优缺点
    优点:
    * 快照方式保存,存的快
    * 恢复快
    缺点:
    * 无法实时持久化
    * 子进程消耗资源
    * 各个版本rdb文件格式不同,无法兼容.

### 1.aof持久化 ###
记录操作的记录,记录的日志.
    1. aof开启
    appendonly yes
    2. aof策略
    appendsync :
    always 每条都记录
    no 系统决定
    everysec 每秒
    3. aof重写
    aof记录每一条指令,会造成冗余,因此会将若干条指令重写为结果指令记录.
    bgwriteaof: 手动重写
    4. 配置文件中开启重写
    auto-aof-rewrite-min-size size 
    auto-aof-rewrit-percentage percentage 

## 2. 事务 ##
redis单线程操作也会有数据安全问题,这里的事务和mysql中并发造成的不同,是一种客户端主观上的的数据问题.

### 1.事务的基本操作 
    1. 开启事务
    multi 
    开启事务后 后面的命令都加到事务中
    2 执行事务
    exec
    事务结束,同时执行事务.
    
    事务内的命令会加到一个任务队列中,结束时一起执行.
    
    3 取消事务
    diccard 
    终止当前事务,在multi和exec之间

### 2.事务的注意事项
    1. 如果命令有语法错误 事务会取消
    2. 如果命令没有语法错误,但不合规定(对数据类型用了另一种数据类型的指令),正确的执行,错误的不执行.
    此种情况需要程序员回滚,redis没有设计回滚.
### 3.事务的锁
    1.如何加锁
    watch key [key2...] 
    如果在执行exec前key发生了变化,终止事务.
    unwatch 取消所有对key的监视.
    
    2.分布式锁
    问题 当多个客户端想要操作同一个数据时?如超卖问题
    
    setnx  key value ;
    这个指令如果没有key返回成功,如果已有key返回失败.
    
    此为约定规范,需要在代码层面实现.
    
    3. 分布式锁的死锁问题
    锁是程序约定的,当一个程序加了锁后,突然挂了,此时没有解锁会有死锁问题.
    我们可以给锁加一个时效,当约定时间过去后锁自动失效.
    expire key seconds :设置过期秒数
    pexpire key millisseconds:设置过期毫秒数
    expireat key timsramp:设置过期时间戳
    pexpireat key timsramp:设置过期时间戳 毫秒

## 3. 删除策略 ## 
ttl可以查看,数据的状态.  
所谓删除策略是,当删除指令发出后,因为cpu占用等问题并不会马上执行删除,redis如何删即为策略.
### 1.何为过期数据 ###
    设置key时过期的数据
### 2.过期数据的存储结构 ###
    内部有一个存储过期时间和keys地址的数据结构. 叫做expires.
### 3.三种删除策略 ###
    有三种删除策略
    1.定时删除 到点就删除,抢占cpu
        内部有个函数,一直不停循环expires.
    2.惰性删除 到点不管,下次访问时检查是否过期,然后删除. 节约cpu,内存换cpu.
        访问时循环expires
    3.定期删除 类似于gc.
        * 服务启动时读取server.hz,
        * 每秒执行server.hz十次serverCron()->databasesCron()->activeExpireCycle(). activeExpireCycle()每次执行250ms
        * activeExpireCycle() 对每个expires逐一检测.
        * 对每个expires检测时,随机挑选w个key检测.
        * 若发现删除key>W*25%,循环该过程.
        * key<W*25%,检查下一个.
        * activeExpireCycle()执行时间到期,会记录当前db,下次从此db开始.
        w配置文件中设置
### 4.逐出策略 ###
        何为逐出策略:注意和删除策略分开,删除策略是删除expires的,逐出是内存不足时强制的,可能波及无辜,删除expires外的数据.  
        redis 在存入新数据时,会调用ferrMemoryifNeeded()检测内存是否充足,如果不充足,需要删除一些数据清理内存空间.  
    
    maxmemory 默认全占有  
    
    manmemory-samples    每次选取待删除数据的个数。
    
    全表扫描占用时间,随机获取数据作为待检测删除数据. 
    maxmemory-policy 达到最大内存后,对选出的数据删除的策略.
        * 检测可能会过期的：设置了过期时间的
        volatile-lru: 最近最少使用的(距离上次使用最远的)
        volatile-lfu: 次数最少的
        volatile-ttl: 将要过期的
        volatile-randow: 任意选择
        * 检测全库：不管是不是设置了过期时间
        allkeys-lru: 最近最少使用的(距离上次使用最远的)
        allkeys-lfu: 次数最少的
        allkeys-randow: 任意选择
        * 放弃驱逐
        no-enviction 会内存溢出
## 4. redis.conf详解 ##
见配置文件
## 5. 高级数据类型 ## 
前面已经讲了五种基础数据类型.  
高级数据类型只是为了解决单一的问题.
### 1.bitmaps ###  
存储的都为1和0
    1.bitmap的应用场景
    2.基础操作
        1.获取指定key对应偏移量上的bit值
         getbit key offset 
        2. 设置指定key对应偏移量上的bit值,value只能是1或0
         setbit key offset value 
    3. 交并或异或
        * bitop and destkey key1 [key2]
        * bitop or destkey key1 [key2]
        * bitop not destkey key1 [key2]
        * bitop xor destkey key1 [key2]
    4. 统计指定key中1的量
        bitcount key [statr end]

    bitmap 应用于信息状态统计 如电影是否被看过
### 2.HyperLogLog ###
    基数统计 
    基数:数据集合去重后的结果集合
    HyperLogLog做基数统计,运用了LogLog算法.  (不懂,了解吧)
    
    1.添加数据
     pfadd key elemennt [ element ..]
    2.统计数据
     pfcount key [key ..]
    3.合并数据
     pfmegrge destkey sourcekey [key ..]
    
     HyperLogLog 应用于信息数量状态统计
### 3.GEO ###  
    如分享位置后计算地图上两个点的距离.
    微信中查看附近的人
    1.添加坐标点
    geoadd key longitude latitude memeber [ 多个]
    2.获取坐标点
     geopos key memeber [多个]
    3. 计算坐标点距离
    geodist key memeber1 member2
    
    4.给一个坐标 求他附近某个范围的其他点
    georadius key longitude latitude radius(范围) m|km|ft|mi(单位)
    5.给一个点,求他附近某个范围的其他点
    georadiusbymemeber key member radius(范围) m|km|ft|mi(单位)
    6.获取指定点对应的hash值
    geohash key member [多个]