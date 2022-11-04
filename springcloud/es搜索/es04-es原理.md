## es04-es原理
### es集群 
>首先，每一个ElasticSearch服务端就是一个集群节点，当我们启动一个elasticsearch时，就相当于启动了一个集群节点。
那么，多个节点之间如何建立联系呢？当我们启动一个节点的时候，这个节点会自动创建一个集群，集群的名称默认为elasticsearch，当我们再次启动一个节点的时候，它首先会尝试寻找名称为elasticsearch的集群，然后加入其中，（所有的都是先尝试寻找，没有再自己创建）。【集群名称可以自行配置，下面讲】
当节点加入到集群中后，这个集群就算是建立起来了。

#### 1.配置文件
ElasticSearch的配置文件是config/elasticsearch.yml，里面有以下几个配置项：
【左边是配置项，右边是值，修改配置也就是修改右边的值】

- 集群名称：cluster.name: my-application
- 索引存储位置：path.data: /path/to/data
- 日志存储位置：path.logs: /path/to/logs
- 绑定的IP地址：network.host: 192.168.0.1
- 绑定的http端口：http.port: 9200
- 是否允许使用通配符来标识索引：action.destructive_requires_name，true为禁止。

#### 2.健康状态
GET /_cluster/health：以json方式显示集群状态

返回结果解析：
- epoch：时间戳
- timestamp：时间
- cluster：集群名
- status：状态
- 集群状态解析看下面。
- node.total：集群中的节点数
- node.data：集群中的数据节点数
- shards：集群中总的分片数量
- pri：主分片数量
- relo：副本分片数量
- init：初始化中的分片数？【不确定，英文是这样的：number of initializing nodes 】
- unassign：没有被分配的分片的数量
- pending_tasks：待处理的任务数
- max_task_wait_time：最大任务等待时间
- activeds_percent：active的分片数量

### 分片

文档的数据是存储到索引中的，而索引的数据是存储在分片上的，而分片是位于节点上的。

>分片shard有主分片primary shard和复制分片replica shard两种，其中主分片是主要存储的分片，可以进行读写操作；副本分片是主分片的备份，可以进行读操作（不支持写操作）。
查询可以在主分片或副本分片上进行查询，这样可以提供查询效率。

主分片有读和写的能力，副本分片只可以读，所以数据的更新都发生在主分片上

### 文档的元数据
- _index:代表当前document存放到哪个index中。
- _type:代表当前document存放在index的哪个type中。
- _id:代表document的唯一标识，与index和type一起，可以唯一标识和定位一个document。【在前面我们都是手动指定的，其实可以不手动指定，那样会随机产生要给唯一的字符串作为ID】
- _version：是当前document的版本，这个版本用于标识这个document的“更新次数”（新建、删除、修改都会增加版本）
- _source：返回的结果是查询出来的当前存储在索引中的完整的document数据。之前在搜索篇中讲到了，我们可以使用_source来指定返回docuemnt的哪些字段。

### 文档的数据类型
ElasticSearch主要有以下这几种数据类型：

- 字符类：
    - text：是存储字符串的类型，在elasticsearch中存储会分词的字符串数据一般用text
    - keyword：也是存储字符串的类型，在elasticsearch中用于存储不会分词的、结构化的字符串数据
    - string:string在5.x之前可以使用，现在已被text和keyword取代。
- 整数类型：
    - integer
    - long
    - short
    - byte
- 浮点数类型：
    - double
    - float
- 日期类型：date
- 布尔类型：boolean
- 数组类型：array
- 对象类型：object

### mapping
>mapping负责维护index中文档的结构，包括文档的字段名、字段数据类型、分词器、字段是否进行分词等。这些属性会对我们的搜索造成影响。

>在前面，其实我们都没有定义过mapping，直接就是插入数据了。其实这时候ElasticSearch会帮我们自动定义mapping,这个mapping会依据文档的数据来自动生成。
此时，如果数据是字符串的，会认为是text类型，并且默认进行分词；如果数据是日期类型类（字符串里面的数据是日期格式的），那么这个字段会认为是date类型的，是不分词的；如果数据是整数，那么这个字段会认为是long类型的数据；如果数据是小数，那么这个字段会认为是float类型的；如果是true或者false，会认为是boolean类型的。

