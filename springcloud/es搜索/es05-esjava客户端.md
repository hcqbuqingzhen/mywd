## ES客户端Java High Level REST Client

本节主要内容是使用ES客户端Java High Level REST Client操作ES  
>Java High Level REST Client是ElasticSearch官方目前推荐使用的，适用于6.x以上的版本，要求JDK在1.8以上，
可以很好的在大版本中进行兼容，并且该架包自身也包含Java Low Level REST Client中的方法，可以应对一些特需的情况进行特殊的处理， 
它对于一些常用的方法封装Restful风格，可以直接对应操作名调用使用即可，支持同步和异步(Async)调用。

### 索引操作和文档基本操作

```java

import java.io.IOException;
import java.util.ArrayList;
import java.util.concurrent.TimeUnit;

import org.elasticsearch.action.admin.indices.delete.DeleteIndexRequest;
import org.elasticsearch.action.bulk.BulkRequest;
import org.elasticsearch.action.bulk.BulkResponse;
import org.elasticsearch.action.delete.DeleteRequest;
import org.elasticsearch.action.delete.DeleteResponse;
import org.elasticsearch.action.get.GetRequest;
import org.elasticsearch.action.get.GetResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchRequest;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.support.master.AcknowledgedResponse;
import org.elasticsearch.action.update.UpdateRequest;
import org.elasticsearch.action.update.UpdateResponse;
import org.elasticsearch.client.RequestOptions;
import org.elasticsearch.client.RestHighLevelClient;
import org.elasticsearch.client.indices.CreateIndexRequest;
import org.elasticsearch.client.indices.CreateIndexResponse;
import org.elasticsearch.client.indices.GetIndexRequest;
import org.elasticsearch.common.unit.TimeValue;
import org.elasticsearch.common.xcontent.XContentType;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.index.query.TermQueryBuilder;
import org.elasticsearch.search.SearchHit;
import org.elasticsearch.search.builder.SearchSourceBuilder;
import org.elasticsearch.search.fetch.subphase.FetchSourceContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;

import com.alibaba.fastjson.JSON;

/**
 *  es7.6.x 高级客户端测试 API
 */
@SpringBootTest
public class ElasticsearchJdApplicationTests {
    // 面向对象来操作
    @Autowired
    @Qualifier("restHighLevelClient")
    private RestHighLevelClient client;

    // 测试索引的创建 Request PUT kuang_index
    @Test
    void testCreateIndex() throws IOException {
        // 1、创建索引请求
        CreateIndexRequest request = new CreateIndexRequest("kuang_index");
        // 2、客户端执行请求 IndicesClient,请求后获得响应
        CreateIndexResponse createIndexResponse = client.indices().create(request, RequestOptions.DEFAULT);
        System.out.println(createIndexResponse);
    }

    // 测试获取索引,判断其是否存在
    @Test
    void testExistIndex() throws IOException {
        GetIndexRequest request = new GetIndexRequest("kuang_index2");
        boolean exists = client.indices().exists(request, RequestOptions.DEFAULT);
        System.out.println(exists);
    }

    // 测试删除索引
    @Test
    void testDeleteIndex() throws IOException {
        DeleteIndexRequest request = new DeleteIndexRequest("kuang_index");
        // 删除
        AcknowledgedResponse delete = client.indices().delete(request, RequestOptions.DEFAULT);
        System.out.println(delete.isAcknowledged());
    }

    // 测试添加文档
    @Test
    void testAddDocument() throws IOException {
        // 创建对象
        User user = new User("狂神说", 3);
        // 创建请求
        IndexRequest request = new IndexRequest("kuang_index");
        // 规则 put /kuang_index/_doc/1
        request.id("1");
        request.timeout(TimeValue.timeValueSeconds(1));
        request.timeout("1s");
        // 将我们的数据放入请求 json
        request.source(JSON.toJSONString(user), XContentType.JSON);
        // 客户端发送请求 , 获取响应的结果
        IndexResponse indexResponse = client.index(request, RequestOptions.DEFAULT);
        System.out.println(indexResponse.toString()); //
        System.out.println(indexResponse.status()); // 对应我们命令返回的状态CREATED
    }

    // 获取文档，判断是否存在 get /index/doc/1
    @Test
    void testIsExists() throws IOException {
        GetRequest getRequest = new GetRequest("kuang_index", "1");
        // 不获取返回的 _source 的上下文了
        getRequest.fetchSourceContext(new FetchSourceContext(false));
        getRequest.storedFields("_none_");
        boolean exists = client.exists(getRequest, RequestOptions.DEFAULT);
        System.out.println(exists);
    }

    // 获得文档的信息
    @Test
    void testGetDocument() throws IOException {
        GetRequest getRequest = new GetRequest("kuang_index", "1");
        GetResponse getResponse = client.get(getRequest, RequestOptions.DEFAULT);
        System.out.println(getResponse.getSourceAsString()); // 打印文档的内容
        System.out.println(getResponse); // 返回的全部内容和命令式一样的
    }

    // 更新文档的信息
    @Test
    void testUpdateRequest() throws IOException {
        UpdateRequest updateRequest = new UpdateRequest("kuang_index", "1");
        updateRequest.timeout("1s");
        User user = new User("狂神说Java", 18);
        updateRequest.doc(JSON.toJSONString(user), XContentType.JSON);
        UpdateResponse updateResponse = client.update(updateRequest, RequestOptions.DEFAULT);
        System.out.println(updateResponse.status());
    }

    // 删除文档记录
    @Test
    void testDeleteRequest() throws IOException {
        DeleteRequest request = new DeleteRequest("kuang_index", "1");
        request.timeout("1s");
        DeleteResponse deleteResponse = client.delete(request, RequestOptions.DEFAULT);
        System.out.println(deleteResponse.status());
    }

    // 特殊的，真的项目一般都会批量插入数据！
    @Test
    void testBulkRequest() throws IOException {
        BulkRequest bulkRequest = new BulkRequest();
        bulkRequest.timeout("10s");
        ArrayList<User> userList = new ArrayList<>();
        userList.add(new User("kuangshen1", 3));
        userList.add(new User("kuangshen2", 3));
        userList.add(new User("kuangshen3", 3));
        userList.add(new User("qinjiang1", 3));
        userList.add(new User("qinjiang1", 3));
        userList.add(new User("qinjiang1", 3));
        // 批处理请求
        for (int i = 0; i < userList.size(); i++) {
            // 批量更新和批量删除，就在这里修改对应的请求就可以了
            bulkRequest.add(new IndexRequest("kuang_index").id("" + (i + 1))
                .source(JSON.toJSONString(userList.get(i)), XContentType.JSON));
        }
        BulkResponse bulkResponse = client.bulk(bulkRequest, RequestOptions.DEFAULT);
        System.out.println(bulkResponse.hasFailures()); // 是否失败，返回 false 代表 成功！
    }

    // 查询
    // SearchRequest 搜索请求
    // SearchSourceBuilder 条件构造
    // HighlightBuilder 构建高亮
    // TermQueryBuilder 精确查询
    // MatchAllQueryBuilder
    // xxx QueryBuilder 对应我们刚才看到的命令！
    @Test
    void testSearch() throws IOException {
        SearchRequest searchRequest = new SearchRequest("kuang_index");
        // 构建搜索条件
        SearchSourceBuilder sourceBuilder = new SearchSourceBuilder();
        sourceBuilder.highlighter();
        // 查询条件，我们可以使用 QueryBuilders 工具来实现
        // QueryBuilders.termQuery 精确
        // QueryBuilders.matchAllQuery() 匹配所有
        TermQueryBuilder termQueryBuilder = QueryBuilders.termQuery("name", "qinjiang1");
        // MatchAllQueryBuilder matchAllQueryBuilder =
        QueryBuilders.matchAllQuery();
        sourceBuilder.query(termQueryBuilder);
        sourceBuilder.timeout(new TimeValue(60, TimeUnit.SECONDS));
        searchRequest.source(sourceBuilder);
        SearchResponse searchResponse = client.search(searchRequest, RequestOptions.DEFAULT);
        System.out.println(JSON.toJSONString(searchResponse.getHits()));
        System.out.println("=================================");
        for (SearchHit documentFields : searchResponse.getHits().getHits()) {
            System.out.println(documentFields.getSourceAsMap());
        }
    }
}
```

