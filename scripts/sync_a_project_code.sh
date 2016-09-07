
p_ret() {
	if [ -z "$3" ];then
		return 1
	fi

	if [ "$1" -eq 0 ];then
		echo -e "$2"
	else
		echo -e "$3"
	fi
}

sync_individually() {
	#
	# 分发单个项目到所有apps
	#
	#usage: echo 72cf40a112e106565e2cbcb4cebec8a0 sync_a_project_code haoyadatestdemo | /usr/bin/gearman -h 211.152.60.33 -f CommonWorker_10.0.0.200
	local APP_IP_ARY=('172.18.1.10' '172.18.1.11' '172.18.1.12' '172.18.1.13' '172.18.1.14' '172.18.1.24' )
	local PXY_IP_ARY=('10.0.0.1' '10.0.0.2')
	local parameter='-vrptl --delete --delete-excluded '

	if [ -z "$1" ];then
		echo "project_code or hostname missing."
		return 1
	fi

	project_code="$1"
	# 这一段确定 域名 $hostname 和 项目代码目录 $subdir; 有可能出现这几种情况:
	#	提供的是项目域名
	#	提供的是项目编号
	#	多个域名对应相同目录或子目录 比如 /home/webs/vanke-center.umaman.com
	#	某些老项目是以域名为目录名的
	#	某些老项目改为使用发布工具后,已经使用新的目录名,但老的目录并没有删除.比如cloud.umaman.com
	if echo ${project_code}|grep -e '\.' -q  && echo ${project_code}|grep -P -e '\.(com|cn|org|net)$' -q ;then
		#是合法域名
		hostname=${project_code}
		NGXCONF_DIR='/home/app_nginx_conf/'
		vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
		if [ ! -f "$vhostfile" ];then
			#不是配置过的域名,退出
			echo "DomainName '${hostname}' not configured in system."
			return 1
		else
			#域名有配置过,从配置文件查找webroot目录名
			subdir=$(grep -P -e "^[ |\t]*root[ |\t].*" ${vhostfile} | /usr/bin/head -n 1 | awk -F '/|;' '{print $4}')
		fi
	else
		#不是合法域名
		if [ ! -d /home/webs/${project_code} ];then
			#不是合法域名,目录也不存在,直接退出.
			echo "Dir /home/webs/${project_code} not exist."
			return 1
		else
			#目录存在
			hostname="${project_code}.umaman.com"	#简单拼接一下,就当项目编号.除非某个项目既不是以 项目编号 也不是以 项目域名 作为webroot.
			#vhostfile=$(grep -rl -P -e "^[ |\t]*root[ |\t].*/home/webs/${project_code}/public[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
			#hostname=$()
			subdir=$project_code
		fi
	fi

	#测试
	#echo -e "${hostname}\t${subdir}"
	#return

	## 对开启 微商城 ( 已包含直播 ) 的项目,在分发时做软链接
	## 举例: /home/webs/weshop/application/modules/shop -> /home/webs/haoyadatestdemo/application/modules/shop
	##
	#for keyword in weshop ;do
	#	local webroot='/home/webs'				# WebRoot目录
	#	local hostslist="/var/lib/${keyword}_enabled_hosts"	# 项目编号列表,一行一个
	#	local filelist="/var/lib/${keyword}_filelist"		# 文件/目录,一行一个
	#	if [ $keyword = 'weshop' ] ;then			# 源项目编号
	#		local src_project=weshop
	#	#elif [ $keyword = 'zhibo' ] ;then
	#	#	local src_project=160523fg0262
	#	fi
	#	if grep -q -e "^${subdir}$" ${hostslist} ;then
	#		# 源项目目录
	#		local src_project_dir="${webroot}/${src_project}"
	#		echo "${subdir}" | grep -q -e 'demo$' &&  local src_project_dir="${webroot}/${src_project}demo"
	#		# 目标项目目录
	#		local project_dir="${webroot}/${subdir}"
	#		# 建立软连接
	#		for item in $(cat ${filelist});do
	#			local src_item="${src_project_dir}${item}"
	#			local dst_item="${project_dir}${item}"
	#			# 无条件删除[软链接|文件|文件夹|无] 并 确保上级目录存在
	#			#rm ${dst_item} -rf &>/dev/null; mkdir -p ${dst_item%/*} &>/dev/null
	#			test -h ${dst_item} && rm ${dst_item} -rf ; mkdir -p ${dst_item%/*} &>/dev/null
	#			# 创建软链接
	#			#echo "${src_item} ---> ${dst_item}"
	#			if   [ -f ${src_item} ];then
	#				#ln -s ${src_item} ${dst_item}
	#				rsync -ac ${src_item} ${dst_item} || rsync -ac ${src_item} ${dst_item}
	#			elif [ -d ${src_item} ];then
	#				#ln -s ${src_item} ${dst_item%/*}/
	#				rsync -ac --delete ${src_item} ${dst_item%/*}/ || rsync -ac --delete ${src_item} ${dst_item%/*}/
	#			fi
	#		done
	#		#break	# 一个项目要么是直播要么微商?可能不一定
	#	fi
	#done

	# 微商城 | 直播 项目同步-分发 触发操作
	#
	if [ "${subdir}" = 'weshop' ] ;then
	#	# 触发相关项目分发
	#	for proj in $(cat /var/lib/weshop_enabled_hosts |grep -v -e 'demo$');do
	#		echo $localkey sync_a_project_code  $proj | /usr/bin/gearman -h 10.0.0.200 -p 4730 -f "CommonWorker_10.0.0.200" -b
	#	done
		# 触发办公室内网 host48 去做一系列操作
		echo $localkey weshop_syncto_prod_hook | /usr/bin/gearman -h 10.0.0.200 -p 4731 -f "CommonWorker_192.168.5.48" -b
	#elif [ "${subdir}" = 'weshopdemo' ] ;then
	#	# 触发相关项目分发
	#	for proj in $(cat /var/lib/weshop_enabled_hosts|grep -e 'demo$');do
	#		echo $localkey sync_a_project_code  $proj | /usr/bin/gearman -h 10.0.0.200 -p 4730 -f "CommonWorker_10.0.0.200" -b
	#	done
	#elif [ "${subdir}" = '160523fg0262' ] ;then
	#	# 触发相关项目分发
	#	for proj in $(cat /var/lib/zhibo_enabled_hosts|grep -v -e 'demo$');do
	#		echo $localkey sync_a_project_code  $proj | /usr/bin/gearman -h 10.0.0.200 -p 4730 -f "CommonWorker_10.0.0.200" -b
	#	done
	#elif [ "${subdir}" = '160523fg0262demo' ] ;then
	#	# 触发相关项目分发
	#	for proj in $(cat /var/lib/zhibo_enabled_hosts|grep -e 'demo$');do
	#		echo $localkey sync_a_project_code  $proj | /usr/bin/gearman -h 10.0.0.200 -p 4730 -f "CommonWorker_10.0.0.200" -b
	#	done
	fi




	# 按webroot目录,分发项目代码
	echo -e "分发 /home/webs/${subdir}/ 目录 :\n"
	for ip in ${APP_IP_ARY[@]} ;do
		# 现在 10.0.0.1 和 10.0.0.2 也要跑php了,代码要实时同步,注释掉下面这段
		#if [ "${ip}" = '10.0.0.1' -o "${ip}" = '10.0.0.2' ];then
		#	if ! echo -n ${subdir}|grep -q -i -e '^icc' -e 'cloud' ;then
		#		# 如果不是icc这个项目,不要分发到 10.0.0.1 和 10.0.0.2.
		#		continue
		#	fi
		#fi

		#分发项目代码 并 清理项目应用程序缓存 连php写的日志也一并排除并删除,日志不应该放在代码目录 
		rm /home/webs/${subdir}/cache/* -rf &>/dev/null
		/bin/env USER='backup' RSYNC_PASSWORD='123456' /usr/bin/rsync \
		${parameter} \
		--blocking-io \
		--exclude='.svn' \
		--exclude='.git' \
		--exclude='*.log' \
		--exclude='*/logs/*' \
		--exclude=node_modules \
		/home/webs/${subdir}/ \
		${ip}::web/${subdir}/

		p_ret $? "分发项目 ${hostname} 代码到 ${ip},分发成功.\n" "分发项目 ${hostname} 代码到 ${ip},分发失败.\n"
	done

	# 按域名清理缓存
	if [ "${hostname}" != 'common.umaman.com' -a "${hostname}" != 'ZendFramework-1.12.9-minimal.umaman.com' ] ;then
		for ip in ${PXY_IP_ARY[@]} ;do
			echo "${hostname} /" |/usr/bin/gearman -h 211.152.60.33 -f "purge_${ip}" -b
		done
		if grep -q -i -e "${hostname}" /var/lib/cdn_enabled_hosts ;then
			echo -e "\n清理源站及CDN缓存: ${hostname} 已提交到队列."
		else
			echo -e "\n清理缓存: ${hostname} 已提交到队列."
		fi
	fi
}


#下面是用配置文件里的所有域名测试这个函数的正确性
#for my_hostname in `grep -hr -P -e '^[ |\t]*server_name[ |\t]' /home/app_nginx_conf/ \
#                        |sed 's#server_name##;s#;.*$##' \
#                        |tr ' |\t' '\n' \
#                        |sort|uniq \
#                        |grep -P -e '\.(com|cn|org|net)'`
#do
#	sync_individually $my_hostname
#done

