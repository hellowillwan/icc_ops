# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		cronjob_list	all_users|user_name
# usage		cronjob_add	user_name	cronjob_identity
# usage		cronjob_del	user_name	cronjob_identity
# usage		cronjob_disable	user_name	cronjob_identity
# usage		cronjob_enable	user_name	cronjob_identity
# usage		cronjob_runonce	user_name	cronjob_identity
# usage		cronjob_taillog	user_name	cronjob_identity
#
#
# cronjob_identity:
# * * * * *
# root
# /usr/bin/php
# /home/webs/131203fg0370demo/scripts/cronjob.php
# controller=auction action=start2
# >> /tmp/wanlong_131203fg0370demo.umaman.com_74f1f9c52c6a1703a2ebb0b1fb402aeb_$(date '+\%s').log 2>&1
# #domain_name:131203fg0370demo.umaman.com
# #job_owner:wanlong
#
#DT2="date '+%Y-%m-%d %H:%M:%S'"
#CRON_DIR='/etc/cron.d/'
CRON_DIR='/etc/cron.d/'
CRON_LOG_DIR='/tmp/cut_cron_log/'
CRON_OLDLOG_DIR='/tmp/cut_cron_log_old/'
RUN_TIME_USER='wanlong'
PHP_BIN='/usr/bin/php'
PYTHON_BIN='/usr/bin/python'


gen_random_str() {
	random_str=`head -c 10 /dev/urandom |md5sum |head -c 16`
	echo $random_str
}

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

chk_hostname() {
	if [ -z "$1" ];then
		return 1
	else
		hostname=$1
	fi

	if echo ${hostname}|grep -e '\.' -q  && echo ${hostname}|grep -P -e '\.(com|cn|org|net)$' -q ;then
		#是合法域名
		NGXCONF_DIR='/home/nginx/'
		vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
		if [ ! -f "$vhostfile" ];then
			#不是配置过的域名,退出
			#echo "此域名没有配置到系统."
			return 1
		else
			#域名有配置过
			return 0
		fi
	else
		#不是合法域名
		#echo "不是合法域名."
		return 1
	fi
}

get_dir_from_hostname() {
	if [ -z "$1" ];then
		#echo "缺少参数."
		return 1
	else
		hostname=$1
	fi

	#域名经过检查,确认有配置过,从配置文件查找webroot目录名
	NGXCONF_DIR='/home/nginx/'
	vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
	webdir=$(grep -P -e "^[ |\t]*root[ |\t].*" ${vhostfile} | /usr/bin/head -n 1 | awk -F '/' '{printf "/%s/%s/%s", $2,$3,$4}')
	echo $webdir
}

mv_old_logs() {
	cron_file="${CRON_DIR}cut_*"
	#检查每一个cronjob的日志文件个数
	cat ${cron_file}|while read line;do
		log_files_pattern=$(echo -n "${line}"|grep -o -P -e '>.+_\$'|sed 's#>\+[ |\t]\+##;s#\$#\*#')
		num_all=$(ls ${log_files_pattern} 2>/dev/null |wc -l)
		if [ ${num_all} -le 10 ];then
			#不超过10个
			:
		else
			ls ${log_files_pattern}|sort -nr|tail -n $((${num_all}-10)) | xargs -I '{}' mv -f {} ${CRON_OLDLOG_DIR} &>/dev/null
		fi
	done

	#检查效果
	#$ ls /tmp/cut_cron_log|sed "s/^.*.\(com\|cn\)_//;s/_142.*$//"|sort |uniq -c
}