### 查询选项
#### 一个基本的查询构造
1. 创建SearchRequest，不带参数，表示查询所有索引
2. 添加大部分查询参数到 SearchSourceBuilder，接收QueryBuilders构建的查询参数
3. 添加 match_all 查询到 SearchSourceBuilder
4. 添加 SearchSourceBuilder 到 SearchRequest  

```java
SearchRequest searchRequest = new SearchRequest(); 
SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder(); 
searchSourceBuilder.query(QueryBuilders.matchAllQuery()); 
searchRequest.source(searchSourceBuilder); 
```
#### SearchRequest 有一些可选参数
```java
// 指定查询“posts”索引
SearchRequest searchRequest = new SearchRequest("posts"); 
// 设置路由
searchRequest.routing("routing"); 
// IndicesOptions 设置如何解析未知的索引及通配符表达式如何扩展
searchRequest.indicesOptions(IndicesOptions.lenientExpandOpen()); 
// 设置偏好参数，如设置搜索本地分片的偏好，默认是在分片中随机检索
searchRequest.preference("_local"); 
```
#### 使用SearchSourceBuilder

```java
// 使用默认参数创建 SearchSourceBuilder
SearchSourceBuilder sourceBuilder = new SearchSourceBuilder(); 
// 可以设置任何类型的QueryBuilder查询参数
sourceBuilder.query(QueryBuilders.termQuery("user", "kimchy")); 
// 设置查询的起始位置，默认是0
sourceBuilder.from(0); 
// 设置查询结果的页大小，默认是10
sourceBuilder.size(5); 
// 设置当前查询的超时时间
sourceBuilder.timeout(new TimeValue(60, TimeUnit.SECONDS));
```

