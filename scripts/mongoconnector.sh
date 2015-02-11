#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/home/mongodb/bin"

#variables
MONGOS='10.0.0.30:27017'
DB='mctest'
COLLECTION_1='th_blog'
ES='10.0.0.30:9200'
DOC_MANAGERS_DIR='/usr/lib/python2.6/site-packages/mongo_connector/doc_managers/'

# testing
# mongo-connector -h

# echo "db.th_blog.findOne()"|mongo ${MONGOS}/${DB}
# {
#         "_id" : ObjectId("54811b01b1752f335e8b4567"),
#         "bid" : "99",
#         "uid" : "14",
#         "top" : "0",
#         "type" : "1",
#         "tag" : "学习周报,Etrade,E",
#         "title" : "电商联手比价网站打破“价格铁幕”",
#         "body" : "在过去的流通领域，由于信息不透明和商品流通区域存在差异性，消费者难以透明地比价，于是就有了“价格铁幕”的说法。然而，随着电商的兴起，零售行业正经历着一场前所未有的转变。<p>　　资料显示，美国网上零售额的35%均来自比较购物网站，68%的用户习惯在购物之前，事先使用比较购物网站进行查询，这种趋势逐渐扩散到了国内。去年，以一淘网为先驱，国内整个<a href=\"http://search.iresearch.cn/36/\" target=\"_blank\" class=\"link_black\">购物搜索</a>行业开始发力，一淘自身的月度复合增长率达到了44.7%。显然，比价已成大势所趋。由于该类购物搜索具备价格比较以及实时监测的敏感功能，曾遭遇到一些电商的抵制。以京东商城为代表的一些电商，曾宣布屏蔽“一淘蜘蛛”对其评价以及商品信息的抓取。然而，凡客、亚马逊等却表达了另一种截然不同的看法：购物搜索与B2C之间的关系是合作，而非竞争。当然，这其中也包括主打家电<a href=\"http://s.iresearch.cn/search.aspx?k=%E7%BD%91%E8%B4%AD\" target=\"_blank\" class=\"link_black\">网购</a>的库巴网。“消费者拥有获得价格全面信息的权利。”库巴网CEO王治全表示。在今年，他将与一淘网展开流量、商品、运营等方面的合作。这无疑会在<a href=\"http://ec.iresearch.cn/\" target=\"_blank\" class=\"link_black\">电子商务</a>圈内激起新一轮的波澜：消费者一旦能够货比多家，历来已久的“价格铁幕”将可能被打破。</p><p>　　波澜过后，首当其冲的便可能是传统实体店。事实上，在<a href=\"http://s.iresearch.cn/search.aspx?k=%E7%BD%91%E7%BB%9C%E8%B4%AD%E7%89%A9\" target=\"_blank\" class=\"link_black\">网络购物</a>被消费者认可之初，传统实体店的“价格铁幕”就被处于急速扩张的电商打得七零八落。随着电商的“圈地”运动逐渐成规模，新的“价格铁幕”又会悄然形成，控制权则完全属于电商。电商也有着传统实体店的“贪婪”。“一旦某个或几个B2C电商以相对的低价起家，在拥有较大的市场份额后，它们同样会有调整价格的冲动，这同样不利于公平消费。”王治全认为。因此，商品信息透明化是解决“价格铁幕”的唯一选择。</p><p>　　对此，易观国际高级分析师陈寿送认为，“价格铁幕”在行业内是个普遍问题，但在电商们的推动下，“铁幕”终难持久。传统零售商利用信息不透明和消费者的依赖性而操纵价格，甚至是随意涨价，但是，随之而来的抗争也从未断绝过。因为对于消费者而言，自主比价早成了茶余饭后的自然习惯，而恰好<a href=\"http://s.iresearch.cn/search.aspx?k=%E4%BA%92%E8%81%94%E7%BD%91\" target=\"_blank\" class=\"link_black\">互联网</a>提供了这样一个平台。</p><p>　　网购比价工具动了一些人的“奶酪”，称其挑起了“价格战”，让商家毫无利润可言，其实，这是一种错觉。业内人士分析认为，商品价格透明未来将会一往无前，当比价成为一种风尚时，这会倒逼电商及其供应商做出差异化、增值化的措施，无论对行业还是消费者，都是百利无害的。王治全认为，比价的最大意义其实并不在于让消费者买到价格最低的那款产品，而是通过比价，把价格差异过大的商品淘汰。“同样一款产品，不能因为销售平台不同就产生20%以上的价格差异，这对消费者不公平。”</p><br />",
#         "open" : "1",
#         "hitcount" : "187",
#         "feedcount" : "0",
#         "replaycount" : "0",
#         "votecount" : "0",
#         "noreply" : "0",
#         "time" : "1330708997",
#         "ouid" : "99",
#         "score" : "0",
#         "isfeed" : "0",
#         "isscore" : "0",
#         "notic" : ""
# }
# echo "db.th_blog.count()"|mongo ${MONGOS}/${DB}
# 1000



