#!/bin/sh
#
## 脚本功能：从WEB访问日志获取相关数据,保存成JSON格式 或 写入Mongodb
#


## 函数
#
filter_for_MicroMessenger_before_uid() {
	# 过滤规则:
	# 过滤静态请求
	# 输出符合条件记录的 time request referer字段

	if [ -z "$1" ] ;then
		#echo "file missing,nothing done.'
		return 1
	else
		local FILE="$1"
	fi

	awk '$7 !~ /\.(jpg|jpeg|gif|bmp|png|ico|css|js|map|flv|ogg|mp3|mp4|swf|webm|avi|wma|wmv)(\?.*)?$/ {print $4,$7,$11}' ${FILE}
}

filter_for_MicroMessenger_after_uid() {
	# 过滤规则:
	# 过滤静态请求
	# 输出符合条件记录的 urm_id time request referer字段

	if [ -z "$1" ] ;then
		#echo "file missing,nothing done.'
		return 1
	else
		local FILE="$1"
	fi

	# 记录uid后,日志字段列表有变化,输出所有字段
	awk '$8 !~ /\.(jpg|jpeg|gif|bmp|png|ico|css|js|map|flv|ogg|mp3|mp4|swf|webm|avi|wma|wmv)(\?.*)?$/ \
		&& $5 ~ /20[1-9][5-9]/ \
		{print $0}' \
		${FILE}
}

convert_ts() {
	# 转换WEB访问日志时间格式 到 unix时间戳
	#
	# date -d "2/01/2015 00:01:08" '+%s'  
	# 1422720068
	# 验证
	# date -d @1422720068
	# Sun Feb  1 00:01:08 CST 2015

	if [ -z "$1" ];then
		#echo "usage: time_stamp \$time_str"
		return 1
	else
		local time_str=$(echo "$1"|awk 'BEGIN{FS="[/|:]"}{gsub("\\[","",$1);print $2"/"$1"/"$3" "$4":"$5":"$6}' \
		|sed "s/Jan/1/;s/Feb/2/;s/Mar/3/;s/Apr/4/;s/May/5/;s/Jun/6/;s/Jul/7/;s/Aug/8/;s/Sep/9/;s/Oct/10/;s/Nov/11/;s/Dec/12/"
		)
		local time_stamp=$(date -d "${time_str}" '+%s')
	fi
	echo $time_stamp
}

get_fun() {
	# 从 request 或 referer 字段 获取Fromusername
	#
	if [ -z "$1" ];then
		#echo "usage: get_fun \$request_str \$referer_str"
		return 1
	else
		local request_str="$1"
	fi
	logger $1 $2

	# 以&|?为记录分隔符分隔 request | referer 字段,取FromUserName,并去掉'FromUserName='以及特殊字符
	#
	local from_user_name=$(echo ${request_str}|awk 'BEGIN{RS="&|?"}{print $0}' \
		|grep -i -P -e '^FromUserName='|head -n 1 \
		|sed 's#^.*FromUserName=##;s/[#|;].*$//')

	if [ -z "${from_user_name}" -a -n "$2" ];then
		local referer_str="$2"
		local from_user_name=$(echo ${referer_str}|awk 'BEGIN{RS="&|?"}{print $0}' \
			|grep -i -P -e '^FromUserName='|head -n 1 \
			|sed 's#^.*FromUserName=##;s/[#|;].*$//')
	fi
	echo $from_user_name
}

