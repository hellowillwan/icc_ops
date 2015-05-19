#!/bin/sh
# kill ops which match some conditions
# shard2:PRIMARY> db.currentOp({'ns':'local.oplog.rs','secs_running':{$gt:10}})
# {
#         "inprog" : [
#                 {
#                         "opid" : 304335043,
#                         "active" : true,
#                         "secs_running" : 272,
#                         "op" : "query",
#                         "ns" : "local.oplog.rs",
#                         "query" : {
#                                 "ns" : /th_blog/
#                         },
#                         "client" : "10.0.0.200:62038",
#                         "desc" : "conn3841885",
#                         "threadId" : "0x7f55e55fa700",
#                         "connectionId" : 3841885,
#                         "locks" : {
#                                 "^" : "r",
#                                 "^local" : "R"
#                         },
#                         "waitingForLock" : false,
#                         "numYields" : 520,
#                         "lockStats" : {
#                                 "timeLockedMicros" : {
#                                         "r" : NumberLong(542981247),
#                                         "w" : NumberLong(0)
#                                 },
#                                 "timeAcquiringMicros" : {
#                                         "r" : NumberLong(271872534),
#                                         "w" : NumberLong(0)
#                                 }
#                         }
#                 }
#         ]
# }
# 
# shard2:PRIMARY> db.killOp(304335043);
# { "info" : "attempting to kill op" }








#
MONGOS='
10.0.0.30
10.0.0.31
10.0.0.32
'
MONGO='/home/mongodb/bin/mongo'

get_mongo_currentops() {
	if [ -z "$2" ];then
		echo "port parameter missing"
		return 1;
	else
		PORT="$1"
		DB="$2"
	fi

	for IP in ${MONGOS} ;do
		echo "db.currentOp({'ns' : /^${DB}./})" | $MONGO ${IP}:${PORT}
	done
}

kill_mongo_op () {
	if [ -z "$4" ];then
		echo "Usage: $0 IP PORT COLLECTION"
		return 1;
	else
		IP="$1"
		PORT="$2"
		DB="$3"
		COLLECTION="$4"
	fi

	#取到 操作指定集合的查询的opid,逐一kill掉.
	#或许 可 以集合名称作为查询条件,复合其他条件比如查询语句类型,查询语句执行时间!!!
	for opid in $( echo "db.currentOp({'ns' : /^${DB}./})" | $MONGO ${IP}:${PORT} \
			|grep -i -e  '"opid"' -e '"ns"' \
			|grep -B 1 ${COLLECTION} \
			|grep -e '"opid"'|awk -F'"' '{print $4}')
	do
		#echo "db.killOp('$opid')\" | $MONGO ${IP}:${PORT} "
		echo "db.killOp('$opid')" | $MONGO ${IP}:${PORT} 
	done
}

kill_mongo_op_2 () {
	#这个函数用来放在crontab周期性运行,杀掉耗时大于1小时的操作
	#PORT=57017
	PORT=$1
	#DB='ICCv1'
	DB=$2
	if [ "$3" -gt 10 ];then
		SECS_RUNNING="$3"
	else
		SECS_RUNNING=3600
	fi
	
	for IP in ${MONGOS} ;do
		#
		#查询每一个 MongoS 实例里的 Op
		#查询条件:
		#	ns		库，集合，目前只匹配库名 $DB
		# 	secs_running	执行时间 $SECS_RUNNING
		#
		#记录并杀掉符合条件的 Op
		#
		for opid in $( echo "db.currentOp({'ns' : /^${DB}./ , 'secs_running' : { '\$gt' : ${SECS_RUNNING} }})" | $MONGO ${IP}:${PORT} \
				| grep -v -e 'MongoDB shell version:' -e 'connecting to:' -e '^bye$' \
				| grep -v -e '{ "inprog" : \[ \] }' \
				| tee -a /var/log/killop.log \
				| grep -e '"opid"'|awk -F'"' '{print $4}')
		do
			#记录
			#echo "将要杀掉的Op："
			#下面这个查询,按opid竟然取不到Op信息
			#echo "db.currentOp({'opid' : '${opid}'})" | $MONGO ${IP}:${PORT} | grep -v -e 'MongoDB shell version:' -e 'connecting to:' -e '^bye$'
			#杀掉
			#echo "db.killOp('$opid')\" | $MONGO ${IP}:${PORT} "
			echo "db.killOp('$opid')" | $MONGO ${IP}:${PORT} |grep -v -e 'MongoDB shell version:' -e 'connecting to:' -e '^bye$'
			#结果
			if [ $? -eq 0 ];then
				echo "killOp done."
			else
				echo "killOp fail."
			fi
			#记录kill操作的时间点
			date
		done
		echo
	done
}






#main
PORT=57017
#PORT=27017
DB='ICCv1'
#DB='umav3'

if [ -z "$1" ];then
	#show all ops of the cluster
	#get_mongo_currentops ${PORT} ${DB}
	echo "show all ops of the cluster ${PORT} ${DB} :"
	get_mongo_currentops ${PORT} ${DB} |grep '"ns"'|awk -F '"' '{print $4}'|sort|uniq -c|sort -k1,1nr|head -n 50
else
	if [ "$1" = 'kill_mongo_op_2' ];then
		$1 27017 umav3 3600
		$1 57017 ICCv1 3600
		$1 57017 mapreduce 3600
	else
		COLLECTION="$1"
		read -p "Are you sure to kill all the queries to collection ${COLLECTION} ? (y/n)" answer
		if [ "$answer" = 'y' ];then
			for IP in ${MONGOS} ;do
				kill_mongo_op $IP $PORT $DB $COLLECTION
			done
		else
			echo 'nothing done.';
		fi
	fi
fi