- 构建查询参数QueryBuilder

可以使用QueryBuilde构造器创建一个QueryBuilder：
```java
// 构建一个全文检索Match Query, 查询匹配kimchy的user字段
MatchQueryBuilder matchQueryBuilder = new MatchQueryBuilder("user", "kimchy");

// 可以针对创建的QueryBuilder对象设置查询参数
// 开启模糊查询
matchQueryBuilder.fuzziness(Fuzziness.AUTO); 
// 设置查询前缀长度
matchQueryBuilder.prefixLength(3); 
// 设置模糊查询最大扩展
matchQueryBuilder.maxExpansions(10); 
```
可以使用工具类QueryBuilders,采用流式编程的形式构建QueryBuilder  
```java
QueryBuilder matchQueryBuilder = QueryBuilders.matchQuery("user", "kimchy")
                                                .fuzziness(Fuzziness.AUTO)
                                                .prefixLength(3)
                                                .maxExpansions(10);
```
创建好的querubuilder，一定要执行下面这一步
```java
searchSourceBuilder.query(matchQueryBuilder);
```

- 指定排序
>SearchSourceBuilder允许增加一或多个排序参数SortBuilder，有四个具体实现FieldSortBuilder, ScoreSortBuilder, GeoDistanceSortBuilder 和 ScriptSortBuilder。    
```java
// 默认排序。根据_score倒序
sourceBuilder.sort(new ScoreSortBuilder().order(SortOrder.DESC)); 
// 根据_id升序
sourceBuilder.sort(new FieldSortBuilder("id").order(SortOrder.ASC)); 
```

- 使用Source字段过滤

默认情况下，查询请求会返回_source字段的全部内容，但是该行为可以被覆写，比如，你可以完全关掉该字段的索引（不推荐，该行为，原因参考上面的链接）  
```java
sourceBuilder.fetchSource(false);
```
该方法fetchSource也可以接收组通配模式来以更细粒度地方式控制哪些字段被包含或者被排除。

