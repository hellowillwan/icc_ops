#!/bin/sh
#
# 脚本功能:自动更新 weshop 的代码到多个微商项目
#

# 变量
#
weshop_enabled_hosts='/var/lib/weshop_enabled_hosts'	# 开启微商功能的项目编号列表,一行一个
weshop_filelist='/var/lib/weshop_filelist'		# 需要更新的微商项目文件/目录,一行一个
webroot='/home/webs/dev'				# 内网dev环境(dev.umaman.xyz域名)的 WebRoot目录
weshop_dir="${webroot}/weshop"				# 内网dev环境(dev.umaman.xyz域名)的 weshop 项目目录
svncmd='/usr/bin/svn '
svnoptions=' --config-dir /var/lib/.subversion --no-auth-cache --non-interactive --username young --password 123456 '
rsynccmd="/bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' /usr/bin/rsync -vzrpt --blocking-io --exclude='.svn' --exclude='.git' --exclude='*.log' --exclude='.buildpath' --exclude='.project' --exclude='.gitignore' --exclude='/cache/*' --exclude='/logs/*' "
rsyncserver='211.152.60.33'

# 函数
#
# 提交代码文件变更到项目SVN仓库
svncommit() {
	:
}

# 更新 weshop 代码到各个微商项目并提交到项目SVN仓库,操作:更新,覆盖,并提交
update_to_all_projects() {
	# 默认更新到所有开启微商的项目,可以接受参数只更新到指定项目
	if [ -z "$1" ];then
		projects=$(cat ${weshop_enabled_hosts})
	else
		projects="$1"
	fi

	for project in ${projects};do
		echo "$(date) update to ${project} begin."
		if [ ! -d ${webroot}/${project} ] ;then
			echo "dir: ${webroot}/${project} not exits."
			continue
		fi
		for item in $(cat ${weshop_filelist});do
			if [ ! -d ${weshop_dir}${item}  -a ! -f ${weshop_dir}${item} ] ;then
				echo "item: ${weshop_dir}${item} not exits."
				continue
			fi
			${svncmd} ${svnoptions} up ${weshop_dir}${item}
			# 检查 item 的父目录
			if [ -d ${webroot}/${project}${item%/*}/ ];then
				${svncmd} ${svnoptions} up ${webroot}/${project}${item%/*}/
			else
				mkdir -p ${webroot}/${project}${item%/*}/ #&>/dev/null
				${svncmd} ${svnoptions} --force add ${webroot}/${project}${item%/*}/
			fi
			# 同步 item
			rsync -avc --exclude='.svn' ${weshop_dir}${item} ${webroot}/${project}${item%/*}/
			# 提交 item
			${svncmd} ${svnoptions} --force add ${webroot}/${project}${item}
			${svncmd} ${svnoptions} commit -m"update by weshop ci_tool ${message}" ${webroot}/${project}${item}
			echo
		done
		echo "$(date) update to ${project} end."
		echo
		echo
	done
}

# 为各个项目编译打包(webpack?),并提交到项目SVN仓库
pack() {
	# 默认更新到所有开启微商的项目,可以接受参数只更新到指定项目
	if [ -z "$1" ];then
		projects=$(cat ${weshop_enabled_hosts})
	else
		projects="$1"
	fi

	for project in ${projects};do
		workingdir="${webroot}/${project}/public/html/m"
		echo $workingdir;continue
		if [ ! -d ${workingdir} ];then
			echo "dir: ${workingdir} not exits."
			continue
		fi
		cd ${workingdir}
		${svncmd} ${svnoptions} up
		npm i
		npm run build2
		${svncmd} ${svnoptions} --force add ${workingdir}/dist/images
		${svncmd} ${svnoptions} --force add ${workingdir}/dist/js/*.js
		${svncmd} ${svnoptions} commit -m"update by weshop ci_tool ${message}" ${workingdir}/dist
	done
}

# 检查指定workingdir的版本完整性
checkintegrity() {
	if [ -z "$2" ];then
		echo 'uage: checkintegrity workingdir expectversion'
		return 2
	else
		local dir="$1"
		local expectversion="$2"
	fi
	local realversion=$(${svncmd} ${svnoptions} info ${dir}|awk '/^Revision/{print $2}')
	local diffnumber=$(${svncmd} ${svnoptions} st ${dir} 2>&1|wc -l)
	if [ $realversion -eq $expectversion -a $diffnumber -eq 0 ];then
		return 0
	else
		#echo realversion: $realversion , diffnumber: $diffnumber
		return 1
	fi
}

# 签出指定版本,并确保完整性
checkoutver() {
	if [ -z "$2" ];then
		echo 'uage: checkoutver project_code neededversion'
		return
	else
		local projectcode="$1"
		local neededversion="$2"
	fi
	local webroot='/home/webs/test';mkdir -p ${webroot} &>/dev/null	# 目前只有 test 环境需要签出指定版本
	local workingdir="${webroot}/${projectcode}"
	local svnurl="https://192.168.5.40/svn/${projectcode}/"
	# 检查完整性 直到满足要求
	until checkintegrity ${workingdir} ${neededversion} ; do
		#完整性检查失败,删除有变更的文件,重新签出
		${svncmd} ${svnoptions} st ${workingdir}|awk '{print $2}'|xargs rm -rf
		${svncmd} ${svnoptions} checkout -r ${neededversion} ${svnurl} ${workingdir}
	done
	# 签出后打印版本信息
	${svncmd} ${svnoptions} info ${workingdir}
	#${svncmd} ${svnoptions} st ${workingdir}
	#echo ${rsynccmd} ${webroot}/weshop/ ${rsyncserver}::webs/weshopdemo/
}

# 发布各个项目的编译打包后的文件( dev -> demo,sync_individually )
dev2demo() {
	for project in p r o j c t s;do
		rsync pack 211.152.60.33:${webroot}/${project}demo/path/
		# $RSYNCCMD '$item' '${RSYNCSERVER}::${RSYNCMODULE}/${dst_item}
		sync_individually ${project}demo
	done
}

# 同步各个项目的编译打包后的文件( demo -> prod,sync_individually )
demo2prod() {
	for project in p r o j c t s;do
		rsync pack 211.152.60.33:${webroot}/${project}demo/path/
		# echo $commonworker_key sync_demo_prod $item $dst_item |/usr/bin/gearman -h 211.152.60.33 -f CommonWorker_{$node_ips['host200']}
		sync_individually ${project}
	done
}
