#!/bin/sh

DT1="date '+%H_%M'"
DT2="date '+%Y-%m-%d %H:%M:%S'"

PROXY_IP_ARY=('10.0.0.1' '10.0.0.2')
APP_IP_ARY=('10.0.0.10' '10.0.0.11' '10.0.0.12' '10.0.0.13')

parameter=' -qrptlc --delete '

RsyncCfg2Ngx () {

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
		echo -e "$(eval $DT2)  SyncNgxCfg ${ip} ${ret}."
	fi
}

sync_to_apps () {
	for ip in  ${APP_IP_ARY[@]} ;do 
		RsyncCfg2Ngx '/home/nginx/' $ip nginx
	done
	
	/usr/bin/func 'app0[1-4]' call command run "/usr/sbin/nginx -s reload" | sort | while read line;do
		echo "$line" | tr -d "',()[]" | while read hostname retcode;do
			hostname="$(($(echo $hostname|sed 's/app0//')-1))"
			hostip="${APP_IP_ARY[$hostname]}"
			if [ $retcode -eq 0 ];then
				ret='OK'
			else
				ret='Fail'
			fi
			echo "$(eval $DT2)  reload nginx $hostip $ret."
			unset hostip ; unset ret 
		done 
	done
}

sync_to_proxy () {
	for ip in  ${PROXY_IP_ARY[@]} ;do 
		RsyncCfg2Ngx '/home/ngx_proxy_conf/' $ip ngx_proxy_conf
	done
	
	/usr/bin/func 'proxy0[1-2]' call command run "/usr/local/tengine/sbin/nginx -s reload" | sort | while read line;do
		echo "$line" | tr -d "',()[]" | while read hostname retcode;do
			hostname="$(($(echo $hostname|sed 's/proxy0//')-1))"
			hostip="${PROXY_IP_ARY[$hostname]}"
			if [ $retcode -eq 0 ];then
				ret='OK'
			else
				ret='Fail'
			fi
			echo "$(eval $DT2)  reload nginx $hostip $ret."
			unset hostip ; unset ret 
		done 
	done
}

if [ -z "$1" ] ;then
	sync_to_proxy
	echo
	sync_to_apps
elif [ "$1" = "apps" ];then
	sync_to_apps
elif [ "$1" = "proxy" ];then
	sync_to_proxy
else
	#cut 传过来的是个项目编号
	sync_to_proxy
	echo
	sync_to_apps
fi
