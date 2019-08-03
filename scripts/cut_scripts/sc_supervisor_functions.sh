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

# 获取某个项目的命令行
get_cmdline() {
	if [ -z "$1" ] ;then
		echo "Action parameter missing."
		return 0
	else
		program_name="$1"
		grep -A 5 -e "program:${program_name}" $SUPERVISORCFG|grep '^command'|head -n 1
	fi
}

# 设定某个项目的命令行
set_cmdline() {
	if [ -z "$2" ] ;then
		echo "Action parameter missing."
		return 0
	else
		program_name="$1"
		new_cmdline="$2"
		line_number=$(grep -n -A 5 -e "program:${program_name}" $SUPERVISORCFG|grep -P '^[0-9]+-command'|head -n 1|awk -F'-' '{print $1}')
		# 编辑配置文件
		#sed -n "${line_number}p" $SUPERVISORCFG
		sed -i "${line_number}c${new_cmdline}" $SUPERVISORCFG	# abc=wl;seq 3|sed "2c\\$abc"
		# 更新配置,使用新的参数启动进程
		${SUPERVISORCTL} -c ${SUPERVISORCFG} update ${program_name} 2>&1
	fi
}

# 获取mongo-connector项目的命令行参数---集合列表,返回格式:空格间隔的库名.集合名
list_collections() {
	if [ -z "$1" ] ;then
		echo "Action parameter missing."
		return 1
	else
		if [ "$1" = 'download' ];then
			program_name=mongo-connector-prod_iccv1-to-dev_iccv1ro
			get_cmdline ${program_name} |tr ' |,' '\n'|grep -i -P '^(ICCv1\.)'|tr '\n' ' '
		elif [ "$1" = 'upload' ];then
			program_name=mongo-connector-bda_from_office
			get_cmdline ${program_name} |tr ' |,' '\n'|grep -i -P '^(bda\.)'|tr '\n' ' '
		else
			echo "no program_name found for ${1},exit"
			return 2
		fi
	fi
}

# 添加mongo-connector项目的命令行参数---集合 新增 集合对应关系 -n ... -g ...
add_collections() {
	if [ -z "$2" ] ;then
		echo "Action parameter missing."
		return 1
	else
		if [ "$1" = 'download' ];then
			program_name=mongo-connector-prod_iccv1-to-dev_iccv1ro
			#anchor_str='ICCv1.idatabase_logs'
		elif [ "$1" = 'upload' ];then
			program_name=mongo-connector-bda_from_office
			anchor_str='bda.idatabase_logs'
		else
			echo "no program_name found for ${1},exit"
			return 2
		fi
		local direction="$1"
		local input_colls="$2"	# 用户输入的集合列表 格式是 db.coll,db.coll
	fi

	# 处理输入的集合列表,默认格式:逗号间隔的库名.集合名(可能有多个),如果包含已经在列表中的集合则去掉
	local new_collections=''	# 准备添加的集合
	local coll_list="$(list_collections $direction | tr ' ' '\n')"	# 当前集合列表
	for coll in $(echo $input_colls | tr ',' ' ') ; do
		echo "$coll_list" | grep -q -e "^${coll}\$" || new_collections="${new_collections},${coll}"
	done
	local new_collections=$(echo ${new_collections}|sed 's/^,//;s/,$//')
	if [ -z "${new_collections}" ];then
		return
	fi

	# 编辑新的命令行 保存
	if [ "$direction" = 'download' ] ;then
		new_collections_dst=$(echo $new_collections | sed 's/ICCv1\./ICCv1RO\./g')
		new_cmdline=$(get_cmdline ${program_name} | sed "s/\( -n \)/\1${new_collections},/;s/\( -g \)/\1${new_collections_dst},/")
	elif [ "$direction" = 'upload' ];then
		new_cmdline=$(get_cmdline ${program_name} | sed "s/\(${anchor_str}\)/\1,${new_collections}/")
	fi
	set_cmdline ${program_name} "$new_cmdline"
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
			proc_name="$2"
			log_file=$(grep -A 20 "program:${proc_name}" ${SUPERVISORCFG} |grep -P -e '^[ |\t]*stdout_logfile='|head -n 1|awk -F'=' '{print $2}')
			tail -c 32768 ${log_file}
			if [ "$?" -eq 0 ];then
				echo "命令执行成功."
			else
				echo "命令执行失败."
			fi
			return
			#
			#proc_name="-32768 ${2}:${2}0"
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
