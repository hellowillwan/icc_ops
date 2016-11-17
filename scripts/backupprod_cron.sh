#!/bin/bash
#
#	备份生产环境代码,有版本文件并且最近一次发布是在30分钟以前,即触发备份
#

WEBROOT='/home/webs/'
time_threshold=$((120*60))	# 最近一次同步操作距离现在的时间差,太短则表示可能还在调试,不要备份

# 扫描所有项目的正式环境代码 通过版本文件检查最近一次同步操作的时间
for project in $( ls /home/webs/ \
	| grep -v -e '^common$' -e 'ZendFramework' \
	-e 'demo$' -e '\.mv$'  -e 'delete$' -e 'backup$' )
	#-e 'demo$' -e '\.mv$'  -e 'delete$' -e 'backup$' |grep haoyadatest )
do
	# 检查项目是否有版本文件,没有则忽略 (久没有同步操作了)
	echo "$(date) begin backup $project"
	VerFile="${WEBROOT}${project}/__VERSION__.txt"
	if [ ! -f $VerFile ];then
		echo -e "$(date) $project has no ${VerFile},bypass.\n\n"
		continue
	fi
	# 获取最近一次同步操作的时间
	dt_str=$(tail -n 1 $VerFile)
	time_of_sync_demo_prod=$(date -d "$dt_str" '+%s' 2>/dev/null)
	# 检查取到的时间是否是时间戳,不是则忽略
	if [[ "$time_of_sync_demo_prod" =~ ^[0-9]+$ ]];then
		echo -e "$(date) $project ${VerFile} time_of_sync_demo_prod found: $time_of_sync_demo_prod"
		# 继续检查 最近一次同步操作的时间 距离当前时间是否大于等于阀值
		time_diff=$(($(date +%s)-${time_of_sync_demo_prod}))
		if [ $time_diff -ge $time_threshold ];then
			# 检查当前生产环境 和 Bak1 是否相同
			VerFile_Bak1="/home/baks/${project}_Bak1/__VERSION__.txt"
			if diff -q $VerFile $VerFile_Bak1 &>/dev/null ;then
				# 版本文件相同 说明当前生产环境已经备份到 Bak1了 不用再次备份
				echo -e "$(date) $project ${VerFile} ${VerFile_Bak1} is the same,bypass.\n\n"
				continue
			else
				# 执行备份
				localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
				echo $localkey backupprod ${project} | /usr/bin/gearman -h 10.0.0.200 -f CommonWorker_10.0.0.200 -b
				echo -e "$(date) $project backup job sent,last line of ${VerFile}: $(tail -n 1 ${VerFile}).\n\n"
			fi
		else
			# 最近一次同步操作的时间 距离当前时间 小于时间阀值,不做备份
			echo -e "$(date) $project ${VerFile} time_of_sync_demo_prod less than $time_threshold sec,bypass.\n\n"
			continue
		fi
	else
		# 版本文件存在,但取到的时间戳不是对,可能有同步操作正在进行中,不做备份
		echo -e "$(date) $project ${VerFile} time_of_sync_demo_prod not found,bypass.\n\n"
		continue
	fi
done 

