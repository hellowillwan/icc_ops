#!/bin/sh

DT1="date '+%H_%M'"
DT2="date '+%Y-%m-%d %H:%M:%S'"
localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)

PROXY_IP_ARY=('10.0.0.1' '10.0.0.2')
APP_IP_ARY=('10.0.0.10' '10.0.0.11' '10.0.0.12' '10.0.0.13' '10.0.0.14' '10.0.0.1' '10.0.0.2' '10.0.0.24')
#APP_IP_ARY=('10.0.0.12' '10.0.0.13')

parameter=' -qrptlc --delete '

RsyncCfg () {

	if [ -z "$3" ] ;then
		echo "Missing Parameter."
		return 1
	else
		source="$1"
		ip="$2"
		module="$3"

		/bin/env USER='backup' RSYNC_PASSWORD='123456' /usr/bin/rsync \
		${parameter} \
		--blocking-io \
		${source} \
		${ip}::${module}/

		if [ $? -eq 0 ] ; then
			ret='OK'
		else
			ret='Fail'
		fi
		echo -e "$(eval $DT2) SYNC ${module} to ${ip} ${ret}."
	fi
}

sync_app_php_conf () {
	for ip in  ${APP_IP_ARY[@]} ;do 
		RsyncCfg '/home/app_php_conf/' $ip app_php_conf
	done
	# app05 内存比较多,配置中需要特别设置
	func 'app05' call command run "/usr/bin/sed -i '/^pm.max_children/c\pm.max_children = 600' /etc/app_php_conf/php-5.4/php-fpm.d/www.conf" &>/dev/null
}

sync_app_nginx_conf () {
	for ip in  ${APP_IP_ARY[@]} ;do 
		RsyncCfg '/home/app_nginx_conf/' $ip app_nginx_conf
	done

	# RELOAD apps nginx of all docker containers
	for ip in  ${APP_IP_ARY[@]} ;do 
		echo "${ip}"|grep -q -P -e '^10.0.0.(1|2|24)$' && break #没有docker容器在运行,忽略
		local cmd=ngx_reload # restart_nginx_php
		echo $localkey $cmd | gearman -f "CommonWorker_${ip}"
	done
}

sync_proxy_nginx_conf () {
	for ip in  ${PROXY_IP_ARY[@]} ;do 
		RsyncCfg '/home/proxy_nginx_conf/' $ip proxy_nginx_conf
	done
	
	# RELOAD proxy nginx
	/usr/bin/func 'proxy0[1-2]' call command run "/usr/local/tengine/sbin/nginx -s reload" | sort | while read line;do
		echo "$line" | tr -d "',()[]" | while read hostname retcode;do
			hostname="$(($(echo $hostname|sed 's/proxy0//')-1))"
			hostip="${PROXY_IP_ARY[$hostname]}"
			if [ $retcode -eq 0 ];then
				ret='OK'
			else
				ret='Fail'
			fi
			echo "$(eval $DT2) Reload nginx $hostip $ret."
			unset hostip ; unset ret 
		done 
	done
}

if [ -z "$1" ] ;then
	sync_proxy_nginx_conf
	echo
	sync_app_php_conf
	echo
	sync_app_nginx_conf
elif [ "$1" = "apps" ];then
	sync_app_php_conf
	echo
	sync_app_nginx_conf
elif [ "$1" = "proxy" ];then
	sync_proxy_nginx_conf
else
	#cut 传过来的是个项目编号
	sync_proxy_nginx_conf
	echo
	sync_app_php_conf
	echo
	sync_app_nginx_conf
fi
