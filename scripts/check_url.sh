#!/bin/sh

uma(){
	TMPFILE="/tmp/$$.txt"
	/usr/bin/curl -m 5 -s http://scrm.umaman.com/admin/index/phpinfo > $TMPFILE
	#M=$(/usr/bin/wc -l $TMPFILE | awk '{print $1}')
	M=$(/usr/bin/nl $TMPFILE |tail -n 1|awk '{print $1}')
	H=$(/bin/grep -n '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "DTD/xhtml1-transitional.dtd">' $TMPFILE |/usr/bin/tail -n 1|awk -F':' '{print $1}')
	B=$(/bin/grep -n '</div></body></html>$' $TMPFILE |/usr/bin/head -n 1|awk -F':' '{print $1}')
	rm $TMPFILE -f
	#echo "M:$M H:$H B:$B";exit
	if [ $H -eq 1  -a $B -eq $M ];then
		echo 1
	else
		echo 0
	fi
}

$1
