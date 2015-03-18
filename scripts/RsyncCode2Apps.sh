#!/bin/sh

LOGFILE='/var/log/RsyncCode2APP.log'
DT1="date '+%H_%M'"
DT2="date '+%Y-%m-%d %H:%M:%S'"

APPS='
10.0.0.10
10.0.0.11
10.0.0.12
10.0.0.13
10.0.0.1
10.0.0.2
'

#仅在凌晨2:30的同步命令中带checksum这个参数
if [ "$(eval $DT1)" = '02_30' ];then
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
			parameter='-vrptlc '
		else
			parameter='-vrptl '
		fi

		/bin/env USER='backup' RSYNC_PASSWORD='123456' /usr/bin/rsync \
		${parameter} \
		--blocking-io \
		--exclude='.svn' \
		--exclude='*.log' \
		--exclude='*/cache/*' \
		/home/webs/ \
		${ip}::web/  &> /var/log/RsyncCode2APP-${ip}-$(eval $DT1).log

		echo -e "$(eval $DT2)\t RsyncCode2APP ${2} ${ip}: $?." >> $LOGFILE
	fi

}

#初始化代码源目录的属主和权限
rm /home/webs/*/cache/* -rf &>/dev/null &
for d in  /home/webs/* ; do
	ls $d -l | grep -e '^drwxrwxrwx.*cache$' &>/dev/null || chmod -R 777 $d/cache &>/dev/null &
done
chown -R ftpuser.ftpuser /home/webs/* &>/dev/null &

#按crontab周期性执行同步
for ip in ${APPS} ;do
	RsyncCode2App ${ip} "${checksum}" & 
done

