#!/bin/sh
#
## 脚本功能: 将WEB访问日志写入Hive,访问日志按域名建表,按日期分区 (表名就是域名, 域名中的 . 和 - 转成 _ )
#

## 函数
#
# 根据返回码输出日志
p_ret() {
	if [ -z "$3" ];then
		return 1
	fi

	if [ "$1" -eq 0 ];then
		echo -e "$2"
	else
		echo -e "$3"
	fi
}

# 从日志文件名提取域名,输出表名
get_domain_name() {
	[ -z "$1" ] && return 1		#需要参数：日志文件名
	#weixin.schwarzkopfclub.com.cn.access.log-20150502
	echo "$1" | sed -e 's#^.*\/##;s#\.access\.log.*$##;s#\.#_#g;s#-#_#g'
}

# 从日志文件名提取产生的日期
get_event_date() {
	[ -z "$1" ] && return 1		#需要参数：日志文件名
	#weixin.schwarzkopfclub.com.cn.access.log-20150502
	# 测试正确性
	#for f in /home/ngx_proxy_logs/proxy0?/*access.log-*;do echo -en "$f\t"; date -d "$(echo "$f" | sed -e 's#^.*\.access\.log-##') -1day" "+%Y%m%d";done
	#/home/ngx_proxy_logs/proxy02/www.schwarzkopfclub.com.cn.access.log-20150701     20150630
	date -d "$(echo "$1" | sed -e 's#^.*\.access\.log-##') -1day" "+%Y%m%d"
}

