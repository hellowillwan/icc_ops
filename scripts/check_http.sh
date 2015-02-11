#!/bin/sh

nginx() {
	if [ -z "$1" ] ;then
		echo "parameter error."
		return 0
	fi
	IP="$1"
	COUNT=$(/usr/bin/curl -m 5 -s http://${IP}/NginxStatus|awk '/^Active connections/{print $3}')
	echo ${COUNT:-0}
	return 0 
}

httpd(){
	if [ -z "$1" ] ;then
		echo "parameter error."
		return 0
	fi
	IP="$1"
	COUNT=$(/usr/bin/curl -m 5 -s http://${IP}/server-status|awk '/idle workers/{print substr($1,5)}')
	echo ${COUNT:-0}
	return 0 
}

php() {
	if [ -z "$1" ] ;then
		echo "parameter error."
		return 0
	fi
	IP="$1"
	COUNT=$(/usr/bin/curl -m 5 -s http://${IP}/status|awk '/^active processes/{print $3}')
	echo ${COUNT:-0}
	return 0 
}

memcached() {
	if [ -z "$2" ] ;then
		echo "PORT parameter missing."
		return 0
	fi
	IP="$1"
	PORT="$2"
	COUNT=$(echo stats|/usr/bin/nc ${IP} ${PORT}|awk '/uptime/{print $3}')
	if echo -en "set monitor_test_key_1 0 30 6\r\nvalue1\r\n"|/usr/bin/nc ${IP} ${PORT} >/dev/null ; then
		echo ${COUNT:-0}
	else
		echo 0
	fi
	return 0 
}

gearmand() {
	if [ -z "$2" ] ;then
		echo "PORT parameter missing."
		return 0
	fi
	IP="$1"
	PORT="$2"
	COUNT1=$(/usr/bin/gearadmin -h ${IP} -p ${PORT} --status|awk '/purge_10.0.0.1\t/{print $4}')
	COUNT2=$(/usr/bin/gearadmin -h ${IP} -p ${PORT} --status|awk '/purge_10.0.0.2\t/{print $4}')
	if [ ${COUNT1} -ge 1 ] && [ ${COUNT2} -ge 1 ] ; then
		echo 1 
	else
		echo 0
	fi
	return 0 
}

if [ -z "$2" ] ;then
	echo "parameter error."
	$0 Usage 0
	exit 0
fi

case "$1" in
  nginx)
        nginx $2
        ;;
  httpd)
        httpd $2
        ;;
  php)
        php $2
        ;;
  memcached)
        memcached $2 $3
        ;;
  gearmand)
        gearmand $2 $3
        ;;
  *)
        echo "Usage: $0 {nginx|httpd|php|memcached|gearmand} ip_addr [memcached_port]"
        exit 1
esac
