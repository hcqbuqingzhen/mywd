# mongodb安装和集群搭建
## 1. mongodb安装
1.官网下载适合的包,本次下载红帽系tgz包,上传到linux.

```
解压到合适的位置
tar -zxvf mongodb-linux-x86_64.tgz
mv mongodb-linux-x86_64  /opt/mongodb
cd /opt/mongodb
mkdir data
mkdir logs
cd logs/
touch mongo.log
```
2. 配置文件和环境变量
```
mkdir -p /opt/mongodb/conf
vim /opt/mongodb/conf/mongo.conf
```
写入如下配置
```
dbpath=/opt/mongodb/data
logpath=/opt/mongodb/logs/mongo.log
logappend=true
journal=true
quiet=true
port=27017
fork=true #后台运行
bind_ip=0.0.0.0 #允许任何IP进行连接
auth=false #是否授权连接
```
环境变量
```
vim /etc/profile
添加
export PATH=$PATH:/opt/mongodb/bin
source /etc/profile

mongod -f /opt/mongodb/conf/mongo.conf

即可进入mongo来操作数据库了
```

## 2. 集群搭建

在 MongoDB 中,有两种数据冗余方式,一种 是 Master-Slave 模式（主从复制）,一种是 Replica Sets 模式（副本集）。
还可以水平分片,可以存储大数据.

### 2.1 主从复制
1. 机器环境
192.168.1.111
192.168.1.112

2. 主从配置文件

    master－node节点配置
```shell
port=27017
bind_ip=0.0.0.0 #允许任何IP进行连接
dbpath=/usr/local/mongodb/data
logpath=/usr/local/mongodb/log/mongo.log
logappend=true
journal=true
fork=true
master= true        //确定自己是主服务器
```
    slave－node节点配置
```shell
port=27017
dbpath=/usr/local/mongodb/data
logpath=/usr/local/mongodb/log/mongo.log
logappend=true
journal=true
fork=true
bind_ip=0.0.0.0 #允许任何IP进行连接
source=192.168.1.111:27017      //确定主数据库端口
slave=true               //确定自己是从服务器
```
3. 主从数据同步测试

    启动主从数据库
    在192.168.1.111 数据库中登录
```shell
mongo
use test-ms
function add(){ 
    var i = 0;
    for(;i<20;i++){
        db.persons.insert({"name":"wang"+i})
        }
    }
add()
db.persons.find()

#slave-node节点查看
#首先开启rs.sleveok() 可以让从机可以查看
rs.slaveOk();
show dbs
use test-ms
db.persion.find()
```

在主从结构中，主节点的操作记录成为oplog（operation log）。oplog存储在一个系统数据库local的集合oplog.$main中，这个集合的每个文档都代表主节点上执行的一个操作。
从服务器会定期从主服务器中获取oplog记录，然后在本机上执行！对于存储oplog的集合，MongoDB采用的是固定集合，也就是说随着操作过多，新的操作会覆盖旧的操作！
 
主从复制的其他设置项
--only             从节点指定复制某个数据库,默认是复制全部数据库
--slavedelay       从节点设置主数据库同步数据的延迟(单位是秒)
--fastsync         从节点以主数据库的节点快照为节点启动从数据库
--autoresync       从节点如果不同步则从新同步数据库(即选择当通过热添加了一台从服务器之后，从服务器选择是否更新主服务器之间的数据)
--oplogSize        主节点设置oplog的大小(主节点操作记录存储到local的oplog中)


slave-node从节点的local数据库中，存在一个集合sources。这个集合就保存了这个服务器的主服务器是谁

### 2.2 副本集(Replica Sets)
意思是一个副本集由多个主机组成,一台主机,多台备机,当主机宕机后,备机会投票选择一台作为主机.

传统的主从模式,需要手工指定集群中的 Master。如果 Master 发生故障,一般都是人工介入,指定新的 Master。 这个过程对于应用一般不是透明的,往往伴随着应用重新修改配置文件,重启应用服务器等。
而 MongoDB 副本集,集群中的任何节点都可能成为 Master 节点。一旦 Master 节点故障,则会在其余节点中选举出一个新的 Master 节点。 并引导剩余节点连接到新的 Master 节点。这个过程对于应用是透明的。

1. 机器环境
192.168.1.111   master-node(主节点)
192.168.1.112    slave-node1(从节点)
192.168.1.113   slave-node2(从节点)
MongoDB 安装目录:/opt/mongodb
MongoDB 数据库目录:/opt/mongodb/data
MongoDB 日志目录:/opt/mongodb/log/mongo.log
MongoDB 配置文件:opt/mongodb/conf/mongo.conf