# $ ls /usr/lib/python2.6/site-packages/mongo_connector/doc_managers/
# doc_manager_simulator.py   elastic_doc_manager.py   formatters.py   __init__.py   mongo_doc_manager.py   schema.xml           solr_doc_manager.pyc
# doc_manager_simulator.pyc  elastic_doc_manager.pyc  formatters.pyc  __init__.pyc  mongo_doc_manager.pyc  solr_doc_manager.py

# DOCs
# https://github.com/10gen-labs/mongo-connector/wiki
# http://www.csdn.net/article/2014-09-02/2821485-how-to-perform-fuzzy-matching-with-mongo-connector
# 若没有一个类似Mongo Connector的工具，我们不得不使用一个类似mongoexport工具去定期地从MongoDB转储数据至JSON，然后再上传这些数据至一个闲置的Elasticsearch中，导致我们空闲时无法提前删除文件。这大概是一件很麻烦的事，同时失去了Elasticsearch的近实时查询能力。

# mongo ---> ES
target=${ES}
doc_manager="${DOC_MANAGERS_DIR}elastic_doc_manager.py"
# mongo ---> mongo
#target='127.0.0.1:27017'
#doc_manager="${DOC_MANAGERS_DIR}mongo_doc_manager.py"
#-g test.${COLLECTION_1} \

mongo-connector \
-m ${MONGOS} \
-t ${target} \
-n ${DB}.${COLLECTION_1} \
--fields _id,bid,uid,tag,title,body,hitcount \
-d ${doc_manager}


#
# $ ./mongoconnector.sh 
# /usr/bin/python /usr/bin/mongo-connector -m 10.0.0.30:27017 -t 127.0.0.1:27017 -n mctest.th_blog -g test.th_blog --fields _id,bid,uid,tag,title,body,hitcount -d /usr/lib/python2.6/site-packages/mongo_connector/doc_managers/mongo_doc_manager.py
# 2014-12-05 11:51:08,594 - INFO - Beginning Mongo Connector
# 2014-12-05 11:51:10,126 - INFO - MongoConnector: Can't find config.txt, attempting to create an empty progress log
# 2014-12-05 11:51:10,164 - INFO - MongoConnector: Empty oplog progress file.
# 2014-12-05 11:51:10,404 - INFO - OplogThread: Initializing oplog thread
# 2014-12-05 11:51:10,406 - INFO - MongoConnector: Starting connection thread MongoClient([u'10.0.0.41:40000', u'10.0.0.40:40000', u'10.0.0.42:40000'])
# 2014-12-05 11:51:10,409 - INFO - OplogThread: Initializing oplog thread
# 2014-12-05 11:51:10,430 - INFO - MongoConnector: Starting connection thread MongoClient([u'10.0.0.52:40000', u'10.0.0.50:40000', u'10.0.0.51:40000'])
# 2014-12-05 12:16:20,385 - INFO - OplogThread: dumping collection mctest.th_blog
# 2014-12-05 13:47:11,271 - INFO - Caught keyboard interrupt, exiting!
# 2014-12-05 13:47:11,279 - INFO - Mongo DocManager Stopped: If you will not target this system again with mongo-connector then please drop the database __mongo_connector in order to return resources to the OS.
# 2014-12-05 13:47:11,692 - INFO - MongoConnector: Stopping all OplogThreads
# 
# #test 
# shard2:PRIMARY> db.th_blog.find({'bid':'99'});
# shard2:PRIMARY> db.th_blog.count()
# 2999

# $ cat config.txt 
# ["Collection(Database(MongoClient([u'10.0.0.52:40000', u'10.0.0.50:40000', u'10.0.0.51:40000']), u'local'), u'oplog.rs')", 6089225888614842369][wanlong@cactifans PKG]$ 


# 删掉一条记录
# mongos> db.th_blog.remove({'bid':'99'})
# mongo connector 立刻输出日志
# 2014-12-05 14:52:49,991 - INFO - DELETE http://10.0.0.30:9200/mctest.th_blog/string/54814fecb1752fbd6f8b4567?refresh=false [status:200 request:0.322s]
# 2014-12-05 14:52:49,994 - INFO - DELETE http://10.0.0.30:9200/mongodb_meta/mongodb_meta/54814fecb1752fbd6f8b4567?refresh=false [status:200 request:0.003s]



# curl -XPOST 'http://10.0.0.30:9200/mctest.th_blog/_search' -d'{
#   "query": {
#     "match": {
#       "body": {
#         "query": "zabbix",
#         "fuzziness": 2,
#         "prefix_length": 1
#       }
#     }
#   }
# }'
# 
# {"took":47,"timed_out":false,"_shards":{"total":5,"successful":5,"failed":0},"hits":{"total":0,"max_score":null,"hits":[]}}
~                                                                                                                                                              
~                                                                                                                                                              
~           








