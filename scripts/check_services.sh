#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
alias mongo='/home/mongodb/bin/mongo'


LINUXS='
10.0.0.1
10.0.0.2
10.0.0.10
10.0.0.11
10.0.0.12
10.0.0.13
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
10.0.0.10
10.0.0.11
10.0.0.12
10.0.0.13
'

PHPS='
10.0.0.10
10.0.0.11
10.0.0.12
10.0.0.13
'

MEMCACHEDS='
10.0.0.1:11211
10.0.0.1:11212
10.0.0.2:11211
10.0.0.2:11212
10.0.0.20:11211
10.0.0.20:11212
'

MONGODBS='
10.0.0.30:40000
10.0.0.31:40000
10.0.0.32:40000

10.0.0.30:27017
10.0.0.31:27017
10.0.0.32:27017

10.0.0.40:40000
10.0.0.41:40000
10.0.0.42:40000

10.0.0.50:40000
10.0.0.51:40000
10.0.0.52:40000

10.0.0.41:40001
10.0.0.41:40002
10.0.0.51:40001
10.0.0.51:40002

10.0.0.30:50000
10.0.0.31:50000
10.0.0.32:50000

10.0.0.30:57017
10.0.0.31:57017
10.0.0.32:57017

10.0.0.40:50000
10.0.0.41:50000
10.0.0.42:50000

10.0.0.50:50000
10.0.0.51:50000
10.0.0.52:50000

10.0.0.41:50001
10.0.0.41:50002
10.0.0.51:50001
10.0.0.51:50002

10.0.0.200:27017
'

MONGOSES='
10.0.0.30:27017
10.0.0.31:27017
10.0.0.32:27017

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

funcping () {
	#func ping check
	/usr/bin/func '*' ping
}

load () {
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

nginx () {
	#check nginx
	displayheader 'Checking Nginx'
	for ip in ${NGINXS} ;do
		echo -en "$ip\t"
		#curl -m 3 http://${ip}/NginxStatus 2>/dev/null |grep -e 'Activ' -e 'Writing'|tr -d ' '|tr '\n' '\t '
		curl -m 3 http://${ip}/NginxStatus 2>/dev/null |grep -e 'Activ' -e 'Writing'|tr '\n' '\t '
		echo
	done
}

httpd () {
	#check httpd
	displayheader 'Checking Httpd'
	for ip in ${HTTPD} ;do
		echo -en "$ip\t"
		curl -m 3 http://${ip}/server-status 2>/dev/null |grep -e 'idle workers'
		echo
	done
}

php () {
	#check php-fpm
	displayheader 'Checking PHP-FPM'
	for ip in ${PHPS} ;do
		echo -en "$ip\t"
		curl -m 3 http://${ip}/status 2>/dev/null |grep -e 'active processes' -e 'idle processes' -e 'slow requests'|tr -d ' '|tr '\n' '\t'
		echo
	done
}

php_terminating () {
	displayheader 'Checking PHP Terminating'
	func 'app0[1-4]' call command run "grep -e '$(date +%d-%b-%Y).*terminating' /var/log/php-fpm/error.log |wc -l"|sort
}

php_tooslow () {
	displayheader 'Checking PHP Tooslow'
	func 'app0[1-4]' call command run "grep -e '$(date +%d-%b-%Y).*executing too slow' /var/log/php-fpm/error.log |wc -l"|sort
}

php_segfault () {
	displayheader 'Checking PHP Segfault'
	func 'app0[1-4]' call command run "grep -P \"$(date '+%b %d').*php-fpm.*(segfault|general protection)\" /var/log/messages|wc -l"|sort
}

full_dropping () {
	func '*' call command run "dmesg|grep ' table full, dropping packet'"
}
	
memcached () {
	#check memcached
	displayheader 'Checking Memcached'
	for ip_port in ${MEMCACHEDS} ;do
		/usr/local/bin/check_memcached -H ${ip_port} -w 500 -c 800 --size-warning 86 --size-critical 90 2>/dev/null \
		| sed -e "s/^.*Time/Time/" -e "s/checked[:|;]/:/g"
	done
}
	
gearmand () {
	#check gearmand
	displayheader 'Checking Gearmand'
	#/usr/bin/gearadmin -h 10.0.0.200 -p 4730 --status|sort
	/usr/bin/gearadmin -h 10.0.0.200 -p 4730 --status|sort|grep -v -e '^\.$'|awk '{printf "%-24s %-2s %-2s %-2s %-2s\n",$1,$2,$3,$4,$5}'
}
	
api_urls () {
	#check api_urls
	displayheader 'Checking Thirdpart API URLs'
	for url in ${API_URLS} ;do
		echo "Checking $url"
		/usr/local/bin/curl -m 5 -sD - "$url" |head
		echo
	done
}
mongodb () {	
	#check replica-set status
	displayheader 'Checking Replica-set status'
	#for port in 40001 40002 50001 50002;do
	for connstr in 10.0.0.40:40000 10.0.0.50:40000 10.0.0.42:50000 10.0.0.52:50000;do
		#echo "rs.status()"|mongo 10.0.0.200:${port}|grep -e '"set"' -e '"name"' -e '"stateStr"'|awk -F':' '{print $2}'|tr -d '\n|"'| \
		#sed "s/^ *//;s/,$/\n/"

		echo "rs.status()"|mongo ${connstr}|awk -F '"' '/"set"|"name"|"stateStr"/{printf "%-s,",$4}END{printf "\n"}'| \
		sed "s/,/:: /;s/Y,/Y; /g;s/..$/\./;s/,/:/g"

		echo 'db.printReplicationInfo()'|mongo ${connstr}|grep -e '^configured oplog size:' -e '^log length start to end:' \
		-e '^oplog first event time:' -e '^oplog last event time:'

		echo 'db.printSlaveReplicationInfo()'|mongo ${connstr} \
		|awk '/source:|syncedTo:|secs ago/{gsub("[ |\t]{1,}"," ");gsub("source:","\n");printf "%-s",$0} END{printf "\n\n"}'
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

if [ -z "$1" ] ;then
	funcping
	load
	nginx
	php
	httpd
	memcached
	gearmand
	mongodb
elif [ "$1" = 'web' -o "$1" = "nginx_php" ];then
	nginx
	php
elif [ "$1" = 'php' -o "$1" = "php_stat" ];then
	php_terminating
	php_tooslow
	php_segfault
elif [ "$1" = 'load' -o "$1" = "system_load" ];then
	load
elif [ "$1" = 'db' ];then
	mongodb
elif [ "$1" = 'mc' ];then
	memcached
elif [ "$1" = 'gm' ];then
	gearmand
else
	grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{" $0 && $1
	grep -q -P -e "^${2}[ |\t]?\(\)[ |\t]?\{" $0 && $2
	grep -q -P -e "^${3}[ |\t]?\(\)[ |\t]?\{" $0 && $3
fi

echo -e "\n\n"
