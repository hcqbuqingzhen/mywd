# macos下环境搭建

趁着国补降价，买了个m芯片的macos，此文件用来记录搭建一些环境的问题。
分为两个部分，一部分是基础的开发环境和一些工具，二是一些服务器中间件，如mysql，kafka之类的。
最基础的开发环境，使用homebrew安装或者其他的方式安装即可。
服务器软件一般都是运行在linux上的，本机搭建就是临时使用，因此大部分采用docker搭建。可以使用docker—desktop，但界面上可以设置的有限，有时还是需要命令行。

## 一.开发环境搭建

使用homebrew可以节约一些时间

### java环境

使用homebrew安装即可，orcal和openjdk似乎还没有编译arm版本的jdk，暂时还是使用最先出了arm版的zulujdk
![安装zulujdk](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414232506987.png)
这个想装什么版本装什么版本,一般不用命令行来搞java,idea里选择安装的jdk就好了

### python环境

使用pyenv这个包来管理python环境,这个的好处是可以给不同的项目设置python版本,其原理是在项目目录下设置一个文件,当进入到此文件夹时,默认选择对应的python版本. 一般在ide中如pycharm中也是可以选择不同的python版本的.

![下载pyenv](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414233647449.png)
同时需要在bash的rc中设置环境变量
例如打开zshrc,粘贴以下文件

```shell
#pyenv-管理python环境
export PYENV_ROOT=~/.pyenv
export PATH=$PYENV_ROOT/shims:PYENVROOT/shims:$PATH
```

这样打开命令行的时候就可以使用默认设置的python环境了
![pyenv常用命令](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414234156694.png)

### nvm管理node版本

![nvm](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414234344461.png)

安装好之后也是要在rc中设置环境变量,如下

```shell
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

nvm管理node版本,也有一篇详细的笔记,不过那篇笔记中只记录了linux和windows下的node版本,此处又增加了macos下的记录

## 二.相关中间件

### 1.mysql

使用docker
界面上配置就好了,mysql官方提供的docker,文件挂载部分有data文件挂载到外部,可以参阅官方的dockerhub页面.
除了配置挂载文件,也要配置一个环境变量
MYSQL_ROOT_PASSWORD=root账户密码

![挂载文件](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414235104183.png)

### 2.redis

redis有些配置在docker—desktop无法配置,使用命令行启动如下
1、文件夹映射

```shell
mkdir /Users/eee/docker/redis/data
mkdir /Users/eee/docker/redis/conf
touch /Users/eee/docker/redis/conf/redis.conf
```

2、启动容器

```shell
docker run --name redis
-p 6379:6379
-v /Users/eee/docker/redis/conf/redis.conf:/etc/redis/redis.conf
-v /Users/eee/docker/redis/data:/data
-d redis redis-server /etc/redis/redis.conf
```

这样的目的是因为要使用挂载的配置文件

### 3.mongodb

mongodb的容器,需要做的前置工作挺多

1. 建立挂载文件夹

   ```shell
   mkdir /Users/eee/docker/mongodb/data
   mkdir /Users/eee/docker/mongodb/log
   mkdir /Users/eee/docker/mongodb/conf
   touch /Users/eee/docker/mongodb/conf/mongod.conf
   vim /Users/eee/docker/mongodb/conf/mongod.conf
   ```

2. 编辑内容如下

   ```yml
   storage:
     dbPath: /data/db  ## 和挂载的容器文件夹一致
   systemLog:
     destination: file
     path: /data/log/mongod.log ## 这里要和挂载的容器文件夹一致
   net:
     bindIp: 0.0.0.0
     port: 27017
   security:
     authorization: enabled
   ```

3. 执行命令

   (最后的配置文件名称,要和12建立的配置文件对应上,且要和挂载的configdb文件夹对应上)

   ```shell
   docker run -it
   --name mongodb
   --restart=always
   --privileged
   -p 27017:27017
   -v /Users/eee/docker/mongodb/data:/data/db
   -v /Users/eee/docker/mongodb/log:/data/log
   -v /Users/eee/docker/mongodb/conf:/data/configdb
   -d  mongodb/mongodb-community-server:latest
   --config /data/configdb/mongod.conf
   ```

3. 进入到mongodb容器执行

   ```shell
   mongosh
   ```

    ```javascript
    use admin
    //创建admin用户
    db.createUser({
    user: "admin",
    pwd: "roothcq123",  // 设置复杂密码
    roles: ["root"]  // 赋予超级管理员权限
    })

    //创建一般应用用户和库
    db.createUser({
    user: "rrs_read_write",
    pwd: "rrs@hcq@123",
    roles: [
    { role: "readWrite", db: "rrs" },
    { role: "read", db: "admin" }  // 额外只读其他库
    ]
    })
    ```

4. 退出容器,停止容器,修改配置文件

```yml
security:
  authorization: true # 修改为true
