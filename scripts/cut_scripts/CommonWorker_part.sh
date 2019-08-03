#!/bin/sh
# gearman CommonWorker
# key command parameter ...
# key restart_memcached port
#

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

#variables
LOGFILE='/var/log/CommonWorker.log'
DT2="date '+%Y-%m-%d %H:%M:%S'"
localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)

#functions
source /usr/local/sbin/sc_memcached_functions.sh
source /usr/local/sbin/sc_nginx_functions.sh
source /usr/local/sbin/sc_nginx_php_functions.sh
source /usr/local/sbin/sc_mongodb_functions.sh

#main
while read p1 p2 p3 p4 p5 p6 ;do
	if [ -z "$p2" ];then
		echo "missing parameter,return code:1"
		exit 1
	else
		key="$p1"
		cmd="$p2"
	fi
	
	if [ "$key" != "$localkey" ];then
		echo "invalid key,return code:2"
		exit 2
	fi
	
	case "$cmd" in
	
	restart_memcached|restart_mongos)
		$cmd $p3
		ret=$?
		logger CommonWorker $p1 $p2 $p3 return code:$ret
		exit $ret
	        ;;
	restart_nginx)
		$cmd
		ret=$?
		logger CommonWorker $p1 $p2 return code:$ret
		exit $ret
	        ;;
	restart_nginx_php)
		$cmd
		ret=$?
		logger CommonWorker $p1 $p2 return code:$ret
		exit $ret
	        ;;
	*)
		echo "unknow command,return code:3"
		exit 3
	esac
done