cronjob_list() {
	if [ -z "$1" ];then
		echo "user_name parameter missing."
		return 1
	else
		user_name="$1"
	fi

	if [ "$user_name" = 'all_users' ];then
		cron_file="${CRON_DIR}cut_*"
		if ! ls ${cron_file} &>/dev/null ;then
			echo "crontab文件未找到,该用户尚未创建计划任务."
			return 1
		fi
	else
		cron_file="${CRON_DIR}cut_${user_name}"
		if [ ! -f ${cron_file} -o ! -s ${cron_file} ] ;then
			echo "crontab文件未找到或为空,该用户尚未创建计划任务."
			return 1
		fi
	fi

	cat ${cron_file}|while read line;do
		job_owner=$(echo "${line}"|grep -o -P -e '#job_owner:[^ |\t|#]+'|sed 's/#job_owner://')
		domain_name=$(echo "${line}"|grep -o -P -e '#domain_name:[^ |\t|#]+'|sed 's/#domain_name://')
		cronjob_hash=$(echo "${line}"|grep -o -P -e '#cronjob_hash:[^ |\t|#]+'|sed 's/#cronjob_hash://')
		script=$(echo "${line}"|grep -o -P -e 'scripts/.*\.(php|py)'|sed 's#scripts/##')		#从 scripts/ 之后开始截取
		if echo "${script}"|grep -q -e '\.php$';then
			INTERPRETER_BIN=${PHP_BIN}
		elif echo "${script}"|grep -q -e '\.py$';then
			INTERPRETER_BIN=${PYTHON_BIN}
		else
			INTERPRETER_BIN=${PHP_BIN}
		fi
		#parameters=$(echo "${line}"|grep -o -P -e '\.php.*[^2][ |\t]?\>'|sed 's/\.php[ |\t]\+//;s/[ |\t]\+>\+$//')
		parameters=$(echo "${line}"|grep -o -P -e '\.(php|py).*[^2][ |\t]?\>'|sed 's/\.php[ |\t]\+//;s/\.py[ |\t]\+//;s/[ |\t]\+>\+$//')
		trigger_time=$(echo "${line}"|awk -F' ' '{(gsub("#","",$1));printf "%s %s %s %s %s",$1,$2,$3,$4,$5}')
		job_active=$(if echo -n "${line}"|grep -q -e '^#';then echo "计划已停止";else echo "计划已开启";fi)
		cmdline=$(echo "${line}"|grep -o -P -e  "${INTERPRETER_BIN}.+>>"|sed 's/ >>//')
		running=$(ps -ef|grep -e "${cmdline}\$" 2>/dev/null |grep -v grep 2>/dev/null |wc -l)		# running_processor_number
		log_files_pattern=$(echo -n "${line}"|grep -o -P -e '>.+_\$'|sed 's#>\+[ |\t]\+##;s#\$#\*#')
		last_run_time=$(if ls ${log_files_pattern} &>/dev/null ;then
					date '+%Y-%m-%d %H:%M:%S' -d \
					@$(for f in ${log_files_pattern} ;do echo "${f##*_}"|sed 's/\.log.*$//';done|sort -nr|head -n 1);
				else
					echo '未知';
				fi)
		last_write_log_time=$(if ls ${log_files_pattern} &>/dev/null ;then
						ls -lht --time-style='+%Y-%m-%d %H:%M:%S' ${log_files_pattern}|head -n 1 |awk '{printf "%s %s",$6,$7}';
					else
						echo '未知';
					fi)
		[ ${running:-0} -gt 0 ] && running_status="此刻运行中: ${running} 个进程" || running_status="此刻未在运行"
		job_status="${job_active} ${running_status}<br>上次运行的时刻:${last_run_time}<br>最后输出的时刻:${last_write_log_time}"
		echo "${job_owner}||${domain_name}||${cronjob_hash}||${script}||${parameters}||${trigger_time}||${job_status}"
	done
}

