#### sql执行计划 ####
explain sql语句可以查看sql的执行计划

id:编号 与子查询有关,子查询的id大,优先查询.

select_type:查询类型 语句的查询类型 
    primary 主要的查询 .包含子查询的最外层。
    subquery 子查询 
    simple 简单查询 
    derived 使用到了临时表 
    union联合查询的左表 
    union result 联合查询的表

table:表 会因为表的数据量,查询表的顺序改变,数据小的优先查询. 从上到下由小变大.

type:索引类型
    system:只有一条数据的系统表,衍生表只有一条数据的主查询.
    const:仅仅能查到一条数据的sql,用于primary key或者unique
    eq_ref:查询的索引,返回匹配唯一行数据(只能为1,不能0或多)
    ref:非唯一性索引,查询的索引,返回匹配的数据(0,1,多)
    range:范围查询,where后面跟范围条件 between,><=,in 注意in,当in的范围大于表数据一半时,会全表扫描.
    index:查询全部索引中的数据
    all:查询全表数据,索引失效.

possible_keys:预测使用到的索引

key:实际使用的索引

key_len:实际使用的长度 
    用于判断复合索引是否被完全适用.

ref:表之间的引用
    条件中的=号后面的指向,

rows:通过索引查到的数据量
    被索引优化查询的数据个数,实际通过索引查到的数据个数.

extra:额外信息
    using filesort :性能消耗大,where 和orderby出现.
        *where 和orderby 使用同一个字段
        where 和orderby 在复合索引中不要跨列.
        如果复合索引和使用的顺序全部一致,则复合索引全部使用,  若跨列 则失效.
    using temporary : 用到了临时表,一般出现在group by.
        *select 什么列就group by什么列.
    using index:索引覆盖,不读取原文件,只从索引中获取数据.
    using where:需要回表查询
    impossible where:where子句永远为false