#!/bin/sh
#
# 检查正在使用的脚本是否最新
#

echo -e "检查脚本文件"
cd /home/wanlong/PKG/ops/scripts/
svn up
svn st
echo

for file_using in /usr/local/sbin/*;do
	file_newest="/home/wanlong/PKG/ops/scripts/${file_using##*/}"
	if ls $file_newest &>/dev/null ;then
		diff  $file_newest $file_using || echo -e "diff ${file_newest} ${file_using}\n"
	fi
done

# purge cache
diff  -x 'accounts.php' -r /var/www/html/purge /home/wanlong/PKG/ops/scripts/purge | grep -v -e '^Only in /home/wanlong/PKG/ops/scripts/purge'

#
# 检查ngx配置文件
#
echo -e "\n检查ngx配置文件"
cd /home/wanlong/PKG/ops/ngx_cfg/
svn up
svn st
echo

diff -r /usr/local/share/commonworker/ /home/wanlong/PKG/ops/ngx_cfg/cfg_template/ 2>&1|grep -v -e '\.svn$' -e '^Only in /home/wanlong/PKG/ops/ngx_cfg'
diff -r /home/proxy_nginx_conf/ /home/wanlong/PKG/ops/ngx_cfg/proxy_nginx_conf/ 2>&1|grep -v -e '\.svn$' -e '^Only in /home/wanlong/PKG/ops/ngx_cfg'
diff -r /home/app_nginx_conf/ /home/wanlong/PKG/ops/ngx_cfg/app_nginx_conf/ 2>&1|grep -v -e '\.svn$' -e '^Only in /home/wanlong/PKG/ops/ngx_cfg'
diff -r /home/app_php_conf/ /home/wanlong/PKG/ops/app_php_conf/ 2>&1|grep -v -e '\.svn$' -e '^Only in /home/wanlong/PKG/ops/app_php_conf'

#
# 检查 zabbix 配置文件
#
echo -e "\n检查 zabbix 配置文件"
cd /home/wanlong/PKG/ops/zabbix_cfg/
svn up
svn st
echo

diff -r /usr/local/zabbix-2.2.3/etc/ /home/wanlong/PKG/ops/zabbix_cfg/

echo "同步命令"
echo "rsync -rptcvz /usr/local/share/commonworker/ /home/wanlong/PKG/ops/ngx_cfg/cfg_template/"
echo "rsync -rptcvz /home/proxy_nginx_conf/ /home/wanlong/PKG/ops/ngx_cfg/proxy_nginx_conf/"
echo "rsync -rptcvz /home/app_nginx_conf/ /home/wanlong/PKG/ops/ngx_cfg/app_nginx_conf/"
echo "rsync -rptcvz /home/app_php_conf/ /home/wanlong/PKG/ops/app_php_conf/"
echo "rsync -rptcvz /usr/local/zabbix-2.2.3/etc/ /home/wanlong/PKG/ops/zabbix_cfg/"
