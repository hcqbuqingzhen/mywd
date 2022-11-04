# Docker

***
## 1 docker安装和启动
### 1.1 安装
    ``` 
    sudo pacman -S docker

    //redhet系linux
    sudo yum install docker-ce
    ```
此时会安装docker和依赖

### 1.2 设置ustc的镜像 

```
vi /etc/docker/daemon.json  
```

在该文件中输入如下内容：

```
{
"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
```

### 1.3 Docker守护进程的启动与停止

启动docker：docker服务即docker守护进程的启动和停止

```
systemctl start docker
```

停止docker：

```
systemctl stop docker
```

重启docker：

```
systemctl restart docker
```

查看docker状态：

```
systemctl status docker
```

开机启动：

```
systemctl enable docker
```

查看docker概要信息

```
docker info
```

查看docker帮助文档

```
docker --help
```
## 2 镜像相关命令

### 2.1 查看镜像
```
docker images
```

REPOSITORY：镜像名称

TAG：镜像标签

IMAGE ID：镜像ID

CREATED：镜像的创建日期（不是获取该镜像的日期）

SIZE：镜像大小

镜像都是存储在Docker宿主机的/var/lib/docker目录下
此目录也是docker的容器的工作目录

### 2.2 搜索镜像

如果你需要从网络中查找需要的镜像，可以通过以下命令搜索

```
docker search 镜像名称
```

NAME：仓库名称

DESCRIPTION：镜像描述

STARS：用户评价，反应一个镜像的受欢迎程度

OFFICIAL：是否官方

AUTOMATED：自动构建，表示该镜像由Docker Hub自动构建流程创建的

### 2.3 拉取镜像

拉取镜像就是从中央仓库中下载镜像到本地

```
docker pull 镜像名称
```

例如，我要下载centos7镜像

```
docker pull centos:7
```

### 2.4 删除镜像

按镜像ID删除镜像

```
docker rmi 镜像ID
```

删除所有镜像

```
docker rmi `docker images -q`
```

## 3 容器相关命令

### 3.1 创建与启动容器

创建容器常用的参数说明：

创建容器命令：docker run

 -i：表示运行容器

 -t：表示容器启动后会进入其命令行。加入这两个参数后，容器创建就能登录进去。即分配一个伪终端。

 --name :为创建的容器命名。

 -v：表示目录映射关系（前者是宿主机目录，后者是映射到宿主机上的目录），可以使用多个－v做多个目录或文件映射。注意：最好做目录映射，在宿主机上做修改，然后共享到容器上。

 -d：在run后面加上-d参数,则会创建一个守护式容器在后台运行（这样创建容器后不会自动登录容器，如果只加-i -t两个参数，创建后就会自动进去容器）。

 -p：表示端口映射，前者是宿主机端口，后者是容器内的映射端口。可以使用多个-p做多个端口映射

（1）交互式方式创建容器 创建后会自动登陆进去

```
docker run -it --name=容器名称 镜像名称:标签 /bin/bash
```

这时我们通过ps命令查看，发现可以看到启动的容器，状态为启动状态  

退出当前容器

```
exit
```

（2）守护式方式创建容器：创建后不会自动登陆进去

```
docker run -di --name=容器名称 镜像名称:标签
```

登录守护式容器方式：

```
docker exec -it 容器名称 (或者容器ID)  /bin/bash
```

### 3.2 停止与启动容器

停止容器：

```
docker stop 容器名称（或者容器ID）
```

启动容器：

```
docker start 容器名称（或者容器ID）
```
### 3.3 查看容器

查看正在运行的容器

```
docker ps
```

查看所有容器

```
docker ps –a
```

查看最后一次运行的容器

```
docker ps –l
```

查看停止的容器

```
docker ps -f status=exited
```
### 3.4 文件拷贝

如果我们需要将文件拷贝到容器内可以使用cp命令：容器启动与否均可拷贝

```
docker cp 需要拷贝的文件或目录 容器名称:容器目录
```

也可以将文件从容器内拷贝出来

```
docker cp 容器名称:容器目录 需要拷贝的文件或目录
```
### 3.5 目录挂载

我们可以在创建容器的时候，将宿主机的目录与容器内的目录进行映射，这样我们就可以通过修改宿主机某个目录的文件从而去影响容器。
创建容器 添加-v参数 后边为   宿主机目录:容器目录，例如：

```
docker run -di -v /usr/local/myhtml:/usr/local/myhtml --name=mycentos3 centos:7
```

如果你共享的是多级的目录，可能会出现权限不足的提示。

这是因为CentOS7中的安全模块selinux把权限禁掉了，我们需要添加参数  --privileged=true  来解决挂载的目录没有权限的问题

### 3.6 查看容器各种数据

我们可以通过以下命令查看容器运行的各种数据

```
docker inspect 容器名称（容器ID） 
```

也可以直接执行下面的命令直接输出IP地址：注意NetworkSettings 前面的.不可省略

```
docker inspect --format='{{.NetworkSettings.IPAddress}}' 容器名称（容器ID）

示例：
docker inspect --format={{.NetworkSettings.Networks.bridge.Gateway}} mycentos3
```

### 3.7 删除容器 

删除指定的容器：不能删除正在运行的容器

```
docker rm 容器名称（容器ID）
```