cronjob_add() {
	if [ -z "$5" ];then
		echo "usage: user_name domain_name script parameters trigger_time"
		return 1
	else
		user_name="$1" ; cron_file="${CRON_DIR}cut_${user_name}"	#用户名、crontab文件路径
		domain_name="$2" ; if ! chk_hostname $domain_name ;then echo "此域名没有配置到系统,添加失败.";return 1;fi	#检查提交的域名
		script_dir=$(get_dir_from_hostname ${domain_name});
		script_file=$(echo "$3"|sed -e 's#^.\?/##')	#去掉开头的./或/
		script_file="${script_dir}/scripts/${script_file}"
		if [ ! -f "${script_file}" ];then echo "脚本文件没找到,添加失败.";return 1;fi	#检查脚本文件
		#区别php、python脚本
		if echo "${script_file}"|grep -q -e '\.php$';then
			INTERPRETER_BIN=${PHP_BIN}
		elif echo "${script_file}"|grep -q -e '\.py$';then
			INTERPRETER_BIN=${PYTHON_BIN}
		else
			INTERPRETER_BIN=${PHP_BIN}
		fi
		parameters=$(echo -n "$4"|base64 -d 2>/dev/null)	#这里不做校验了,提交表单的时候在php那里校验吧.
		trigger_time=$(echo -n "$5"|base64 -d 2>/dev/null)
		if [ $(echo -n "${trigger_time}"|awk '{print NF}') -ne 5 ];then echo "触发时间格式不正确,添加失败.";return 1;fi		#检查触发时间格式
		cronjob_hash=$(echo -n "${user_name}${domain_name}${script_file}${parameters}${trigger_time}"|md5sum|head -n 1|awk '{print $1}')
		log_file="${CRON_LOG_DIR}${user_name}_${domain_name}_${cronjob_hash}_\$(date '+\%s').log"
	fi

	if grep -q "${cronjob_hash}" ${cron_file} ;then
		echo "不能添加重复的计划任务,请检查后重新提交."
		return 1
	fi

	echo "#${trigger_time} ${RUN_TIME_USER} ${INTERPRETER_BIN} ${script_file} ${parameters} >> ${log_file} 2>&1 #domain_name:${domain_name} #job_owner:${user_name} #cronjob_hash:${cronjob_hash}" >> ${cron_file}
	p_ret $? "计划任务添加成功,请刷新页面查看." "计划任务添加失败,请检查后重新提交."
}

cronjob_del() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2"
	fi

	sed -i "/${cronjob_hash}/d" ${cron_file}
	p_ret $? "计划任务删除成功,请刷新页面查看." "计划任务删除失败,请检查后重新提交."

	#移动日志文件到log目录
	log_files_pattern="${CRON_LOG_DIR}*${cronjob_hash}*"
	mv -f ${log_files_pattern}  ${CRON_OLDLOG_DIR} &>/dev/null &

	#可能有进程在运行,可能有日志文件正在被写入,以后再解决
}

cronjob_enable() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2"
	fi

	sed -i -r "s/^#(.+${cronjob_hash}.+)/\1/" ${cron_file}
	p_ret $? "计划开启成功,请刷新页面查看." "计划开启失败,请检查后重新提交."
}

cronjob_disable() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2"
	fi

	sed -i -r "s/(.+${cronjob_hash}.+)/#\1/" ${cron_file}
	p_ret $? "计划关闭成功,请刷新页面查看." "计划关闭失败,请检查后重新提交."
}

cronjob_runonce() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2"
	fi

	line=$(grep "${cronjob_hash}" ${cron_file})
	run_user=$(echo "${line}"|awk '{print $6}')
	#cmd_line=$(echo "${line}"|grep -o '^.*2>&1'|awk '{$1=$2=$3=$4=$5=$6="";print}'|sed "s/^ \+//")
	#cmd_line=$(echo "${line}"|grep -P -o '/[^0-9]+php.+2>&1'|sed 's/\\//')
	cmd_line=$(echo "${line}"|grep -P -o '/[^0-9]+(php|py).+2>&1'|sed 's/\\//')
	#su ${run_user} -c "nohup ${cmd_line} &" &
	su ${run_user} -c "nohup ${cmd_line} &" &>/dev/null &
	#p_ret $? "已经开始运行,请密切关注日志的变化." "运行失败,请检查后重新提交."
	echo "已经开始运行,请密切关注日志的变化."

}

