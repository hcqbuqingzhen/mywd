 

# mysql



## 1.mysql深分页问题

#### 现象

![image-20220725000222824](assets/image-20220725000222824.png)



#### 原因

![image-20220725000333773](assets/image-20220725000333773.png)

#### 解决

![image-20220725000604772](assets/image-20220725000604772.png)

## 2.Mysql主从同步原理？



![image-20221105232057466](assets/image-20221105232057466.png)



1

![image-20221105232851276](assets/image-20221105232851276.png)

2

![image-20221105232942012](assets/image-20221105232942012.png)

## 3. mysql主从同步延迟解决方案

#### 原因



![image-20221105233321985](assets/image-20221105233321985.png)

#### 解决



![image-20221105233501227](assets/image-20221105233501227.png)



![image-20221105234251229](assets/image-20221105234251229.png)



![image-20221105234422780](assets/image-20221105234422780.png)



![image-20221105234555875](assets/image-20221105234555875.png)![image-20221105234548973](assets/image-20221105234548973.png)

## 4.Mysql主从同步的三种模式

异步

![image-20221105234918268](assets/image-20221105234918268.png)

同步

![image-20221105234932779](assets/image-20221105234932779.png)

半同步

![image-20221105235030866](assets/image-20221105235030866.png)



## 5.Mysql的int(1)和int(10)的区别？

![image-20221106161311844](assets/image-20221106161311844.png)



![image-20221106161515475](assets/image-20221106161515475.png)



![image-20221106161615474](assets/image-20221106161615474.png)



## 6.Mysql中空字符串和null值的区别？

![image-20221106164141025](assets/image-20221106164141025.png)



![image-20221106164434580](assets/image-20221106164434580.png)



![image-20221106164637697](assets/image-20221106164637697.png)



## 7.Mysql索引失效的情况？

![image-20221106165141197](assets/image-20221106165141197.png)



## 8.什么是Mysql聚集索引与非聚集索引？

![image-20221106175738757](assets/image-20221106175738757.png)



![image-20221106175854868](assets/image-20221106175854868.png)



![image-20221106175953038](assets/image-20221106175953038.png)



## 9.数据库连接池泄漏如何排查？

### 现象

![image-20221106182130611](assets/image-20221106182130611.png)

### 应对方法



![image-20221106182209913](assets/image-20221106182209913.png)





![image-20221106182331782](assets/image-20221106182331782.png)





![image-20221106182358476](assets/image-20221106182358476.png)

## 10.Mysql的redo日志工作原理？

### 什么是redo日志

1.

![image-20221106220926962](assets/image-20221106220926962.png)

2.

![image-20221106221155829](assets/image-20221106221155829.png)

3.

![image-20221106221331286](assets/image-20221106221331286.png)



![image-20221106221528246](assets/image-20221106221528246.png)



### 工作过程



![image-20221106221700861](assets/image-20221106221700861.png)



![image-20221106221833403](assets/image-20221106221833403.png)



## 11.Mysql的Redo日志刷盘策略？

### 流程

![image-20221106222126129](assets/image-20221106222126129.png)

### 策略

![image-20221106222250397](assets/image-20221106222250397.png)



## 12.什么是Mysql的undo日志？

### 什么是

![image-20221106222457966](assets/image-20221106222457966.png)



### 作用

![image-20221106223036650](assets/image-20221106223036650.png)

## 13.Mysql的undo日志的回滚段是什么？

![image-20221106223251315](assets/image-20221106223251315.png)



![image-20221106223335519](assets/image-20221106223335519.png)

![image-20221106223548339](assets/image-20221106223548339.png)

![image-20221106223613288](assets/image-20221106223613288.png)



## 14.Mysql的count(*)和count(1)谁更快？

![image-20221106224350637](assets/image-20221106224350637.png)



![image-20221106224518144](assets/image-20221106224518144.png)



## 15.Mysql表时间列用datetime还是timestamp？

![](assets/image-20221107000012134.png)



![image-20221107000052704](assets/image-20221107000052704.png)



![image-20221107000146167](assets/image-20221107000146167.png)

## 16.为什么大厂严禁使用join查询？

### 现象

![image-20221107173429192](assets/image-20221107173429192.png)

### 解决

![image-20221107173621579](assets/image-20221107173621579.png)

## 17.为什么大厂不让用外键？

### 背景和现象

![image-20221107173753539](assets/image-20221107173753539.png)



![image-20221107173930362](assets/image-20221107173930362.png)



### 解决

![image-20221107174049767](assets/image-20221107174049767.png)

### 好处

![image-20221107174145706](assets/image-20221107174145706.png)
