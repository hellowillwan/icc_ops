#!/bin/sh

LOGFILE='/var/log/RsyncCode2APP.log'
DT1="date '+%H_%M'"
DT2="date '+%Y-%m-%d %H:%M:%S'"

APPS='
172.18.1.10
172.18.1.11
172.18.1.12
172.18.1.13
172.18.1.14
172.18.1.1
172.18.1.2
'

#仅在凌晨2:30的同步命令中带checksum这个参数
if [ "$(eval $DT1)" = '02_30' ];then
		# 顺便删除 .svn .git 文件夹
		find /home/webs/ -type d  -name '.svn'|xargs rm -rf &
		find /home/webs/ -type d  -name '.git'|xargs rm -rf &
		checksum='checksum' 
else
	:
fi

RsyncCode2App ()
{
	if [ -z "$1" ] ;then
		echo "Missing Parameter."
		return 1
	else
		if [ "$2" = 'checksum' ];then
			parameter='-vrptlc --delete --delete-excluded '
		else
			parameter='-vrptl --delete --delete-excluded '
		fi

		/bin/env USER='backup' RSYNC_PASSWORD='123456' /usr/bin/rsync \
		${parameter} \
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
		/home/webs/ \
		${ip}::web/  &> /var/log/RsyncCode2APP-${ip}-$(eval $DT1).log

		echo -e "$(eval $DT2)\t RsyncCode2APP ${2} ${ip}: $?." >> $LOGFILE
	fi

}

#初始化代码源目录的属主和权限
rm /home/webs/*/{cache,logs}/* -rf &>/dev/null &
chmod -R 777 /home/webs/*/{cache,logs} &>/dev/null &
chown -R ftpuser.ftpuser /home/webs/* &>/dev/null &

#按crontab周期性执行同步
for ip in ${APPS} ;do
	RsyncCode2App ${ip} "${checksum}" & 
done

