#!/bin/sh
# gearman CommonWorker
# key command parameter ...
# key get_project_status project_code
# key add_project project_code

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

#variables
LOGFILE='/var/log/CommonWorker.log'
DT2="date '+%Y-%m-%d %H:%M:%S'"
localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
proxy_cfg_path='/home/proxy_nginx_conf/'
proxy_cfg_template='/usr/local/share/commonworker/proxy_cfg_template'
proxy_cfg_template_demo='/usr/local/share/commonworker/proxy_cfg_template_demo'
proxy_cache_cfg='/home/proxy_nginx_conf/cache-zone.conf'
app_cfg_path='/home/app_nginx_conf/'
app_cfg_template='/usr/local/share/commonworker/app_cfg_template'
WEBROOT='/home/webs/'

#functions

# 根据返回码输出日志
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

get_project_status ()
{
	if [ -z "$1" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi

	local project_code="$1"
	local project_domain="${project_code}.umaman.com"
	if grep -rl -P -e "^[ |\t]*server_name[ |\t].*$project_domain" $proxy_cfg_path \
		&& grep -rl -P -e "^[ |\t]*server_name[ |\t].*$project_domain" $app_cfg_path
	then
		echo -e "项目 [ ${project_code} ] 配置文件路径.\n"

		grep -o -P -e "^[ |\t]*server_name[ |\t].*[^;]" \
		$(grep -rl -P -e "^[ |\t]*server_name[ |\t].*$project_domain" $proxy_cfg_path) \
		| sed 's/^[ |\t]*server_name[ |\t]\+//'
		echo -e "项目 [ ${project_code} ] 绑定的域名.\n"

		grep -e "keys_zone=$project_domain:" "$proxy_cache_cfg" \
		&& echo "项目 [ ${project_code} ] 缓存配置."
		return 0
	else
		echo -e "项目 [ ${project_code} ] 配置文件未找到.\n"
		return 1
	fi
}

add_hostname ()
{
	#给一个vhost增加一个主机名: add_hostname project_code host.domain.com
	if [ -z "$2" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi
	local project_code="$1"
	local hostname="$2"
	if get_project_status $project_code &>/dev/null ;then
		#项目是否是demo
		if echo "$project_code" | grep -e 'demo$' &>/dev/null ;then
			local subpath='demo/'
		else
			local subpath='vhost/'
		fi

		#是否已经有该主机头了
		if grep -P -e "^[ |\t]*server_name[ |\t].*$hostname" $app_cfg_path$subpath$project_code.conf &>/dev/null && \
			grep -P -e "^[ |\t]*server_name[ |\t].*$hostname" $proxy_cfg_path$subpath$project_code.conf &>/dev/null
		then
			echo "Deployer : hostname $hostname already in app&proxy_cfg of $project_code,return code:3"
			return 3
		fi

		#这里检查并添加主机头
		grep -P -e "^[ |\t]*server_name[ |\t].*$hostname" $app_cfg_path$subpath$project_code.conf &>/dev/null || \
		sed -i -e "s/^[ |\t]*server_name[ |\t][^;]*/& $hostname/" $app_cfg_path$subpath$project_code.conf

		if [ $? -gt 0 ];then
			echo "Deployer : adding hostname $hostname to app_cfg of $project_code with error,return code:4"
			return 4
		fi
		grep -P -e "^[ |\t]*server_name[ |\t].*$hostname" $proxy_cfg_path$subpath$project_code.conf &>/dev/null || \
		sed -i -e "s/^[ |\t]*server_name[ |\t][^;]*/& $hostname/" $proxy_cfg_path$subpath$project_code.conf

		if [ $? -gt 0 ];then
			echo "Deployer : adding hostname $hostname to proxy_cfg of $project_code with error,return code:5"
			return 5
		else
			echo "Deployer : adding hostname $hostname to app&proxy_cfg of $project_code ok,return code:0"
			return 0
		fi

	else
		#项目尚未配置,返回
		echo "Deployer : $project_code not configured,can't add hostname,return code:2"
		return 2
	fi

}

add_project ()
{
	if [ -z "$1" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi

	local project_code="$1"
	#项目主域名
	local project_domain="${project_code}.umaman.com"
	if get_project_status $project_code &>/dev/null ;then
		#项目已经配置,返回
		echo "Deployer : $project_code was allready configured,return code:1"
		return 1
	else
		#项目是否是demo
		if echo "$project_code" | grep -e 'demo$' &>/dev/null ;then
			# 配置文件路径
			local subpath='demo/'
			local proxy_cfg_t="$proxy_cfg_template_demo"
		else
			# 配置文件路径
			local subpath='vhost/'
			local proxy_cfg_t="$proxy_cfg_template"
		fi
		#专门服务静态资源的域名
		local project_domain_static="${project_code}.umaman.net"
		#另外三个备用的域名
		local project_domain_backup="${project_code}.icatholiccloud.com ${project_code}.icatholiccloud.net ${project_code}.icatholiccloud.cn"
		# 配置模板中需要替换的变量
		local PROJECT_DOMAIN="$project_domain $project_domain_static $project_domain_backup"
		local PROJECT_STATIC_DOMAIN="${project_domain_static}"
		local CACHE_ZONE_NAME="$project_domain"

		#生成项目app配置
		cat $app_cfg_template | sed -e "s/PROJECT_DOMAIN/$PROJECT_DOMAIN/g" \
						-e "s/PROJECT_CODE/$project_code/g" > $app_cfg_path$subpath$project_code.conf
		if [ $? -gt 0 ];then
			app_cfg创建失败,返回
			echo "Deployer : $project_code app_cfg creating with error,return code:2"
			return 2
		fi
		#app配置中传递 APPLICATION_ENV
		#if [ "$subpath" = 'demo/' ];then
			#sed -i -e "/#INCLUDE_FASTCGI_PARAMS_TAG;/c\\\t\\tinclude fastcgi_params_development;" $app_cfg_path$subpath$project_code.conf
		#else
			sed -i -e "/#INCLUDE_FASTCGI_PARAMS_TAG;/c\\\t\\tinclude fastcgi_params_production;" $app_cfg_path$subpath$project_code.conf
		#fi

		#生成项目proxy配置
		#proxy_cache zone
		echo "$project_code" | grep -q -e 'demo$' &>/dev/null || \
		grep -e "keys_zone=$project_domain:" "$proxy_cache_cfg" || \
		echo "proxy_cache_path /home/proxy/cache/$project_domain levels=1:2 keys_zone=$project_domain:200m inactive=12h max_size=10g;" \
		>> $proxy_cache_cfg
		#proxy_cfg
		cat $proxy_cfg_t | sed -e "s/PROJECT_DOMAIN/$PROJECT_DOMAIN/g" \
						-e "s/PROJECT_STATIC_DOMAIN/$PROJECT_STATIC_DOMAIN/g" \
						-e "s/CACHE_ZONE_NAME/$CACHE_ZONE_NAME/g" > $proxy_cfg_path$subpath$project_code.conf
		if [ $? -gt 0 ];then
			#proxy_cfg创建失败,返回
			echo "Deployer : $project_code proxy_cfg creating with error,return code:2"
			return 2
		fi

		echo "Deployer : $project_code now configured,return code:0"
		#reload apps & proxies
		# 不需要在这里做,cut 添加完项目后会执行 reload_nginx
		#/usr/local/sbin/RsyncCfg.sh
		return 0
	fi
}

recreate_project_cfgs() {
	if [ -z "$1" ];then
		echo "missing parameter,return code:1,Usage: ${FUNCNAME[0]} project_code"
		return 1
	fi

	local project_code="$1"

	find /home/proxy_nginx_conf/ -iname "${project_code}*" |xargs -i mv {} /home/backup/old_cfgs/proxy
	find /home/app_nginx_conf/ -iname "${project_code}*" |xargs -i mv {} /home/backup/old_cfgs/app
	add_project ${project_code}
	for domain_name in $(grep -P -e "^[ |\t]*server_name[ |\t]" /home/backup/old_cfgs/proxy/${project_code}.conf \
		| sed 's/[ |\t]*server_name[ |\t]*//;s/;$//') ;do
		add_hostname ${project_code} ${domain_name}
	done
	add_project "${project_code}demo"
}

sync_demo_prod ()
{
	# test
	# echo 19a65877f1c3911eb80a4173c52d353e sync_demo_prod /home/webs/haoyadatestdemo/public/zhibo /home/webs/haoyadatest/public/ 1474443736.3109_290435329 the_last_one | ./CommonWorker.sh
	if [ -z "$2" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi

	# 如果有传递 sync_id 则加锁备份生产环境代码
	if [ -n "$3" ];then
		local sync_id="$3"	# sync_id 标记一次同步操作(一次同步操作可能有1个或多个文件被同步,下面的rsync会被调用1次或多次)
		local project=$(echo $2 | cut -d '/' -f 4)
		local lock_file="/var/lib/${project}.lock"
		# 有lock file
		if [ -f ${lock_file} ];then
			if grep -q $sync_id ${lock_file} ;then
				# 是同一次操作加的锁,应该已经备份了
				local is_backupd='yes'
			else
				# 是其他操作加的锁 等待 直到其他操作解锁
				while test -f ${lock_file} ;do
					sleep 1
				done
			fi
		fi
		# 没有 lock file (必满足下面的条件) 则 加锁 备份;
		# 如果有 lock file,上面已经判断过了:
		#	同一次操作的必然已经备份过了,必然不满足下面的条件,会跳过;
		#	不是同一次操作,会等到其他操作完成,也就必然满足下面的条件
		if [ -z "${is_backupd}" -o "${is_backupd}" != 'yes' ];then
			# 加锁
			echo $1 $2 $sync_id > $lock_file
			# 备份 ( Prod ---> Bak1 ---> Bak2 ---> Bak3 )
			local WEBROOT='/home/webs/'
			local BAKROOT='/home/baks/'
			local Prod="${WEBROOT}${project}" ; test -d $Prod || mkdir -p $Prod &>/dev/null
			local Bak1="${BAKROOT}${project}_Bak1" ; test -d $Bak1 || mkdir -p $Bak1 &>/dev/null
			local Bak2="${BAKROOT}${project}_Bak2" ; test -d $Bak2 || mkdir -p $Bak2 &>/dev/null
			local Bak3="${BAKROOT}${project}_Bak3" ; test -d $Bak3 || mkdir -p $Bak3 &>/dev/null
			rsync -a --delete $Bak2/ $Bak3/ &>/dev/null
			rsync -a --delete $Bak1/ $Bak2/ &>/dev/null
			rsync -a --delete $Prod/ $Bak1/ &>/dev/null
			# 清除 Prod 版本号文件
			test -f ${Prod}/public/__VERSION__.txt && rm -f ${Prod}/public/__VERSION__.txt &>/dev/null
		fi
	fi

	# 同步 demo -> prod
	#rsync	-vrogptlc --delete \
	rsync	-vrogptl --delete \
		--blocking-io \
		--exclude='.svn' \
		--exclude='.git' \
		--exclude='.buildpath' \
		--exclude='.project' \
		--exclude='.gitignore' \
		--exclude='*.log' \
		--exclude='/logs/*' \
		--exclude='/cache/*' \
		--exclude=node_modules \
		"$1" "$2" 2>&1

	local ret=$?
	if [ $ret -gt 0 ];then
		echo "Deployer : sync $1 to $2 with error,return code:$ret"
	else
		echo "Deployer : sync $1 to $2 ok,return code:$ret"
	fi

	# 写个版本号到 Prod 记录每次同步操作的内容和时间(但如果本次同步操作并没有差异文件被同步的话,这个版本文件不会被分发到app机器)
	if [ -n "${sync_id}" ];then
		# 记录同步的条目以及同步命令的返回码
		local VerFile="/home/webs/${project}/public/__VERSION__.txt"
		echo "$1 ---> $2 : $ret" | sed 's#/home/webs##g' >> $VerFile 2>&1
		# 记录同步操作的时间
		if [ -n "$4" -a "$4" = 'the_last_one' ];then
			echo $sync_id >> $VerFile 2>&1
			date -d @$(echo ${sync_id} | cut -d _ -f 1) >> $VerFile 2>&1
		fi
	fi

	# 如果是同步操作中的最后一个 item ,在这里解锁
	if [ -n "$4" -a "$4" = 'the_last_one' ];then
		test -f ${lock_file} && rm ${lock_file} -f
	fi

	return $ret
}

listbak() {
	if [ -z "$1" ];then
		echo "parameter missing,need project_code"
		return 1
	else
		local project="$1"
	fi

	for bak in /home/baks/${project}_*;do
		local bakname=$(echo $bak |sed 's#/home/baks/##')
		local bak_public_items_number=$(ls ${bak}/public/ 2>/dev/null | wc -l)
		local bak_latest_mtime=$(ls ${bak} -lt|grep -v -e '^total'|head  -n 1|awk '{print $6,$7,$8}')	# 由于 version 文件,所以这个值没意义
		# 如果 public 目录下有2个或以上的文件|目录,则判断这个备份不为空(新项目第一次同步产生的备份肯定是空的)
		if [ $bak_public_items_number -ge 2 ];then
			# 备份功能上线后,同步4次以后,3个备份目录里将都会有__VERSION__.txt文件
			if [ -f ${bak}/public/__VERSION__.txt ];then
				local version_info=$(cat ${bak}/public/__VERSION__.txt | base64 -w 0)
				local output="${bakname}#${bak_latest_mtime}#${version_info}"
			else
				local output="${bakname}#${bak_latest_mtime}#"
			fi
		else
			local output="${bakname}##"
		fi
		echo $output
	done
}

rollback() {
	if [ -z "$2" ];then
		echo "parameter missing,need project, bakname"
		return 1
	else
		local project="$1"
		local bakname="$2"
	fi
	rsync -av --delete /home/baks/${bakname}/ /home/webs/${project}/ 2>&1

}

dir_tree ()
{
	if [ -z "$1" ];then
		echo "Dir_tree : missing parameter,return code:1"
		return 1
	fi

	/usr/bin/php /usr/local/sbin/dir_tree.php $1 2>/dev/null
}

#main
while read p1 p2 p3 p4 p5 p6 p7 p8 p9;do
	if [ -z "$p2" ];then
		echo "missing parameter,return code:1"
		exit 1
	else
		key="$p1"
		cmd="$p2"
	fi
	
	if [ "$key" != "$localkey" ];then
		echo "invalid key,return code:2"
		exit 2
	fi
	
	case "$cmd" in
	
	get_project_status|add_project|recreate_project_cfgs|dir_tree)
		$cmd $p3
		logger Deployer $p1 $p2 $p3 return code:$?
		;;
	add_hostname|sync_demo_prod|listbak|rollback)
		$cmd $p3 $p4 $p5 $p6
		ret=$?
		logger Deployer $p1 $p2 $p3 $p4 $p5 $p6 return code:$ret
		exit $ret
		;;
	sync_a_project_code)
		source /usr/local/sbin/sync_a_project_code.sh
		sync_individually $p3
		ret=$?
		logger Deployer $p1 $p2 $p3 $p4 return code:$ret
		exit $ret
		;;
	reload_nginx)
		#/usr/bin/func 'app0[1-4]' call command run "/usr/sbin/nginx -s reload"
		#/usr/bin/func 'proxy0[1-2]' call command run "/usr/local/tengine/sbin/nginx -s reload"
		/usr/local/sbin/RsyncCfg.sh $p3 2>&1
		logger Deployer $p1 $p2 $p3 return code:$?
		;;
	check_services)
		/usr/local/sbin/check_services.sh $p3 2>&1
		;;
	supervisor_status)
		source /usr/local/sbin/sc_supervisor_functions.sh
		supervisor_status 2>&1
		;;
	supervisor_config|supervisor_control|list_collections|add_collections)
		source /usr/local/sbin/sc_supervisor_functions.sh
		$cmd $p3 $p4 $p5
		;;
	edit_file)
		source /usr/local/sbin/sc_editfile_functions.sh
		$cmd $p3 $p4 $p5
		;;
	ensure_ftp_account)
		source /usr/local/sbin/sc_vsftpd_functions.sh
		ensure_ftp_account $p3 $p4 $p5
		logger Deployer $p1 $p2 $p3 $p4 $p5 return code:$?
		;;
	cleanup_wsdl)
		source /usr/local/sbin/sc_cleanup_wsdl.sh
		cleanup_wsdl
		;;
	restart_all_mongos)
		source /usr/local/sbin/sc_mongodb_functions.sh
		$cmd $p3
		ret=$?
		logger CommonWorker $p1 $p2 $p3 return code:$ret
		exit $ret
		;;
	mongo_query|mongo_sync|check_mongo_sync|pull_restore)
		source /usr/local/sbin/sc_mongodb_functions.sh
		#mongo_query	db col query projection sort limit skip
		#mongo_sync	download|upload db_name_for_sync collections_for_sync
		#check_mongo_sync	download|upload db_name_for_sync collections_for_sync
		$cmd $p3 $p4 $p5 $p6 $p7 $p8 $p9
		ret=$?
		logger CommonWorker $p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 return code:$ret
		exit $ret
		;;
	cronjob_list)
		source /usr/local/sbin/sc_cronjob_functions.sh
		$cmd $p3 $p4 $p5 $p6 $p7 $p8|sort -t '|' -k3
		ret=$?
		logger CommonWorker $p1 $p2 $p3 $p4 $p5 $p6 $p7 return code:$ret
		exit $ret
		;;
	cronjob_add|cronjob_del|cronjob_disable|cronjob_enable|cronjob_runonce|cronjob_taillog|cronjob_maillog)
		source /usr/local/sbin/sc_cronjob_functions.sh
		$cmd $p3 $p4 $p5 $p6 $p7 $p8
		ret=$?
		logger CommonWorker $p1 $p2 $p3 $p4 $p5 $p6 $p7 return code:$ret
		exit $ret
		;;
	restart_all_nginx_php)
		source /usr/local/sbin/sc_nginx_php_functions.sh
		$cmd
		ret=$?
		logger CommonWorker $p1 $p2 return code:$ret
		exit $ret
		;;
	restart_all_pyweixin)
		if [ -n "$p3" -a "$p3" != 'ALL' ];then
			/usr/bin/func "$p3" call command run '. ~/.bashrc;pyweixin_restart'
		else
			/usr/bin/func 'app*' call command run '. ~/.bashrc;pyweixin_restart'
		fi
		ret=$?
		sleep 5
		/usr/local/sbin/check_services.sh pyweixin 2>&1
		logger CommonWorker $p1 $p2 $p3 return code:$ret
		exit $ret
		;;
	swoolechat_restart)
		app="$p3"
		port="$p4"
		proj="$p5"
		/usr/bin/func "${app}" call command run ". ~/.bashrc;swoolechat_restart ${port} ${proj}" &
		echo 'should have been finished restarting.'
		logger CommonWorker $p1 $p2 $p3 $p4 $p5
		;;
	flush_alicdn)
		source /usr/local/sbin/sc_cdn_functions.sh
		$cmd $p3 $p4 | logger
		;;
	sendemail)
		sendemail "$p3" "$p4" "$p5" "$p6"
		;;
	diff_weshopcode|distr_weshopcode)
		source /usr/local/sbin/sc_weshopci_functions.sh
		$cmd $p3 $p4
		logger CommonWorker $p1 $p2 $p3
		;;
	test_timeout)
		sleep 1200
		ret=$?
		echo "ret:${ret}"
		;;
	*)
		echo "unknow command,return code:3"
		exit 3
	esac
done
