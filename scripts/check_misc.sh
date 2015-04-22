#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"


#functions

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
	else
		IP="$1"
		if [ ! -z "$2" -a "$2" = 'idle' ];then
			type='idle processes'
		else
			type='active processes'
		fi
	fi
	COUNT=$(/usr/bin/curl -m 5 -s http://${IP}/status|grep -e "^${type}" 2>/dev/null|awk '{print $3}')
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

mongodb() {
	if [ -z "$2" ] ;then
		echo "PORT parameter missing."
		return 0
	fi
	IP="$1"
	PORT="$2"
	MONGO='/home/mongodb/bin/mongo'
	if echo 'db.currentOp()' | $MONGO ${IP}:${PORT} &>/dev/null ;then
#		WaitingForLock_COUNT=1
#		RET=$(echo 'db.currentOp()' | $MONGO ${IP}:${PORT})
#		echo "${RET}" | grep waitingForLock |while read line ;do
#			if  echo "$line" |grep  true &>/dev/null ;then
#				WaitingForLock_COUNT=$((${WaitingForLock_COUNT}+1)) 
#			fi
#		done 
#		echo ${WaitingForLock_COUNT}
#		return 0 
		WaitingForLock_COUNT=$(echo 'db.currentOp()' | $MONGO ${IP}:${PORT}|grep -e 'waitingForLock.*true'|/usr/bin/wc -l)
		echo $((${WaitingForLock_COUNT}+1))
		return 0
	else
		echo 0
		return 1
	fi
}

sendemail () {
	SNDEMAIL_LOG='/tmp/sendemail.log'
	if [ -z "$4" ] ;then
		echo -e "\n$(date) : parameters missing." >> $SNDEMAIL_LOG 
		return 1
	fi
	
	to_list=$1
	subject=$2
	content=$3
	file=$4
	#echo -e "\n$(date)\n${to_list}\n${subject}\n${content}" >> $SNDEMAIL_LOG
	echo -e "\n$(date)\n${to_list}\n${subject}" >> $SNDEMAIL_LOG
	#/usr/local/sbin/sendemail.py -s smtp.catholic.net.cn -f serveroperations@catholic.net.cn -u serveroperations@catholic.net.cn -p zd0nWmAkDH_tUwFl1wr \
	/usr/local/sbin/sendemail.py -s smtp.icatholic.net.cn -f system.monitor@icatholic.net.cn -u system.monitor@icatholic.net.cn -p abc123 \
		-t "$to_list" \
		-S "$subject" \
		-m "$content" \
		-F "$file" >> $SNDEMAIL_LOG 2>&1
	[ $? -eq 0 ] && echo "$(date) : mail sent." >> $SNDEMAIL_LOG
}

log_analyst () {
	if [ -z "$4" ] ;then
		echo "parameter missing: hostname request_time_threshold count_threshold_stdc count_threshold_dnmc"
		return 0
	else
		#下载项目开发者邮箱列表
		email_list_url='http://27.115.13.122/project_email_list.txt'
		email_list_file='/tmp/project_email_list.txt'
		/usr/bin/curl -s -m 5 "$email_list_url" -o "$email_list_file"
	fi
	#是否发邮件的参数,如果没有提供,默认是发的
	if [ -z "$5" ];then
		if_send=1
	else
		if_send="$5"
	fi
	#默认此脚本每1小时运行1次,统计前一个小时的日志
	DT=$(date -d "-1hour" "+%d/%b/%Y:%H")
	DT2=$(date -d "-1hour" "+%d/%b/%Y %H:00:00--%H:59:59")
	hostname="$1"	#域名
	request_time_threshold="$2"	#请求时间阀值
	#count_threshold="$3"	#超时请求数量阀值
	count_threshold_stdc="$3"	#静态超时请求数量阀值
	count_threshold_dnmc="$4"	#动态超时请求数量阀值
	#to_list="$5"
	NGX_CONF_DIR='/usr/local/tengine/conf/'
	LOG_DIR='/usr/local/nginx/logs/'
	LOG_FILE="${LOG_DIR}${hostname}.access.log"	#访问日志文件,要求nginx配置里使用这种文件名和格式！
	TMP_FILE_DNMC="/tmp/log_analyst_dynamic.${hostname}.$$.txt"	#临时文件-动态,将在压缩后作为邮件附件
	TMP_FILE_STDC="/tmp/log_analyst_static.${hostname}.$$.txt"	#临时文件-静态,将在压缩后作为邮件附件
	TMP_FILE_GZ="/tmp/log_analyst.${hostname}.$$.tgz"
	#找出 当前周期内 && 大于等于阀值 && 动态请求 记录写入临时文件
	grep "$DT" $LOG_FILE \
		|awk -v rtt=$request_time_threshold \
		'$NF >= rtt {printf "%-21s %-16s %-7s %-7s %-8s %-3s %-4s %s\n",substr($5,2),$1,$NF,$(NF-1),$(NF-3),$10,substr($7,2),$8}' \
		|grep -v -i -P -e '\.(jpg|jpeg|gif|bmp|png|ico|css|js|flv|ogg|mp3|mp4|swf|webm|avi|wma|wmv)(\?.*)?$' \
		> $TMP_FILE_DNMC
	#找出 当前周期内 && 大于等于阀值 && 静态请求 记录写入临时文件
	grep "$DT" $LOG_FILE \
		|awk -v rtt=$request_time_threshold \
		'$NF >= rtt {printf "%-21s %-16s %-7s %-7s %-8s %-3s %-4s %s\n",substr($5,2),$1,$NF,$(NF-1),$(NF-3),$10,substr($7,2),$8}' \
		|grep -i -P -e '\.(jpg|jpeg|gif|bmp|png|ico|css|js|flv|ogg|mp3|mp4|swf|webm|avi|wma|wmv)(\?.*)?$' \
		> $TMP_FILE_STDC
	#大于阀值的记录条数
	COUNT_STDC=$(wc -l $TMP_FILE_STDC 2>/dev/null | tail -n 1 |awk '{print $1}')
	COUNT_DNMC=$(wc -l $TMP_FILE_DNMC 2>/dev/null | tail -n 1 |awk '{print $1}')
	COUNT_SUM=$(($COUNT_STDC+$COUNT_DNMC))
	echo $COUNT_SUM

	#收件人列表,这里要根据域名选择相关的收件人
	to_list=$(grep $hostname $email_list_file|awk '{print $2}')
	[ -z "$to_list" ] && to_list='youngyang@icatholic.net.cn,dkding@icatholic.net.cn,willwan@icatholic.net.cn'
	#邮件主题和内容
	subject="$hostname 在 $DT2 有 $COUNT_SUM 个请求耗时超过 $request_time_threshold 秒"
	content="$hostname has $COUNT_STDC static and $COUNT_DNMC dynamic requests which respone time exceeded $request_time_threshold seconds in last hour, Pls checkout the attachment files."
	#打包临时文件
	if [ $COUNT_STDC -eq 0 -a $COUNT_DNMC -gt 0 ];then
		TMP_FILE_LIST="${TMP_FILE_DNMC##*/}"
	elif [ $COUNT_DNMC -eq 0 -a $COUNT_STDC -gt 0 ];then
		TMP_FILE_LIST="${TMP_FILE_STDC##*/}"
	else
		TMP_FILE_LIST=" ${TMP_FILE_DNMC##*/} ${TMP_FILE_STDC##*/} "
	fi
	cd ${TMP_FILE_GZ%/*} ; tar zcf $TMP_FILE_GZ $TMP_FILE_LIST
	#检查是否满足条件,发送报警邮件
	if [ $if_send -eq 1 ] ;then
		if [ $COUNT_STDC -ge $count_threshold_stdc  -o $COUNT_DNMC -ge $count_threshold_dnmc ] ;then
			sendemail "$to_list" "$subject" "$content" "${TMP_FILE_GZ}" &>/dev/null
		fi
	fi
	rm $TMP_FILE_DNMC $TMP_FILE_STDC $TMP_FILE_GZ -f
}

mongo_index () {
	if [ -z "$4" ] ;then
		echo "Parameter missing: ip port db record_count_threshold"
		return 1
	fi
	MONGO='/home/mongodb/bin/mongo'
	IP="$1"
	PORT="$2"
	DB="$3"
	record_count_threshold="$4"	#集合记录数量阀值

	#是否发邮件的参数,如果没有提供,默认是发的
	if [ -z "$5" ];then
		if_send=1
	else
		if_send="$5"
	fi

	tmp_file="/tmp/mongo_index_${DB}.$$.txt"	#临时文件
	tmp_indexed_file="/tmp/mongo_indexed_${DB}.txt"	#已经做了索引的集合列表
	#查询集合的索引情况,将记录条数超过阀值并且没有索引的集合名写入临时文件
	COLLECTIONS=$(echo "show collections"|${MONGO} ${IP}:${PORT}/${DB} 2>/dev/null|grep -i -e '^idatabase')
	for colct in ${COLLECTIONS} ;do
		if grep -q -e "^${colct}$" ${tmp_indexed_file} &>/dev/null ;then
			#在做了索引的集合列表里找到,跳过
			:
		else
			record_count=$(echo "db.getCollection('${colct}').count()" |${MONGO} ${IP}:${PORT}/${DB} 2>/dev/null|grep -e '^[0-9]')
			if [ ${record_count:-0} -ge ${record_count_threshold} ] ;then
				#index_count=$(echo "db.getCollection('${colct}').getIndexes()" |${MONGO} ${IP}:${PORT}/${DB} 2>/dev/null |grep '"name"'|wc -l)
				index_count=$(echo "db.getCollection('${colct}').getIndexes()" |${MONGO} ${IP}:${PORT}/${DB} 2>/dev/null |grep '"name"'|grep -v -e '"_id_"' -e 'REMOVED' -e 'CREATE_TIME' -e 'MODIFY_TIME'|wc -l)
				if [ ${index_count} -eq 0 ] ;then
					echo -e "${DB}\t${colct}\t${record_count}" >> $tmp_file 
				else
					grep -q -e "^${colct}$" ${tmp_indexed_file} &>/dev/null|| echo "${colct}" >> $tmp_indexed_file
				fi
			fi
		fi
	done
	tmp_file_count=$(wc -l $tmp_file 2>/dev/null|awk '{print $1}')
	echo ${tmp_file_count:-0}
	#根据条件发送邮件
	if [ ${tmp_file_count:-0} -gt 0 -a $if_send -eq 1 ];then
		gzip $tmp_file ; TMP_FILE_GZ="${tmp_file}.gz"
		to_list='youngyang@icatholic.net.cn,dkding@icatholic.net.cn,willwan@icatholic.net.cn'
		subject="${tmp_file_count} collections without index have found in ${DB} which has more than ${record_count_threshold} records"
		content="Pls checkout the attachment files for detail information."
		sendemail "$to_list" "$subject" "$content" "${TMP_FILE_GZ}" &>/dev/null
	fi
	rm ${tmp_file} ${TMP_FILE_GZ} -f
}

out_conn () {
	source /usr/local/sbin/ProcNetTCP_Parser.sh
	count=$(core_netstat 2>/dev/null | awk '$3 !~ /10.0.0/ && $3 !~ /127.0.0.1/ && $3 !~ /0.0.0.0/' 2>/dev/null|wc -l)
	echo ${count:-0}
}

nic_link() {
	dmesg |grep 'Link is Down'|wc -l
}


#main

if [ -z "$2" ] ;then
	echo "parameter error."
	$0 Usage 0
	exit 0
else
	cmd="$1"
fi

case "$cmd" in
  nginx|httpd|out_conn|nic_link)
        $cmd $2
        ;;
  memcached|gearmand|mongodb|php)
        $cmd $2 $3
        ;;
  mongo_index)
        $cmd $2 $3 $4 $5 $6
        ;;
  log_analyst)
        $cmd $2 $3 $4 $5 $6
        ;;
  *)
        echo "Usage: $0 {nginx|httpd|php|memcached|gearmand|mongodb|mongo_index|log_analyst|out_conn} ip_addr port"
        exit 1
esac
