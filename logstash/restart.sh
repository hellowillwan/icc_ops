#!/bin/bash
#
#
# 由于内存不够大,只保留最近7天的数据在ES里,7天前的数据移动到备份目录

purgeIndex {
	# elasticsearch 5.x 版本 index 目录名改为 uuid 了
	#for index_dir in $(ls /home/elasticsearch/es_of_icc/nodes/0/indices/ -alht|grep 'logstash-'|awk 'NR >9{print $NF}');do
	#	if [ -d /home/elasticsearch/es_of_icc/nodes/0/indices/${index_dir} ];then
	#		mv /home/elasticsearch/es_of_icc/nodes/0/indices/${index_dir} /home/elasticsearch_backup/es_of_icc/nodes/0/indices/
	#	fi
	#done
	
	local index_dir_root='/home/elasticsearch/es_of_icc/nodes/0/indices/'
	#for index_dir_name in $(curl -s 'http://10.0.0.23:9200/_cat/indices?v'|awk '$3 ~ /2016/{print $4}');do
	#for index_dir_name in `awk '$1 ~ /^red/{print $4}' t1.txt`;do
	for index_dir_name in $(
		/usr/bin/curl -s 'http://10.0.0.23:9200/_cat/indices?v' | awk '/logstash-20/{
			sub("logstash-","",$3);
			gsub("\\."," ",$3);
			ts=mktime($3" 00 00 00");
			if ((systime()-ts)/86400 > 60) {print $4}
		}'
	);do
		if test -d  "${index_dir_root}${index_dir_name}";then
			echo "${index_dir_root}${index_dir_name} exist"
			#rm -rf "${index_dir_root}${index_dir_name}"
		else
			echo "${index_dir_root}${index_dir_name} not exist"
		fi
	done
}
purgeIndex


# kill 掉 ES & logstash index

/etc/init.d/elasticsearch stop
/etc/init.d/elasticsearch stop
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9
ps -ef|grep java|grep -v grep|awk '{print $2}'|xargs kill -9


# 重启ES & logstash index

/etc/init.d/elasticsearch restart
sleep 60
nohup /usr/local/logstash-5.0.2/bin/logstash -f /usr/local/logstash-5.0.2/index.conf &> /usr/local/logstash-5.0.2/index.log &