例子  
```json
1.创建一个mapping,只定义数据类型：【定义了每个字段的数据类型后，插入数据的时候并没有说要严格遵循，数据类型的作用是提前声明字段的数据类型，例如在之前第二篇说type的时候，就提到了多个type中的字段其实都会汇总到mapping中，如果不提前声明，那么可能导致因为使用dynamic mapping而使得数据类型定义出错。比如在type1中birthdate字段】    

当我们直接插入document的时候，如果不指定document的数据结构，那么ElastciSearch会基于dynamic mapping来自动帮我们声明每一个字段的数据类型  

比如"content":"hello world!"会被声明成字符串类型，"post_date":"2017-07-07"会被认为是date类型。

如果我们首先在一个type中声明了content为字符串类型，再在另外一个type中声明成日期类型，这会报错，因为对于index来说，这个content已经被声明成字符串类型了。

PUT /test0101
{
  "settings": {
    "index":{
      "number_of_shards":3,
      "number_of_replicas":1
    }
  },
  "mappings": {
    "person":{
      "properties": {
        "name":{
          "type": "text"
        },
        "age":{
          "type": "long"
        },
        "birthdate":{
          "type":"date"
        }
      }
    }
  }
}

2.设置某个字段不进行索引【设置后，你可以尝试对这个字段搜索，会报错！】
PUT /test0102
{
  "settings": {
    "index":{
      "number_of_shards":3,
            "number_of_replicas":1
    }
  },
  "mappings": {
    "person":{
      "properties": {
        "name":{
          "type": "text",
          "index": "false"
        },
        "age":{
          "type": "long"
        },
        "birthdate":{
          "type":"date"
        }
      }
    }
  }
}
测试：
PUT /test0102/person/1
{
  "name":"Paul Smith",
  "age":18,
  "birthdate":"2018-01-01"
}
GET /test0102/person/_search
{
  "query": {
    "match": {
      "name": "Paul"
    }
  }
}

3.给某个字段增加keyword

PUT /test0103
{
  "settings": {
    "index":{
      "number_of_shards":3,
            "number_of_replicas":1
    }
  },
  "mappings": {
    "person":{
      "properties": {
        "name":{
          "type": "text",
          "index": "false",
          "fields": {
            "keyword": {
							"type": "keyword",
							"ignore_above": 256
						}
          }
        },
        "age":{
          "type": "long"
        },
        "birthdate":{
          "type":"date"
        }
      }
    }
  }
}
测试：
PUT /test0103/person/1
{
  "name":"Paul Smith",
  "age":18,
  "birthdate":"2018-01-01"
}
【注意这里是不能使用name来搜索的，要使用name.keyword来搜索，而且keyword是对原始数据进行**不分词**的搜索的，所以你搜单个词是找不到的。】
GET /test0103/person/_search
{
  "query": {
    "match": {
      "name.keyword": "Paul Smith"
    }
  }
}
```

#### 修改mapping  
mapping只能新增字段，不能修改原有的字段。
```json
// 给索引test0103的类型person新增一个字段height
PUT /test0103/_mapping/person
{
  "properties": {
    "height":{
      "type": "float"
    }
  }
}
```

#### 查看mapping

1.之前说过了，可以通过查看索引来查看mapping：GET /index，例如GET /test0103/_mapping
2.通过GET /index/_mapping，例子：GET /test0103/_mapping
3.你也可以附加type来查看指定type包裹的mapping。GET /test0103/_mapping/person

### 相关度分数

相关度分数的具体算法我们其实并不需要关心。但可能还是需要大概了解一下计算的方式。

- 在我们进行搜索的时候，你可以看到一个score，这个就是相关度分数，在默认排序中相关度分数最高的会被排在最前面，这个分数是ElasticSearch根据你搜索的内容，使用内部算法计算出的一个数值。
- 内部算法主要是指TF算法和IDF算法。

- TF算法，全称Term frequency，索引词频率算法。
意义就像它的名字，会根据索引词的频率来计算，索引词出现的次数越多，分数越高  

- IDF算法全称Inverse Document Frequency，逆文本频率。
搜索文本的词在整个索引的所有文档中出现的次数越多，这个词所占的score的比重就越低。

#### score计算API
```json
GET /index/type/_search?explain=true
{
  "query": {
    "match": {
      "搜索字段": "搜索值"
    }
  }
}
例子：
GET /douban/book/_search?explain=true
{
  "query": {
    "match": {
      "book_name": "Story"
    }
  }
}
```

### 分词器

中文分词器
IK分词器提供了两种分词器ik_max_word和ik_smart

- ik_max_word: 会将文本做最细粒度的拆分，比如北京天安门广场会被拆分为北京，京，天安门广场，天安门，天安，门，广场，会尝试各种在IK中可能的组合；
- ik_smart: 会做最粗粒度的拆分，比如会将北京天安门广场拆分为北京，天安门广场。
一般都会使用ik_max_word，只有在某些确实只需要最粗粒度的时候才使用ik_smart。

