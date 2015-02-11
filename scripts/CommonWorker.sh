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
proxy_cfg_path='/home/ngx_proxy_conf/'
proxy_cfg_template='/usr/local/share/commonworker/proxy_cfg_template'
proxy_cache_cfg='/home/ngx_proxy_conf/cache-zone.conf'
app_cfg_path='/home/nginx/'
app_cfg_template='/usr/local/share/commonworker/app_cfg_template'
WEBROOT='/home/webs/'

#functions

get_project_status ()
{
	if [ -z "$1" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi

	project_code="$1"
	project_domain="$project_code.umaman.com"
	if grep -rl -P -e "^[ |\t]*server_name[ |\t].*$project_domain" $proxy_cfg_path && grep -e "keys_zone=$project_domain:" "$proxy_cache_cfg" && \
		grep -rl -P -e "^[ |\t]*server_name[ |\t].*$project_domain" $app_cfg_path  
	then
		echo "$project_code was configured.return code:0"
		return 0
	else
		echo "$project_code not configured.return code:1"
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
	project_code="$1"
	hostname="$2"
	if get_project_status $project_code &>/dev/null ;then
		#项目是否是demo
		if echo "$project_code" | grep -e 'demo$' &>/dev/null ;then
			subpath='demo/'
		else
			subpath='vhost/'
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

	project_code="$1"
	project_domain="$project_code.umaman.com"
	if get_project_status $project_code &>/dev/null ;then
		#项目已经配置,返回
		echo "Deployer : $project_code was allready configured,return code:1"
		return 1
	else
		#项目是否是demo
		if echo "$project_code" | grep -e 'demo$' &>/dev/null ;then
			subpath='demo/'
		else
			subpath='vhost/'
		fi

		#生成项目app配置
		cat $app_cfg_template | sed -e "s/PROJECT_DOMAIN/$project_domain/g" \
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
		grep -e "keys_zone=$project_domain:" "$proxy_cache_cfg" || \
		echo "proxy_cache_path /home/proxy/cache/$project_domain levels=1:2 keys_zone=$project_domain:200m inactive=12h max_size=10g;" \
		>> $proxy_cache_cfg
		#proxy_cfg
		cat $proxy_cfg_template | sed -e "s/PROJECT_DOMAIN/$project_domain/g" > $proxy_cfg_path$subpath$project_code.conf 
		if [ $? -gt 0 ];then
			#proxy_cfg创建失败,返回
			echo "Deployer : $project_code proxy_cfg creating with error,return code:2"
			return 2
		fi

		echo "Deployer : $project_code now configured,return code:0"
		#reload apps & proxies
		#/usr/local/sbin/RsyncNgxCfg.sh
		return 0
	fi
}

sync_demo_prod ()
{
	if [ -z "$2" ];then
		echo "Deployer : missing parameter,return code:1"
		return 1
	fi

	rsync	-vrogptlc --delete \
		--blocking-io \
		--exclude='.svn' \
		--exclude='*.log' \
		--exclude='/cache/*' \
		"$1" "$2" 2>&1

	ret=$?
	if [ $ret -gt 0 ];then
		echo "Deployer : sync $1 to $2 with error,return code:$ret"
	else
		echo "Deployer : sync $1 to $2 ok,return code:$ret"
	fi
	return $ret
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
	
	get_project_status|add_project|dir_tree)
		$cmd $p3
		logger Deployer $p1 $p2 $p3 return code:$?
	        ;;
	add_hostname|sync_demo_prod)
		$cmd $p3 $p4
		ret=$?
		logger Deployer $p1 $p2 $p3 $p4 return code:$ret
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
		/usr/local/sbin/RsyncNgxCfg.sh $p3 2>&1
		logger Deployer $p1 $p2 $p3 return code:$?
	        ;;
	check_services)
		/usr/local/sbin/check_services.sh $p3 2>&1
		;;
	supervisor_config)
		source /usr/local/sbin/sc_supervisor_functions.sh
		supervisor_config $p3 $p4
		;;
	supervisor_status)
		source /usr/local/sbin/sc_supervisor_functions.sh
		supervisor_status 2>&1
		;;
	supervisor_control)
		source /usr/local/sbin/sc_supervisor_functions.sh
		supervisor_control $p3 $p4
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
	mongo_query)
		source /usr/local/sbin/sc_mongodb_functions.sh
		#mongo_query	db col query projection sort limit skip
		$cmd $p3 $p4 $p5 $p6 $p7 $p8 $p9
		ret=$?
		logger CommonWorker $p1 $p2 $p3 $p4 $p5 $p6 $p7 $p8 $p9 return code:$ret
		exit $ret
	        ;;
	cronjob_list|cronjob_add|cronjob_del|cronjob_disable|cronjob_enable|cronjob_runonce|cronjob_taillog)
		source /usr/local/sbin/sc_cronjob_functions.sh
		$cmd $p3 $p4 $p5 $p6 $p7
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
	*)
		echo "unknow command,return code:3"
		exit 3
	esac
done
