# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		cleanup_wsdl
#

#
# cleanup /tmp/wsdl* files on host200 and all apps.
DT2="date '+%Y-%m-%d %H:%M:%S'"
APP_IP_ARY=('10.0.0.10' '10.0.0.11' '10.0.0.12' '10.0.0.13')


p_ret() {
	if [ -z "$3" ];then
		return 1
	fi

	if [ "$1" -eq 0 ];then
		echo -e "$2"
	else
		echo -e "$3"
	fi
}

cleanup_wsdl() {
	rm /tmp/wsdl* -f &>/dev/null;ls /tmp/wsdl* &>/dev/null
	p_ret $? "$(eval $DT2)  10.0.0.200 清除WSDL缓存失败,请重试." "$(eval $DT2)  10.0.0.200 清除WSDL缓存成功."

	/usr/bin/func 'app*' call command run 'rm /tmp/wsdl* -f;ls /tmp/wsdl*' | sort | while read line;do
		echo "$line" | tr -d "',()[]" | while read hostname retcode omit;do
			hostname="$(($(echo $hostname|sed 's/app0//')-1))"
			hostip="${APP_IP_ARY[$hostname]}"
			p_ret $retcode "$(eval $DT2)  ${hostip} 清除WSDL缓存失败,请重试." "$(eval $DT2)  ${hostip} 清除WSDL缓存成功."
			unset hostip ; unset hostname
		done
	done
}

