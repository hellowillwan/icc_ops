#!/bin/sh

# kill 掉 ES & logstash index
/etc/init.d/elasticsearch stop
/etc/init.d/elasticsearch stop
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9


# 由于内存不够大,只保留最近7天的数据在ES里,7天前的数据移动到备份目录

for index_dir in $(ls /home/elasticsearch/es_of_icc/nodes/0/indices/ -alht|grep 'logstash-'|awk 'NR >9{print $NF}');do
	if [ -d /home/elasticsearch/es_of_icc/nodes/0/indices/${index_dir} ];then
		mv /home/elasticsearch/es_of_icc/nodes/0/indices/${index_dir} /home/elasticsearch_backup/es_of_icc/nodes/0/indices/
	fi
done


# 重启ES & logstash index

/etc/init.d/elasticsearch restart
sleep 60
nohup /usr/local/logstash-2.3.3/bin/logstash -f /usr/local/logstash-2.3.3/index.conf &> /usr/local/logstash-2.3.3/index.log &
#nohup /usr/local/logstash-2.3.3/bin/logstash -f /usr/local/logstash-2.3.3/index.conf &> /dev/null &
