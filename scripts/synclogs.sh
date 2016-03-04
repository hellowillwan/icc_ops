#!/bin/sh

# 同步系统日志
#USER='backup' RSYNC_PASSWORD='12345678' /usr/bin/rsync -tv /var/log/messages 172.18.1.200::server_log_dir/$(hostname)/
/usr/bin/rsync -tv /var/log/messages /tmp/server_log_dir/host200/
#
# 同步 mongodb 日志
#USER='backup' RSYNC_PASSWORD='12345678' /usr/bin/rsync -rtv --delete /home/60000/log/ 172.18.1.200::server_log_dir/$(hostname)/mongo/
#
# 同步每个 php 容器的日志
#for ctn_tmp_dir in /tmp/icc_appserver_c*;do
#	# nginx 错误日志
#	USER='backup' RSYNC_PASSWORD='12345678' /usr/bin/rsync -rtv --delete \
#				--exclude='*com.log' \
#				--exclude='*cn.log' \
#				--exclude='*access.log' \
#				$ctn_tmp_dir/nginx/ \
#				172.18.1.200::server_log_dir/$(hostname)/${ctn_tmp_dir##*/}/nginx/
#	# php-fpm 相关日志
#	USER='backup' RSYNC_PASSWORD='12345678' /usr/bin/rsync -rtv --delete \
#				$ctn_tmp_dir/php-fpm/ \
#				172.18.1.200::server_log_dir/$(hostname)/${ctn_tmp_dir##*/}/php-fpm/
#done
#
# 同步redis 日志
/usr/bin/rsync -rtv --delete /home/redis-cluster/log/ /tmp/server_log_dir/host200/redis/
#USER='backup' RSYNC_PASSWORD='12345678' /usr/bin/rsync -rtv --delete /home/redis-cluster/log/ 172.18.1.200::server_log_dir/${hostname}/redis/
