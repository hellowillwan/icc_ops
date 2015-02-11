#!/bin/sh

MEGACLI='/usr/bin/sudo /opt/MegaRAID/MegaCli/MegaCli64'

raid(){
	if $MEGACLI -LDInfo -LALL -aAll 2>&1 | grep -e '^State'|grep -v -e 'Optimal' &>/dev/null ;then
		echo 0
		return 1
	else
		echo 1
		return 0
	fi
}

disk(){
	#$MEGACLI -PDList -aAll 2>&1 | grep -e '[Media|Other] Error Count' 2>&1 | while read media error count n ;do
	while read media error count n ;do
		if [ $n -gt 0 ] ;then
			echo 0
			return 1
		fi
	done <<EOF
		$($MEGACLI -PDList -aAll 2>&1 | grep -e '[Media|Other] Error Count' 2>&1)
EOF

	echo 1
	return 0
}


if [ "$1" = 'raid' -o "$1" = 'disk' ] ;then
	$1
else
	exit 1
fi
