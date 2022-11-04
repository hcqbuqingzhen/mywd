# rabbitmq集群和架构相关

## 1. mq日志与监控

- rabbitmq的日志默认放在 - /var/log/rabbitmq/rabbit@xxx.log

[![Xy0Ads.png](https://s1.ax1x.com/2022/06/09/Xy0Ads.png)](https://imgtu.com/i/Xy0Ads)


- web控制台监控

[![Xy0MyF.png](https://s1.ax1x.com/2022/06/09/Xy0MyF.png)](https://imgtu.com/i/Xy0MyF)

- 控制台命令

[![Xy0YJx.png](https://s1.ax1x.com/2022/06/09/Xy0YJx.png)](https://imgtu.com/i/Xy0YJx)

## 2. 消息追踪

微服务调用有链路追踪,mq当然也有类似的叫做消息追踪.

1. firehose

[![Xy0cfP.png](https://s1.ax1x.com/2022/06/09/Xy0cfP.png)](https://imgtu.com/i/Xy0cfP)

- 增加一个队列绑定到amq.rabbitmq.trace交换机,然后开启这个功能 rabbitmqctl trace_on .

[![XyB9t1.png](https://s1.ax1x.com/2022/06/09/XyB9t1.png)](https://imgtu.com/i/XyB9t1)

任意交换机增加消息,都可以被test_trace队列接受到.
[![XyBf9x.png](https://s1.ax1x.com/2022/06/09/XyBf9x.png)](https://imgtu.com/i/XyBf9x)

消息追踪中包含了更多的信息,更加详细.

2. rabbitmq_tracing插件 

[![XyBbEd.png](https://s1.ax1x.com/2022/06/09/XyBbEd.png)](https://imgtu.com/i/XyBbEd)

查看开启的插件,然后开启这个插件.

[![XyDQa9.png](https://s1.ax1x.com/2022/06/09/XyDQa9.png)](https://imgtu.com/i/XyDQa9)

```shell
 sudo rabbitmq-plugins enable rabbitmq_tracing
```

控制台会多出以下.

[![XyrtWq.png](https://s1.ax1x.com/2022/06/09/XyrtWq.png)](https://imgtu.com/i/XyrtWq)

可以增加trace文件
点击log可以在新页面中查看文本形式的日志.

## 3. 集群方案
一般采用镜像模式

如果我们自己实验,可以选择的有三台虚拟机搭建,也可以一个mq搭建三个实例,也可以使用docker来搭建,如果使用docker还可以使用docker-compose来搭建.

### 3.1 三台虚拟机实现

1. 修改host文件

```bash
1、修改HOST文件方便输入命令行
	vim /etc/hosts

2、对HOST文件添加内容
	192.168.226.148 node1
	192.168.226.149 node2
	192.168.226.150 node3
```
2. 复制erlange cookie

```shell
scp /var/lib/rabbitmq/.erlang.cookie root@node2:/var/lib/rabbitmq/.erlang.cookie
scp /var/lib/rabbitmq/.erlang.cookie root@node3:/var/lib/rabbitmq/.erlang.cookie
```

3. 在所有节点上执行组成集群命令

```shell
rabbitmq-server -detached
```

4. 此那个节点加入集群

```shell
1、停止MQ服务
rabbitmqctl stop_app

1、重置MQ
rabbitmqctl reset

3、加入主节点
rabbitmqctl join_cluster rabbit@node1									

4、重启服务
rabbitmqctl start_app(只启动应用服务)
```

这是可以查看集群状态
```shell
rabbitmqctl cluster_status
```
5. 现在可以在主节点上创建超级管理员和其他用户,

```shell
1、添加账号
	rabbitmqctl add_user admin 123

2、设置用户角色
	rabbitmqctl set_user_tags admin administrator
  
3、设置用户权限
	rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"
```


6. 镜像队列配置

[![Xyy5id.png](https://s1.ax1x.com/2022/06/09/Xyy5id.png)](https://imgtu.com/i/Xyy5id)

参数解释
>Name:  policy的名称
>Pattern:  queue的匹配模式（正则表达式）
>Definition:  镜像定义，包括三个部分 ha-mode，ha-params，ha-sync-mode,ha-mode:  指明镜像队列的模式，有效值为 all/exactly/nodesall表示在集群所有的节点上进行镜像exactly表示在指定个数的节点上进行镜像，节点的个数由ha-params指定，个数包含主机nodes表示在指定的节点上进行镜像，节点名称通过ha-params指定ha-params: ha-mode模式需要用到的参数ha-sync-mode: 镜像队列中消息的同步方式，有效值为 automatic、manually
>Priority:  可选参数， policy的优先级

7. 创建一个镜像队列

[![Xy68Te.png](https://s1.ax1x.com/2022/06/09/Xy68Te.png)](https://imgtu.com/i/Xy68Te)

创建一个名为 backup-node1 的队列,刷新后可以看到控制页上多出 +1 提示,意为当前已有一个备份，点击查看详情可看到备份队列具体存在的节点

### 3.2 docker实现

docker的安装和docker-compose安装这里不再细讲.

#### 1. docker直接实现
1. 创建容器

```shell
docker run -d --hostname rabbit1 --name myrabbit1 -p 15672:15672 -p 5672:5672 -e RABBITMQ_ERLANG_COOKIE='dmbjzcookies' rabbitmq:3-management
docker run -d --hostname rabbit2 --name myrabbit2 -p 15673:15672 -p 5673:5672 --link myrabbit1:rabbit1 -e RABBITMQ_ERLANG_COOKIE='dmbjzcookies' rabbitmq:3-management
docker run -d --hostname rabbit3 --name myrabbit3 -p 15674:15672 -p 5674:5672 --link myrabbit1:rabbit1 --link myrabbit2:rabbit2 -e RABBITMQ_ERLANG_COOKIE='dmbjzcookies' rabbitmq:3-management
```

2. 加入集群

```shell
docker exec -it myrabbit1 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl start_app
exit

docker exec -it myrabbit2 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster  rabbit@rabbit1
rabbitmqctl start_app
exit


docker exec -it myrabbit3 bash
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster  rabbit@rabbit1
rabbitmqctl start_app
exit
```
#### 2 docker-compose实现

1. compose文件

```yml
version: "2.0"
services:
  rabbit1:
    image: rabbitmq:3-management
    hostname: rabbit1
    ports:
      - 5672:5672
      - 15672:15672
    environment:
      - RABBITMQ_DEFAULT_USER=guest
      - RABBITMQ_DEFAULT_PASS=guest
      - RABBITMQ_ERLANG_COOKIE='dmbjzrabbitmq'

  rabbit2:
    image: rabbitmq:3-management
    hostname: rabbit2
    ports:
      - 5673:5672
    environment:
      - RABBITMQ_ERLANG_COOKIE='dmbjzrabbitmq'
    links:
      - rabbit1
  rabbit3:
    image: rabbitmq:3-management
    hostname: rabbit3
    ports:
      - 5674:5672
    environment:
      - RABBITMQ_ERLANG_COOKIE='dmbjzrabbitmq'
    links:
      - rabbit1
      - rabbit2
```

执行

```shell
docker-compose up -d
```

2. 在节点2,3中配置加入到集群(进入到容器中执行)

- 节点2

```shell
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app
exit
```

- 节点3

```shell
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl join_cluster rabbit@rabbit2
rabbitmqctl start_app
exit
```

## 4. 集群方案之上的高可用
采用haproxy负载均衡mq
用keepalive保证haproxy的统一入口和高可用.

### 1. haproxy安装和配置

1. 安装
centos安装

```shell
1、安装依赖
	yum install -y gcc wget


2、下载HaProxy
	wget http://www.haproxy.org/download/1.6/src/haproxy-1.6.5.tar.gz
  
  
3、解压HaProxy
	tar -zxvf haproxy-1.6.5.tar.gz -C /usr/local
  
  
4、安装HaProxy
	cd /usr/local/haproxy-1.6.5
	make TARGET=linux31 PREFIX=/usr/local/haproxy
	make install PREFIX=/usr/local/haproxy
	mkdir /etc/haproxy
  

5、赋权
	groupadd -r -g 149 haproxy
  useradd -g haproxy -r -s /sbin/nologin -u 149 haproxy
  
  
6、创建配置文件
	touch /etc/haproxy/haproxy.cfg
```

至于我的archinux

```shell
sudo pacman -S haproxy即可
```

2. 配置

```properties
#logging options
global
	log 127.0.0.1 local0 info
	maxconn 5120
	chroot /usr/local/haproxy
	uid 99
	gid 99
	daemon
	quiet
	nbproc 20
	pidfile /var/run/haproxy.pid

defaults
	log global
	#使用4层代理模式，”mode http”为7层代理模式
	mode tcp
	#if you set mode to tcp,then you nust change tcplog into httplog
	option tcplog
	option dontlognull
	retries 3
	option redispatch
	maxconn 2000
	contimeout 5s
     ##客户端空闲超时时间为 60秒 则HA 发起重连机制
     clitimeout 60s
     ##服务器端链接超时时间为 15秒 则HA 发起重连机制
     srvtimeout 15s	
#front-end IP for consumers and producters

listen rabbitmq_cluster
	bind 0.0.0.0:5672
	#配置TCP模式
	mode tcp
	#balance url_param userid
	#balance url_param session_id check_post 64
	#balance hdr(User-Agent)
	#balance hdr(host)
	#balance hdr(Host) use_domain_only
	#balance rdp-cookie
	#balance leastconn
	#balance source //ip
	#简单的轮询
	balance roundrobin
	#rabbitmq集群节点配置 #inter 每隔五秒对mq集群做健康检查， 2次正确证明服务器可用，2次失败证明服务器不可用，并且配置主备机制
        server bhz76 192.168.226.148:5672 check inter 5000 rise 2 fall 2
        server bhz77 192.168.226.149:5672 check inter 5000 rise 2 fall 2
        server bhz78 192.168.226.150:5672 check inter 5000 rise 2 fall 2
#配置haproxy web监控，查看统计信息，152机器bind的就是192.168.226.152:8100
listen stats
	bind 192.168.226.151:8100
	mode http
	option httplog
	stats enable
	#设置haproxy监控地址为http://localhost:8100/rabbitmq-stats
	stats uri /rabbitmq-stats
	stats refresh 5s
```

3. 启动和访问

```shell
1、启动HaProxy
  /usr/local/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg


2、查看HaProxy状态
	ps -ef | grep haproxy
  
  
3、访问Web控制台
	http://192.168.226.151:8100/rabbitmq-stats
	http://192.168.226.152:8100/rabbitmq-stats
```

### 2. keepalive

1. 安装

centos(通用)

```shell
1、下载依赖和资源包
	yum install -y openssl openssl-devel
	wget http://www.keepalived.org/software/keepalived-1.2.18.tar.gz


2、解压&编译&安装
	tar -zxvf keepalived-1.2.18.tar.gz -C /usr/local/
  cd /usr/local/
	cd keepalived-1.2.18/ && ./configure --prefix=/usr/local/keepalived
	make && make install
  
  
3、将keepalived安装成Linux系统服务
	mkdir /etc/keepalived
	cp /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/
  ln -s /usr/local/sbin/keepalived /usr/sbin/
	ln -s /usr/local/keepalived/sbin/keepalived /sbin/
  
  如果又遇到软连接不能生成的问题，需要先删除
    rm -f /usr/sbin/keepalived
    rm -f /sbin/keepalived
    
    
4、设置KeepAlive开启自启动
		chkconfig keepalived on
```

至于archlinux

```shell
sudo pacman -S keepalived
```

2. 修改配置文件 
   
etc/keepalived/keepalived.conf ,主从节点中 vrrp_instance VI_1 中的部分参数不

```conf
! Configuration File for keepalived

global_defs {
   router_id node4  ##标识节点的字符串，通常为hostname
}

vrrp_script chk_haproxy {
    script "/etc/keepalived/haproxy_check.sh"  ##执行脚本位置
    interval 2  ##检测时间间隔
    weight -20  ##如果条件成立则权重减20
}

vrrp_instance VI_1 {
    state MASTER  ## 主节点为MASTER，备份节点为BACKUP
    interface ens33 ## 绑定虚拟IP的网络接口（网卡）,与本机IP地址所在的网络接口相同
    virtual_router_id 79  ## 虚拟路由ID号（主备节点一定要相同）
    mcast_src_ip 192.168.226.151 ## 本机ip地址
    priority 100  ##节点优先级配置,主节点优先级要大于从节点（0-254的值）
    nopreempt
    advert_int 1  ## 组播信息发送间隔，俩个节点必须配置一致，默认1s
		authentication {  ## 使用密码认证匹配
        auth_type PASS
        auth_pass bhz
    }

    track_script {
        chk_haproxy
    }

    virtual_ipaddress {
        192.168.11.70  ## 虚拟ip，可以指定多个，给外部访问
    }
    
}
```

增加一个挂掉后自启动的脚本

/etc/keepalived/haproxy_check.sh

```shell
#!/bin/bash
COUNT=`ps -C haproxy --no-header |wc -l`
if [ $COUNT -eq 0 ];then
    /usr/local/haproxy/sbin/haproxy -f /etc/haproxy/haproxy.cfg
    sleep 2
    if [ `ps -C haproxy --no-header |wc -l` -eq 0 ];then
        killall keepalived
    fi
fi
```

```shell
chmod +x /etc/keepalived/haproxy_check.sh
```

启动查看

```shell
1、启动KeepAlived
	service keepalived start


2、查看状态
	ps -ef | grep haproxy
  ps -ef | grep keepalived


3、查看虚拟IP创建情况
	ip a
```

当我们应用中mq的地址改为192.168.11.70会自动路由到某一个mq的节点上.

## 小结

1. mq的日志和控制台其他功能
2. 消息追踪即trace的两种实现.控制台和插件.
3. 搭建集群的几种方式,使用docker比较简便.
4. 使用可ha和keepalive,ha保证mq的高可用和负载均衡.  keepalive保证ha的主从高可用,在不同机器之间提供了统一的虚拟ip.
这种架构图如下
[![Xyg0Ig.png](https://s1.ax1x.com/2022/06/10/Xyg0Ig.png)](https://imgtu.com/i/Xyg0Ig)
