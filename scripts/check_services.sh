#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
MONGO_CLIENT_v2='/home/mongodb/bin/mongo'
MONGO_CLIENT_v3='/home/60000/bin/mongo'


LINUXS='
10.0.0.1
10.0.0.2
10.0.0.10
10.0.0.11
10.0.0.12
10.0.0.13
10.0.0.14
10.0.0.20
10.0.0.30
10.0.0.31
10.0.0.32
10.0.0.40
10.0.0.41
10.0.0.42
10.0.0.50
10.0.0.51
10.0.0.52
10.0.0.200
10.0.0.23
'

HTTPD='
211.152.60.36
211.152.60.33
'

NGINXS='
10.0.0.1
10.0.0.2
10.0.0.10:60081
10.0.0.10:60082
10.0.0.10:60083
10.0.0.11:60081
10.0.0.11:60082
10.0.0.11:60083
10.0.0.12:60081
10.0.0.12:60082
10.0.0.12:60083
10.0.0.13:60081
10.0.0.13:60082
10.0.0.13:60083
10.0.0.14:60081
10.0.0.14:60082
10.0.0.14:60083
10.0.0.14:60084
'

PHPS='
10.0.0.10:60081
10.0.0.10:60082
10.0.0.10:60083
10.0.0.11:60081
10.0.0.11:60082
10.0.0.11:60083
10.0.0.12:60081
10.0.0.12:60082
10.0.0.12:60083
10.0.0.13:60081
10.0.0.13:60082
10.0.0.13:60083
10.0.0.14:60081
10.0.0.14:60082
10.0.0.14:60083
10.0.0.14:60084
'
PY_WX_SRV='
10.0.0.10:60000
10.0.0.11:60000
10.0.0.12:60000
10.0.0.13:60000
10.0.0.14:60000
'
SWCHAT_SRV='
10.0.0.10:9503
10.0.0.11:9503
10.0.0.12:9503
10.0.0.13:9503
10.0.0.14:9503
'

MEMCACHEDS='
10.0.0.1:11211
10.0.0.1:11212
10.0.0.2:11211
10.0.0.2:11212
10.0.0.20:11211
10.0.0.20:11212
'

REDIS='
172.18.1.1:7101
172.18.1.1:7102
172.18.1.1:7103
172.18.1.2:7101
172.18.1.2:7102
172.18.1.2:7103

10.0.0.31:6379
10.0.0.32:6379
'

MONGODBS='
10.0.0.40:40000
10.0.0.41:40000

10.0.0.24:40102


10.0.0.30:60000
10.0.0.31:60000
10.0.0.32:60000

10.0.0.30:57017
10.0.0.31:57017
10.0.0.32:57017

10.0.0.40:60000
10.0.0.41:60000
10.0.0.42:60000

10.0.0.50:60000
10.0.0.51:60000
10.0.0.52:60000

10.0.0.24:60101
10.0.0.24:60102
10.0.0.24:60201
10.0.0.24:60202

10.0.0.200:27017
'

MONGOSES='
10.0.0.30:57017
10.0.0.31:57017
10.0.0.32:57017
'

API_URLS='
http://180.153.17.45:2615/HisComSvr/HsCRMWebSrv.dll/wsdl/IHsCRMWebSrv
'

displayheader() {
	[ -z "$1" ] && return 1
	echo -e "\n"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo -e "$(date)\t${1}\t"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
}

#begin check

funcping() {
	#func ping check
	/usr/bin/func '*' ping
}

load() {
	#check load
	displayheader 'Checking Load'
	for ip in ${LINUXS} ;do
		echo -en "$ip\t"
		if [ "$(whoami)" = 'wanlong' ];then
			ssh $ip 'uptime'|sed 's/^.*average:/load:/'
		else
			su wanlong -c "ssh $ip 'uptime'"|sed 's/^.*average:/load:/'
		fi
	done
}

