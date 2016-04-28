#!/bin/sh


newContainer_for_appserver_php56() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,2 \
	--memory=5120M \
	--name=app02_icc_appserver_c01 \
	-h app02_icc_appserver_c01 \
	-v /home/webs:/home/webs \
	-v /etc/app_nginx_conf:/usr/local/tengine/conf \
	-v /etc/app_php_conf/php-7.0:/etc/app_php_conf \
	-v /tmp/icc_appserver_c01:/tmp \
	-v /var/log/xdebug_log_dir:/var/log/xdebug_log_dir \
	-p 8081:80 \
	icc_appserver_tengine-2.1.1_php-7.0.4:latest \
	/bin/bash
}

newContainer_for_appserver_php54() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=1,3 \
	--memory=5120M \
	--name=app02_icc_appserver_c02 \
	-h app02_icc_appserver_c02 \
	-v /home/webs:/home/webs \
	-v /etc/app_nginx_conf:/usr/local/tengine/conf \
	-v /etc/app_php_conf/php-5.4:/etc/app_php_conf \
	-v /tmp/icc_appserver_c02:/tmp \
	-v /var/log/xdebug_log_dir:/var/log/xdebug_log_dir \
	-p 8082:80 \
	icc_appserver_tengine-2.1.0_php-5.4.45:latest \
	/bin/bash
}

newContainer_for_appserver_php54_2() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,2 \
	--memory=5120M \
	--name=app02_icc_appserver_c03 \
	-h app02_icc_appserver_c03 \
	-v /home/webs:/home/webs \
	-v /etc/app_nginx_conf:/usr/local/tengine/conf \
	-v /etc/app_php_conf/php-5.4:/etc/app_php_conf \
	-v /tmp/icc_appserver_c03:/tmp \
	-v /var/log/xdebug_log_dir:/var/log/xdebug_log_dir \
	-p 8083:80 \
	icc_appserver_tengine-2.1.0_php-5.4.45:latest \
	/bin/bash
}

newContainer_for_appserver_php54_3() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,2 \
	--memory=5120M \
	--name=app01_icc_appserver_c04 \
	-h app01_icc_appserver_c04 \
	-v /home/webs:/home/webs \
	-v /etc/app_nginx_conf:/usr/local/tengine/conf \
	-v /etc/app_php_conf/php-5.4:/etc/app_php_conf \
	-v /tmp/icc_appserver_c04:/tmp \
	-v /var/log/xdebug_log_dir:/var/log/xdebug_log_dir \
	-p 8084:80 \
	icc_appserver_tengine-2.1.0_php-5.4.45:php-mongo-1.6.11 \
	/bin/bash
}

newContainer_for_mongod_40101() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=1,3 \
	--memory=1024M \
	--name=mongod_40101 \
	-h mongod_40101 \
	-v /usr/local/mongodb-linux-x86_64-2.4.5:/usr/local/mongodb-linux-x86_64-2.4.5 \
	-v /home/40101:/home/40101 \
	-p 40101:40101 \
	docker.io/centos:latest \
	/home/40101/bin/mongod --shardsvr --replSet shard1 --port 40101 --dbpath /home/40101/data --logpath /home/40101/log/mongod.log --logappend --nssize 2000
}

newContainer_for_mongod_40102() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,2 \
	--memory=1024M \
	--name=mongod_40102 \
	-h mongod_40102 \
	-v /usr/local/mongodb-linux-x86_64-2.4.5:/usr/local/mongodb-linux-x86_64-2.4.5 \
	-v /home/40102:/home/40102 \
	-p 40102:40102 \
	docker.io/centos:latest \
	/home/40102/bin/mongod --shardsvr --replSet shard1 --port 40102 --dbpath /home/40102/data --logpath /home/40102/log/mongod.log --logappend --nssize 2000
}

