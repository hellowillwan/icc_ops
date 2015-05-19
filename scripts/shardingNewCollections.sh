#!/bin/sh
#
# 对 ICCv1 新增的集合 进行分片
# 片键 {"_id":"hashed"}
# 成功就记录到已分片列表,失败这发邮件报警
#


MONGO_CLIENT='/home/60000/bin/mongo'
MONGOS='10.0.0.30:57017'
DB='ICCv1'
SHARDED_COLL_LIST_FILE='/tmp/sharded_coll_list'

# 集合列表
COLLECTION_LIST=$(echo 'show tables;'| ${MONGO_CLIENT} ${MONGOS}/${DB})

#n=0
# 对每一个集合进行检查
for collection in ${COLLECTION_LIST};do
	# 检查集合是否已经在 已分片集合 列表
	if grep -q -e "^${collection}$" ${SHARDED_COLL_LIST_FILE} ;then
		#echo "sharded coll ${collection} found, bypass."
		continue
	fi

	# 仅针对 idatabase_collection_xxx 集合进行确认分片情况
	if echo ${collection} | grep -q -P -e '^idatabase_collection_' ;then
		#echo "++++${collection}++++"
		# 确认集合是否分片
		query_str="db.getCollection('${collection}').stats()"
		if_sharded=$(echo "${query_str}"| ${MONGO_CLIENT} ${MONGOS}/${DB}|grep '"sharded"' |sed "s/[ |\t]//g"|awk -F':|,' '{print $2}')
		if [ "${if_sharded}" = 'true' ];then
			# 已经分片: 记录到 已分片集合 列表
			echo "${collection}" >> ${SHARDED_COLL_LIST_FILE}
			echo "sharded coll ${collection} found, loged."
		else
			# 未分片: 建立 _id:hash 索引;进行分片操作;添加到 已分片集合 列表
			#
			# 语句
			#printjson(db.getCollection('idatabase_collection_55306a64b1752fa45f8b5446').createIndex({_id:hashed}));
			#printjson(sh.shardCollection('ICCv1.idatabase_collection_55306a64b1752fa45f8b5446',{ _id : hashed }));
			create_hash_index_str="printjson(db.getCollection('${collection}').createIndex({\"_id\":\"hashed\"}));"
			sharding_str="printjson(sh.shardCollection('ICCv1.${collection}',{ \"_id\" : \"hashed\" }));"
			# 输出语句到标准输出
			echo "${create_hash_index_str}"
			echo "${sharding_str}"

			# 执行并保留 返回信息
			create_hash_index_result=$(echo "${create_hash_index_str}" | ${MONGO_CLIENT} ${MONGOS}/${DB})
			sharding_result=$(echo "${sharding_str}" | ${MONGO_CLIENT} ${MONGOS}/${DB})
			# 输出返回信息到标准输出
			echo "${create_hash_index_result}"
			echo "${sharding_result}"

			# 从 返回信息 获得执行结果:是否成功
			#echo "create_hash_index_result:"
			#echo "${create_hash_index_result}"|grep -i -e '"ok"' | sed "s/[ |\t]//g"|awk -F':|,' '{print $2}'|sort|uniq
			#echo "sharding_result:"
			#echo "${sharding_result}"|grep -i -e '"ok"' | sed "s/[ |\t]//g"|awk -F':|,' '{print $2}'|sort|uniq
			if echo "${sharding_result}"|grep -A 1 '"collectionsharded"'|grep -q -e '"ok" : 1';then
				#分片成功: 记录到 已分片集合 列表
				echo "${collection}" >> ${SHARDED_COLL_LIST_FILE}
			else
				#发邮件报警
				to_list='willwan@icatholic.net.cn'
				subject="集合 ${collection} 分片 失败"
				content="建索引的语句:\n${create_hash_index_str}\n建索引语句的返回信息:\n${create_hash_index_result}"
				content="${content}\n分片的语句:\n${sharding_str}\n分片语句的返回信息:\n${sharding_result}\n"
				/usr/local/sbin/sendemail.py -s smtp.icatholic.net.cn -f system.monitor@icatholic.net.cn \
				-u system.monitor@icatholic.net.cn -p abc123 \
				-t "$to_list" \
				-S "$subject" \
				-m "$content"

			fi

			#n=$(($n+1))
		fi

		#n=$(($n+1))
	fi
	#[ $n -ge 1 ] && exit
done


# 检查 已分片集合 列表 里的集合 是否已经分片
check_coll_sharding() {
	cat /tmp/sharded_coll_list |while read coll_name ;do
		#获取集合分片信息
		coll_stats=$(echo "db.getCollection('${coll_name}').stats()" | /home/60000/bin/mongo 10.0.0.30:57017/ICCv1)
		echo "${coll_stats}"	# 统计检查结果 grep '"sharded"' check_shard_result.log |sort |uniq -c
		continue
		if_sharded=$(echo "${coll_stats}"|grep '"sharded"' |sed "s/[ |\t]//g"|awk -F':|,' '{print $2}')
	
		if [ "${if_sharded}" = 'true' ];then
			echo "$coll_name shared."
		else
			echo "$coll_name not shared."	# grep not check_shard_result.log
		fi
	done
}


