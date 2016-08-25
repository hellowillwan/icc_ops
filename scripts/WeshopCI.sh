#!/bin/sh
#
# 脚本功能:自动更新 weshop 的代码到多个微商项目
#

# 变量
#
weshop_enabled_hosts='/var/lib/weshop_enabled_hosts'	# 开启微商功能的项目编号列表,一行一个
weshop_filelist='/var/lib/weshop_filelist'		# 需要更新的微商项目文件/目录,一行一个
weshop_ui_enabled_projects='/var/lib/weshop_ui_enabled_projects'	# 开启微商 ui 的项目编号列表,一行一个
weshop_ui_filelist='/var/lib/weshop_ui_filelist'		# 需要更新的微商 ui 文件/目录,一行一个
weshop_php_enabled_projects='/var/lib/weshop_php_enabled_projects'	# 开启微商 php 的项目编号列表,一行一个
weshop_php_filelist='/var/lib/weshop_php_filelist'		# 需要更新的微商 php 文件/目录,一行一个
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
				${svncmd} ${svnoptions} add --force ${webroot}/${project}${item%/*}/
			fi
			# 同步 item
			rsync -avc --exclude='.svn' ${weshop_dir}${item} ${webroot}/${project}${item%/*}/
			# 提交 item
			${svncmd} ${svnoptions} add --force ${webroot}/${project}${item}
			${svncmd} ${svnoptions} commit -m"update by weshop ci_tool ${message}" ${webroot}/${project}${item}
			echo
		done
		echo "$(date) update to ${project} end."
		echo
		echo
	done
}

# 从线上 weshop 生产环境 拉取 前|后端代码 到 开启微商的子项目
pull_weshop_prod_for_child_projects() {
	if [ -z "$2" ];then
		return 1
	fi
	local type="$1"
	local projects="$2"
	if [ "${type}" = 'ui' ];then
		#local projects="$( cat ${weshop_ui_enabled_projects} )"
		local project_list=${weshop_ui_enabled_projects}
		local flists="$( cat ${weshop_ui_filelist} )"
	elif [ "${type}" = 'php' ];then
		#local projects="$( cat ${weshop_php_enabled_projects} )"
		local project_list=${weshop_php_enabled_projects}
		local flists="$( cat ${weshop_php_filelist} )"
	else
		return 1
	fi

	for project_code in ${projects} ;do
		if ! grep -q -i -e "^${project_code}\$" $project_list &>/dev/null;then echo $project_code not in $project_list ;continue ;fi # 检查一下
		for item in ${flists};do
			echo "pull_weshop_prod_for_child_projects ${project_code} $item"
			# 确定排除参数
			if [ "${type}" = 'ui' -a -d ${webroot}/${project_code}${item} ] ;then
				# 如果该项目 存在此目录 并且 是操作 ui 相关目录,则排除 diff 目录进行同步
				#local is_exclude_diff=" --exclude='diff' "  # bad substitution
				local is_exclude_diff=' --exclude=diff '
			else
				# 如果该项目 不存在此目录 或 操作 php 相关目录,则直接进行同步
				unset is_exclude_diff
			fi

			# 确定 源/目的录
			local src_item="web/weshop${item}"
			local dst_item="${webroot}/${project_code}${item%/*}/"

			# 确保父目录存在
			test -d ${dst_item} || mkitem -p ${dst_item}

			# 拉取操作
			/bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' \
			/usr/bin/rsync \
			-vzrpt \
			--blocking-io \
			--exclude='.svn' ${is_exclude_diff} \
			211.152.60.33::${src_item} ${dst_item} 2>&1
			echo
		done
	done
}

# 为各个项目编译打包(webpack m2),并提交到项目SVN仓库
pack_and_commit_svn() {
	if [ -z "$2" ];then
		return 1
	fi
	local type="$1"
	local projects="$2"
	if [ "${type}" = 'ui' ];then
		#local projects="$( cat ${weshop_ui_enabled_projects} )"
		local project_list=${weshop_ui_enabled_projects}
		local flists="$( cat ${weshop_ui_filelist} )"
	elif [ "${type}" = 'php' ];then
		#local projects="$( cat ${weshop_php_enabled_projects} )"
		local project_list=${weshop_php_enabled_projects}
		local flists="$( cat ${weshop_php_filelist} )"
	else
		return 1
	fi

	for project_code in ${projects};do
		if ! grep -q -i -e "^${project_code}\$" $project_list &>/dev/null;then echo $project_code not in $project_list ;continue ;fi # 检查一下
		for item in ${flists};do
			local workingdir="${webroot}/${project_code}${item}"
			# 打包前端文件
			if [ "${type}" = 'ui' ];then
				echo "pack_ui ${workingdir}"
				if [ ! -d ${workingdir} ];then
					echo "dir: ${workingdir} not exits."
					continue
				fi
		
				# 删除项目 ui 目录下的 node_modules,并链接到全局目录
				rm ${workingdir}/node_modules -rf
				ln -s /var/lib/node_modules ${workingdir}/
				# 更新
				# ${svncmd} ${svnoptions} up ${workingdir}
				# 打包
				( cd ${workingdir} ; gulp pro )
				echo
				
				# 删除项目 ui 目录下的 node_modules 准备提交 m2 到具体项目 svn 库
				rm ${workingdir}/node_modules -rf
				# 等待一段时间 打包后清理临时文件可能需要一点时间
				sleep 5
			fi

			# 添加到 SVN
			echo "svn add ${workingdir}"
			until ${svncmd} ${svnoptions} add --force ${workingdir} 2>&1;do
				local workingdir=${workingdir%/*}	# 父目录
				[ "${workingdir}" = "${webroot}" ] && break
			done
			echo

			# 检查一下,以防某些临时文件被 svn add
			if ${svncmd} ${svnoptions} st ${workingdir} | grep -q -e '^!';then
				for badfile in $(${svncmd} ${svnoptions} st ${workingdir} | grep -e '^!' 2>/dev/null | awk '{print $NF}');do
					${svncmd} ${svnoptions} del --force $badfile &>/dev/null	# 删除已经不存在的文件,避免提交失败
				done
			fi

			# 提交到 SVN
			echo "svn commit ${workingdir}"
			while ${svncmd} ${svnoptions} commit -m "update by weshop ci_tool ${message}" ${workingdir} 2>&1 \
				| grep -q -e 'svn: E195022.*is locked in another working copy' ; do
				${svncmd} ${svnoptions} unlock --force \
				$(${svncmd} ${svnoptions} commit -m "update by weshop ci_tool ${message}" ${workingdir} 2>&1 \
				| grep -q -e 'svn: E195022.*is locked in another working copy' \
				| awk -F"'" '{print $2}')
			done
			${svncmd} ${svnoptions} commit -m "update by weshop ci_tool ${message}" ${workingdir} 2>&1	# 如果有其他报错,这里抛出来
			echo
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
	if [ -z "$2" ];then
		return 1
	fi
	local type="$1"
	local projects="$2"
	if [ "${type}" = 'ui' ];then
		#local projects="$( cat ${weshop_ui_enabled_projects} )"
		local project_list=${weshop_ui_enabled_projects}
		local flists="$( cat ${weshop_ui_filelist} )"
	elif [ "${type}" = 'php' ];then
		#local projects="$( cat ${weshop_php_enabled_projects} )"
		local project_list=${weshop_php_enabled_projects}
		local flists="$( cat ${weshop_php_filelist} )"
	else
		return 1
	fi

	# 指定目录
	for project_code in ${projects} ;do
		if ! grep -q -i -e "^${project_code}\$" $project_list &>/dev/null;then echo $project_code not in $project_list ;continue ;fi # 检查一下
		for item in ${flists};do
			echo "sync to demo ${project_code} ${item}"
			# 发布到demo
			/bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' \
			/usr/bin/rsync \
			-vzrpt \
			--blocking-io \
			--exclude='.svn' \
			${webroot}/${project_code}${item} 211.152.60.33::web/${project_code}demo${item%/*}/ 2>&1
			echo
			# 分发到所有节点
			localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
			echo $localkey sync_a_project_code ${project}demo | /usr/bin/gearman -h 211.152.60.33 -f CommonWorker_10.0.0.200 -b
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

weshop_syncto_prod_hook() {
	# 对 ui|php 两个列表中的项目轮流操作
	for project in $(cat ${weshop_ui_enabled_projects}) ;do
	#for project in haoyadatest ;do
		local log_file="/var/log/weshop_syncto_prod_hook.${project}.ui.$(date +%s_%N).log"
		echo "$(date) 项目: $project ui" >> ${log_file}
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "从线上 weshop 正式环境拉取 ui 相关目录" >> ${log_file}
			pull_weshop_prod_for_child_projects ui $project >> ${log_file}  2>&1
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "打包 ui 目录 并提交到项目 $project SVN" >> ${log_file}
			pack_and_commit_svn ui $project >> ${log_file} 2>&1
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "发布项目 $project 到 demo 环境" >> ${log_file}
			dev2demo ui $project >> ${log_file} 2>&1
		echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >> ${log_file}
		# 压缩日志文件
		gzip $log_file ; local log_file="${log_file}.gz"
		# 发邮件
		local to_list='virgilzhang@catholic.net.cn,annekang@catholic.net.cn,wendyguo@icatholic.net.cn,lihua@catholic.net.cn'
		local to_list="${to_list},youngyang@icatholic.net.cn,willwan@icatholic.net.cn"
		local to_list="${to_list},handersonguo@icatholic.net.cn,hansonzhang@icatholic.net.cn,zhuweiyou@icatholic.net.cn"
		local subject="Syncing Weshop UI to project: ${project}'s SVN&DEMO has completed"
		local content="$subject. check attachment for more details."
		local file="$log_file"
		sendemail "$to_list" "$subject" "$content" "$file" &>/dev/null
	done

	for project in $(cat ${weshop_php_enabled_projects}) ;do
	#for project in haoyadatest ;do
		local log_file="/var/log/weshop_syncto_prod_hook.${project}.php.$(date +%s_%N).log"
		echo "$(date) 项目: $project php" >> ${log_file}
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "从线上 weshop 正式环境拉取 php 相关目录" >> ${log_file}
			pull_weshop_prod_for_child_projects php $project >> ${log_file} 2>&1
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "打包 php 目录 并提交到项目 $project SVN" >> ${log_file}
			pack_and_commit_svn php $project >> ${log_file} 2>&1
		echo ++++++++++++++++++++++++++++++ >> ${log_file}
		echo "发布项目 $project 到 demo 环境" >> ${log_file}
			dev2demo php $project >> ${log_file} 2>&1
		echo +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >> ${log_file}
		# 压缩日志文件
		gzip $log_file ; local log_file="${log_file}.gz"
		# 发邮件
		local to_list='virgilzhang@catholic.net.cn,annekang@catholic.net.cn,wendyguo@icatholic.net.cn,lihua@catholic.net.cn'
		local to_list="${to_list},youngyang@icatholic.net.cn,willwan@icatholic.net.cn"
		local to_list="${to_list},handersonguo@icatholic.net.cn,hansonzhang@icatholic.net.cn,zhuweiyou@icatholic.net.cn"
		local subject="Syncing Weshop PHP to project: ${project}'s SVN&DEMO has completed"
		local content="$subject. check attachment for more details."
		local file="$log_file"
		sendemail "$to_list" "$subject" "$content" "$file" &>/dev/null
	done
}


# 发布到demo
# /bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' /usr/bin/rsync  -vzrptn --blocking-io --exclude='.svn' /home/webs/dev/140821fg0374/public/html/m2/ 211.152.60.33::web/140821fg0374demo/public/html/m2/

# 拉取m2
# /bin/env USER='cutu5er' RSYNC_PASSWORD='1ccOper5' /usr/bin/rsync -vzrptn --blocking-io --exclude='.svn' --exclude='diff' 211.152.60.33::web/weshop/public/html/m2/ /home/webs/dev/140821fg0374/public/html/m2/

# 手工执行
# . /usr/local/sbin/WeshopCI.sh ; pack_and_commit_svn ui 140821fg0374
