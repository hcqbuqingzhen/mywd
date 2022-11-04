#### 慢sql分析 ####
##### 1 打开mysql慢查询阈值开关 #####
打开后会记录慢sql的日志
##### 2 mysqldunpslow分析慢查询日志 #####
使用mysqldunpslow 查找分析1中记录
##### 3.profiles 使用 #####
1 编写存储函数,写入海量垃圾数据.
2 profiles工具分析 
 1).set profiles=on;
 prifiles打开后,会记录所有的sql语句和花费的时间.
 2).show profile ;
    show profile all for query 上一步sqlid
 3).全局查询日志
  会将profile的sql语句持久化.
 set global general_log=1 开启全局日志
 set global log_output ='table'  sql记录在表中

 set global general_log=1 
 set global log_output ='file' sql记录在文件中
 set global general_log_file ='目录' 

