#!/bin/sh
#
# 脚本功能:自动更新 weshop 的代码到多个微商项目
#

# 变量
#
weshop_enabled_hosts='/var/lib/weshop_enabled_hosts'	# 开启微商功能的项目编号列表,一行一个
weshop_filelist='/var/lib/weshop_filelist'		# 需要更新的微商项目文件/目录,一行一个
weshop_ui_enabled_hosts='/var/lib/weshop_ui_enabled_hosts'	# 开启微商 ui 的项目编号列表,一行一个
weshop_ui_filelist='/var/lib/weshop_ui_filelist'		# 需要更新的微商 ui 文件/目录,一行一个
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

# 同步线上生产环境 weshop 前端代码到 dev环境开启微商的具体项目
pull_weshop_prod_for_child_projects() {
	# 默认更新到所有开启微商的项目,可以接受参数只更新到指定项目
	if [ -z "$1" ];then
		local projects=$(cat ${weshop_ui_enabled_hosts})
	else
		local projects="$1"
	fi

	for project_code in ${projects} ;do
		for dir in $(cat $weshop_ui_filelist);do
			echo "pull_weshop_prod_for_child_projects ${project_code} $dir"
			if test -d ${webroot}/${project_code}${dir} ;then 
				# 如果该项目 存在此目录,则排除 diff 目录进行同步
				local src_dir="web/weshop${dir}/"
				#local src_dir="${webroot}/weshop/${dir}/"
				local dst_dir="${webroot}/${project_code}${dir}/"
				is_exclude_diff=" --exclude='diff' "
			else
				# 如果该项目 不存在此目录,则直接进行同步
				local src_dir="web/weshop${dir}"
				#local src_dir="${webroot}/weshop/${dir}"
				local dst_dir="${webroot}/${project_code}${dir}"
				local dst_dir="${dst_dir%/*}/"
				# 确保父目录存在
				test -d ${dst_dir} || mkdir -p ${dst_dir}
				is_exclude_diff=' '
			fi
			/bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' \
			/usr/bin/rsync \
			-vzrpt \
			--blocking-io \
			--exclude='svn' ${is_exclude_diff} \
			211.152.60.33::${src_dir} ${dst_dir}	# 从线上正式环境拉取
			#${src_dir} ${dst_dir}
		done
	done
}

# 为各个项目编译打包(webpack m2),并提交到项目SVN仓库
pack_ui_and_commit() {
	# 只更新到指定项目
	if [ -z "$1" ];then
		echo no project_code
		return 1
	else
		local projects="$1"
	fi

	for project in ${projects};do
		for dir in $(cat $weshop_ui_filelist);do
			workingdir="${webroot}/${project}${dir}/"
			echo "pack_ui_and_commit ${workingdir}"
			if [ ! -d ${workingdir} ];then
				echo "dir: ${workingdir} not exits."
				continue
			fi
	
			# 删除项目 ui 目录下的 node_modules,并链接到全局目录
			rm ${workingdir}/node_modules -rf
			ln -s /var/lib/node_modules ${workingdir}
			# 更新
			# ${svncmd} ${svnoptions} up ${workingdir}
			# 打包
			( cd ${workingdir} ; gulp pro )
			
			# 删除项目 ui 目录下的 node_modules 准备提交 m2 到具体项目 svn 库
			rm ${workingdir}/node_modules -rf
			${svncmd} ${svnoptions} --force add ${workingdir}/ 2>&1
			# ${svncmd} ${svnoptions} --force add ${workingdir}/dist/images
			# ${svncmd} ${svnoptions} --force add ${workingdir}/dist/js/*.js
			# ${svncmd} ${svnoptions} commit -m"update by weshop ci_tool ${message}" ${workingdir}/dist
			${svncmd} ${svnoptions} commit -m"update by weshop ci_tool ${message}" ${workingdir}/ 2>&1
		done
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
	# 只发布指定项目
	if [ -z "$1" ];then
		echo no project_code
		return 1
	else
		local projects="$1"
	fi

	# 指定目录
	for project in ${projects} ;do
		for dir in $(cat $weshop_ui_filelist);do
			# 发布到demo
			/bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' \
			/usr/bin/rsync \
			-vzrpt \
			--blocking-io \
			--exclude='svn' \
			${webroot}/${project}${dir} 211.152.60.33::web/${project}demo${dir%/*}/
			# 分发到所有节点
			localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
			echo $localkey sync_a_project_code ${project}demo | /usr/bin/gearman -h 211.152.60.33 -f CommonWorker_10.0.0.200
		done
	done
}

# 同步各个项目的编译打包后的文件( demo -> prod,sync_individually )
demo2prod() {
	for project in p r o j c t s;do
		rsync pack 211.152.60.33:${webroot}/${project}demo/path/
		# echo $localkey sync_demo_prod $item $dst_item |/usr/bin/gearman -h 211.152.60.33 -f CommonWorker_{$node_ips['host200']}
		sync_individually ${project}
	done
}

weshop_sync_prod() {
	# 默认更新到所有开启微商 ui 的项目,可以接受参数只更新到指定项目
	if [ -z "$1" ];then
		local PROJECTS=$(cat ${weshop_ui_enabled_hosts})
	else
		local PROJECTS="$1"
	fi

	for project in ${PROJECTS} ;do
		echo "$(date) 项目: $project"
		echo -en "从线上 weshop 正式环境拉取 ui 相关目录\n\t"
			pull_weshop_prod_for_child_projects $project 2>&1 #|tail -n 1
		echo -en "打包 ui 目录 并提交到项目 $project SVN\n\t"
			pack_ui_and_commit $project 2>&1 #|tail -n 1
		echo -en "发布项目 $project 到 demo 环境\n\t"
			dev2demo $project 2>&1 |tail -n 1
		echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	done
}


# 发布到demo
# /bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' /usr/bin/rsync  -vzrptn --blocking-io --exclude='svn' /home/webs/dev/140821fg0374/public/html/m2/ 211.152.60.33::web/140821fg0374demo/public/html/m2/

# 拉取m2
# /bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' /usr/bin/rsync -vzrptn --blocking-io --exclude='svn' --exclude='diff' 211.152.60.33::web/weshop/public/html/m2/ /home/webs/dev/140821fg0374/public/html/m2/

# 手工执行
# . /usr/local/sbin/WeshopCI.sh ; pack_ui_and_commit 140821fg0374