# 表结构 access_logs.sample_table
create_sample_table() {
	local HIVE_CLI='/home/hadoop/hive/bin/hive'
	local DB_NAME='access_logs'

	local DDL1="DROP TABLE \`${DB_NAME}.sample_table\`;"
	local DDL2="
		CREATE TABLE \`${DB_NAME}.sample_table\`(
			\`remote_addr\` string,
			\`http_x_forwarded_for\` string,
			\`remote_user\` string,
			\`time_local\` string,
			\`request\` string,
			\`status\` int,
			\`http_referer\` string,
			\`http_user_agent\` string,
			\`request_length\` int,
			\`body_bytes_sent\` int,
			\`bytes_sent\` int,
			\`upstream_addr\` string,
			\`upstream_response_time\` string,
			\`request_time\` float,
			\`cookie_phpsessid\` string,
			\`cookie___urm_uid__\` string,
			\`http_cookie\` string)
		PARTITIONED BY (
			\`event_date\` string)
		ROW FORMAT DELIMITED
			FIELDS TERMINATED BY '\t';
	"
	local DDL3="CREATE TABLE \`${DB_NAME}\`.\`test_table\` like \`${DB_NAME}\`.\`sample_table\`;"
	echo $DDL1 | $HIVE_CLI
	echo $DDL2 | $HIVE_CLI
	echo $DDL3 | $HIVE_CLI
}

# 表结构 access_logs2.sample_table
create_sample_table2() {
	local HIVE_CLI='/home/hadoop/hive/bin/hive'
	local DB_NAME='access_logs2'

	local DDL1="DROP TABLE \`${DB_NAME}.sample_table\`;"
	local DDL2="
		CREATE TABLE \`${DB_NAME}.sample_table\`(
			\`remote_addr\` string,
			\`http_x_forwarded_for\` string,
			\`remote_user\` string,
			\`time_local\` string,
			\`request\` string,
			\`status\` int,
			\`http_referer\` string,
			\`http_user_agent\` string,
			\`request_length\` int,
			\`body_bytes_sent\` int,
			\`bytes_sent\` int,
			\`upstream_addr\` string,
			\`upstream_response_time\` string,
			\`request_time\` float,
			\`cookie_phpsessid\` string,
			\`cookie___urm_uid__\` string,
			\`http_cookie\` string,
			\`os\` string,
			\`release\` string,
			\`micro\` string,
			\`nettype\` string)
		PARTITIONED BY (
			\`event_date\` string)
		ROW FORMAT DELIMITED
			FIELDS TERMINATED BY '\t';
	"
	local DDL3="CREATE TABLE \`${DB_NAME}\`.\`test_table\` like \`${DB_NAME}\`.\`sample_table\`;"
	echo $DDL1 | $HIVE_CLI
	echo $DDL2 | $HIVE_CLI
	echo $DDL3 | $HIVE_CLI
}

# 建表
create_table() {
	[ -z "$1" ] && return 1		#需要参数：表名
	local TABLE_NAME="$1"
	local DDL="create table if not exists \`${DB_NAME}\`.\`${TABLE_NAME}\` like \`${DB_NAME}\`.\`sample_table\`;"
	echo "creating table \`${DB_NAME}\`.\`${TABLE_NAME}\`"
	echo $DDL | $HIVE_CLI &>/dev/null
	local RET=$?
	p_ret $RET "create table \`${DB_NAME}\`.\`${TABLE_NAME}\` ok." "create table \`${DB_NAME}\`.\`${TABLE_NAME}\` fail."
	return $RET
}

# 导入数据 将ngx日志导入access_logs库
load_data() {
	[ -z "$1" ] && return 1		#需要参数：日志文件名
	local DATA_FILE_PATH="$1"
	local TABLE_NAME=$(get_domain_name "${DATA_FILE_PATH}")
	local EVENT_DATE=$(get_event_date "${DATA_FILE_PATH}")
	local LDL="load data local inpath '${DATA_FILE_PATH}' into table \`${DB_NAME}\`.\`${TABLE_NAME}\` PARTITION(event_date='${EVENT_DATE}');"
	echo "processing data file '${DATA_FILE_PATH}'"
	if create_table "${TABLE_NAME}" ;then
		echo "$LDL" | $HIVE_CLI &>/dev/null
		RET=$?
		echo $RET
	else
		return 1
	fi
	p_ret $RET "load data '${DATA_FILE_PATH}' to \`${DB_NAME}\`.\`${TABLE_NAME}\` ok." "load data '${DATA_FILE_PATH}' to \`${DB_NAME}\`.\`${TABLE_NAME}\` fail."
	return $RET
}

# 导入数据 将access_logs库中的日志表通过transform切分出更细的字段后,导入access_logs2库
load_data2(){
	local SOURCE_DB='access_logs'
	local DESTIN_DB='access_logs2'
	local event_date=$(date -d "-1day" "+%Y%m%d")
	for table_name in $( echo 'show tables in access_logs;' | $HIVE_CLI 2>/dev/null |grep -v -e '^hive>' );do
		DML="CREATE TABLE if not exists \`${DESTIN_DB}\`.\`${table_name}\` like \`${DESTIN_DB}\`.\`sample_table\`;"
		DML="${DML}set hive.exec.dynamic.partition.mode=nonstrict;"
		DML="${DML}add file /home/hadoop/PKG/icc_bda/mrjob/hive_stdin_demo.py;"

		# 不带where条件 导全部的日志 适用于第一次导入
		#DML="${DML}insert into table \`${DESTIN_DB}\`.\`${table_name}\` partition(event_date) select transform(*) using 'python hive_stdin_demo.py' as (remote_addr,http_x_forwarded_for,remote_user,time_local,request,status,http_referer,http_user_agent,request_length,body_bytes_sent,bytes_sent,upstream_addr,upstream_response_time,request_time,cookie_phpsessid,cookie___urm_uid__,http_cookie,os,release,micro,nettype,event_date) from \`${SOURCE_DB}\`.\`${table_name}\`;"
		# 带where条件 导入前一天的日志
		DML="${DML}insert into table \`${DESTIN_DB}\`.\`${table_name}\` partition(event_date) select transform(*) using 'python hive_stdin_demo.py' as (remote_addr,http_x_forwarded_for,remote_user,time_local,request,status,http_referer,http_user_agent,request_length,body_bytes_sent,bytes_sent,upstream_addr,upstream_response_time,request_time,cookie_phpsessid,cookie___urm_uid__,http_cookie,os,release,micro,nettype,event_date) from \`${SOURCE_DB}\`.\`${table_name}\` where event_date=${event_date};"

		# 组织 DML 语句
		#echo $DML;
		#exit;
		#hive> CREATE TABLE `access_logs2`.`130701fg0191_umaman_com` like `access_logs2`.`sample_table`;set hive.exec.dynamic.partition.mode=nonstrict;add file /home/hadoop/PKG/icc_bda/mrjob/hive_stdin_demo.py;insert into table access_logs2.130701fg0191_umaman_com partition(event_date) select transform(*) using 'python hive_stdin_demo.py' as (remote_addr,http_x_forwarded_for,remote_user,time_local,request,status,http_referer,http_user_agent,request_length,body_bytes_sent,bytes_sent,upstream_addr,upstream_response_time,request_time,cookie_phpsessid,cookie___urm_uid__,http_cookie,os,release,micro,nettype,event_date) from access_logs.130701fg0191_umaman_com;

		# 执行DML 语句
		echo $DML | $HIVE_CLI && echo -e "${table_name}\t${event_date}" >> ${DONE_LIST2}
	done
}


## 变量
#
# 工作目录路径
export WORKING_DIR="/home/hadoop/PKG/loadLogsToHive"
# 完成列表
export DONE_LIST="${WORKING_DIR}/DONE.LIST"
export DONE_LIST_BAK="${DONE_LIST}.$(date +%s)"
export DONE_LIST2="${WORKING_DIR}/DONE.LIST2"
export HIVE_CLI='/home/hadoop/hive/bin/hive'
# 数据库名
export DB_NAME='access_logs'


## 主逻辑
#
cd ${WORKING_DIR} 

# 检查用户权限
sysuser=$(whoami)
if [ ! $sysuser = 'hadoop' -a ! $sysuser = 'root' ];then
	echo "current user not permit to run this script."
	exit
fi

# 备份完成列表
cp -a -f ${DONE_LIST} ${DONE_LIST_BAK}

t1=$(date +%s)

# 循环处理,但脚本无法用 nohup 放到背景执行
#for log_file in `ls /home/ngx_proxy_logs/proxy0?/${DOMAIN_NAME}*access.log-*`;do
#	if ! grep -q -e "^${log_file}$" ${DONE_LIST} ;then
#		load_data $log_file && echo "${log_file}" >> ${DONE_LIST}
#		echo
#		#sleep 5
#	fi
#done

processor() {
	[ -z "$1" ] && return 1		#需要参数：日志文件名
	local log_file="$1"
	if ! grep -q -e "^${log_file}$" ${DONE_LIST} ;then
		# 如果日志文件不在 完成列表 中,才会处理,处理成功后添加到完成列表
		load_data $log_file && echo "${log_file}" >> ${DONE_LIST}
		echo
	fi
}

# 将ngx日志导入access_logs库
# 并行处理日志文件
#
export -f p_ret get_domain_name get_event_date create_table load_data processor
find /home/ngx_proxy_logs/proxy0?/ | grep -P '\.access.log-[0-9]+' | xargs -n 1 -P 8 -I log_file bash -c 'processor "$@"' _ log_file


## 执行完毕 输出统计信息
#
t2=$(date +%s)
n=$(diff ${DONE_LIST} ${DONE_LIST_BAK}|grep -e '^<'|wc -l)
echo -e "$(date)\n${n} log files loaded in $((${t2}-${t1})) seconds."
echo


## 将access_logs库中的日志表通过transform切分出更细的字段后,导入access_logs2库
#
#load_data2


## 检查结果的方法
#
#
check_result() {
	#统计处理过的日志文件数量
	cd ${WORKING_DIR} 

	files_number_in_disk=$(ls /home/ngx_proxy_logs/proxy0?|grep 'access.log-'|wc -l)
	echo -e "${files_number_in_disk}\tls /home/ngx_proxy_logs/proxy0?|grep 'access.log-'|wc -l"
	
	files_number_in_hdfs=$(hadoop fs -ls -R hdfs://Master.hadoop:9000/data/hive/warehouse/access_logs.db |grep -e '-201'|wc -l)
	echo -e "${files_number_in_hdfs}\thadoop fs -ls -R hdfs://Master.hadoop:9000/data/hive/warehouse/access_logs.db |grep -e '-201'|wc -l"
	
	loaded_log_files_number=$(grep '^load data.*ok\.$' loadLogsToHive.log|wc -l)
	echo -e "${loaded_log_files_number}\tgrep '^load data.*ok\.\$' loadLogsToHive.log|wc -l"
	
	wc -l DONE.LIST|sed "s/ /\t/"
}

check_result2() {
	# 检查某个域名某一天的访问日志记录条数,预期应该与日志文件行数相等
	echo 'select count(*) from  access_logs.weixin_schwarzkopfclub_com_cn where event_date="20150909";' |hive
	wc -l /home/ngx_proxy_logs/proxy0?/weixin.schwarzkopfclub.com.cn.access.log-20150910
}

## 测试
#  get_domain_name()
#for f in `ls /home/ngx_proxy_logs/proxy01`;do
#	get_domain_name $f 
#done
#exit

#  create_table()
#for f in `ls /home/ngx_proxy_logs/proxy01`;do
#	domain_name=$(get_domain_name $f)
#	create_table "$domain_name"
#done
#exit