```

6. 重启容器
这样使用新的用户名和密码就可以链接了
![mongodb](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250415200508316.png)

### 4.nacos

有一些老项目需要nacos的老版本,因此会搭建新和旧两个版本,分别是2.2.0和3.0,这里的nacos想要使用本地已有的mysql镜像,需要做一些配置.

1. 在原有的mysql中增加新用户

```sql
CREATE USER 'nacos'@'%' IDENTIFIED BY 'nacos';
GRANT ALL ON nacos30.* TO 'nacos'@'%';
GRANT ALL ON nacos22.* TO 'nacos'@'%';
create database nacos30;
create database nacos22;
```

2. 新增docker网络

```shell
docker network create local
docker network connect local mysql8
```

3. nacos3.0运行

```shell
docker run -d \
  --name nacos3.0 \
  --network local \
  -p 8848:8848 \
  -p 8080:8080 \
  -p 9848:9848 \
  -v /Users/eee/docker/nacos/3.0/logs:/home/nacos/logs \
  -v /Users/eee/docker/nacos/3.0/data:/home/nacos/data \
  -e PREFER_HOST_MODE=hostname \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=mysql8 \
  -e MYSQL_SERVICE_DB_NAME=nacos30 \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_USER=nacos \
  -e MYSQL_SERVICE_PASSWORD=nacos \
  -e MYSQL_SERVICE_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true" \
  -e NACOS_AUTH_ENABLE=true \
  -e NACOS_AUTH_IDENTITY_KEY=2222 \
  -e NACOS_AUTH_IDENTITY_VALUE=2xxx \
  -e NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789 \
  --restart=always \
  nacos/nacos-server:v3.0.0-slim
```

```shell
  -e SERVER_PORT=8848 \
  -e SERVER_SERVLET_CONTEXT-PATH=/nacos \
```

3. nacos2.2运行

```shell
docker run -d \
  --name nacos2.2 \
  --network local \
  -p 8858:8848 \
  -p 9858:9848 \
  -v /Users/eee/docker/nacos/2.2/logs:/home/nacos/logs \
  -v /Users/eee/docker/nacos/2.2/data:/home/nacos/data \
  -e PREFER_HOST_MODE=hostname \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=mysql8 \
  -e MYSQL_SERVICE_DB_NAME=nacos22 \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_USER=nacos \
  -e MYSQL_SERVICE_PASSWORD=nacos \
  -e MYSQL_SERVICE_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true" \
  -e NACOS_AUTH_ENABLE=true \
  -e NACOS_AUTH_IDENTITY_KEY=2222 \
  -e NACOS_AUTH_IDENTITY_VALUE=2xxx \
  -e NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789 \
  --restart=always \
  nacos/nacos-server:v2.2.1-slim
```

#### 注意事项

1. 每个版本的nacos的sql可能是不一样的,因此运行不同的nacos版本要在对应的库下执行对应版本的sql,比如我运行2.2和3.0分别建了两个库并且初始化了不同的sql.相对应的sql可以在github上找到,或者直接下载对应版本的nacos解压后找到sql.
[github//nacos下载](https://github.com/alibaba/nacos/releases?expanded=true&page=4&q=2.2.1)
[github//nocos-docker](https://github.com/nacos-group/nacos-docker/blob/master/env/nacos-standalone-mysql.env)

### 5.kafka
1. 使用bitnami打包的kafka镜像,4.0后kafka已经支持无zk的方式,因此搭建一个两个实例的集群即可
[compose文件](https://github.com/bitnami/containers/blob/main/bitnami/kafka/docker-compose.yml)
2. 运行容器(单例)
```shell
docker run -d \
  --name kafka \
  --network local \
  -p 9092:9092 \
  -v /Users/eee/docker/kafka/4.0.0/k00:/bitnami \
  -e TZ=Asia/Shanghai \
  -e KAFKA_CFG_NODE_ID=0 \
  -e KAFKA_CFG_PROCESS_ROLES=controller,broker \
  -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@kafka:9093 \
  -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
 bitnami/kafka:4.0.0
 ```
 KAFKA_CFG_ADVERTISED_LISTENERS这个配置项是为了在本地能访问

3. 运行容器(集群)

```shell
docker run -d \
  --name kafka1 \
  --network local \
  -p 9094:9092 \
  -v /Users/eee/docker/kafka/4.0.0/k01:/bitnami \
  -e TZ=Asia/Shanghai \
  -e KAFKA_CFG_NODE_ID=1 \
  -e KAFKA_CFG_PROCESS_ROLES=controller,broker \
  -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093 \
  -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9094 \
  -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
 bitnami/kafka:4.0.0


 ## 第二个kafka实例
 docker run -d \
  --name kafka2 \
  --network local \
  -p 9095:9092 \
  -v /Users/eee/docker/kafka/4.0.0/k02:/bitnami \
  -e TZ=Asia/Shanghai \
  -e KAFKA_CFG_NODE_ID=2 \
  -e KAFKA_CFG_PROCESS_ROLES=controller,broker \
  -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093 \
  -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
  -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9095 \
  -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
  -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
  -e KAFKA_CFG_INTER_BROKER_LISTENER_NAME=PLAINTEXT \
 bitnami/kafka:4.0.0
```

3.注意事项
注意当集群运行起来后肯定会报错,这是因为两个实例会自己生成cluster.id,导致不一致报错,网上或者ai说可以增加环境变量 KAFKA_CFG_CLUSTER_ID=mycluster来解决,但是我尝试后不生效.因此手动修改了两个实例的文件下的配置文件.如下图.
![如图](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250618000222397.png)
修改其中的配置项cluster.id为一样的值,然后重启容器.

4.管理工具
此管理工具是常用的一个,也尝试过其他的工具,但是都不是很习惯
[Offset Explorer](https://www.kafkatool.com/download.html)