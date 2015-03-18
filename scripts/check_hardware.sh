#!/bin/sh

MEGACLI='/usr/bin/sudo /opt/MegaRAID/MegaCli/MegaCli64'

raid(){
	if $MEGACLI -LDInfo -LALL -aAll 2>&1 | grep -e '^State'|grep -q -v -e 'Optimal' &>/dev/null ;then
		#异常状态
		echo 0
		return 1
	else
		#正常状态
		echo 1
		return 0
	fi
}

disk(){
	#$MEGACLI -PDList -aAll 2>&1 | grep -e '[Media|Other] Error Count' 2>&1 | while read media error count n ;do
	while read media error count n ;do
		if [ $n -gt 0 ] ;then
			#异常状态,报告并退出
			echo 0
			return 1
		fi
	done <<EOF
		$($MEGACLI -PDList -aAll 2>&1 | grep -e '[Media|Other] Error Count' 2>&1)
EOF
	#正常状态
	echo 1
	return 0
}


if grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{?" $0 ;then
	$1
else
	echo "cmd not found,nothing done."
	exit 1
fi