nginx() {
	#check nginx
	displayheader 'Checking Nginx'
	for ip_port in ${NGINXS} ;do
		echo -en "${ip_port}\t"
		#curl -m 3 http://${ip_port}/NginxStatus 2>/dev/null |grep -e 'Activ' -e 'Writing'|tr -d ' '|tr '\n' '\t '
		curl -m 3 http://${ip_port}/NginxStatus 2>/dev/null |grep -e 'Activ' -e 'Writing'|tr '\n' '\t '
		echo
	done
}
proxy_nolive_upstreams() {
	#check proxy no live upstreams
	displayheader 'Checking Proxy no live upsteams'
	for pxy in proxy01 proxy02 ;do
		func "${pxy}" call command run "grep 'no live upstreams' /usr/local/tengine/logs/error.log \
			| grep -o -i -e 'upstream:.*' \
			| awk -F'/' '{print \$3}' | sort | uniq -c"
	done
}

httpd() {
	#check httpd
	displayheader 'Checking Httpd'
	for ip in ${HTTPD} ;do
		echo -en "$ip\t"
		curl -m 3 http://${ip}/server-status 2>/dev/null |grep -e 'idle workers'
		echo
	done
}

php() {
	#check php-fpm
	displayheader 'Checking PHP-FPM'
	for ip_port in ${PHPS} ;do
		echo -en "${ip_port}\t"
		curl -m 3 http://${ip_port}/status 2>/dev/null |grep -e 'active processes' -e 'idle processes' -e 'slow requests'|tr -d ' '|tr '\n' '\t'
		echo
	done
}

pyweixin() {
	displayheader 'Checking Python-Weixin-Service'
	for ip_port in ${PY_WX_SRV} ;do
		echo -en "${ip_port}\t"
		curl -s -o /dev/null -D - http://${ip_port}|head -n 1
		echo
	done
}

