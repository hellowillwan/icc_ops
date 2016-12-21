#!/bin/sh
#
# Resyncing the Connector
# https://github.com/mongodb-labs/mongo-connector/wiki/Resyncing%20the%20Connector
# Using mongodump and mongo-connector together. 
# https://github.com/mongodb-labs/mongo-connector/wiki/Usage-with-MongoDB
#

resync_connector() {
	# Parameters
	if [ -z $1 ];then
		echo "Usage: $0 mongo-connector-program-name"
		return 1
	fi

	local program_name="$1"
	local supervisorcfg='/etc/supervisor.conf'
	local DT2="date '+%Y-%m-%d %H:%M:%S'"

	if ! grep -q "program:${program_name}" ${supervisorcfg} &>/dev/null ;then
		echo "program:${program_name} not found in ${supervisorcfg},return."
		return 2
	fi

	# Generate a mongo-connector timestamp file
	# 获取 timestamp file 文件路径 并检查文件是否存在
	ts_file=$(grep -A 5 -P "^[ |\t]*\[program:${program_name}\]" ${supervisorcfg} | grep '^command'|tr ' ' '\n'|grep -e 'oplog.*timestamp')
	if test -f ${ts_file} ;then
		echo "$(eval ${DT2}) OK: ts_file ${ts_file} exists at beginning."
	else
		echo "$(eval ${DT2}) Error: ts_file ${ts_file} not exist at beginning."
	fi
	# 先停掉 supervisor 运行的 mongoconnector 进程 
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	sleep 60
	# 检查进程是否停掉
	if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" | grep -q STOPPED ;then
		echo "$(eval ${DT2}) OK: supervisorctl stoped ${program_name}."
	else
		echo "$(eval ${DT2}) Error: supervisorctl stop ${program_name} fail."
	fi
	# 删除 timestamp file
	rm ${ts_file} -f ; rm ${ts_file} -f ; rm ${ts_file} -f
	# 检查文件是否删除
	if test -f ${ts_file};then
		echo "$(eval ${DT2}) Error: ts_file ${ts_file} still exists after delete."
	else
		echo "$(eval ${DT2}) OK: ts_file ${ts_file} has been deleted."
	fi

	# Run mongo-connector --no-dump.
	/usr/bin/supervisorctl -c ${supervisorcfg} start "${program_name}:${program_name}0" &>/dev/null
	sleep 60
	# 检查进程是否启动
	if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" | grep -q RUNNING;then
		echo "$(eval ${DT2}) OK: supervisorctl ${program_name} started,is RUNNING."
	else
		echo "$(eval ${DT2}) Error: supervisorctl start ${program_name} fail."
	fi

	# Stop mongo-connector right after it starts up.
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	sleep 60
	# 检查进程是否停掉
	if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" | grep -q STOPPED ;then
		echo "$(eval ${DT2}) OK: supervisorctl stoped ${program_name}."
	else
		echo "$(eval ${DT2}) Error: supervisorctl stop ${program_name} fail."
	fi

	# 暂时忽略 connector 状态,总是做数据的重新同步
	#if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" | grep -q STOPPED ;then
		# Dump & restore
		source /usr/local/sbin/sc_mongodb_functions.sh
		for col in $( grep -A 5 -e "program:${program_name}" ${supervisorcfg} \
			| grep '^command'|head -n 1 \
			| tr ' |,' '\n'|grep -i -P '^ICCv1\.' | sed 's/ICCv1.//'
		);do
			col_base64=$(echo -n $col|base64)
			if [ "${program_name}" = 'mongo-connector-prod_iccv1-to-dev_iccv1ro' ];then
				mongo_sync download 2 ICCv1 ${col_base64} ICCv1RO
			elif [ "${program_name}" = 'mongo-connector-prod_iccv1-to-dev_iccv1' ];then
				mongo_sync download 2 ICCv1 ${col_base64}
			else
				:
			fi
		done

		# Start mongo-connector 
		/usr/bin/supervisorctl -c ${supervisorcfg} start "${program_name}:${program_name}0"
		# 检查进程是否启动
		if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" | grep -q RUNNING;then
			echo "$(eval ${DT2}) OK: supervisorctl ${program_name} started,is RUNNING."
		else
			echo "$(eval ${DT2}) Error: supervisorctl start ${program_name} fail."
		fi
	#fi
}

# 发送邮件
sendemail () {
	local SNDEMAIL_LOG='/tmp/sendemail.log'
	if [ -z "$3" ] ;then
		echo -e "\n$(date) : parameters missing." >> $SNDEMAIL_LOG 
		return 1
	fi
	
	local to_list=$1
	local subject=$2
	local content=$3
	if [ -z "$4" ];then
		local attachment=''
	else
		local attachment=" -F ${4} "
	fi
	#echo -e "\n$(date)\n${to_list}\n${subject}\n${content}" >> $SNDEMAIL_LOG
	echo -e "\n$(date)\n${to_list}\n${subject}" >> $SNDEMAIL_LOG
	#/usr/local/sbin/sendemail.py -s smtp.catholic.net.cn -f serveroperations@catholic.net.cn -u serveroperations@catholic.net.cn -p zd0nWmAkDH_tUwFl1wr \
	/usr/local/sbin/sendemail.py -s smtp.icatholic.net.cn -f system.monitor@icatholic.net.cn -u system.monitor@icatholic.net.cn -p abc123 \
		-t "$to_list" \
		-S "$subject" \
		-m "$content" ${attachment} 2>&1 | tee -a $SNDEMAIL_LOG 2>&1
	local ret=$?
	if [ $ret -eq 0 ] ;then
		echo "$(date) : mail sent." | tee -a $SNDEMAIL_LOG
	else
		echo "$(date) : send email fail." | tee -a $SNDEMAIL_LOG
	fi
}

report() {
# 发邮件
	local localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
	local to_list='merryjian@icatholic.net.cn,linwaylin@icatholic.net.cn,xiaomingyong@icatholic.net.cn'
	local to_list="${to_list},dkding@icatholic.net.cn,willwan@icatholic.net.cn"
	#local to_list='willwan@icatholic.net.cn'
	local subject="Syncing Data to ICCv1RO has completed"
	local content="$subject. check attachment for more details."
	local file="/var/log/resync_mongoconnector.log"
	sendemail "$to_list" "$subject" "$content" "$file" &>/dev/null
}

resync_connector mongo-connector-prod_iccv1-to-dev_iccv1
resync_connector mongo-connector-prod_iccv1-to-dev_iccv1ro
report

