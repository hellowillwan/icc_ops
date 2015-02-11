# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		restart_nginx
#
#


# restart nginx and check and report status
#DT2="date '+%Y-%m-%d %H:%M:%S'"

check_nginx() {
	if [ -z "$1" ] ;then
		echo "IP parameter error."
		return 0
	fi
	IP="$1"
	if /usr/bin/curl -m 5 -s http://${IP}/NginxStatus 2>/dev/null | grep -q -e '^Active' ; then
		return 0
	else
		return 1
	fi
}

restart_nginx() {
	#不检查IP,默认操作本机的memcached
	IP='10.0.0.2'
	NGINX_DAEMON='/usr/local/tengine/sbin/nginx'

#	#kill nginx
#	${NGINX_DAEMON} -s stop &>/dev/null
#	${NGINX_DAEMON} -s stop &>/dev/null
#	#check
#	if ps -ef|grep -e "nginx"|grep -v grep &>/dev/null ;then
#		echo "$(eval $DT2) Stop ${NGINX_DAEMON} Fail."
#	else
#		echo "$(eval $DT2) Stop ${NGINX_DAEMON} OK."
#	fi
#
#	#start nginx 
#	sleep 1
#	sudo ${NGINX_DAEMON} &
#	#check
#	if [ $? -eq 0 ];then
#		echo "$(eval $DT2) Start ${NGINX_DAEMON} OK."
#	else
#		echo "$(eval $DT2) Start ${NGINX_DAEMON} Fail."
#	fi

	#above method fail sometimes,try another way
	sudo sh -c "${NGINX_DAEMON} -s stop &>/dev/null;${NGINX_DAEMON} -s stop &>/dev/null;${NGINX_DAEMON}"

	#check nginx active
	if check_nginx $IP &>/dev/null || check_nginx $IP &>/dev/null || check_nginx $IP &>/dev/null || check_nginx $IP &>/dev/null ;then
		echo "$(eval $DT2) Restart ${IP} ${NGINX_DAEMON} OK."
		return 0
	else
		echo "$(eval $DT2) Restart ${IP} ${NGINX_DAEMON} Fail."
		return 1
	fi 
}
