# macos下环境搭建

趁着国补降价，买了个m芯片的macos，此文件用来记录搭建一些环境的问题。
分为两个部分，一部分是基础的开发环境和一些工具，二是一些服务器中间件，如mysql，kafka之类的。
最基础的开发环境，使用homebrew安装或者其他的方式安装即可。
服务器软件一般都是运行在linux上的，本机搭建就是临时使用，因此大部分采用docker搭建。可以使用docker—desktop，但界面上可以设置的有限，有时还是需要命令行。

## 开发环境搭建

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

## 相关中间件

### mysql

使用docker
界面上配置就好了,mysql官方提供的docker,文件挂载部分有data文件挂载到外部,可以参阅官方的dockerhub页面.
除了配置挂载文件,也要配置一个环境变量
MYSQL_ROOT_PASSWORD=root账户密码

![挂载文件](https://raw.githubusercontent.com/hcqbuqingzhen/picGoimg/main/picGoimg/20250414235104183.png)

### redis

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

### mongodb

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