cronjob_taillog() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2" ; log_files_pattern="${CRON_LOG_DIR}*${cronjob_hash}*"
	fi

	if ls ${log_files_pattern} &>/dev/null ;then
		log_file=$(ls -lht ${log_files_pattern}|head -n 1|awk '{print $NF}')		#按最后写入时间排序,如果新的任务开始了老的任务还在运行...
		last_run_time=$(date '+%Y-%m-%d %H:%M:%S' -d @$(echo "${log_file##*_}"|sed 's/\.log.*$//'))
		last_write_log_time=$(ls -lht --time-style='+%Y-%m-%d %H:%M:%S' ${log_file}|awk '{printf "%s %s",$6,$7}')
		echo -e "上次运行的时刻:${last_run_time}\n最后输出的时刻:${last_write_log_time}\n日志最后几行如下:"
		tail -n 1000 ${log_file}
	else
		echo "没有找到日志文件."
		return 0
	fi
}

cronjob_maillog() {
	if [ -z "$2" ];then
		echo "usage: job_owner cronjob_hash"
		return 1
	else
		job_owner="$1" ; cron_file="${CRON_DIR}cut_${job_owner}"
		cronjob_hash="$2" ; log_files_pattern="${CRON_LOG_DIR}*${cronjob_hash}*" ; oldlog_files_pattern="${CRON_OLDLOG_DIR}*${cronjob_hash}*"
	fi

	if ls ${log_files_pattern} &>/dev/null ;then
		[ "${job_owner}" = 'sohostockning' ] && to_list="${job_owner}@catholic.net.cn" || to_list="${job_owner}@icatholic.net.cn" 
		to_list="${to_list},willwan@icatholic.net.cn"	#for testing
		cron_file="${CRON_DIR}cut_${job_owner}" ; line=$(grep "${cronjob_hash}" ${cron_file})
		domain_name=$(echo "${line}"|grep -o -P -e '#domain_name:[^ |\t|#]+'|sed 's/#domain_name://')
		script=$(echo "${line}"|grep -o -P -e 'scripts/.*\.(php|py)'|sed 's#scripts/##')		#从 scripts/ 之后开始截取
		parameters=$(echo "${line}"|grep -o -P -e '\.(php|py).*[^2][ |\t]?\>'|sed 's/\.php[ |\t]\+//;s/\.py[ |\t]\+//;s/[ |\t]\+>\+$//')
		subject="计划任务日志_${domain_name}"
		content="domain_name: ${domain_name}\nscript: ${script}\nparameters: ${parameters}\n\nall log files attached,the last 10 log files info:"
		#for file in ${log_files_pattern} ; do		#全部日志文件
		#for file in `ls ${log_files_pattern} -alht|head -n 10|awk '{print $NF}'` ; do		#最后写入的10个日志文件
		for file in `ls ${log_files_pattern} |sort -nr|head -n 10` ; do		#最后10次执行的日志文件
			start_time=$(date '+%Y-%m-%d %H:%M:%S' -d @$(echo "${file##*_}"|sed 's/\.log.*$//'))
			end_time=$(ls -lht --time-style='+%Y-%m-%d %H:%M:%S' ${file}|awk '{printf "%s %s",$6,$7}')
			content="${content}\n\n${file}\nstart_time: ${start_time}\nend_time: ${end_time}"
		done
		content=$(echo -e "$content")
		file="/tmp/${cronjob_hash}.tgz"
		tar zcf ${file} ${log_files_pattern} ${oldlog_files_pattern}
		sendemail "$to_list" "$subject" "$content" "$file"
		rm ${file} -f
	else
		echo "没有找到日志文件."
		return 0
	fi
}

#chk_hostname haoyadademo.umaman.com;echo $?
#cronjob_list walong
