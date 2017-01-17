#!/bin/bash
#
# 查询、检查、修改 nginx config 的几个工具函数
#

#
# 查询全局 缓存 列表
#
get_global_cache_list() {
	local global_cache_conf='/home/proxy_nginx_conf/global.conf'
	grep -B 7 -P -e '^[ \t]*proxy_cache_valid' ${global_cache_conf} \
	| grep -P -e '^[ \t]*location' \
	| awk '{print $3}'
	#| sed 's/[(){}]//g' \
}

#
# weshop 相关项目是否新增 icatholiccloud 域名
# 谨慎使用，肯能会造成配置文件错误
#
enable_icatholiccloud_domain() {
	localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)
	for p in `cat /var/lib/weshop_php_enabled_projects |grep -v -e '__ALL' -e 'haoyada'`;do
		for f in  /home/{app_nginx_conf,proxy_nginx_conf}/vhost/${p}.conf /home/{app_nginx_conf,proxy_nginx_conf}/demo/${p}demo.conf;do
		#for f in  /home/{app_nginx_conf,proxy_nginx_conf}/vhost/${p}.conf ;do
		#for f in  /home/{app_nginx_conf,proxy_nginx_conf}/demo/${p}demo.conf ;do
			#p="${p}demo"
			echo grep server_name $f
			#grep -P -e '^[ |\t]*server_name.*icatholiccloud' $f |tr ' ' '\n'| grep -i -P -e '.icatholiccloud.(cn|com|net)'|wc -l
			grep -o -i -P -e ' [\w]+.icatholiccloud.(cn|com|net)' $f
			#if ! grep -q -P -e '^[ |\t]*server_name.*icatholiccloud' $f ;then
			#	echo ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
			#	echo $f
			#	echo $localkey add_hostname ${p} ${p}.icatholiccloud.cn | /usr/local/sbin/CommonWorker.sh
			#	echo $localkey add_hostname ${p} ${p}.icatholiccloud.com | /usr/local/sbin/CommonWorker.sh
			#	echo $localkey add_hostname ${p} ${p}.icatholiccloud.net | /usr/local/sbin/CommonWorker.sh
			#fi
		done
	done
}

#
# weshop 相关项目 反代 vr 直播流的配置；已生效；
#
enablevr() {
	for p in `cat /var/lib/weshop_php_enabled_projects |grep -v -e 'ALL_PROJECTS'`;do
		echo project: $p
		for f in  /home/proxy_nginx_conf/demo/${p}demo.conf /home/proxy_nginx_conf/vhost/${p}.conf ;do
			ls $f && \
			grep 'rp_vr.conf' $f
			#grep -q 'websocket chat service' $f && \
			#sed '/websocket chat service/i\\tinclude rp_vr.conf;\n' $f |grep -B 2 'websocket chat service'
		done
		echo
	done
}

#
# 检查 weshop 相关项目 是否有 CORS header 配置
#
check_CORS_header() {
	for p in `cat /var/lib/weshop_php_enabled_projects |grep -v -e 'ALL_PROJECTS'`;do
		for f in  /home/proxy_nginx_conf/demo/${p}demo.conf /home/proxy_nginx_conf/vhost/${p}.conf ;do
			grep -A 10 -i -e 'location.*jpg' $f |grep -q Access-Control-Allow
			local ret=$?
			if [ $ret -gt 0 ];then
				echo "$f CORS header not config!!!"
				echo
			fi
		done
	done
}

#
# 打开 weshop 相关项目的 ssl；未生效；
#
enablessl() {
	for p in `cat /var/lib/weshop_php_enabled_projects |grep -v -e 'ALL_PROJECTS'`;do
		echo project: $p
		for f in  /home/proxy_nginx_conf/demo/${p}demo.conf /home/proxy_nginx_conf/vhost/${p}.conf ;do
			# ssl for umaman;
			sed '/^[ |\t]\+listen[ |\t]\+80/c\\tlisten  443 ssl;\n\tssl on;\n\tssl_certificate ssl/umaman.com.crt;\n\tssl_certificate_key ssl/umaman.com.key;' $f > ./${f##*/}_sslforuma.tmp
			sed -i 's#[ |\t]\+\(\w\+\.\)\+icatholiccloud\.\(com\|cn\|net\)##g' ./${f##*/}_sslforuma.tmp
			# ssl for icatholiccloud;
			sed '/^[ |\t]\+listen[ |\t]\+80/c\\tlisten  443 ssl;\n\tssl on;\n\tssl_certificate ssl/icatholiccloud.com.crt;\n\tssl_certificate_key ssl/icatholiccloud.com.key;' $f > ./${f##*/}_sslforicc.tmp
			sed -i 's#[ |\t]\+\(\w\+\.\)\+umaman\.\(com\|cn\|net\)##g' ./${f##*/}_sslforicc.tmp
		done
		echo
	done
}

echo \
had.pho.uma.com buy.wig.icc.com jut.dtl.uma.com gyr.icc.com huv.uma.com lta.icc.com \
pho.uma.net wig.icc.net dtl.uma.net gyr.icc.net huv.uma.net lta.icc.net \
pho.uma.cn wig.icc.cn dtl.uma.cn gyr.icc.cn huv.uma.cn lta.icc.cn \
| grep -o -P -e '[ |\t]*[\w\.]+\.(uma)\.(com|net|cn)'

