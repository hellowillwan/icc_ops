#!/bin/sh
#
# 从线上下载配置、编辑、同步到线下运行环境
#

## 变量
#
# 脚本名称
SCRIPT_NAME=$(/usr/bin/basename $0 | /usr/bin/sed 's/\..*//g')
# 从线上下载配置文件 并进行编辑 的目录
CFG_WORKING_DIR='/home/Backup/Docker_build'

## 先设置权限
#
sudo chown -R wanlong.wanlong /home/Backup/Docker_build/{proxy_nginx_conf,app_nginx_conf,app_php_conf,tmp_vhost} /etc/{proxy_nginx_conf,app_nginx_conf,app_php_conf}


## 下载线上的配置文件
#
rsync --delete -a -e ssh 211.152.60.33:/home/app*_conf ${CFG_WORKING_DIR}/
rsync --delete -a -e ssh 211.152.60.33:/home/proxy*_conf ${CFG_WORKING_DIR}/
/usr/bin/logger "${SCRIPT_NAME} 下载线上的配置文件 完成"


## 编辑Dev环境 app nginx config
#
# 注释掉demo和alias目录的配置
sed -i -e 's/\(include.*demo.*conf;\)/#\1/' ${CFG_WORKING_DIR}/app_nginx_conf/nginx.conf
sed -i -e 's/\(include.*alias.*conf;\)/#\1/' ${CFG_WORKING_DIR}/app_nginx_conf/nginx.conf
# 设置环境参数
sed -i 's/production/testing/' ${CFG_WORKING_DIR}/app_nginx_conf/fastcgi_params_production
# 传递给 php 的环境变量
#sed -i '/fastcgi_param  ICC_MEMCACHED_SERVER/c\fastcgi_param  ICC_MEMCACHED_SERVER  192.168.5.41:11211;' \
sed -i "s/\(^[ |\t]*fastcgi_param[ |\t]\+ICC_MEMCACHED_SERVER[ |\t]\+\).*/\1'192.168.5.41:11211';/" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
#sed -i "/fastcgi_param  MEMCACHED_SERVER/c\fastcgi_param  MEMCACHED_SERVER  'tcp://192.168.5.41:11211/?weight=20';" \
sed -i "s#\(^[ |\t]*fastcgi_param[ |\t]\+MEMCACHED_SERVER[ |\t]\+\).*#\1'tcp://192.168.5.41:11211/?weight=20';#" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
sed -i "s/\(^[ |\t]*fastcgi_param[ |\t]\+GEARMAN_SERVER[ |\t]\+\).*/\1'192.168.5.41:4730';/" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
#sed -i "/fastcgi_param  ICC_REDIS_MASTERS/c\fastcgi_param  ICC_REDIS_MASTERS  192.168.5.41:7001,192.168.5.41:7002,192.168.5.41:7003;" \
sed -i "s#\(^[ |\t]*fastcgi_param[ |\t]\+ICC_REDIS_MASTERS[ |\t]\+\).*#\1'192.168.5.41:7001,192.168.5.41:7002,192.168.5.41:7003';#" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
#sed -i "/fastcgi_param  ICC_REDIS_SLAVES/c\fastcgi_param  ICC_REDIS_SLAVES  192.168.5.41:7004,192.168.5.41:7005,192.168.5.41:7006;" \
sed -i "s#\(^[ |\t]*fastcgi_param[ |\t]\+ICC_REDIS_SLAVES[ |\t]\+\).*#\1'192.168.5.41:7004,192.168.5.41:7005,192.168.5.41:7006';#" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
#sed -i "/fastcgi_param  ICC_MONGOS_ICC/c\fastcgi_param  ICC_MONGOS_ICC  192.168.5.40:57017;" \
sed -i "s#\(^[ |\t]*fastcgi_param[ |\t]\+ICC_MONGOS_ICC[ |\t]\+\).*#\1'192.168.5.40:57017';#" \
	${CFG_WORKING_DIR}/app_nginx_conf/fcgi.conf
# 修改默认vhost
# 允许从内网访问 /NginxStatus /status 状态页面
sed -i -e '/allow 10.0.0/a\\t\tallow 192.168.0.0/16;' \
	${CFG_WORKING_DIR}/app_nginx_conf/vhost/default_server.conf
# 下载 xdebug_log 文件的配置
sed -i -e "/location \/ /i\\\tlocation \/xdebug_log_dir {\\n\\t\\troot /home/webs/fgblog;\\n\\t\\tautoindex on;\\n\\t}\\n" \
	${CFG_WORKING_DIR}/app_nginx_conf/vhost/default_server.conf
# 修改所有vhost 添加 dev,test 域名
for vhostfile in $(find ${CFG_WORKING_DIR}/app_nginx_conf/vhost/ \
			| grep -e '\.conf$' \
			| grep -v -P '\.(com|cn|net).conf' \
			| grep -v -e 'default_server.conf' -e 'example_ssl.conf$'
);do
	project_name=${vhostfile##*/}
	project_name=${project_name%%.*}
	domainnames_add="${project_name}.umaman.xyz ${project_name}.dev.umaman.xyz ${project_name}.test.umaman.xyz ${project_name}.dev.umaman.com"
	# 编辑添加 dev,test 域名
	sed -i "s/\(^[ |\t]*server_name.*\);/\1 ${domainnames_add};/" $vhostfile
	# 检查
	if ! grep -q -P "^[ |\t]*server_name.*${domainnames_add};" $vhostfile ;then
		/usr/bin/logger "${SCRIPT_NAME} edit $vhostfile fail."
	fi
	# 设置 webroot 变量
	sed -i "/\(^[ |\t]*\)root/i\\\tset \$webroot '/home/webs/dev';\n\tif (\$host ~* \".test.umaman.xyz\$\") { set \$webroot '/home/webs/test';}" $vhostfile
	# 编辑 root 路径
	#sed -i 's/\(\/home\/webs\)/\1\/dev/' $vhostfile
	sed -i 's|\(^[ |\t]*root[ |\t]*\)\/home\/webs|\1$webroot|' $vhostfile
	# 编辑增加 autoindex on 指令
	sed -i '/^[ |\t]*root/a\\tautoindex on;' $vhostfile
done
# 补上一些线上没有的vhost
cp -f /home/Backup/Docker_build/tmp_vhost/*.conf ${CFG_WORKING_DIR}/app_nginx_conf/vhost/
#
/usr/bin/logger "${SCRIPT_NAME} 编辑Dev环境 app nginx config 完成"


## 编辑Dev环境 app php config
#
# 修改 php session.save_path memcached 地址
sed -i 's/10.0.0.20:1121[1-2]/192.168.5.41:11211/g' \
	${CFG_WORKING_DIR}/app_php_conf/php-*/php-fpm.d/www.conf
/usr/bin/logger "${SCRIPT_NAME} 编辑Dev环境 app php config 完成"


## 目前没有编辑 proxy nginx config
#


## 同步修改后的配置文件到工作目录
#
rsync --delete -a ${CFG_WORKING_DIR}/app*_conf /etc/
#rsync --delete -a ${CFG_WORKING_DIR}/proxy*_conf /etc/
/usr/bin/logger "${SCRIPT_NAME} 同步修改后的配置文件到工作目录 完成"


## 重启 ngx
#
sudo bash -c ". /root/.bashrc;ngx_reload"
