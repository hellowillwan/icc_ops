#!/bin/sh
#
# for zabbix low level discovery
# /usr/local/zabbix-2.2.3/bin/zabbix_get -s 10.0.0.1 -k zabbix_low_discovery[redis]
# {"data":[
# { "{#REDISPORT}" : "7001" }, { "{#REDISPORT}" : "7002" }, { "{#REDISPORT}" : "7101" }, { "{#REDISPORT}" : "7102" }, { "{#REDISPORT}" : "7103" }
# ] }
#

redis() {
	ps -ef|grep -v -e grep|grep -q 'bin.redis' || return 1
	local ports=$(ps -ef|grep -v -e grep|grep -o 'bin.redis.*'|grep -P -o ':[0-9]+ '|tr -d ':|\t| ')
	echo '{"data":['
	if [ -z "$ports" ];then
		echo -e " { \"{#REDISPORT}\" : \"6379\" } "
	else
		local multi_items=''
		for port in $ports ;do
			local multi_items="${multi_items} { \"{#REDISPORT}\" : \"${port}\" },"
		done
		echo ${multi_items}|sed 's/,$//'
	fi
	echo '] }'
}

grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{" $0 && $1
