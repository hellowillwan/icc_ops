# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		restart_nginx_php
#
#


# restart nginx and check and report status
#DT2="date '+%Y-%m-%d %H:%M:%S'"

check_php() {
	if [ -z "$1" ] ;then
		echo "IP parameter error."
		return 0
	fi
	IP="$1"
	if /usr/bin/curl -m 5 -s http://${IP}/status 2>/dev/null | grep -q -e '^active' ; then
		return 0
	else
		return 1
	fi
}

restart_nginx_php() {
	#不检查IP,默认操作本机的nginx&php
	IP='10.0.0.10'
	NGINX_DAEMON='/usr/sbin/nginx'
	PHP_FPM_INIT='/etc/init.d/php-fpm'

	sudo sh -c "${NGINX_DAEMON} -s stop &>/dev/null;${NGINX_DAEMON} -s stop &>/dev/null;${PHP_FPM_INIT} restart;${NGINX_DAEMON}"

	#check nginx_php active
	if check_php $IP &>/dev/null || check_php $IP &>/dev/null || check_php $IP &>/dev/null || check_php $IP &>/dev/null ;then
		echo "$(eval $DT2) Restart ${IP} nginx&php OK."
		return 0
	else
		echo "$(eval $DT2) Restart ${IP} nginx&php Fail."
		return 1
	fi 
}

restart_all_nginx_php() {
	local APPS_IP_ARY=('10.0.0.10' '10.0.0.11' '10.0.0.12' '10.0.0.13')

	for ip in ${APPS_IP_ARY[@]} ;do
		echo ${localkey} restart_nginx_php | gearman -h 10.0.0.200 -f "CommonWorker_${ip}"
	done

	echo ${localkey} check_services nginx_php | gearman -h 10.0.0.200 -f "CommonWorker_10.0.0.200"
}

#restart_all_nginx_php
