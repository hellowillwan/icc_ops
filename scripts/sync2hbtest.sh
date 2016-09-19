#!/bin/sh
#
#

sync2hbtest() {
	if [ -z "$1" ];then
		echo "usage: sync2hbtest item"
		return 1
	fi
	src_item="$(echo "$1" |sed 's#^/WebRoot#/home/wwwroot/140324fg0119#')"
	if [ -f ${src_item} ];then
		dst_item="$(echo $src_item|sed 's#140324fg0119#ROOT#')"
		dst_item="${dst_item%/*}/"
		echo
		echo sending "'$src_item'"
		rsync -avc ${src_item} -e 'ssh -p 8390 -i /var/lib/.id_rsa' root@211.152.60.33:${dst_item}
	else
		echo file not found: $src_item
	fi
}

restarttc() {
	echo
	echo Tomcat 当前进程:
	ssh -i /var/lib/.id_rsa -p 8390 root@211.152.60.33 "ps -ef|grep java|grep -v -e grep "
	ssh -i /var/lib/.id_rsa -p 8390 root@211.152.60.33 "/usr/local/tomcat/bin/shutdown.sh 2>&1"
	sleep 5
	ssh -i /var/lib/.id_rsa -p 8390 root@211.152.60.33 "/usr/local/tomcat/bin/startup.sh 2>&1"
	echo 重启后Tomcat进程:
	ssh -i /var/lib/.id_rsa -p 8390 root@211.152.60.33 "ps -ef|grep java|grep -v -e grep "
}

#
if [ -z $2 ];then
	echo "usage: $0 sync|restart item"
	exit 1
else
	if [ "$1" = 'sync' ];then
		sync2hbtest $2
	elif [ "$1" = 'restart' ];then
		restarttc
	else
		echo "usage: $0 sync|restart item"
		exit 1
	fi
fi
