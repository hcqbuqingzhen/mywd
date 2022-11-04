## jenkins构建项目

### 1.项目类型

- #### 自由风格

- #### maven

- #### 流水线风格

- pipeline语法

  1. 声明式
  2. 脚本式

### 2.构建触发器

- 触发远程构建

  使用一个链接，远程访问此链接则触发构建。

- 其他工程构建后触发（Build after other projects are build）

  顾名思义，创建一个工程时，可以设定，当下一个工程创建时触发本工程构建。

- 定时构建（Build periodically）

  设定多长时间构建一次。

- 轮询SCM（Poll SCM）

  定时扫描本地代码是否变更，注意是本地。



在此之上有高级触发器

1. Gitlab Hook

   安装插件，Gitlab Hook和GitLab。

   配置gitlab

   Gitlab配置webhook

   1）开启webhook功能使用root账户登录到后台，点击Admin Area -> Settings -> Network勾选"Allow requests to the local network from web hooks and services"

   2）在项目添加webhook点击项目->Settings->Integrations

   

![image-20210506132841237](/home/hxq/code/devops/jenkins/03jenkins构建细节.assets/image-20210506132841237.png)



2.jenkins参数化构建

有时在项目构建的过程中，我们需要根据用户的输入动态传入一些参数，从而影响整个构建结果，这时
我们可以使用参数化构建。
Jenkins支持非常丰富的参数类型



3.配置邮箱服务器发送构建结果

- 安装Email Extension插件

- Jenkins设置邮箱相关参数

  Manage Jenkins->Configure System



### 3.sonar

安装SonarQube

1）安装MySQL（已完成）

2）安装SonarQube

 在MySQL创建sonar数据库

3) 安装SonarQube Scanner插件

4) 添加SonarQube凭证

5) Jenkins进行SonarQube

​	配置Manage Jenkins->Configure System->SonarQube servers

6) Manage Jenkins->Global Tool Configuration

7) 测试