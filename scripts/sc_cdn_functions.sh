
CDNAPI='/usr/local/sbin/cdn.py'
CDN_ENABLED_HOSTS='/var/lib/cdn_enabled_hosts'
NGXCONF_DIR='/home/proxy_nginx_conf/'

# 查询刷新结果
get_flushresult() {
	if [ -z "$1" ];then return 1;fi
	local task_id="$1"
	#local task_id=139066530
	local url=$(python ${CDNAPI} Action=DescribeRefreshTasks TaskId=${task_id})
	#curl -m 30 -s $url | php -r "\$a = json_decode(file_get_contents('php://stdin'));var_dump(\$a);"
		#object(stdClass)#1 (5) {
		#  ["PageNumber"]=>
		#  int(1)
		#  ["TotalCount"]=>
		#  int(1)
		#  ["PageSize"]=>
		#  int(20)
		#  ["RequestId"]=>
		#  string(36) "CACC2A44-A280-414B-A648-B78957EE84AE"
		#  ["Tasks"]=>
		#  object(stdClass)#2 (1) {
		#    ["CDNTask"]=>
		#    array(1) {
		#      [0]=>
		#      object(stdClass)#3 (4) {
		#        ["CreationTime"]=>
		#        string(20) "2015-09-23T04:47:34Z"
		#        ["ObjectPath"]=>
		#        string(37) "http://weixin.schwarzkopfclub.com.cn/"
		#        ["Status"]=>
		#        string(8) "Complete"
		#        ["TaskId"]=>
		#        string(9) "139068295"
		#      }
		#    }
		#  }
		#}
	curl -m 30 -s $url 2>/dev/null | php -r "\$a = json_decode(file_get_contents('php://stdin'));echo \$a->Tasks->CDNTask[0]->Status;"
	echo " get_flushresult_ret:$? "
}

# 刷新缓存
# AliCDN官方文档 https://docs.aliyun.com/#/pub/cdn/api-reference/refresh&RefreshObjectCaches
flush_alicdn() {
	if [ -z "$2" ];then return 1;fi
	local hostname=$1
	local location=$2
	# 如果主机名不在开启CDN的列表之内 要检查一下下面两种情况
	if ! grep -q -i -e "${hostname}" ${CDN_ENABLED_HOSTS} ; then
		if echo "${hostname}" | grep -q -e 'demo.umaman.com' ;then
			# demo环境域名 直接返回
			return
		else
			# 有必要检查一下是否绑定了其他域名并且开启了CDN
			# 以下用域名(hostname)查找该站点绑定的其它域名:hostname-->vhost.conf-->server_name 
			vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
			if [ ! -f "$vhostfile" ];then
				# 配置文件没找到 直接退出
				return
			fi

			for domain_name in $(grep -P -e "^[ |\t]*server_name.*" $vhostfile | sed 's/server_name//g;s/;//g;s/ \|\t/\n/g' | sort | uniq);do
				# 检查绑定的其它域名是否在开启CDN的列表之内
				if grep -q -i -e "${domain_name}" ${CDN_ENABLED_HOSTS} ; then
					hostname_enabled_cdn="${domain_name}"
				fi
			done

			if [ -z "$hostname_enabled_cdn" ] ;then
				# 绑定的其它域名也不在开启CDN的列表之内 直接退出
				return
			else
				hostname=$hostname_enabled_cdn
			fi
		fi
	fi

	echo -en "flush_alicdn Host:${hostname} Path:${location} "
	# 获取 api url
	local ObjectPath="${hostname}${location}"
	local url=$(python ${CDNAPI} Action=RefreshObjectCaches ObjectType=Directory ObjectPath=${ObjectPath})
	# 获取url失败,直接退出
	if ! echo "${url}" | grep -q -i -e '^http' ;then echo 获取url失败;return ;fi

	# 发出刷新请求并记录 task_id
	local task_id=$(curl -m 30 -s $url 2>/dev/null | php -r "\$a = json_decode(file_get_contents('php://stdin'));echo \$a->RefreshTaskId;")
	if [ -z "$task_id" ];then echo 刷新失败,没有获取到 task_id;return ; fi

	# 等待45秒后,查询刷新结果
	echo -n "task_id:$task_id "
	sleep 45
	get_flushresult $task_id
}

# 查询用户名下所有的域名与状态,放在Crontab里,每小时执行1次,用于更新开启CDN 并且 已经解析到CDN 的域名列表
# https://docs.aliyun.com/#/pub/cdn/api-reference/cdndomain&DescribeUserDomains
get_userdomains() {
	# 获取 api url 一页显示50条记录
	local url=$(python ${CDNAPI} Action=DescribeUserDomains DomainStatus=online PageNumber=1 PageSize=50)
	# 请求api获取响应
	respones=$(curl -m 30 -s $url 2>/dev/null )
	# 如果响应有问题直接退出
	if ! echo "${respones}" | grep -q -i -e 'DomainName' ;then return ;fi
	# 清空列表
	:> ${CDN_ENABLED_HOSTS}
	# 解析api返回的结果: hostname --- cname 
	echo "${respones}" | php -r "\$a = json_decode(file_get_contents('php://stdin')); print_r(\$a->Domains->PageData);" \
	| grep -e 'Cname' -e 'DomainName'|tr -d '\n'|tr -d ' '|sed 's/\[Cname\]/\n/g;s/=>/ /g;s/\[DomainName\]//g'|grep -v -e '^$' \
	| while read cname hostname ;do
		# 检查(域名是否解析到对应的CNAME)并写入列表
		if /usr/bin/dig +time=60 $hostname 2>&1|grep -q -i -e "CNAME.*${cname}" ;then
			echo $hostname | tee -a ${CDN_ENABLED_HOSTS}
		fi
	done
}

# 测试
#flush_alicdn 150901fg0440.umaman.com /
#source /usr/local/sbin/sc_cdn_functions.sh;flush_alicdn 150901fg0440.umaman.com /
#echo 9627e13babfbc8bfb64eee3ab105a4ab flush_alicdn 150901fg0440.umaman.com /a.jpg|/usr/local/sbin/CommonWorker.sh
#echo 9627e13babfbc8bfb64eee3ab105a4ab flush_alicdn 150901fg0440.umaman.com /a.jpg|/usr/bin/gearman -h 10.0.0.200 -f "CommonWorker_10.0.0.200" 
#
# 测试 http://211.152.60.33/purge/index.php
#http://150901fg0440.umaman.com/jquery-scrollTo.js?1443074347848
#http://150901fg0440.umaman.com/jquery-scrollTo.js
#http://150901fg0440.umaman.com/jq/
# 预期结果
#Sep 28 09:47:04 localhost wanlong: flush_alicdn Host:150901fg0440.umaman.com Path:/jquery-scrollTo.js task_id:140560193 Complete get_flushresult_ret:0 
#Sep 28 09:47:04 localhost wanlong: flush_alicdn Host:150901fg0440.umaman.com Path:/jquery-scrollTo.js?1443074347848 task_id:140560193 Complete get_flushresult_ret:0 
#Sep 28 09:47:04 localhost wanlong: flush_alicdn Host:150901fg0440.umaman.com Path:/jq/ task_id:140560193 Complete get_flushresult_ret:0 
#Sep 28 09:47:05 localhost wanlong: flush_alicdn Host:150901fg0440.umaman.com Path:/jq/ task_id:140560193 Complete get_flushresult_ret:0 
#
#get_userdomains > /var/lib/cdn_enabled_hosts
