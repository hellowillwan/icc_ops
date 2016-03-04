#!/bin/sh

#用于清除Nginx 缓存;
#如果PATH为/则清除整站缓存,否则清除指定location|目录|路径的缓存.
#启动方法
#GEARMAN='/usr/bin/gearman -h 10.0.0.200 '
#FUNCTION_NAME='purge_10.0.0.15'
#$GEARMAN -w -f $FUNCTION_NAME -- $0
#测试方法
# clear;find /home/proxy/cache/syoss.umaman.com/;echo 'syoss.umaman.com' '/'|  PurgeCacheWorker.sh ;tail -n 1 /var/log/purgecacheworker.log;find /home/proxy/cache/syoss.umaman.com/
# 预期结果：会看到缓存目录的变化
# echo syoss.umaman.com /c/ | /usr/bin/gearman -h 10.0.0.200 -f "purge_10.0.0.1"
# 预期结果：2015-09-24 14:38:05     Host:syoss.umaman.com   Path:/c/        2015-09-24 14:39:08 目录清除成功.
#已修正:多域名站点清缓存的时,传入的域名会被重新取值为配置文件里cache_zone的名字,在清除指定location的缓存时,会不正常,清除整站及单个URL没影响.

NGXCONF_DIR='/usr/local/tengine/conf/'
NGX_CACHE_ZONE_CONF="${NGXCONF_DIR}cache-zone.conf"
LOGFILE='/var/log/purgecacheworker.log'
DT2="date '+%Y-%m-%d %H:%M:%S'"

purgecache() {
	if [ -z "$3" ];then
		echo "参数缺失" >> $LOGFILE
		return 1
	else
		cache_path="$1"
		hostname="$2"
		location="$3"
	fi

	if [ "$location" = '/' ];then
		#清除整站缓存
		rm ${cache_path}/* -rf &> /dev/null || rm ${cache_path}/* -rf &> /dev/null || rm ${cache_path}/* -rf &> /dev/null
		#reload nginx
		#sleep 1
		#/usr/local/tengine/sbin/nginx -s reload &>/dev/null
		[ $? -eq 0 ] && echo "$(eval $DT2) 整站清除成功." >> $LOGFILE || echo "$(eval $DT2) 整站清除失败." >> $LOGFILE
	else
		#清除指定目录
		(grep -rl "KEY: ${hostname}${location%/}" ${cache_path} |/usr/bin/xargs -i rm -f {} )
		(grep -rl "KEY: ${hostname}${location%/}" ${cache_path} |/usr/bin/xargs -i rm -f {} )
		#reload nginx
		#sleep 1
		#/usr/local/tengine/sbin/nginx -s reload &>/dev/null
		[ $? -eq 0 ] && echo "$(eval $DT2) 目录清除成功." >> $LOGFILE || echo "$(eval $DT2) 目录清除失败." >> $LOGFILE
	fi
}

flush_alicdn() {
	# 刷新CDN缓存
	local hostname=$1
	local location=$2
	local localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
	echo $localkey flush_alicdn $hostname $location | /usr/bin/gearman -h 10.0.0.200 -f "CommonWorker_10.0.0.200" -b
}

while read hostname location ; do
	if [ -z "$hostname" ] || [ "$hostname" = ' ' ];then
		echo -e "$(eval $DT2)\tHost:${hostname}\tPath:${location}\t主机名不合法" >> $LOGFILE
		exit
	else
		echo -en "$(eval $DT2)\tHost:${hostname}\tPath:${location}\t" >> $LOGFILE
		#以下用域名(hostname)查找缓存目录路径:hostname-->vhost.conf-->keys_zone name-->proxy cache path
		vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
		if [ ! -f "$vhostfile" ];then
			echo "站点vhost配置文件没找到." >> $LOGFILE
		else
			zone_name=$(grep -P -e '^[^#]*proxy_cache_purge[ |\t]' $vhostfile|head -n 1 |awk '{print $2}')
			cache_path=$(grep -e "keys_zone=${zone_name}:" $NGX_CACHE_ZONE_CONF |grep -P -v -e '^[ |\t]*#'|awk '{print $2}')
			if [ -d "$cache_path" ];then
				purgecache $cache_path $hostname $location
			else
				echo "站点缓存目录不存在." >> $LOGFILE
			fi
		fi

		# 刷新CDN缓存
		flush_alicdn $hostname $location
	fi
done
