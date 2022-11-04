# mysql安装配置 

## 1. centos7下
安装mysql 5.7rpm包.
1. 首先官网下载mysql rpm包,选择版本,然后下载最大的bundle包即可.  
https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.26-1.el7.x86_64.rpm-bundle.tar

2. 解压安装  
```
mkdir mysql #存放解压的mysql tar包.
tar xf mysql-5.7.16-1.el7.x86_64.rpm-bundle.tar -C mysql/

CentOS7开始自带的数据库是mariadb，所以需要卸载系统中的mariadb组件，才能安装mysql的组件
rpm -qa | grep mariadb

yum -y remove mariadb-libs
# cd到mysql目录下.
yum install mysql-community-*
此安装方式会自动安装依赖
```
3. 启动mysql并设置开机自启
```
systemctl start mysqld
systemctl enable mysqld
systemctl status mysqld
```
4. 获取mysql临时密码，设置mysql的root用户密码
```
vim  /var/log/mysqld.log
在日志中查找设置的密码
mysql -uroot -p"V#is9?6Nqpui"

mysql> alter user 'root'@'localhost' identified by '123456'
会发现报错,是因为这个版本的mysql开启了密码验证插件.
可以修改插件的值,也可以在my.cnf中配置不使用插件.
这里先修改原来的密码.
mysql> alter user 'root'@'localhost' identified by 'root123ABC!';

mysql> select @@validate_password_policy;　　//这个参数是密码复杂程度
+----------------------------+
| @@validate_password_policy |
+----------------------------+
| MEDIUM                     |
+----------------------------+

mysql> select @@validate_password_length;　　//这个参数是密码长度
+----------------------------+
| @@validate_password_length |
+----------------------------+
|                          8 |
+----------------------------+

修改这两个值
mysql> set global validate_password_policy=0;

mysql> set global validate_password_length=1;

刷新权限 
mysql> flush privileges;

修改密码为测试用简单密码
mysql> alter user 'root'@'localhost' identified by 'root123';

如果不想改,也可在配置文件中将密码验证插件关闭
vim /etc/my.cnf
validate-password=OFF　　//在[mysqld]模块内添加，将validate_password插件关闭

以上操作退出后重启mysql即可
```
5. 添加远程访问
```
grant all on *.* to root@'%' identified by 'root123';
##可以进入mysql修改user表   *.* 表示任意库任意表
firewall-cmd --zone=public --add-port=3306/tcp --permanent
##开放端口,cents7使用的是firewall作为防火墙,当然也可以自己安装iptables替代.
systemctl restart firewalld.service
##重启
firewall-cmd --list-ports
##查看开放端口
firewall-cmd --zone= public--remove-port=80/tcp --permanent
##删除开放端口
```
## 2. archlinux下

archlinux是我日常使用的桌面linux,因为mysql官网没能找到archlinux的安装版本,只有需要编译的版本.
因此选择archlinux默认的mariadb

1. mysql安装
```
pacman -S mariadb mariadb-clients
##即可安装
```
2. 初始化
安装完后可能会有提示
```
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
若这一步失败 将/var/lib/mysql 备份 删除后重试
这一步执行完后会有提示 
/*
Installing MariaDB/MySQL system tables in '/var/lib/mysql' ...
OK

To start mysqld at boot time you have to copy
support-files/mysql.server to the right place for your system


Two all-privilege accounts were created.
One is root@localhost, it has no password, but you need to
be system 'root' user to connect. Use, for example, sudo mysql
The second is mysql@localhost, it has no password either, but
you need to be the system 'mysql' user to connect.
After connecting you can set the password, if you would need to be
able to connect as any of these users with a password and without sudo

See the MariaDB Knowledgebase at http://mariadb.com/kb or the
MySQL manual for more instructions.

You can start the MariaDB daemon with:
cd '/usr' ; /usr/bin/mysqld_safe --datadir='/var/lib/mysql'

You can test the MariaDB daemon with mysql-test-run.pl
cd '/usr/mysql-test' ; perl mysql-test-run.pl

Please report any problems at http://mariadb.org/jira

The latest information about MariaDB is available at http://mariadb.org/.
You can find additional information about the MySQL part at:
http://dev.mysql.com
Consider joining MariaDB's strong and vibrant community:
https://mariadb.org/get-involved/
*/
使用
mysql -uroot 
##可登录mysql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123';
##修改密码
```

3. 添加远程登录
```
grant all on *.* to root@'%' identified by 'root123';

防火墙已关闭
```
4. 添加用户并授予权限
```
create user 'xiaobai'@'%' identified by '123123';
grant all on *.* to xiaobai@'%' identified by '123123';
```

