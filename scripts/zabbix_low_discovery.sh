#!/bin/sh
#
# for zabbix low level discovery
#

redis() {
	ps -ef|grep -v -e grep|grep -q 'bin.redis' || return 1
	local ports=$(ps -ef|grep -v -e grep|grep -o 'bin.redis.*'|grep -P -o ':[0-9]+ '|tr -d ':|\t| ')
	echo '{"data":['
	if [ -z "$ports" ];then
		echo -e "\t{\n\t\t{#REDISPORT}":"6379\n\t},"
	else
		for port in $ports ;do
			echo -e "\t{\n\t\t{#REDISPORT}":"${port}\n\t},"
		done
	fi
	echo '] }'
}

grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{" $0 && $1