parse_fields() {
	# 解析一条日志的每个字段，生产JSON数据
	#
	if [ -z "$1" ];then
		#echo "usage: parse_fields \$urm_id \$time_str \$request_str \$referer_str ..."
		return 1
	fi

	#输出到标准输出,仅用于调试和统计
	echo "+++++++++++++++++++++++++++++++"

	local json_str="{" ; json_str="${json_str}\"host\":\"${HOST}\","
	# 处理字段列表
	for my_kv in $@ ;do
		if ! echo "$my_kv"|grep -q -e '::';then 
			# 忽略没有分隔符的字段
			continue
		fi

		local key=$(echo $my_kv|awk -F'::' '{print $1}')
		local val=$(echo $my_kv|awk -F'::' '{print $2}')

		# 分别处理每个字段
		case "$key" in
			remote_addr|phpsessid)
				:
			;;
			request_str)
				# 保存到这个变量里用于取得Fromusername
				local my_request_str="$val"
			;;
			urm_id)
				# 忽略urm_id字段为空的记录
				if [ -z "${val}" -o "${val}" = '-' ];then
					continue 2
				fi
			;;
			time_str)
				val=$(convert_ts "$val")
			;;
			status)
				# 忽略状态码不正常的记录
				if [ "${val}" -ge 100  -a "${val}" -le 599 ];then
					:
				else
					continue 2
				fi
			;;
			referer_str)
				#去掉 referer 字段前后的"(双引号)
				val=$(echo ${val}|sed 's/^"//;s/"$//')
				# 保存到这个变量里用于取得Fromusername
				local my_referer_str="$val"
			;;
			ua_str)
				#去掉 ua_str 字段后面的部分(request_length bytes_sent upstream_addr upstream_response_time request_time)
				val=$(echo ${val}|base64 -d|sed 's/^"//'|sed 's/".*$//')
			;;
			*)
				:
			;;
		esac

		# 每个字段组织成JSON格式
		json_str="${json_str}\"${key}\":\"${val}\","

		#输出到标准输出,仅用于调试和统计
		echo "$key: $val"
	done

	#补充Fromusername
	#set -x
	fromusername=$(get_fun "$my_request_str" "$my_referer_str")
	#set +x
	#输出到标准输出,仅用于调试和统计
	echo "fromusername: $fromusername"

	json_str="${json_str}\"fromusername\":\"${fromusername}\""
	json_str="${json_str}}"

	#生成json文件
	echo "${json_str}" >> ${DATA_FILE}
	# 导入mongodb
	# $ /home/37017/bin/mongoimport -h 192.168.5.41 --port 37017 -d test -c schwarzkopf --drop weixin.schwarzkopfclub.com.cn_2015-05-05_18-05-44.json

	#直接写入mongodb
	#echo "db.${collection_name}.save(${json_str})" | ${MONGO_CLIENT} ${MONGO_SERVER_IP}:${MONGO_PORT}/${DB_NAME} 

}

processor() {
	if [ -z "$1" ];then
		echo "parameter missing.nothing done."
		return 1
	else
		file="$1"
	fi

	# 检查日志文件是否已经被处理
	if grep -q -e "^${file}$" ${DONE_LIST} &>/dev/null ;then
		return 0
	fi

	filter_for_MicroMessenger_after_uid $file | while read \
		remote_addr \
		phpsessid \
		urm_id \
		remote_user \
		time_str \
		time_zone \
		method \
		request_str \
		protocol \
		status \
		body_bytes_sent \
		referer_str \
		ua_str		#ua_str 还包含: request_length bytes_sent upstream_addr upstream_response_time request_time
	do
		#ua_str 还包含 带有空格的 其他字段,所以编码一下
		ua_str=$(echo -n "${ua_str}"|base64|tr -d "\n")

		# 要处理哪些字段,在这里指定
		parse_fields \
			"remote_addr::${remote_addr}" \
			"phpsessid::${phpsessid}" \
			"urm_id::${urm_id}" \
			"time_str::${time_str}" \
			"request_str::${request_str}" \
			"status::${status}" \
			"referer_str::${referer_str}" \
			"ua_str::${ua_str}" \
			>> ${LOG_FILE} 2>&1
	done

	echo $file >> ${DONE_LIST}
	echo $file done.	#could be more detail and save in a file use tee;
}


## 变量
#
DT1="date '+%Y-%m-%d_%H-%M-%S'"
DT2="date '+%Y-%m-%d %H:%M:%S'"

#MONGO_CLIENT='/home/mongodb/bin/mongo'
#MONGO_CLIENT='/home/37017/bin/mongo'
MONGOIMPORT='/home/37017/bin/mongoimport'
MONGO_SERVER_IP='192.168.5.41'
MONGO_PORT='37017'
DB_NAME='test'

# 域名和日志文件路径,还需要记录处理到哪里的时间节点
if [ -z "$1" ];then
	echo -e "domain name missing,nothing done.\tusage: $0 weixin.schwarzkopfclub.com.cn"
	exit 1
