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

有一些老项目需要nacos的老版本,因此会搭建新和旧两个版本,分别是2.1.0和2.5.0,这里的nacos想要使用本地已有的mysql镜像,需要做一些配置.

1. 在原有的mysql中增加新用户

```sql
CREATE USER 'nacos'@'%' IDENTIFIED BY 'nacos';
GRANT ALL ON nacos24.* TO 'nacos'@'%';
GRANT ALL ON nacos21.* TO 'nacos'@'%';
create database nacos24;
create database nacos21;
```

2. 新增docker网络

```shell
docker network create local
docker network connect local mysql8
```

3. nacos2.4运行

```shell
docker run -d \
  --name nacos2.4 \
  --network local \
  -p 8848:8848 \
  -p 9848:9848 \
  -v /Users/eee/docker/nacos/2.4/logs:/home/nacos/logs \
  -v /Users/eee/docker/nacos/2.4/data:/home/nacos/data \
  -e PREFER_HOST_MODE=hostname \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=mysql8 \
  -e MYSQL_SERVICE_DB_NAME=nacos24 \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_USER=nacos \
  -e MYSQL_SERVICE_PASSWORD=nacos \
  -e MYSQL_SERVICE_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true" \
  -e NACOS_AUTH_ENABLE=true \
  -e NACOS_AUTH_IDENTITY_KEY=2222 \
  -e NACOS_AUTH_IDENTITY_VALUE=2xxx \
  -e NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789 \
  --restart=always \
  nacos/nacos-server:v2.4.0-slim
```

3. nacos2.1运行

```shell
docker run -d \
  --name nacos2.1 \
  --network local \
  -p 8858:8848 \
  -p 9858:9848 \
  -v /Users/eee/docker/nacos/2.1/logs:/home/nacos/logs \
  -v /Users/eee/docker/nacos/2.1/data:/home/nacos/data \
  -e PREFER_HOST_MODE=hostname \
  -e MODE=standalone \
  -e SPRING_DATASOURCE_PLATFORM=mysql \
  -e MYSQL_SERVICE_HOST=mysql8 \
  -e MYSQL_SERVICE_DB_NAME=nacos21 \
  -e MYSQL_SERVICE_PORT=3306 \
  -e MYSQL_SERVICE_USER=nacos \
  -e MYSQL_SERVICE_PASSWORD=nacos \
  -e MYSQL_SERVICE_DB_PARAM="characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true" \
  -e NACOS_AUTH_ENABLE=true \
  -e NACOS_AUTH_IDENTITY_KEY=2222 \
  -e NACOS_AUTH_IDENTITY_VALUE=2xxx \
  -e NACOS_AUTH_TOKEN=SecretKey012345678901234567890123456789012345678901234567890123456789 \
  --restart=always \
  nacos/nacos-server:v2.1.0-slim
```

#### 注意事项

1. 每个版本的nacos的sql可能是不一样的,因此运行不同的nacos版本要在对应的库下执行对应版本的sql,比如我运行2.1和2.4分别建了两个库并且初始化了不同的sql.相对应的sql可以在github上找到,或者直接下载对应版本的nacos解压后找到sql.
[github//nacos下载](https://github.com/alibaba/nacos/releases?expanded=true&page=4&q=2.1)
[github//nocos-docker](https://github.com/nacos-group/nacos-docker/blob/master/env/nacos-standalone-mysql.env)