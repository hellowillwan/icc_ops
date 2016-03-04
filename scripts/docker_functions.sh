#!/bin/sh

check_webStatus()  {
	#usage: watch -d -n 1 'source ~wanlong/docker_functions.sh; check_webStatus 8081'
	port=$1
	curl -s 10.0.0.10:${1}/NginxStatus
	echo
	curl -s 10.0.0.10:${1}/status
}

goto () {
	containers="$(docker ps|awk '{print $NF}'|grep -v -e '^NAMES$')"

	if [ -z $1 ];then
		echo "CONTAINER ID|NAME missing,Usage:"
		for container_name in $containers;do
			echo -e "\t\tgoto ${container_name}"
		done
		return 1
	else
		my_container="$1"
		container_name=$(echo $containers|grep -o -P -e "[^ ]*${my_container}[^ ]*"|head -n 1)
		if [ -z "${container_name}" ];then
			echo "${my_container} not running or not exist."
		else
			echo "goto ${container_name}"
			docker exec -i -t ${container_name} '/bin/bash'
		fi
	fi

}

docker_stop_all_container() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`; do docker stop $ctn;done
}

docker_start_all_container() {
	for ctn in `docker ps -a|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`; do docker start $ctn;done
}

docker_run_a_cmd_on_all_container() {
	if [ -z "$1" ] ;then echo usage:docker_run_a_cmd_on_all_container "cmd";return 1;fi
	for ctn in `docker ps -a|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`; do
		echo "${ctn} result: "
		docker exec -i ${ctn} bash -c "$1" 
		echo
	done
}

docker_stats() {
	docker stats `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`
}

ngx_reload() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} reload nginx : "
		docker exec -i ${ctn} /usr/local/tengine/sbin/nginx -s reload
		echo $?
	done
}

ngx_restart() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} restart nginx : "
		docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx -s stop &>/dev/null; /usr/local/tengine/sbin/nginx -s stop &>/dev/null; /usr/local/tengine/sbin/nginx'
		echo $?
	done
}

php_restart() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} reload nginx : "
		docker exec -i ${ctn} /usr/local/tengine/sbin/nginx -s reload
		echo $?
		echo "${ctn} reload php-fpm : "
		docker exec -i ${ctn} /etc/init.d/php-fpm restart
	done
}

docker_restart() {
	systemctl restart docker.service;sleep 1;iptables -F;ngx_restart ;php_restart
}

docker_commit(){
	# Create a new image from a container's changes
	:
	# docker commit -p -m 'all php modules installed,update at 20151029' app01_icc_appserver_c02 icc_appserver_tengine-2.1.0_php-5.4.45
	# docker commit -p -m 'update php mongo driver to 1.6.11 at 20151117' app01_icc_appserver_c04 icc_appserver_tengine-2.1.0_php-5.4.45:php-mongo-1.6.11
	# docker commit -p -m 'all php modules installed,update at 20151029' app01_icc_appserver_c01 icc_appserver_tengine-2.1.0_php-5.6.14
	# docker commit -p -m 'lr installed' loadrunner01 icc_loadrunner
	# docker commit -p -m 'based docker.io/centos:latest,local time,local repo,install tools.' tmpc1 centos-7-local
	# docker commit -p -m 'based docker.io/centos:latest,local time,local repo,install tools,python-2.7,pymongo-3.0.' tmpc1 centos-7-local-python
	# docker commit -p -m 'based docker.io/centos:latest,local time,local repo,install tools,python-2.7,pymongo-3.0,supervisor.' py_weixin_service_1 python_weixin_service
}

docker_save(){
	# Save an image(s) to a tar archive (streamed to STDOUT by default)
	:
	# docker save icc_appserver_tengine-2.1.0_php-5.4.45:latest > /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.4.45.`date -I`.tar
	# docker save icc_appserver_tengine-2.1.0_php-5.4.45:php-mongo-1.6.11 > /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.4.45_php-mongo-1.6.11.`date -I`.tar
	# docker save icc_appserver_tengine-2.1.0_php-5.6.14:latest > /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.6.14.`date -I`.tar
	# docker save icc_loadrunner:latest > /home/Backup/Docker_build/icc_loadrunner.`date -I`.tar
	# docker save centos-7-local:latest > /home/Backup/Docker_build/centos-7-local.`date -I`.tar                            
	# docker save centos-7-local-python:latest > /home/Backup/Docker_build/centos-7-local-python.`date -I`.tar
	# docker save python_weixin_service:latest > /home/Backup/Docker_build/python_weixin_service.`date -I`.tar
	#
	# 有问题！这样保存的镜像 用下面的命令 import 后,docker run 启动容器,找不到 /bin/bash
	# cat /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.6.10.2015-07-01.tar |docker import - icc_appserver_tengine-2.1.0_php-5.6.10:latest
	#
	# 原来应该这样:
	# Load an image from a tar archive on STDIN
	# docker load -i /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.6.10.2015-07-01.tar
	# docker load -i /home/Backup/Docker_build/icc_appserver_tengine-2.1.0_php-5.4.45_php-mongo-1.6.11.2015-11-17.tar 
	# 导入后可以保留 Tag
	# [root@app05 scripts]# docker images
	# REPOSITORY                               TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
	# icc_appserver_tengine-2.1.0_php-5.4.45   php-mongo-1.6.11    0ed4ee68c83d        32 minutes ago      2.898 GB
	# icc_appserver_tengine-2.1.0_php-5.4.45   latest              f8de09c8a551        2 weeks ago         2.895 GB
}


