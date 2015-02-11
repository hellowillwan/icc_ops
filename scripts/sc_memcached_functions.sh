# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		restart_memcached 11212
#
#


# restart memcached and check and report status
#DT2="date '+%Y-%m-%d %H:%M:%S'"
check_memcached() {
	if [ -z "$2" ] ;then
		echo "PORT parameter missing."
		return 0
	fi
	IP="$1"
	PORT="$2"
	if echo -en "set monitor_test_key_1 0 30 6\r\nvalue1\r\n"|/usr/bin/nc ${IP} ${PORT} &>/dev/null ; then
		echo 100
		return 0
	else
		echo 0
		return 1
	fi
}

restart_memcached() {
	if [ -z "$1" ] ;then
		echo "PORT parameter missing."
		return 1
	fi

	PORT="$1"
	#不检查IP,默认操作本机的memcached
	IP='10.0.0.2'

	#每个memcached实例参数各不相同,注意修改
	if [ "$PORT" = "11211" ];then
		PIDFILE='/var/run/memcached/memcached.pid'
		SIZE='2048'
	elif [ "$PORT" = "11212" ];then
		PIDFILE='/var/run/memcached/memcached2.pid'
		SIZE='2048'
	else
		echo "Bad port parameter."
		return 1
	fi

	#kill memcached
	ps -ef|grep -e "memcached.*${PORT}"|grep -v grep |awk '{print $2}'|xargs kill -9 &>/dev/null
	ps -ef|grep -e "memcached.*${PORT}"|grep -v grep |awk '{print $2}'|xargs kill -9 &>/dev/null
	#check
	if ps -ef|grep -e "memcached.*${PORT}"|grep -v grep &>/dev/null ;then
		echo "$(eval $DT2) Stop memcached ${IP}:${PORT} Fail."
	else
		echo "$(eval $DT2) Stop memcached ${IP}:${PORT} OK."
	fi

	#start memcached
	sudo /usr/bin/memcached -d -p ${PORT} -u memcached -m ${SIZE} -c 65536 -P ${PIDFILE} -l ${IP}
	#check
	if [ $? -eq 0 ];then
		echo "$(eval $DT2) Start memcached ${IP}:${PORT} OK."
	else
		echo "$(eval $DT2) Start memcached ${IP}:${PORT} Fail."
	fi

	#check writeable
	if check_memcached $IP $PORT &>/dev/null ;then
		echo "$(eval $DT2) Write memcached ${IP}:${PORT} OK."
		return 0
	else
		echo "$(eval $DT2) Write memcached ${IP}:${PORT} Fail."
		return 1
	fi 
}

#restart_memcached 11212
