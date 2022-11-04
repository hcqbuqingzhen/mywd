## jenkins安装和配置

 

### 1.持续集成流程

1）首先，开发人员每天进行代码提交，提交到Git仓库

2）然后，Jenkins作为持续集成工具，使用Git工具到Git仓库拉取代码到集成服务器，再配合JDK，Maven等软件完成代码编译，代码测试与审查，测试，打包等工作，在这个过程中每一步出错，都重新再执行一次整个流程。

3）最后，Jenkins把生成的jar或war包分发到测试服务器或者生产服务器，测试人员或用户就可以访问应用。

### 2.gitlab安装和使用

#### 1.安装

使用docker安装gitlab服务

- 拉取

  docker pull gitlab/gitlab-ce:latest

- 运行容器

  ``docker run \`
   `-itd  \`
   `-p 9980:80 \`
   `-p 9922:22 \`
   `-p 9943:433 \`
   `-v $GITLAB_HOME/config:/etc/gitlab  \`
   `-v $GITLAB_HOME/data:/var/opt/gitlab \`
   `-v $GITLAB_HOME/logs:/var/log/gitlab \`
   `--restart always \`
   `--privileged=true \`
   `--name gitlab \`
   gitlab/gitlab-ce:latest`

  ```shell

#### 2.使用

创建群组，用户，项目。给用户赋权。

### 3.jenkins安装和配置

#### 1.docker安装

- 拉取

  docker pull jenkinszh/jenkins-zh

- 运行

  `

   docker run \
   -itd \
   -p 8080:8080 \
   -v /var/jenkins_home/:/var/jenkins_home/ \
   -v /usr/local/maven/apache-maven-3.8.1/:/usr/local/maven \
   --name="jenkins" \
   jenkinszh/jenkins-zh
  
  `

#### 2.配置

- 必要插件

Role-based Authorization Strategy ：管理Jenkins用户权限

创建用户，角色，为角色分配权限。并测试权限。

Credentials Binding：凭证管理

git：git工具

git的配置

- maven配置

  本机安装maven并映射目录。

  添加全局变量 maven-home

- jdk配置，docker中已经有了jdk,可以利用容器中的jdk.

  添加java-home

- tomcat服务器配置

  在服务器的tomcat中，修改。

  - tomcat/conf/tomcat-users.xml

    添加如下内容：

     <role *rolename*="admin-gui"/>

      <role *rolename*="manager-gui"/>

      <role *rolename*="manager-jmx"/>

      <role *rolename*="manager-script"/>

      <role *rolename*="manager-status"/>

      <user *username*="tomcat" *password*="tomcat" *roles*="admin-gui,manager-gui,manager-jmx,manager-script,manager-status"/>

  - tomcat/webapps/manager/META-INF/context.xml

     <Valve *className*="org.apache.catalina.valves.RemoteAddrValve"

    ​         *allow*="^.*$" />

访问 http://localhost:8081/manager/html 可以成功

