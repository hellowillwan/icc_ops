# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		svn_checkout project_code
#
#

SVNCMD='/usr/bin/svn '
SVNOPTIONS=' --config-dir /var/.subversion --no-auth-cache --non-interactive --username young --password 123456 '
WORKINGCOPYROOT='/home/webs/dev/'
SVNURL='https://192.168.5.40/svn/'

svn_checkout() {
	if [ -z "$1" ];then
		echo "usage: $0 project_code"
		return 1
	fi
	local project_code="$1"
	local logfile="/var/log/svn-${project_code}.log"
	local project_workingcopypath="${WORKINGCOPYROOT}${project_code}"
	local project_svnurl="${SVNURL}${project_code}"
	#local autotest_api="http://192.168.5.41:8888/cutapi?project_id=${project_code}"

	# 更新代码前通知测试接口
	#fetch_url "${autotest_api}&type=preupdate"

	echo ++++++++++++++++++++++++++ >> ${logfile} 2>&1
	date >> ${logfile} 2>&1
	local svn_co_result=$( ${SVNCMD} checkout ${project_svnurl} ${project_workingcopypath} ${SVNOPTIONS} 2>&1;echo $? )
	local ret=$(echo ${svn_co_result} | awk '{print $NF}' )	# svn checkout 命令的返回码
	echo ${svn_co_result} >> ${logfile} 2>&1
	date >> ${logfile} 2>&1
	echo -e "\n\n" >> ${logfile} 2>&1

	# 根据返回码做一些处理比如邮件报警
 
	# 更新代码后通知测试接口
	#fetch_url "${autotest_api}&type=updated"

	# weshop 项目更新 自动更新其他相关项目
	#if [ ${project_code} = 'weshop' ];then
	#	for item in $(cat /var/lib/weshop_filelist);do
	#		if echo ${svn_co_result} | grep -q -e ${item#/} ;then
	#			. /usr/local/sbin/WeshopCI.sh ;update_to_all_projects >> ${logfile} 2>&1
	#			break
	#		fi
	#	done
	#fi

	echo ++++++++++++++++++++++++++ >> ${logfile} 2>&1
	return $ret
}

check_projectsworkingcopy() {
	for project_code in `cat /var/lib/weshop_php_enabled_projects | grep -v -e '__ALL_PROJECTS__'`;do
		local project_workingcopypath="${WORKINGCOPYROOT}${project_code}"
		local project_svnurl="${SVNURL}${project_code}"
		local result_lines=$( ${SVNCMD} st ${project_workingcopypath} ${SVNOPTIONS} 2>/dev/null | wc -l )	# svn 状态正,常情况下是没有输出的
		echo check project: $project_code workingcopy: $project_workingcopypath svn_st_result_lines: $result_lines
		# 如果 项目 working copy 目录 的 svn 状态不对,则重新签出一份
		if [ $result_lines -ge 1 ];then 
			local postfix=$RANDOM
			echo ${SVNCMD} co ${project_svnurl} ${project_workingcopypath}_${postfix} ${SVNOPTIONS}
			${SVNCMD} co ${project_svnurl} ${project_workingcopypath}_${postfix} ${SVNOPTIONS} &>/dev/null
			echo "rm $project_workingcopypath -rf"
			test -d $project_workingcopypath && rm $project_workingcopypath -rf
			echo "mv ${project_workingcopypath}_${postfix} ${project_workingcopypath}"
			mv ${project_workingcopypath}2 ${project_workingcopypath}
		fi
		# 再次更新(可能会和 SVN Commit Hook 更新操作发生死锁,注意执行的时间)并检查状态
		echo "svn up ${project_workingcopypath}" 
		${SVNCMD} up ${project_workingcopypath} ${SVNOPTIONS}
		echo "svn st ${project_workingcopypath}" 
		${SVNCMD} st ${project_workingcopypath} ${SVNOPTIONS}
		echo done
		echo
	done
}


