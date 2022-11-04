#### 02 mysql原理 ####
##### 1.逻辑分层 #####
    mysql的服务端分为
    1.连接层 :用于获取维护和客户端的连接
    2.服务层 :提供各种用户使用的接口,sql优化器.
    3.引擎层 :提供各种存储数据的方式
    4.存储层 :存储数据
![image-20210608160202462](/home/hxq/code/wd/msyql优化/02_mysql原理.assets/image-20210608160202462.png)

##### 2.存储引擎 ##### 

    show engines ;
    1.InnoDB :事务优先(适合高并发操作 行锁) 默认
    2.MyISAM :性能优先(表锁)
    给创建的数据库制定引擎
    create table test()engines=MyISAM ; 
##### 3.sql解析原理 ##### 
    例如一个sql语句格式如下
    select .. from ..join ..on ..where ..group by ..having..order by..limit
    解析过程
    from..on..join ..whewe..group by..having..select ..order by..limit
    
    * sql 优化主要是优化索引
    索引是数据结构,是一个b树.
    弊端:1索引本身要占据很大空间
         2索引会降低增删改的效率
    好处:1 提高查询效率
         2 降低cpu使用率
    基于以上 频繁更新 数据比较少 很少使用的字段 . 不建议索引
##### 4.b树和索引 ######
    b树的结构
    索引:
    单值索引:单列
    唯一索引:不能重复
    复合索引:多个列
    
    create index 索引名 on 表(列)
    alter table tb add index 表(列)