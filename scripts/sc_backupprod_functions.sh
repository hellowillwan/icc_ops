# -*-Shell-script-*-
#
# functions		This file contains functions to be used by Commonworker 
# usage			backupprod haoyadatest
#
#


backupprod() {
	if [ -z "$1" ];then
		echo "usage: ${FUNCNAME[0]} project_code"
		return 1
	else
		local project="$1"
	fi

	# 日志文件
	local log_file="/var/log/backupprod_${project}.log"

	# 加锁备份生产环境代码
	local lock_file="/var/lib/${project}.lock"
	# 如果有lock file 等待 直到其他操作解锁
	while test -f ${lock_file} ;do
		sleep 1
	done

	# 加锁
	date | tee -a $log_file >> $lock_file
	echo "begin backup $project" >> $log_file
	# 备份 ( Prod ---> Bak1 ---> Bak2 ---> Bak3 )
	local WEBROOT='/home/webs/'
	local BAKROOT='/home/baks/'
	local Prod="${WEBROOT}${project}" ; test -d $Prod || mkdir -p $Prod &>/dev/null
	local Bak1="${BAKROOT}${project}_Bak1" ; test -d $Bak1 || mkdir -p $Bak1 &>/dev/null
	local Bak2="${BAKROOT}${project}_Bak2" ; test -d $Bak2 || mkdir -p $Bak2 &>/dev/null
	local Bak3="${BAKROOT}${project}_Bak3" ; test -d $Bak3 || mkdir -p $Bak3 &>/dev/null
	# diff -q -r $Bak2/ $Bak3/ &>/dev/null || \		# 太慢了
		rsync -a --delete $Bak2/ $Bak3/ &>/dev/null
	# diff -q -r $Bak1/ $Bak2/ &>/dev/null || \
		rsync -a --delete $Bak1/ $Bak2/ &>/dev/null
	# diff -q -r $Prod/ $Bak1/ &>/dev/null || \
		rsync -a --delete $Prod/ $Bak1/ &>/dev/null

	# 备份完清除 Prod 版本号文件
	#local VerFile="${Prod}/public/__VERSION__.txt"
	#test -f ${VerFile} && rm -f ${VerFile} &>/dev/null

	# 日志
	date >> $log_file
	echo -e "done\n\n" >> $log_file

	# 备份完解锁
	test -f ${lock_file} && rm ${lock_file} -f
}