2. 配置文件编写
```shell
port=27017
bind_ip =192.168.1.111                 //这个最好配置成本机的ip地址。否则后面进行副本集初始的时候可能会失败！           
dbpath=/opt/mongodb/data
logpath=/opt/mongodb/log/mongo.log
pidfilepath=/opt/mongodb/mongo.pid
fork=true
logappend=true
shardsvr=true
directoryperdb=true
#auth=true
#keyFile =/usr/local/mongodb/keyfile
replSet =hcqmongodb #同一副本集这个配置相同
```
3. master-node主节点进行配置
首先启动三台机器上的mongodb

```shell
mongo

var config={
    _id:'hcqmongodb',
    members:[
        {_id:1, host:'192.168.1.111:27017'},
        {_id:2, host:'192.168.1.112:27017'},
        {_id:3, host:'192.168.1.113:27017'}
    ]
}

rs.initiate(config)

rs.status()
#
{
	"set" : "hcqmongodb",
	"date" : ISODate("2020-01-03T17:20:48.733Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"syncingTo" : "",
	"syncSourceHost" : "",
	"syncSourceId" : -1,
	"heartbeatIntervalMillis" : NumberLong(2000),
	"majorityVoteCount" : 2,
	"writeMajorityCount" : 2,
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1578072034, 1),
			"t" : NumberLong(1)
		},
		"lastCommittedWallTime" : ISODate("2020-01-03T17:20:34.903Z"),
		"readConcernMajorityOpTime" : {
			"ts" : Timestamp(1578072034, 1),
			"t" : NumberLong(1)
		},
		"readConcernMajorityWallTime" : ISODate("2020-01-03T17:20:34.903Z"),
		"appliedOpTime" : {
			"ts" : Timestamp(1578072034, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1578072034, 1),
			"t" : NumberLong(1)
		},
		"lastAppliedWallTime" : ISODate("2020-01-03T17:20:34.903Z"),
		"lastDurableWallTime" : ISODate("2020-01-03T17:20:34.903Z")
	},
	"lastStableRecoveryTimestamp" : Timestamp(1578072033, 2),
	"lastStableCheckpointTimestamp" : Timestamp(1578072033, 2),
	"electionCandidateMetrics" : {
		"lastElectionReason" : "electionTimeout",
		"lastElectionDate" : ISODate("2020-01-03T17:20:32.697Z"),
		"electionTerm" : NumberLong(1),
		"lastCommittedOpTimeAtElection" : {
			"ts" : Timestamp(0, 0),
			"t" : NumberLong(-1)
		},
		"lastSeenOpTimeAtElection" : {
			"ts" : Timestamp(1578072022, 1),
			"t" : NumberLong(-1)
		},
		"numVotesNeeded" : 2,
		"priorityAtElection" : 1,
		"electionTimeoutMillis" : NumberLong(10000),
		"numCatchUpOps" : NumberLong(0),
		"newTermStartDate" : ISODate("2020-01-03T17:20:33.425Z"),
		"wMajorityWriteAvailabilityDate" : ISODate("2020-01-03T17:20:34.894Z")
	},
	"members" : [
		{
			"_id" : 1,
			"name" : "192.168.1.111:27017",
			"ip" : "192.168.1.111",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 1224,
			"optime" : {
				"ts" : Timestamp(1578072034, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-01-03T17:20:34Z"),
			"syncingTo" : "",
			"syncSourceHost" : "",
			"syncSourceId" : -1,
			"infoMessage" : "could not find member to sync from",
			"electionTime" : Timestamp(1578072032, 1),
			"electionDate" : ISODate("2020-01-03T17:20:32Z"),
			"configVersion" : 1,
			"self" : true,
			"lastHeartbeatMessage" : ""
		},
		{
			"_id" : 2,
			"name" : "192.168.1.112:27017",
			"ip" : "192.168.1.112",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 26,
			"optime" : {
				"ts" : Timestamp(1578072034, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1578072034, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-01-03T17:20:34Z"),
			"optimeDurableDate" : ISODate("2020-01-03T17:20:34Z"),
			"lastHeartbeat" : ISODate("2020-01-03T17:20:48.706Z"),
			"lastHeartbeatRecv" : ISODate("2020-01-03T17:20:46.912Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "192.168.1.111:27017",
			"syncSourceHost" : "192.168.1.111:27017",
			"syncSourceId" : 1,
			"infoMessage" : "",
			"configVersion" : 1
		},
		{
			"_id" : 3,
			"name" : "192.168.1.113:27017",
			"ip" : "192.168.1.113",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 26,
			"optime" : {
				"ts" : Timestamp(1578072034, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1578072034, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2020-01-03T17:20:34Z"),
			"optimeDurableDate" : ISODate("2020-01-03T17:20:34Z"),
			"lastHeartbeat" : ISODate("2020-01-03T17:20:48.708Z"),
			"lastHeartbeatRecv" : ISODate("2020-01-03T17:20:46.939Z"),
			"pingMs" : NumberLong(0),
			"lastHeartbeatMessage" : "",
			"syncingTo" : "192.168.1.111:27017",
			"syncSourceHost" : "192.168.1.111:27017",
			"syncSourceId" : 1,
			"infoMessage" : "",
			"configVersion" : 1
		}
	],
	"ok" : 1,
	"$clusterTime" : {
		"clusterTime" : Timestamp(1578072034, 1),
		"signature" : {
			"hash" : BinData(0,"AAAAAAAAAAAAAAAAAAAAAAAAAAA="),
			"keyId" : NumberLong(0)
		}
	},
	"operationTime" : Timestamp(1578072034, 1)
}
#
```
可以发现副本集已搭建完成
在从机上执行
rs.slaveOk()

