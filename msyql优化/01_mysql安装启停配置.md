#### mysql安装启停和配置 ####
##### 1.mysql的版本 ####
    5.x:主流版本 
    5.0-5.1:早期产品延续,升级维护
    5.5-5.x: mysql整合了三方公司的新存储引擎
##### 2.mysql安装 #####
    见 mysql安装
##### 3.mysql目录 #####
     /var/lib/mysql :mysql安装目录 ,默认数据目录.
     /var/share/mysql :配置文件目录
     /usr/bin : 可执行文件目录
     /etc/my.cnf /etc/my.cnf.d  配置文件和配置文件目录

     启动脚本
     /var/lib/systemd/system/mysql.service 
     因linux版本不同而不同
##### 4.mysql字符编码 #####

    sql :show variables like '%char%';
    统一编码
    改配置文件