```java
String[] includeFields = new String[] {"title", "innerObject.*"};
String[] excludeFields = new String[] {"user"};
sourceBuilder.fetchSource(includeFields, excludeFields);
```

- 搜索结果高亮（Highlighting）

```java
SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
HighlightBuilder highlightBuilder = new HighlightBuilder(); 
// 设置需要突出的字段
HighlightBuilder.Field highlightTitle = new HighlightBuilder.Field("title"); 
highlightTitle.highlighterType("unified");  
highlightBuilder.field(highlightTitle);  
HighlightBuilder.Field highlightUser = new HighlightBuilder.Field("user");
highlightBuilder.field(highlightUser);
// 设置HighlightBuilder到SearchSourceBuilder
searchSourceBuilder.highlighter(highlightBuilder);
```
例子：  
```java
    // 获取数据实现高亮功能
    public List<Map<String, Object>> searchPageHighlightBuilder(String keyword, int pageNo, int pageSize)
        throws IOException {
        if (pageNo <= 1) {
            pageNo = 1;
        }

        keyword = URLDecoder.decode(keyword, "UTF-8");

        // 条件搜索
        SearchRequest searchRequest = new SearchRequest("jd_goods");
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();

        // 分页
        searchSourceBuilder.from(pageNo);
        searchSourceBuilder.size(pageSize);

        // 精准匹配
        TermQueryBuilder termQueryBuilder = QueryBuilders.termQuery("title", keyword);
        searchSourceBuilder.query(termQueryBuilder);
        searchSourceBuilder.timeout(new TimeValue(60, TimeUnit.SECONDS));

        // 高亮
        HighlightBuilder highlightBuilder = new HighlightBuilder();
        highlightBuilder.field("title");
        highlightBuilder.requireFieldMatch(true);// 多个高亮显示
        highlightBuilder.preTags("<span style='color:red'>");
        highlightBuilder.postTags("</span>");
        searchSourceBuilder.highlighter(highlightBuilder);

        // 执行搜索
        searchRequest.source(searchSourceBuilder);
        SearchResponse search = restHighLevelClient.search(searchRequest, RequestOptions.DEFAULT);

        // 解析结果
        ArrayList<Map<String, Object>> list = new ArrayList<>();
        for (SearchHit documentFields : search.getHits().getHits()) {

            // 解析高亮的字段
            Map<String, HighlightField> highlightFields = documentFields.getHighlightFields();
            HighlightField title = highlightFields.get("title");
            Map<String, Object> sourceAsMap = documentFields.getSourceAsMap();
            if (title != null) {
                Text[] fragments = title.fragments();
                String n_title = "";
                for (Text text : fragments) {
                    n_title += text;
                }
                sourceAsMap.put("title", n_title);
            }
            list.add(sourceAsMap);
        }
        return list;

    }
```

- 请求聚合（Requesting Aggregations）

聚合各公司下员工的平均年龄  
```java
SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
TermsAggregationBuilder aggregation = AggregationBuilders.terms("by_company").field("company.keyword");
aggregation.subAggregation(AggregationBuilders.avg("average_age").field("age"));
searchSourceBuilder.aggregation(aggregation);
```

- 请求建议Requesting Suggestions

在查询请求中可以设置请求Suggestions，通过使用SuggestBuilders辅助类，或者SuggestionBuilder构造器，将其设置到SuggestBuilder，最后将SuggestBuilder设置SearchSourceBuilder中。  

```java
SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
// 为字段user和文本kmichy创建 TermSuggestionBuilder 
SuggestionBuilder termSuggestionBuilder = SuggestBuilders.termSuggestion("user").text("kmichy"); 
SuggestBuilder suggestBuilder = new SuggestBuilder();
// 添加TermSuggestionBuilder到suggestBuilder中，并命名为suggest_user
suggestBuilder.addSuggestion("suggest_user", termSuggestionBuilder); 
searchSourceBuilder.suggest(suggestBuilder);
```