## 4 实际操作
根据以上命令拉取一个原生的centos镜像,部署tomcat,jdk,nginx等.

### 4.1 操作容器部署jdk和tomcat

1. 拉取镜像
```
docker pull centos
```
2. 建立容器
```
docker run  --name=mytomcat -ti  -p 8080:8080 centos /bin/bash
    ## --name:容器的名字  -di:运行且分配一个伪终端,且进入docker内.  
    ## -p 8080:8080 将docker内的8080端口映射到宿主机的8080端口
docker run  --name=mytomcat -di  -p 8080:8080 centos /bin/bash
    ## --name:容器的名字  -di:后台运行且分配一个伪终端  
    ## -p 8080:8080 将docker内的8080端口映射到宿主机的8080端口
docker exec -it mytomcat /bin/bash 
    ## 进入后台运行的cocker 
```
3. 复制tomcat和jdk到容器中的目录
```
cp tomcat8 mytomcat:/usr/local

cp jdk8 mytomcat:/usr/local
```
4. docker添加环境变量

docker推荐的环境变量添加方式有两种
一是通过dockerfile建立镜像的时候添加.
二是run镜像的时候添加参数

不过我想也可以修改运行中容器的环境变量,不过都不推荐这么做,docker应该是无状态的.

修改 /etc/profile 文件添加环境变量不管用.查阅资料可知 docker启动容器是非登录状态.
修改 /root/.bashrc文件,添加环境变量才起作用.
```
vim /root/.bashrc 
```
添加
```
export JAVA_HOME=/usr/local/jdk8
export PATH=$JAVA_HOME/bin:$PATH 
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar 
```
(这么做是在不推荐,环境变量应该在建立镜像的时候添加,使用dockerfile)
5. 进入tomcat目录下,运行tomcat.
```
/usr/local/tomcat8/bin/startup.sh
```
宿主机启动浏览器访问 localhost:8080即可访问docker内的tomcat服务.

可挂载宿主机上线目录到容器中的tomcat工作目录,启动容器时即可访问上线的web应用.

### 4.2 使用dockerfile和镜像 搭建tomcat+jdk8新镜像.

(1). 编辑Dockerfile文件

```
vim Dockerfile
```

```
#依赖镜像名称和ID
FROM centos:latest
#指定镜像创建者信息
MAINTAINER xiaobai
#COPY 是相对路径jar,把java添加到容器中
COPY jdk8 /usr/local/tomcat
COPY tomcat /usr/local/jdk8
# 这里不知道为啥复制的时候全都复制的tomcat或者jdk8里面的子目录 还需要在docker中再添加目录(会主动创建)
#配置java环境变量
ENV JAVA_HOME /usr/java/jdk8
ENV JRE_HOME $JAVA_HOME/jre
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib:$CLASSPATH
ENV PATH $JAVA_HOME/bin:$PATH

# 设置容器run自启动tomcat
ENTRYPOINT ["/usr/local/tomcat/bin/catalina.sh","run"]
# 不使用 startup.sh 因为是后台进行,docker会直接退出.
```

(2). 执行命令构建镜像

```
docker build -t='mytomcat:test' .
```

注意后边的空格和点，不要省略

(3). 查看镜像是否建立完成

```
docker images
```

(4).  运行新创建的容器

写一个html页面
```
cd ~/env/tool/tomcat/tomcat01-docker/webapps
mkdir ROOT
vim index.html

输入一下内容
<html>
<body>
<h2>Hello tomcat+docker!</h2>
</body>
</html>
```
运行容器
```
docker run --name=mytomcat -di -p 8080:8080 -v ~/dev/tool/tomcat/tomcat01-docker/webapps:/usr/local/tomcat/webapps/ mytomcat:test /bin/bash
# -di 后台运行
# -v 将宿主机目录挂载到tomcat服务目录下  宿主机目录:docker中目录
# -p 端口映射 宿主机端口:docker中端口
# 
```
宿主机访问localhost:8080 访问成功.

## 5 容器的备份
### 5.1 容器保存为镜像

我们可以通过以下命令将容器保存为镜像

```
docker commit mytomcat mytomcat_i:test

执行 docker images 查看当前的境像，发现mytomcat_i存在

```

### 5.2 镜像备份

我们可以通过以下命令将镜像保存为tar 文件

```
// -o表示输出
docker  save -o mynginx.tar mynginx_i
会将境像mynginx_i保存在本地，保存为mynginx.tar文件
```

### 5.3 镜像恢复与迁移

先删除掉mynginx_i镜像  然后执行此命令进行恢复

```
docker load -i mynginx.tar
```

-i 输入的文件

执行后再次查看镜像，可以看到镜像已经恢复

***

参考 ：
[https://www.runoob.com/docker/docker-tutorial.html](https://www.runoob.com/docker/docker-tutorial.html)

想了解docker镜像和容器存储原理的可以看几篇很不错的文章
[https://www.cnblogs.com/wdliu/p/10483252.html](https://www.cnblogs.com/wdliu/p/10483252.html)
[https://sq.163yun.com/blog/article/172542620051890176](https://sq.163yun.com/blog/article/172542620051890176)
这一篇比较老，浓重的翻译腔。
[http://dockone.io/article/783](http://dockone.io/article/783)