newContainer_for_mongod_60101() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=1,2 \
	--memory=2048M \
	--name=mongod_60101 \
	-h mongod_60101 \
	-v /usr/local/mongodb-linux-x86_64-rhel62-3.0.4:/usr/local/mongodb-linux-x86_64-rhel62-3.0.4 \
	-v /home/60101:/home/60101 \
	-p 60101:60101 \
	docker.io/centos:latest \
	/home/60101/bin/mongod --port 60101 --shardsvr --replSet 6w_shard1 --oplogSize 153600 --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --dbpath /home/60101/data --logpath /home/60101/log/mongod.log --logappend --nssize 2000
}

newContainer_for_mongod_60102() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=1,2 \
	--memory=2048M \
	--name=mongod_60102 \
	-h mongod_60102 \
	-v /usr/local/mongodb-linux-x86_64-rhel62-3.0.4:/usr/local/mongodb-linux-x86_64-rhel62-3.0.4 \
	-v /home/60102:/home/60102 \
	-p 60102:60102 \
	docker.io/centos:latest \
	/home/60102/bin/mongod --port 60102 --shardsvr --replSet 6w_shard1 --oplogSize 51200  --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --dbpath /home/60102/data --logpath /home/60102/log/mongod.log --logappend --nssize 2000
}

newContainer_for_mongod_60201() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,3 \
	--memory=4096M \
	--name=mongod_60201 \
	-h mongod_60201 \
	-v /usr/local/mongodb-linux-x86_64-rhel62-3.0.4:/usr/local/mongodb-linux-x86_64-rhel62-3.0.4 \
	-v /home/60201:/home/60201 \
	-p 60201:60201 \
	docker.io/centos:latest \
	/home/60201/bin/mongod --port 60201 --shardsvr --replSet 6w_shard2 --oplogSize 153600 --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --dbpath /home/60201/data --logpath /home/60201/log/mongod.log --logappend --nssize 2000
}

newContainer_for_mongod_60202() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0,3 \
	--memory=2048M \
	--name=mongod_60202 \
	-h mongod_60202 \
	-v /usr/local/mongodb-linux-x86_64-rhel62-3.0.4:/usr/local/mongodb-linux-x86_64-rhel62-3.0.4 \
	-v /home/60202:/home/60202 \
	-p 60202:60202 \
	docker.io/centos:latest \
	/home/60202/bin/mongod --port 60202 --shardsvr --replSet 6w_shard2 --oplogSize 51200  --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --dbpath /home/60202/data --logpath /home/60202/log/mongod.log --logappend --nssize 2000
}


newContainer_for_loadrunner() {
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=3 \
	--memory=1024M \
	--name=loadrunner01 \
	-h app02_loadrunner01 \
	-v /tmp/loadrunner01:/tmp \
	-p 8001:54345 \
	icc_loadrunner:latest \
	/bin/bash
}

newContainer_for_py_weixin_service() {
	container_name="py_weixin_service_1"
	image_name="python_weixin_service"
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=0-3 \
	--memory=2048M \
	--name=${container_name} \
	-h ${container_name} \
	-v /tmp:/tmp \
	-v /home/webs:/home/webs \
	-p 8000:8000 \
	${image_name}:latest \
	/usr/bin/python /home/webs/icc/scripts/weixin/service.py --logging=None --log=/tmp/py_weixin_service.log
}

newContainer_for_testing() {
	if [ -z "$2" ] ; then
		echo usage: newContainer_ container_name image_name
		return
	else
		container_name="$1"
		image_name="$2"
	fi
	docker run \
	-d -t \
	--restart=always \
	--cpuset-cpus=3 \
	--memory=1024M \
	--name=${container_name} \
	-h ${container_name} \
	-v /tmp:/tmp \
	-v /home/webs:/home/webs \
	${image_name}:latest \
	/bin/bash
}

newContainer_for_dockerui() {
	docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock docker.io/dockerui/dockerui
}

newContainer_for_shipyard() {
	docker run -d -p 9001:8080 -v /var/run/docker.sock:/var/run/docker.sock docker.io/shipyard/shipyard
}


if [ -z "$1" ];then
	echo "parameter missing,nothing done."
	grep -P -e "^.*[ |\t]?\(\)[ |\t]?\{" $0 |sed 's/(\|)\|{//g'
else
	if grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{" $0 ;then
		$1 $2 $3
	else
		echo "command not found,nothing done."
	fi
fi