else
	export HOST="$1"
	if ls /home/ngx_proxy_logs/proxy0?/*${HOST}* &>/dev/null ;then
		# 日志文件
		#FILES="/home/ngx_proxy_logs/proxy0?/*${HOST}*"
		#FILES=$(ls /home/ngx_proxy_logs/proxy0?/*${HOST}* |grep -A 356 -e '20150412')	#添加urm_id之后的日志文件
		FILES='ls /home/ngx_proxy_logs/proxy0?/${HOST}.access.log-*'
		#FILES='./testtext.file'	#调试

		# 集合名
		if [ "${HOST}" = 'weixin.schwarzkopfclub.com.cn' ];then
			COLLECTION_NAME='schwarzkopf'
		elif [ "${HOST}" = 'hoyoda.umaman.com' ];then
			COLLECTION_NAME='hoyoda'
		else
			:
		fi
	else
		#域名不正确或该域名的访问日志文件不存在
		echo "no log files fount for domain name ${HOST},nothing done."
		exit
	fi
fi

# 工作目录路径,生成的json文件名
export WORKING_DIR="/home/wanlong/PKG/Accesslog2Mongodb"
export DATA_FILE="${WORKING_DIR}/${HOST}_$(eval ${DT1}).json"
export LOG_FILE="${WORKING_DIR}/${HOST}_$(eval ${DT1}).log"
export DONE_LIST="${WORKING_DIR}/${HOST}_DONE.list"



## 主逻辑
#

t1=$(date +%s)

## 并行处理文件的方式
#  参考: http://stackoverflow.com/questions/11003418/calling-functions-with-xargs-within-a-bash-script
#  性能: 3116293 records found for weixin.schwarzkopfclub.com.cn in 35126 seconds.
#
export -f processor
export -f filter_for_MicroMessenger_after_uid
export -f parse_fields
export -f convert_ts
export -f get_fun
eval ${FILES} | xargs -n 1 -P 8 -I file_name bash -c 'processor "$@"' _ file_name
#echo ${FILES} | xargs -n 1 -P 8 -I file_name bash -c 'processor "$@"' _ file_name
#echo ${FILES} | xargs -n 1 -P 8 -I file_name bash -c 'processor file_name'
#
# 效果
#
#bash(955)─┬─pstree(11912)
#          └─splitAccesslog2(24376)───xargs(24383)─┬─bash(1234)─┬─bash(1272)───awk(1280)
#                                                  │            └─bash(1275)                       
#                                                  ├─bash(2363)─┬─bash(2411)───awk(2418)           
#                                                  │            └─bash(2415)                       
#                                                  ├─bash(20547)─┬─bash(20589)───awk(20604)        
#                                                  │             └─bash(20590)                     
#                                                  ├─bash(20989)─┬─bash(21024)───awk(21031)        
#                                                  │             └─bash(21028)                     
#                                                  ├─bash(24256)─┬─bash(24296)───awk(24300)        
#                                                  │             └─bash(24297)                     
#                                                  ├─bash(24443)─┬─bash(24493)───awk(24502)        
#                                                  │             └─bash(24495)                     
#                                                  ├─bash(26116)─┬─bash(26163)───awk(26173)        
#                                                  │             └─bash(26165)                     
#                                                  └─bash(29625)─┬─bash(29672)───awk(29678)        
#                                                                └─bash(29674)

## 另一种并行处理文件的方式
#  性能: 3113941 records found for weixin.schwarzkopfclub.com.cn in 53207 seconds.
#
#n=0
#for file in ${FILES} ;do
#	# 检查日志文件是否已经被处理
#	if grep -q -e "^${file}$" ${DONE_LIST} ;then
#		continue
#	fi
#
#	# 同时处理多个文件
#	#
#	processor $file &
#	n=$(($n+1))
#
#	# 如果同时在处理的文件数量达到 8 个,等待处理完成
#	if [ $n -ge 8 ];then
#		wait
#		n=0
#	fi
#done
#	# 如果总计文件数量小于 8 个,已经都在同时处理中了，等待处理完成
#	wait


## 执行完毕 输出统计信息
#
t2=$(date +%s)
n=$(wc -l ${DATA_FILE} |awk '{print $1}')
echo "${n} records found for ${HOST} in $((${t2}-${t1})) seconds."
echo


## 检查结果
#
# $ echo 'db.schwarzkopf.find({fromusername:{$regex:/^[#|;]?$/}},{_id:0,fromusername:1,event:1})'|mongo
echo "统计 fromusername 和 status 字段"
echo "grep -P -e '(urm_id|status|fromusername):' ${LOG_FILE} |sort |uniq -c|sort -k1,1nr|less"
echo "统计每个字段空值的数量"
echo "grep -P -e '(remote_addr|phpsessid|urm_id|time_str|request_str|status|referer_str|ua_str|fromusername): \$' ${LOG_FILE} |sort|uniq -c"
echo


## 导入Mongodb
#
t3=$(date +%s)
${MONGOIMPORT} -j 8 -h ${MONGO_SERVER_IP} --port ${MONGO_PORT} -d ${DB_NAME}  -c ${COLLECTION_NAME} ${DATA_FILE}
t4=$(date +%s)
echo "导入数据耗时: $((${t4}-${t3})) seconds."


## 杀掉正在执行的进程
#
# ps -ef|grep split|grep -v -e grep|awk '{print $2}'|xargs -i kill -9 {}
# ps -ef|grep bash.*processor.*ngx_proxy_logs|grep -v -e grep|awk '{print $2}'|xargs -i kill -9 {}

# 执行耗时(直接插入mongodb)
# size 2208 MB
# count 151015
# real    69m33.975s
# user    44m37.711s
# sys     8m27.055s

# 执行耗时(生成json文件)
# records 147392 
# real    15m50.782s
# user    3m12.829s
# sys     1m12.301s