swoolechat() {
	displayheader 'Checking SwooleChat'
	for ip_port in ${SWCHAT_SRV} ;do
		echo -en "${ip_port}\t"
		curl -s -o /dev/null -D - http://${ip_port}|head -n 1
		local ip=${ip_port%:*}
		local port=${ip_port#*:}
		local hostname=$(grep -P "^[ |\t]*${ip}" /etc/hosts|awk '{print $2}')
		func "${hostname}" call command run ". /root/.bashrc ;swoolechat_status ${port}"
		echo
	done
}

check_containers() {
	if [ -z "$1" ];then
		echo usage: $0 http://weshopdemo.umaman.com/default/index/test
		return 1
	else
		url="$1"
	fi
	displayheader '检查所有容器对同一个url的输出是否一致'
	for ip_port in ${PHPS} ;do
		echo -en "${ip_port}\t"
		curl -sx ${ip_port} "$url"
		echo
	done
}

php_terminating() {
	displayheader 'Checking PHP Terminating'
	#func 'app0[1-4]' call command run "grep -e '$(date +%d-%b-%Y).*terminating' /var/log/php-fpm/error.log |wc -l"|sort
	func 'app0[1-5]' call command run \
		'for f in /tmp/icc_appserver_c0*/php-fpm/error.log;do
			count=$(grep -e "$(date +%d-%b-%Y).*terminating" $f|wc -l);
			printf "%-4s%-5s" ${f:19:3} ${count};
		done' \
	|sort
}

php_tooslow() {
	displayheader 'Checking PHP Tooslow'
	#func 'app0[1-4]' call command run "grep -e '$(date +%d-%b-%Y).*executing too slow' /var/log/php-fpm/error.log |wc -l"|sort
	func 'app0[1-5]' call command run \
		'for f in /tmp/icc_appserver_c0*/php-fpm/error.log;do
			count=$(grep -e "$(date +%d-%b-%Y).*executing too slow" $f|wc -l);
			printf "%-4s%-5s" ${f:19:3} ${count};
		done' \
	|sort
}

php_segfault() {
	displayheader 'Checking PHP Segfault'
	func 'app0[1-5]' call command run "grep -P \"$(date '+%b %d').*php-fpm.*(segfault|general protection)\" /var/log/messages|wc -l"|sort
}

full_dropping() {
	func '*' call command run "dmesg|grep ' table full, dropping packet'"
}
	
memcached() {
	#check memcached
	displayheader 'Checking Memcached'
	for ip_port in ${MEMCACHEDS} ;do
		/usr/local/bin/check_memcached -H ${ip_port} -w 500 -c 800 --size-warning 86 --size-critical 90 2>/dev/null \
		| sed -e "s/^.*Time/Time/" -e "s/checked[:|;]/:/g"
	done
}

redis() {
	#check redis
	REDIS_CLI='/home/redis-cluster/bin/redis-cli'
	displayheader 'Checking Redis'
	for ip_port in ${REDIS} ;do
		echo ${ip_port}
		echo info | ${REDIS_CLI} -c -h ${ip_port%%:*} -p ${ip_port##*:} | grep \
		-e used_memory_human \
		-e used_memory_peak_human \
		-e 'db0:keys' \
		-e master_host \
		-e master_port \
		-e slave0
		echo
	done
}
	
gearmand() {
	#check gearmand
	displayheader 'Checking Gearmand'
	#/usr/bin/gearadmin -h 10.0.0.200 -p 4730 --status|sort
	/usr/bin/gearadmin -h 10.0.0.200 -p 4730 --status|sort|grep -v -e '^\.$'|awk '{printf "%-24s %-2s %-2s %-2s %-2s\n",$1,$2,$3,$4,$5}'
}
	
api_urls() {
	#check api_urls
	displayheader 'Checking Thirdpart API URLs'
	for url in ${API_URLS} ;do
		echo "Checking $url"
		/usr/local/bin/curl -m 5 -sD - "$url" |head
		echo
	done
}

mongodb() {
	#check replica-set status
	displayheader 'Checking Replica-set status'
	#for port in 40001 60001 60002;do
	for connstr in 10.0.0.41:40000 10.0.0.42:60000 10.0.0.52:60000;do
		#echo "rs.status()"|mongo 10.0.0.200:${port}|grep -e '"set"' -e '"name"' -e '"stateStr"'|awk -F':' '{print $2}'|tr -d '\n|"'| \
		#sed "s/^ *//;s/,$/\n/"
		if echo $connstr|grep -q '60000';then
			MONGO_CLIENT="$MONGO_CLIENT_v3"
		else
			MONGO_CLIENT="$MONGO_CLIENT_v2"
		fi

		echo "rs.status()"|${MONGO_CLIENT} ${connstr}|awk -F '"' '/"set"|"name"|"stateStr"/{printf "%-s,",$4}END{printf "\n"}'| \
		sed "s/,/:: /;s/Y,/Y; /g;s/..$/\./;s/,/:/g"

		echo 'db.printReplicationInfo()'|${MONGO_CLIENT} ${connstr}|grep -e '^configured oplog size:' -e '^log length start to end:' \
		-e '^oplog first event time:' -e '^oplog last event time:'

		#echo 'db.printSlaveReplicationInfo()'|${MONGO_CLIENT_v2} ${connstr} \
		#|awk '/source:|syncedTo:|secs ago/{gsub("[ |\t]{1,}"," ");gsub("source:","\n");printf "%-s",$0} END{printf "\n\n"}'
		echo 'db.printSlaveReplicationInfo()'|${MONGO_CLIENT_v3} ${connstr} \
		|grep -v -e '^MongoDB shell version:' -e '^connecting to:' -e '^bye$' |tr -d '\n'|sed "s/source: /\n/g";echo;echo
	done

	#check mongodb
	displayheader 'Checking Mongodb'
	for ip_port in ${MONGODBS} ;do
		echo 'db.currentOp()' | /home/mongodb/bin/mongo ${ip_port} &>/dev/null && connret='OK' || connret='Fail'
		if [ "$connret" = 'OK' ];then
			CURRENT_CONN=$(echo 'db.serverStatus().connections'|/home/mongodb/bin/mongo ${ip_port}|tr '\n' ' '|grep -o -e 'current.*[0-9],' \
					|awk '{printf "%-6s %-6s",$3,$6}'|tr -d ',')
			Lock_COUNT=$(echo 'db.currentOp()' | /home/mongodb/bin/mongo ${ip_port} |grep -e 'waitingForLock.*true' 2>/dev/null |/usr/bin/wc -l)
		else
			CURRENT_CONN='n/a'
			Lock_COUNT='n/a'
		fi
		#echo -e "Connect to ${ip_port}: ${connret};\tcurrent connection: ${CURRENT_CONN}\twaitingForLock: ${Lock_COUNT}"
		printf "Connect to %-16s: %-4s    current connection: %-11s    waitingForLock: %-4s\n" ${ip_port} ${connret} "${CURRENT_CONN}" ${Lock_COUNT}
	done
}

mongos() {
	#check mongos
	displayheader 'Checking MongoS'
	for ip_port in ${MONGOSES} ;do
		echo 'db.currentOp()' | /home/mongodb/bin/mongo ${ip_port} &>/dev/null && connret='OK' || connret='Fail'
		if [ "$connret" = 'OK' ];then
			CURRENT_CONN=$(echo 'db.serverStatus().connections'|/home/mongodb/bin/mongo ${ip_port}|tr '\n' ' '|grep -o -e 'current.*[0-9],' \
					|awk '{printf "%-6s %-6s",$3,$6}'|tr -d ',')
			Lock_COUNT=$(echo 'db.currentOp()' | /home/mongodb/bin/mongo ${ip_port} |grep -e 'waitingForLock.*true' 2>/dev/null |/usr/bin/wc -l)
		else
			CURRENT_CONN='n/a'
			Lock_COUNT='n/a'
		fi
		#echo -e "Connect to ${ip_port}: ${connret};\tcurrent connection: ${CURRENT_CONN}\twaitingForLock: ${Lock_COUNT}"
		printf "Connect to %-16s: %-4s    current connection: %-11s    waitingForLock: %-4s\n" ${ip_port} ${connret} "${CURRENT_CONN}" ${Lock_COUNT}
	done
}

mongo_configdb_differ() {
	displayheader 'Checking ConfigDB differ'
	func 'mongodbc*' call command run 'grep -i differ /home/60000/log/mongos.log|wc -l'
}

mongo_slow_query_of_master(){
	# counting slow query and average qtime of master
	displayheader 'Slow Query of Master'
	grep -hoe 'idata.*ms$' /tmp/server_log_dir/mongodbp?d3/mongo/mongod.log | grep -v -e 'oplog:' \
	| awk -F' |"' '{sub(/ms$/,"",$NF);ary1[$1] += 1;ary2[$1] += $NF}END{for(c in ary1) printf "%45-s %8d %8.0f\n",c,ary1[c],ary2[c]/ary1[c]}' \
	| sort -k2,3nr | head -n 10

	# 查看mongod日志中最耗时的请求
	#awk '/ms$/{sub(/ms$/,"",$NF);if ($NF>110 && $NF<30000) {print $NF,$0}}' /ssd_volume/60000/log/mongod.log|sort -k1,1nr|less
}

get_collection_info() {
	# 查询集合信息
	read -p "Pls input collection name: " cn
		local MONGO="/home/60000/bin/mongo"
		local MONGOS_IP='10.0.0.30'
		local MONGOS_PORT='57017'
		local DB='ICCv1'
		local COLLECTION_NAME="$cn"
		source sc_mongodb_functions.sh
		get_collection_info
}

if [ -z "$1" ] ;then
	funcping
	load
	nginx
	php
	swoolechat
	httpd
	memcached
	redis
	gearmand
	mongodb
	mongos
	mongo_configdb_differ
	mongo_slow_query_of_master
elif [ "$1" = 'web' -o "$1" = "nginx_php" ];then
	nginx
	php
	pyweixin
	swoolechat
	proxy_nolive_upstreams
elif [ "$1" = 'sw' -o "$1" = "swoolechat" ];then
	swoolechat
elif [ "$1" = 'php' -o "$1" = "php_stat" ];then
	php_terminating
	php_tooslow
	php_segfault
elif [ "$1" = 'load' -o "$1" = "system_load" ];then
	load
elif [ "$1" = 'db' -o "$1" = 'mongodb' ];then
	mongodb
	mongos
	mongo_configdb_differ
	mongo_slow_query_of_master
elif [ "$1" = 'slow' ];then
	mongo_slow_query_of_master
elif [ "$1" = 'mc' ];then
	memcached
elif [ "$1" = 'gm' ];then
	gearmand
else
	grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{" $0 && $1 $2 $3
	grep -q -P -e "^${2}[ |\t]?\(\)[ |\t]?\{" $0 && $2
	grep -q -P -e "^${3}[ |\t]?\(\)[ |\t]?\{" $0 && $3
fi

echo -e "\n\n"
