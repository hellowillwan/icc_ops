#!/bin/sh
#
# 脚本功能: 在单机上快速搭建一个包含两个复制集的Mongdb分片集合
# 参考:《[奥莱理] MongoDB The Definitive Guide 2nd Edition》 Page 232: Chapter 13 Introducion to Sharding, A One-Minute Test Setup
#
#

#
# 配置信息
#
# 指定Mongodb 二进制包的下载链接,保存路径,安装路径
mongodb_binary_package_url='https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.0.7.tgz'
mongodb_binary_package_save_path='/root/PKG/mongodb-linux-x86_64-rhel62-3.0.7.tgz'
mongodb_install_path='/usr/local/'
# 指定各Mongo实例监听的IP端口,复制集名称
mongo_bind_server_ip='10.0.2.15'
mongos_ports='57000 57001 57002'
configdb_ports='50000 50001 50002'
replset_shard1_ports='60000 60001 60002'
replset_shard2_ports='61000 61001 61002'
replset_shard1_name='6w_shard1'
replset_shard2_name='6w_shard2'

#
# 函数
#
# 根据返回码输出日志
p_ret() {
	if [ -z "$3" ];then
		return 1
	fi
	if [ "$1" -eq 0 ];then
		messsage="$2"
	else
		messsage="$3"
	fi
	echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${messsage}\n"
}

# 解压安装 Mongodb 二进制包
install_mongodb() {
	if [ ! -s "$mongodb_binary_package_save_path" ];then
		# 下载
		wget -O ${mongodb_binary_package_save_path} ${mongodb_binary_package_url}
		ret=$?
		p_ret $ret "download ok." "download fail,exit"
		if [ $ret -ne 0 ];then
			exit 1
		fi
	fi
	# 解压安装
	tar -zxvf ${mongodb_binary_package_save_path} -C ${mongodb_install_path}
	ret=$?
	p_ret $ret "install ok." "install fail,exit"
	if [ $ret -ne 0 ];then
		exit 1
	fi
}

# 为 mongo 实例创建文件夹
mkdirs() {
	# mkdirs for mongos,configdb,mongod of shards
	for port in ${mongos_ports} ${configdb_ports} ${replset_shard1_ports} ${replset_shard2_ports} ;do
		mkdir -p /home/${port}/{data,log}
	done
	p_ret $? "create dirs ok." "create dirs fail."
}

# 建立软连接
mklinks() {
	mongodb_binary_install_path="${mongodb_install_path}$(echo ${mongodb_binary_package_save_path}|sed 's/.*\///;s/\.tgz//')"
	if [ ! -d "${mongodb_binary_install_path}" ];then
		echo "Error: mongodb_binary_install_path:${mongodb_binary_install_path} not exist,exit."
		exit 7
	fi
	for subdir in ${mongos_ports} ${configdb_ports} ${replset_shard1_ports} ${replset_shard2_ports} ;do
		ln -s "${mongodb_binary_install_path}/bin"  "/home/${subdir}/"
	done
	p_ret $? "create links ok." "create links fail."
}

# 系统初始化
init_sys() {
	ulimit -n 65535
	ulimit -u 65537
	if [ -f /sys/kernel/mm/transparent_hugepage/enabled ] ; then
		echo never > /sys/kernel/mm/transparent_hugepage/enabled
	fi
	if [ -f /sys/kernel/mm/transparent_hugepage/defrag ] ; then
		echo never > /sys/kernel/mm/transparent_hugepage/defrag
	fi
}

# 启动 configdb
start_configdb() {
	for port in ${configdb_ports};do
		/home/$port/bin/mongod \
			--port ${port} \
			--configsvr --dbpath /home/${port}/data \
			--logpath /home/$port/log/configdb_${port}.log \
			--logappend \
			--nssize 2000 \
			--fork
		p_ret $? "start configdb ${port} ok." "start configdb ${port} fail."
	done
}

# 启动 mongod of shards
start_shard() {
	if [ -z "$2" ] ;then
		echo 'usage: start_shard repleset_name mongod_of_shard_ports'
		return 1
	else
		repleset_name="$1"
		ports="$2"
	fi

	for port in ${ports} ;do
		/home/${port}/bin/mongod \
			--port ${port} \
			--shardsvr \
			--replSet ${repleset_name} \
			--setParameter failIndexKeyTooLong=false --storageEngine wiredTiger \
			--dbpath /home/${port}/data \
			--logpath /home/${port}/log/mongod_${port}.log \
			--logappend \
			--nssize 2000 \
			--fork
		p_ret $? "start ${repleset_name} mongod ${port} ok." "start ${repleset_name} mongod ${port} fail."
	done
}

# 启动 mongod of shard1
start_shard1() {
	start_shard "$replset_shard1_name" "$replset_shard1_ports"
}

# 启动 mongod of shard2
start_shard2() {
	start_shard "$replset_shard2_name" "$replset_shard2_ports"
}

# 启动 mongos
start_mongos() {
	configdb_str=''
	for configdb_port in ${configdb_ports};do
		configdb_str="${configdb_str},${mongo_bind_server_ip}:${configdb_port}"
	done
	configdb_str=$(echo ${configdb_str}|sed 's/^,//;s/,$//')

	for port in ${mongos_ports} ;do
		/home/${port}/bin/mongos \
			--port ${port} \
			--configdb ${configdb_str} \
			--logpath /home/${port}/log/mongos_${port}.log \
			--logappend \
			--fork
		p_ret $? "start mongos ${port} ok." "start mongos ${port} fail."
	done
}

# 初始化 复制集 
init_replset() {
	if [ -z "$3" ] ;then
		echo "usage: init_replset reple_set_name server_ip replset_shard_ports"
		return 1
	else
		reple_set_name="$1"
		server_ip="$2"
		replset_shard_ports="$3"
		port1="$(echo $3|cut -d ' ' -f 1)"
	fi
	# replset members
	members_count=$(echo $replset_shard_ports | awk '{print NF}')
	members=''
	id=0
	for port in $replset_shard_ports ;do
		if [ -n "${members}" ];then members="${members},"; fi
		members="${members}
				{
					\"_id\" : ${id},
					\"host\" : \"${server_ip}:${port}\"
				}"
		id=$((${id}+1))
	done
	# replset config
	conf="
		{
			\"_id\" : \"${reple_set_name}\",
			\"members\" : [
				${members}
			]
		}
	"
	# init replset
	echo "rs.initiate(${conf});"  | /home/${port1}/bin/mongo ${server_ip}:${port1} \
	| grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye' 
	p_ret $? "init replset ${reple_set_name} ok." "init replset ${reple_set_name} fail."
}

# 初始化 复制集 shard1
init_shard1() {
	init_replset "$replset_shard1_name" "$mongo_bind_server_ip" "$replset_shard1_ports"
}

# 初始化 复制集 shard2
init_shard2() {
	init_replset "$replset_shard2_name" "$mongo_bind_server_ip" "$replset_shard2_ports"
}

# 初始化 分片集群
init_shard_cluster() {
	:
}


# 主逻辑
main() {
	install_mongodb
	mkdirs
	mklinks
	init_sys
	# start mongods
	start_configdb
	start_shard1
	start_shard2
	# init_replset
	init_shard1
	init_shard2
	sleep 90
	start_mongos
	#init_shard_cluster
	p_ret $? "done $?" "done $?"
}


#main



