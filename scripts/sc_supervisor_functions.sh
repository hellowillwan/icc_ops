# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		supervisor_config [get|set]
# usage		supervisor_control
# usage		supervisor_status
#
#

#
SUPERVISORCTL='/usr/bin/supervisorctl'
SUPERVISORCFG='/etc/supervisor.conf'
DT2="date '+%Y-%m-%d_%H-%M-%S'"

proc_maillog() {
	if [ -z "$2" ];then
		echo "usage: proc_name email_addr"
		return 1
	else
		proc_name="$1"
		to_list="$2"
	fi

	log_file=$(
		grep -A 25 -e "program:${proc_name}" ${SUPERVISORCFG} |grep stdout_logfile |head -n 1 |awk -F'=' '{print $2}'
	)
	#log_files_pattern="${log_file}*"

	command=$(
		grep -A 25 -e "program:${proc_name}" ${SUPERVISORCFG} |grep command |head -n 1 |awk -F'=' '{print $2}'
	)

	if ls ${log_file} &>/dev/null ;then
		to_list="${to_list},willwan@icatholic.net.cn"	#for testing
		subject="Supervisor进程日志_${proc_name}"
		content="program: ${proc_name}\ncommand: ${command}\n\nthe last 2 log files attached."
		content=$(echo -e "$content")
		file="/tmp/supervisor_${proc_name}_$(eval $DT2).tgz"
		tar zcf ${file} ${log_file} ${log_file}.1 &>/dev/null
		sendemail "$to_list" "$subject" "$content" "$file"
		rm ${file} -f
	else
		echo "没有找到日志文件."
		return 0
	fi
}

supervisor_config() {
	#SUPERVISORCFG='/tmp/sp_cfg_text.txt'
	if [ -z "$1" ] ;then
		echo "Action parameter missing."
		return 0
	else
		if [ "$1" = "get" ];then
			#grep -v -e '^[ |\t]*$' -e '^[ |\t]*;' /etc/supervisor.conf|sed "s/;.*$//;s/ *$//"
			cat /etc/supervisor.conf
		elif [ "$1" = "set" -a -n "$2" ];then
			#backup
			cp -a $SUPERVISORCFG ${SUPERVISORCFG}_$(date +%s_%N)
			echo "$2"|base64 -d > $SUPERVISORCFG 
			if [ "$?" -eq 0 ];then
				echo "配置保存成功,当前配置文件:"
			else
				echo "配置保存失败,当前配置文件:"
			fi
				ls -lht $SUPERVISORCFG
				echo "最后10行:"
				tail $SUPERVISORCFG
		else
			echo "Bad action parameter or cfg_text missing."
			return 0
		fi
	fi
}

#processors status
supervisor_status() {
	for proc_name in $(${SUPERVISORCTL} -c ${SUPERVISORCFG} status | awk '{gsub(":.*","",$1);print $1}'|sort|uniq);do
		proc_status=$(${SUPERVISORCTL} -c ${SUPERVISORCFG} status|grep -e "^${proc_name}[:| ]"|awk '{print $2}'|sort|uniq -c|sed "s/^[ |\t]*//"|tr '\n' ' ')
		printf "%s:%s\n" "$proc_name" "$proc_status"
	done
}

#control processors
supervisor_control() {
	if [ -z "$1" ];then
		echo "parameter missing,usage:sp_cmd [proc_name]"
		return 1
	else
		sp_cmd="$1"
	fi

	if [ -z "$2" ];then
		# update,reload
		${SUPERVISORCTL} -c ${SUPERVISORCFG} ${sp_cmd} 2>&1
	else
		# stop,restart,tail,maillog
		if [ $sp_cmd = 'tail' ];then
			# 查看日志
			# supervisorctl tail命令遇到日志文件编码有问题时会报RPC错误,如果有必要可以从配置文件里获取到日志文件路径后直接tail
			#
			#proc_name="$2"
			#log_file=$(grep -A 20 "program:${proc_name}" ${SUPERVISORCFG} |grep -P -e '^[ |\t]*stdout_logfile='|head -n 1|awk -F'=' '{print $2}')
			#tail -n 1600 ${log_file}
			#
			proc_name="-32768 ${2}:${2}0"
		elif [ $sp_cmd = 'maillog' ];then
			#Email日志
			proc_name="${2}"
			if [ -z "$3" ];then
				echo "parameter missing,usage:maillog proc_name email_addr."
				return 1
			else
				email_addr="${3}"
				proc_maillog "$proc_name" "$email_addr"
				return 1
			fi
		else
			# 其他supervisorctl控制命令
			proc_name="${2}:*"
		fi
		${SUPERVISORCTL} -c ${SUPERVISORCFG} ${sp_cmd} "${proc_name}" 2>&1
	fi

	if [ "$?" -eq 0 ];then
		echo "命令执行成功."
	else
		echo "命令执行失败."
	fi
}
