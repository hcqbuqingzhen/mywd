##  jenkins+docker+springcloud

### 1.大致流程

1. 开发人员每天把代码提交到Gitlab代码仓库

2. Jenkins从Gitlab中拉取项目源码，编译并打成jar包，然后构建成Docker镜像，将镜像上传到Harbor私有仓库。

3. Jenkins发送SSH远程命令，让生产部署服务器到Harbor私有仓库拉取镜像到本地，然后创建容器。

4. 最后，用户可以访问到容器

   ![image-20210506174520400](/home/hxq/code/devops/jenkins/04-J+D+S.assets/image-20210506174520400.png)

   

### 2.docker harbor

是docker的私有仓库。

#### 1.harbor安装

1. 下载Harbor的压缩包
   https://github.com/goharbor/harbor/releases

2. 上传压缩包到linux，并解压
   tar -xzf harbor-offline-installer-v1.9.2.tgz
   mkdir /opt/harbor
   mv harbor/* /opt/harbor
   cd /opt/harbor

3. 修改Harbor的配置
   sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker?compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   vi harbor.yml
   修改hostname和port
   hostname: 192.168.66.102
   port: 85

4. 安装Harbor
   ./prepare
   ./install.sh

5. 启动Harbor
   docker-compose up -d 启动
   docker-compose stop 停止
   docker-compose restart 重新启动

6. 访问Harbor
   端口85

   默认账户密码：admin/Harbor12345

#### 2.harbor使用

1. 创建项目
   Harbor的项目分为公开和私有的：
   公开项目：所有用户都可以访问，通常存放公共的镜像，默认有一个library公开项目。
   私有项目：只有授权用户才可以访问，通常存放项目本身的镜像。
   我们可以为微服务项目创建一个新的项目：
2. 创建用户
3. 给项目分配用户
4. 以新用户登陆

#### 3.镜像上传到Harbor  并下载

1. 把镜像上传到Harbor
   给镜像打上标签
   docker tag eureka:v1 192.168.66.102:85/tensquare/eureka:v1

2. 推送镜像
   docker push 192.168.66.102:85/tensquare/eureka:v1
   这时会出现以上报错，是因为Docker没有把Harbor加入信任列表中

3. 把Harbor地址加入到Docker信任列表
   vi /etc/docker/daemon.json
   {"registry-mirrors": ["https://zydiol88.mirror.aliyuncs.com"],"insecure-registries": ["192.168.66.102:85"]}
   需要重启Docker

4. 再次执行推送命令，会提示权限不足
   需要先登录Harbor，再推送镜像

5. 登录Harbor
   docker login -u 用户名 -p 密码 localhost:85

6. 下载

   先登录，再从Harbor下载镜像

   docker login -u 用户名 -p 密码 localhost:85

   docker pull 192.168.66.102:85/tensquare/eureka:v1



### 3.流程实现

#### 参照大文档