添加两个管理员账号,一个系统管理员:root 一个数据库管理员:hcq
db.createUser({user:"root",pwd:"root",roles:[{role:"root",db:"admin"}]})
db.createUser({user:"hcq",pwd:"121056",roles:[{role:"userAdminAnyDatabase",db:"admin"}]})

4. 开启登录验证
```shell
mkdir /opt/mongodb/keyfile
cd /opt/mongodb/keyfile/
openssl rand -base64 21 > keyfile
cat keyfile
chmod 600 /opt/mongodb/keyfile/keyfile
```
在其他从机上执行
```shell
mkdir /opt/mongodb/keyfile
vim /opt/mongodb/keyfile/keyfile
输入主机上得到的keyfile E4ypGGWzXP7tF77QW+b8ZgXDsPrQ
chmod 600 /opt/mongodb/keyfile/keyfile
```
修改conf文件
```shell
vim /opt/mongodb/conf/mongo.conf
...
auth=true
keyFile=/opt/mongodb/keyfile/keyfile
```
杀掉各个服务器上mongodb线程
重启mongod服务

mongo -u root -p root

5. 测试 
在主机上执行以下代码
5.1 同步
```shell
use test-ms
function add(){ 
    var i = 0;
    for(;i<20;i++){
        db.persons.insert({"name":"wang"+i})
        }
    }
add()
db.persons.find()
```
会发现同步到从机上了

5.2 关闭主服务器,从服务器是否能顶替
mongo 的命令行执行 rs.status() 发现 PRIMARY 替换了主机了
5.3 关闭的服务器,再恢复,以及主从切换
 a:直接启动关闭的服务,rs.status()中会发现,原来挂掉的主服务器重启后变成从服务器了
 b:额外删除新的服务器 rs.remove("192.168.1.113:27017"); rs.status()
 c:额外增加新的服务器 rs.add({_id:0,host:"192.168.1.113:27017",priority:1});
 d:让新增的成为主服务器 rs.stepDown(),注意之前的 priority 投票
5.4 从服务器读写
 db.getMongo().setSlaveOk();
 db.getMongo().slaveOk();//从库只读,没有写权限,这个方法 java 里面不推荐了
 db.setReadPreference(ReadPreference.secondaryPreferred());// 在 复 制 集 中 优 先 读
 secondary,如果 secondary 访问不了的时候就从 master 中读
 db.setReadPreference(ReadPreference.secondary());// 只 从 secondary 中 读 , 如 果
 secondary 访问不了的时候就不能进行查询

 ### 2.3 分片集群
1. 何为分片
Sharding cluster是一种可以水平扩展的模式,在数据量很大时特给力,实际大规模应用一般会采用这种架构去构建。sharding分片很好的解决了单台服务器磁盘空间、内存、cpu等硬件资源的限制问题，把数据水平拆分出去，降低单节点的访问压力
即多个复制集组成一个逻辑数据库
使用场景：
1）机器的磁盘不够用了。使用分片解决磁盘空间的问题。
2）单个mongod已经不能满足写数据的性能要求。通过分片让写压力分散到各个分片上面,使用分片服务器自身的资源。
3）想把大量数据放到内存里提高性能。和上面一样,通过分片使用分片服务器自身的资源。

2. 分片的好处
1）减少单机请求数,将单机负载,提高总负载 
2）减少单机的存储空间,提高总存空间
3. 分片的组成
分片集群主要由三种组件组成:mongos,config server,shard
mongos  (路由进程, 应用程序接入 mongos 再查询到具体分片)
config server  (路由表服务。 每一台都具有全部 chunk 的路由信息)
shard  (为数据存储分片。 每一片都可以是复制集(replica set))
图例见
https://docs.mongodb.com/manual/sharding/
https://www.cnblogs.com/nulige/p/7613721.html

分片集群的搭建由于比较占用机器,本机就不搭建了.查阅官网学习.