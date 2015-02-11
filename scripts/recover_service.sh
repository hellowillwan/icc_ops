#!/bin/sh
# zabiix检测到一个服务有问题后,执行这个脚本恢复服务

#/home/wanlong/PKG/check_services.sh php|awk 'BEGIN{ORS=" "}/^10.0.0.1[1-3]/{print substr($3,17)}END{print "\n"}'|while read a b c ;do
#	number=$(/usr/bin/php -r "echo max(${a},${b},${c})-min(${a},${b},${c});")
#	if [ ${number} -gt 100 ];then
#		/usr/bin/func 'app0[1-4]' call command run '/usr/sbin/nginx -s stop;sleep 1;/etc/init.d/php-fpm restart;/usr/sbin/nginx'
#		/usr/bin/logger "$a $b $c $number php-fpm reload $?"
#	else
#		echo $a $b $c $number OK.
#	fi
#done



restart_php () {
	if [ -z "$1" ];then
		echo "parameter missing."
		return 1
	else
		case "$1" in
			'10.0.0.10')
				host='app01'
				;;
			'10.0.0.11')
				host='app02'
				;;
			'10.0.0.12')
				host='app03'
				;;
			'10.0.0.13')
				host='app04'
				;;
			*)
				return 2
		esac
	fi
	/usr/bin/func "$host" call command run \
	'/usr/sbin/nginx -s stop; sleep 1; /etc/init.d/php-fpm restart; /usr/sbin/nginx; /usr/bin/logger "restarted nginx&php"'

	/usr/bin/logger "restarted nginx&php at $host ret:$?"
}


if [ -z "$2" ] ;then
	echo "parameter error."
	$0 Usage 0
	exit 0
else
	cmd="$1"
fi

case "$cmd" in
  restart_php)
        $cmd $6
        ;;
  *)
        echo "Usage: $0 {restart_php} parameter"
        exit 1
esac