- Profiling Queries和aggregations#
Profile API可以配置某个具体的查询或聚合请求的执行过程。如果想使用该功能，需要将SearchSourceBuilder的开关打开。
```java
SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
searchSourceBuilder.profile(true);
```

#### 执行查询
- 同步查询执行Synchronous execution 
```java
SearchResponse searchResponse = client.search(searchRequest, RequestOptions.DEFAULT);
```
- 异步查询执行Asynchronous execution

```java
client.searchAsync(searchRequest, RequestOptions.DEFAULT, listener); 
```
searchRequest执行完成后会调用ActionListener

异步方式不会阻塞，当该异步调用结果后，ActionListener会被调用，如果执行成功，则onResponse会被调用，如果失败，则onFailure被调用。一个典型的search listener如下：
```java
ActionListener<SearchResponse> listener = new ActionListener<SearchResponse>() {
    @Override
    public void onResponse(SearchResponse searchResponse) {
        
    }

    @Override
    public void onFailure(Exception e) {
        
    }
};
```

#### SearchResponse

>SearchResponse提供了查询执行的细节以及返回的文档结果。
>首先，SearchResponse包括当前查询的执行细节，比如HTTP响应码、执行时间、或者是否超时等：

- 检索结果Retrieving SearchHits  
```java
SearchHits hits = searchResponse.getHits();

TotalHits totalHits = hits.getTotalHits();
// the total number of hits, must be interpreted in the context of totalHits.relation
long numHits = totalHits.value;
// whether the number of hits is accurate (EQUAL_TO) or a lower bound of the total (GREATER_THAN_OR_EQUAL_TO)
TotalHits.Relation relation = totalHits.relation;
float maxScore = hits.getMaxScore();

//SearchHits中的单个结果集可以迭代获取：
SearchHit[] searchHits = hits.getHits();
for (SearchHit hit : searchHits) {
    // do something with the SearchHit
}
```
- SearchHit可以以JSON或MAP形式返回文档的source信息。
- 在Map中，普通的字段以字段名作为key，值为字段值。多值字段是以对象列表形式返回，嵌套对象，则以另一个map的形式返回。需要根据实际情况进行强转：
```java
String sourceAsString = hit.getSourceAsString();
Map<String, Object> sourceAsMap = hit.getSourceAsMap();
String documentTitle = (String) sourceAsMap.get("title");
List<Object> users = (List<Object>) sourceAsMap.get("user");
Map<String, Object> innerObject = (Map<String, Object>) sourceAsMap.get("innerObject");
```

- 获取高亮内容
```java
SearchHits hits = searchResponse.getHits();
for (SearchHit hit : hits.getHits()) {
    Map<String, HighlightField> highlightFields = hit.getHighlightFields();
    // Get the highlighting for the title field
    HighlightField highlight = highlightFields.get("title"); 
    // Get one or many fragments containing the highlighted field content
    Text[] fragments = highlight.fragments();  
    String fragmentString = fragments[0].string();
}
```
- 获取聚合结果
```java
Aggregations aggregations = searchResponse.getAggregations();
// Get the by_company terms aggregation
Terms byCompanyAggregation = aggregations.get("by_company"); 
// Get the buckets that is keyed with Elastic
Bucket elasticBucket = byCompanyAggregation.getBucketByKey("Elastic"); 
// Get the average_age sub-aggregation from that bucket
Avg averageAge = elasticBucket.getAggregations().get("average_age"); 
double avg = averageAge.getValue();
```
对比下面来看
```json
{
  "query": {
    "match": {
      "title": "排骨"
    }
  },
  "aggs": {  //searchResponse.getAggregations()
    "count": { //aggregations.get("by_company")
      "max": { //elasticBucket.getAggregations().get("average_age")
        "field": "views" //double avg = averageAge.getValue();
      }
    }
  }
}
```
也可以以map的形式获取aggregations，key是aggregation名称。这种情况下，aggregation 接口需要显式的强转。
```java
Map<String, Aggregation> aggregationMap = aggregations.getAsMap();
Terms companyAggregation = (Terms) aggregationMap.get("by_company");
```
迭代  
```java
for (Aggregation agg : aggregations) {
    String type = agg.getType();
    if (type.equals(TermsAggregationBuilder.NAME)) {
        Bucket elasticBucket = ((Terms) agg).getBucketByKey("Elastic");
        long numberOfDocs = elasticBucket.getDocCount();
    }
}
```

