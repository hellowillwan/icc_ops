sync_individually() {
	#usage: echo 72cf40a112e106565e2cbcb4cebec8a0 sync_a_project_code haoyadatestdemo | /usr/bin/gearman -h 211.152.60.33 -f CommonWorker_10.0.0.200
	local APP_IP_ARY=('10.0.0.10' '10.0.0.11' '10.0.0.12' '10.0.0.13')
	local PXY_IP_ARY=('10.0.0.1' '10.0.0.2')
	local parameter='-vrptl --delete'

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
		NGXCONF_DIR='/home/nginx/'
		vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
		if [ ! -f "$vhostfile" ];then
			#不是配置过的域名,退出
			echo "DomainName '${hostname}' not configured in system."
			return 1
		else
			#域名有配置过,从配置文件查找webroot目录名
			subdir=$(grep -P -e "^[ |\t]*root[ |\t].*" ${vhostfile} | /usr/bin/head -n 1 | awk -F '/' '{print $4}')
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

	#按webroot目录,分发项目代码
	echo -e "分发 /home/webs/${subdir}/ 目录 :\n"
	for ip in ${APP_IP_ARY[@]} ;do
		/bin/env USER='backup' RSYNC_PASSWORD='123456' /usr/bin/rsync \
		${parameter} \
		--blocking-io \
		--exclude='.svn' \
		--exclude='*.log' \
		--exclude='/cache/*' \
		/home/webs/${subdir}/ \
		${ip}::web/${subdir}/
	done

	#按域名清理缓存
	for ip in ${PXY_IP_ARY[@]} ;do
		echo "${hostname} /" |/usr/bin/gearman -h 211.152.60.33 -f "purge_${ip}" -b
	done
	echo -e "\n清理缓存: ${hostname} 已提交到队列."
}


#下面是用配置文件里的所有域名测试这个函数的正确性
#for my_hostname in `grep -hr -P -e '^[ |\t]*server_name[ |\t]' /home/nginx/ \
#                        |sed 's#server_name##;s#;.*$##' \
#                        |tr ' |\t' '\n' \
#                        |sort|uniq \
#                        |grep -P -e '\.(com|cn|org|net)'`
#do
#	sync_individually $my_hostname
#done

