#!/bin/sh
#
# weshop 项目代码分发到相关子项目用到的函数
#

# 变量
#
weshop_ui_enabled_projects='/var/lib/weshop_ui_enabled_projects'	# 开启微商 ui 的项目编号列表,一行一个
weshop_ui_filelist='/var/lib/weshop_ui_filelist'			# 需要更新的微商 ui 文件/目录,一行一个
weshop_php_enabled_projects='/var/lib/weshop_php_enabled_projects'	# 开启微商 php 的项目编号列表,一行一个
weshop_php_filelist='/var/lib/weshop_php_filelist'			# 需要更新的微商 php 文件/目录,一行一个
webroot='/home/webs'				# WebRoot目录
weshop_dir="${webroot}/weshop"			# weshop 项目目录

# 函数
#
# 比较 Weshop 与 子项目代码
diff_weshopcode() {
	if [ -z "$2" ];then
		echo 'parameters missing.'
		return 1
	else
		local PROJECTS="$1"
		local ITEMS="$(echo $2 | base64 -d)"
	fi

	for p in ${PROJECTS} ;do
		if echo $p | grep -q -e 'demo$' ;then
			local weshopdir=weshopdemo
			local envname='demo环境'
		else
			local weshopdir=weshop
			local envname='正式环境'
		fi
		echo "项目 $p 与 weshop (${envname})存在差异的文件列表如下: "
		for f in ${ITEMS} ; do
			diff -r  /home/webs/${weshopdir}${f} /home/webs/${p}${f} &>/dev/null \
			|| diff -r /home/webs/${weshopdir}${f} /home/webs/${p}${f} \
			| grep -e '^Only in /home/webs/weshop' -e '^diff' \
			| grep -v -e '\.gitignore' -e '\.svn' \
			| sed "s#^.*/home/webs/${p}##"
		done
		echo "ps.前端代码目录的 diff、dist 子目录中的文件存在差异应该是正常的.但...最终解释在前端开发人员."
	done
}

# 从 weshop 生产环境 拉取 前|后端代码 到 开启微商的子项目 的 demo环境
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
		local project_code="${project_code}demo"	# 拉取到子项目 demo环境
		for item in ${flists};do
			echo "${FUNCNAME[0]} ${project_code} $item"
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
			local src_item="${weshop_dir}${item}"
			local dst_item="${webroot}/${project_code}${item%/*}/"

			# 确保父目录存在
			test -d ${dst_item} || ( mkdir -p ${dst_item} ; chown -R ftpuser:ftpuser ${dst_item} &>/dev/null )

			# 拉取操作
			/usr/bin/rsync \
			-vzrogpt \
			--blocking-io \
			--exclude='.svn' ${is_exclude_diff} \
			${src_item} ${dst_item} #2>&1
			echo
		done
	done
}

# 打包(webpack m2)子项目 ui
pack_ui() {
	if [ -z "$1" ];then
		return 1
	fi
	local projects="$1"
	local project_list=${weshop_ui_enabled_projects}
	local flists="$( cat ${weshop_ui_filelist} )"

	for project_code in ${projects};do
		if ! grep -q -i -e "^${project_code}\$" $project_list &>/dev/null;then echo $project_code not in $project_list ;continue ;fi # 检查一下
		local project_code="${project_code}demo"	# 在子项目 demo环境打包
		for item in ${flists};do
			local workingdir="${webroot}/${project_code}${item}"
			# 打包前端文件
			echo "${FUNCNAME[0]} ${workingdir}"
			if [ ! -d ${workingdir} ];then
				echo "dir: ${workingdir} not exits."
				continue
			fi
	
			# 删除项目 ui 目录下的 node_modules,并链接到全局目录
			rm ${workingdir}/node_modules -rf
			ln -s /var/lib/node_modules ${workingdir}/
			# 打包 (yum install nodejs ; npm install -g gulp)
			( cd ${workingdir} ; gulp pro )
			echo
			
			# 删除项目 ui 目录下的 node_modules 准备提交 m2 到具体项目 svn 库
			rm ${workingdir}/node_modules -rf
			# 等待一段时间 打包后清理临时文件可能需要一点时间
			#sleep 5
			# 修改目录权限
			chown -R ftpuser:ftpuser ${workingdir} &>/dev/null
		done
	done
}

# 分发 weshop 代码到相关子项目
distr_weshopcode() {
	if [ -z "$1" ];then
		echo 'parameters missing.'
		return 1
	else
		local PROJECTS="$1"
		if [ "${PROJECTS}" = '__ALL_PROJECTS__' ];then
			local PROJECTS="$( cat ${weshop_php_enabled_projects} | grep -v '__ALL_PROJECTS__' )"
		fi
		#local ITEMS="$(echo $2 | base64 -d)"	# 不用这个文件列表因为没区分ui\php
	fi

	for project in ${PROJECTS} ;do
		for ftype in ui php;do
			local log_file="/var/log/weshop_distribute.${project}.${ftype}.$(date +%s_%N).log"
			echo ++++++++++++++++++++++++++++++++++++++++++++++++++++ | /usr/bin/tee -a ${log_file}
			echo "$(date) 分发 weshop $ftype 相关代码到项目 $project demo环境" | /usr/bin/tee -a ${log_file}
			pull_weshop_prod_for_child_projects $ftype $project 2>&1 | /usr/bin/tee -a ${log_file}
			if [ "$ftype" = 'ui' ];then
				echo ++++++++++++++++++++++++++++++++++++++++++++++++++++ | /usr/bin/tee -a ${log_file}
				echo "$(date) 打包项目 $project demo环境 $ftype 相关代码" | /usr/bin/tee -a ${log_file}
				pack_ui $project 2>&1 | /usr/bin/tee -a ${log_file}
			fi
			# 压缩日志文件
			gzip $log_file ; local log_file="${log_file}.gz"
			# 发邮件
			local to_list='virgilzhang@catholic.net.cn,annekang@catholic.net.cn,wendyguo@icatholic.net.cn,lihua@catholic.net.cn'
			local to_list="${to_list},youngyang@icatholic.net.cn,willwan@icatholic.net.cn"
			local to_list="${to_list},handersonguo@icatholic.net.cn,hansonzhang@icatholic.net.cn,zhuweiyou@icatholic.net.cn"
			local subject="Syncing Weshop UI to project: ${project}'s SVN&DEMO has completed"
			local content="$subject. check attachment for more details."
			local file="$log_file"
			#sendemail "$to_list" "$subject" "$content" "$file" &>/dev/null
		done
		# 分发到所有 app 机器
		chown -R ftpuser:ftpuser ${webroot}/${project}demo &>/dev/null
		echo $localkey sync_a_project_code ${project}demo | /usr/bin/gearman -h 10.0.0.200 -f CommonWorker_10.0.0.200 -b
	done
}