- 获取建议结果

```java
// Use the Suggest class to access suggestions
Suggest suggest = searchResponse.getSuggest(); 
// Suggestions can be retrieved by name. You need to assign them to the correct type of Suggestion class (here TermSuggestion), otherwise a ClassCastException is thrown
TermSuggestion termSuggestion = suggest.getSuggestion("suggest_user"); 
// Iterate over the suggestion entries
for (TermSuggestion.Entry entry : termSuggestion.getEntries()) { 
    // Iterate over the options in one entry
    for (TermSuggestion.Entry.Option option : entry) { 
        String suggestText = option.getText().string();
    }
}
```

- 获取配置结果

可以使用SearchResponse的getProfileResults()方法获取。返回结果为每个分片包装一个Map，值为ProfileShardResult对象。key是能唯一标识分片的信息。
```java
// Retrieve the Map of ProfileShardResult from the SearchResponse
Map<String, ProfileShardResult> profilingResults = searchResponse.getProfileResults(); 
// Profiling results can be retrieved by shard’s key if the key is known, otherwise it might be simpler to iterate over all the profiling results
for (Map.Entry<String, ProfileShardResult> profilingResult : profilingResults.entrySet()) { 
    // Retrieve the key that identifies which shard the ProfileShardResult belongs to
    String key = profilingResult.getKey(); 
    // Retrieve the ProfileShardResult for the given shard
    ProfileShardResult profileShardResult = profilingResult.getValue(); 
}
```

ProfileShardResult包含一个或多个profile 结果：

```java
// Retrieve the list of QueryProfileShardResult
List<QueryProfileShardResult> queryProfileShardResults =
        profileShardResult.getQueryProfileResults(); 
// Iterate over each QueryProfileShardResult
for (QueryProfileShardResult queryProfileResult : queryProfileShardResults) { 

}
```

每个QueryProfileShardResult 中可以获取ProfileResult对象列表： 

```java
// Iterate over the profile results
for (ProfileResult profileResult : queryProfileResult.getQueryResults()) {
    // Retrieve the name of the Lucene query
    String queryName = profileResult.getQueryName(); 
    // Retrieve the time in millis spent executing the Lucene query
    long queryTimeInMillis = profileResult.getTime(); 
    // Retrieve the profile results for the sub-queries (if any)
    List<ProfileResult> profiledChildren = profileResult.getProfiledChildren(); 
}
```
QueryProfileShardResult也可以获取Lucene collectors的信息：

```java
// Retrieve the profiling result of the Lucene collector
CollectorResult collectorResult = queryProfileResult.getCollectorResult();  
// Retrieve the name of the Lucene collector
String collectorName = collectorResult.getName();  
// Retrieve the time in millis spent executing the Lucene collector
Long collectorTimeInMillis = collectorResult.getTime(); 
// Retrieve the profile results for the sub-collectors (if any)
List<CollectorResult> profiledChildren = collectorResult.getProfiledChildren(); 
```

QueryProfileShardResult可以获取详细的aggregations tree执行信息：

```java
// Retrieve the AggregationProfileShardResult
AggregationProfileShardResult aggsProfileResults =
        profileShardResult.getAggregationProfileResults(); 
// Iterate over the aggregation profile results
for (ProfileResult profileResult : aggsProfileResults.getProfileResults()) { 
    // Retrieve the type of the aggregation (corresponds to Java class used to execute the aggregation)
    String aggName = profileResult.getQueryName(); 
    // Retrieve the time in millis spent executing the Lucene collector
    long aggTimeInMillis = profileResult.getTime(); 
    // Retrieve the profile results for the sub-aggregations (if any)
    List<ProfileResult> profiledChildren = profileResult.getProfiledChildren(); 
}
```