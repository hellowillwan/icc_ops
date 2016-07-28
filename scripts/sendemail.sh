#!/bin/sh
#
# run as a Media types used in Actions in Zabbix
#

if [ -z "$3" ] ;then
	echo "$(date) : parameters error. $to_list || $subject || $content" >> /tmp/sendemail.log
	exit
fi

to_list=$1
subject=$2
content=$3
echo "$(date) : $to_list || $subject || $content" >> /tmp/sendemail.log
	#/usr/local/sbin/sendemail.py -s smtp.catholic.net.cn -f serveroperations@catholic.net.cn -u serveroperations@catholic.net.cn -p zd0nWmAkDH_tUwFl1wr \
	/usr/local/sbin/sendemail.py -s smtp.icatholic.net.cn -f system.monitor@icatholic.net.cn -u system.monitor@icatholic.net.cn -p abc123 \
	-t "$to_list" \
	-S "$subject" \
	-m "$content"
[ $? -eq 0 ] && echo "$(date) : mail sent." >> /tmp/sendemail.log
