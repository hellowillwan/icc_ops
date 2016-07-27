# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		edit_file [read|write]
#
#

#
DT2="date '+%Y-%m-%d_%H-%M-%S'"

edit_file() {
	if [ -z "$2" ] ;then
		echo "Action parameter missing."
		return 0
	else
		if [ "$2" = 'weshop_enabled_hosts' ];then
			local file='/var/lib/weshop_enabled_hosts'
		elif [ "$2" = 'weshop_filelist' ];then
			local file='/var/lib/weshop_filelist'
		else
			echo 'unkown file.'
			return 1
		fi

		if [ "$1" = "read" ];then
			cat $file
		elif [ "$1" = "write" -a -n "$2" -a -n "$3" ];then
			# backup file
			cp -a $file ${file}_$(date +%s_%N)
			# overwrite file
			echo "$3"|base64 -d |sort|uniq > $file
			if [ "$?" -eq 0 ];then
				echo "配置保存成功,当前配置文件:"
			else
				echo "配置保存失败,当前配置文件:"
			fi
				ls -lht $file
				echo "文件内容如下:"
				cat $file
		else
			echo "Bad action parameter or cfg_text missing."
			return 0
		fi
	fi
}

