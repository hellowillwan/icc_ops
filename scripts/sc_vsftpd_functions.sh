# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		vsftpd_account [check|add|delete] fqdn username
# usage		vsftpd_control [start|stop|restart|try-restart|force-reload|status]
#

#
# add a account to vsftpd and make users_configuration
#DT2="date '+%Y-%m-%d %H:%M:%S'"

VSFTPD_CTL='/etc/init.d/vsftpd'
VSFTPD_CFG_DIR='/etc/vsftpd/'
VSFTPD_USERCFG_DIR="${VSFTPD_CFG_DIR}user_config/"
VSFTPD_ACCOUNT_TXT="${VSFTPD_CFG_DIR}account.txt"
VSFTPD_ACCOUNT_DB="${VSFTPD_CFG_DIR}account.db"
RENEW_ACCOUNT_DB="db_load -T -t hash -f ${VSFTPD_ACCOUNT_TXT} ${VSFTPD_ACCOUNT_DB} "

gen_random_str() {
	random_str=`head -c 10 /dev/urandom |md5sum |head -c 16`
	echo $random_str
}


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

chk_hostname() {
	if [ -z "$1" ];then
		return 1
	else
		hostname=$1
	fi

	if echo ${hostname}|grep -e '\.' -q  && echo ${hostname}|grep -P -e '\.(com|cn|org|net)$' -q ;then
		#是合法域名
		NGXCONF_DIR='/home/nginx/'
		vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
		if [ ! -f "$vhostfile" ];then
			#不是配置过的域名,退出
			#echo "此域名没有配置到系统."
			return 1
		else
			#域名有配置过
			return 0
		fi
	else
		#不是合法域名
		#echo "不是合法域名."
		return 1
	fi
}

get_dir_from_hostname() {
	if [ -z "$1" ];then
		#echo "缺少参数."
		return 1
	else
		hostname=$1
	fi

	#域名经过检查,确认有配置过,从配置文件查找webroot目录名
	NGXCONF_DIR='/home/nginx/'
	vhostfile=$(grep -rl -P -e "^[ |\t]*server_name.*[ |\t]${hostname}[ |\t|;]" $NGXCONF_DIR | /usr/bin/head -n 1)
	webdir=$(grep -P -e "^[ |\t]*root[ |\t].*" ${vhostfile} | /usr/bin/head -n 1 | awk -F '/' '{printf "/%s/%s/%s", $2,$3,$4}')
	echo $webdir
}

chk_account() {
	#仅提供返回码
	if [ -z "$1" ];then
		return 1
	else
		ftp_account="$1"	#ftp账号
	fi
	#如果在账号文件中能找到该账号,就判断为账号存在.
	if grep -q -P -e "^[ |\t]*${ftp_account}[ |\t]*$" $VSFTPD_ACCOUNT_TXT ;then
		return 0
	else
		return 1
	fi


}

get_account() {
	#提供账号信息
	if [ -z "$1" ];then
		return 1
	else
		ftp_account="$1"	#ftp账号
	fi

	#输出账号、密码、主目录.
	password=$(grep -A 1 -P -e "^[ |\t]*${ftp_account}[ |\t]*$" $VSFTPD_ACCOUNT_TXT|tail -n 1)
	dir=$( grep -P -e "^[ |\t]*local_root" ${VSFTPD_USERCFG_DIR}${ftp_account} \
		|awk -v act="$ftp_account" -F'=' '{gsub(/\$USER/,act,$2);print $2}')
	#echo -e "${ftp_account} ${password} ${dir}"
	echo -e "\n请记录以下信息：\nFtp服务器IP：211.152.60.33 Ftp账号：${ftp_account} 密码：${password}"

}

renew_account_db() {
	mv -f ${VSFTPD_ACCOUNT_DB} ${VSFTPD_ACCOUNT_DB}.$(date +%s)		#备份账号数据库文件
	db_load -T -t hash -f ${VSFTPD_ACCOUNT_TXT} ${VSFTPD_ACCOUNT_DB}	#重新生成账号数据库文件
	logger "renew vsftp account.db return code:$?"
}

ensure_ip() {
	if [ -z $1 ];then
		#echo "缺少参数."
		return 1
	else
		local my_ip=$1
	fi
	iptables -L -nv|grep -q -P -e "ACCEPT.*[ |\t]${my_ip}[ |\t].*dports 21,5500:5700" \
	|| iptables -I INPUT -s ${my_ip} -p tcp -m multiport --dports 21,5500:5700 -j ACCEPT

	p_ret $? "\n你提交的IP：${my_ip} 已添加到防火墙白名单." "\n你提交的IP：${my_ip} 添加防火墙白名单失败,请检查并重新提交."
}

ensure_ftp_account() {
	#没有就创建,有就修改密码;最后输出账号信息
	if [ -z $3 ];then
		echo "缺少参数,无法执行."
		return 1
	else
		local hostname=$1		#项目域名
		local username=$2		#用户名是cut用户email的@前面的部分
		local my_account="${1}.${2}"	#ftp账户名: 项目域名.用户名
		local my_ip=$3			#用户公网IP
	fi

	#检查用户提交的域名
	if  chk_hostname $hostname ;then
		local my_dir=$(get_dir_from_hostname $hostname)
		#检查是否有创建Ftp账号的必要
		if ! echo ${my_dir}|grep -P -e '\.(com|cn|org|net)$' -q  && echo ${my_ip}|grep -e '101.231.69.78' -e '27.115.13.12' -q ;then
			#项目采用发布工具,办公室IP
			echo "你在办公室、并且这个项目可以使用发布工具发布，没必要开设Ftp账号.如有疑问，请联系管理员."
			return 1
		fi
	else
		#域名检查失败,不是配置过的,直接退出
		echo "此域名没有配置到系统,请检查后重新提交."
		return 1
	fi

	#检查、修改 或 创建账号
	if chk_account "${my_account}" ;then
		#账号存在,先删掉账号
		cp -a $VSFTPD_ACCOUNT_TXT $VSFTPD_ACCOUNT_TXT.$(date +%s).1	#备份账号文件
		n=$(grep -n -P -e "^[ |\t]*${my_account}[ |\t]*$" $VSFTPD_ACCOUNT_TXT|sed 's/:.*$//')
		sed -i "${n},$((n+1))d" $VSFTPD_ACCOUNT_TXT
	fi
		#账号不存在,创建账号
		my_passwd=$(gen_random_str)
		cp -a $VSFTPD_ACCOUNT_TXT $VSFTPD_ACCOUNT_TXT.$(date +%s)	#备份账号文件
		echo -e "${my_account}\n${my_passwd}" >> $VSFTPD_ACCOUNT_TXT	#在账号文件中添加新账号
		p_ret $? "ftp账号文件更新成功." "ftp账号文件更新失败."

		#更新账号数据库文件,并重启vsftpd服务
		renew_account_db &>/dev/null
		p_ret $? "ftp账号数据库更新成功." "ftp账号数据库更新失败."

		#更新用户ftp配置文件
		echo -e "local_root=${my_dir}\nanon_world_readable_only=NO\nanon_other_write_enable=YES\nanon_mkdir_write_enable=YES\nanon_upload_enable=YES\nanon_max_rate=307200" > "${VSFTPD_USERCFG_DIR}${my_account}"
		p_ret $? "用户配置信息更新成功." "用户配置信息更新失败."

		#重启ftp服务
		#sudo sh -c "$VSFTPD_CTL force-reload" #&>/dev/null	#sudo也不行,不过账号的变更,应该不需要重启ftpd;
		#p_ret $? "重载ftp服务成功." "重载ftp服务失败."


	#输出账号信息
	get_account $my_account

	#IP 添加到防火墙白名单
	ensure_ip $my_ip

	#提示信息
	echo -e "\n温馨提示："
	echo -e "请尽量使用发布工具发布代码，走正常发布流程;"
	echo -e "Ftp账号仅在紧急情况下临时使用，在以下情况下会失效："
	echo -e "出于安全考虑，上传下载活动结束3小时后账号失效;"
	echo -e "你的公网IP变更后(比如换了网络环境、宽带断线重新拨号等)将无法连接;"
	echo -e "如果Ftp账号无法使用，请在这里重新创建."
	echo -e "推荐使用Ftp客户端工具:<a target='_blank' href='https://filezilla-project.org/download.php?type=client'>Filezilla</a>."
}

del_account() {
	p_ret $?  '删除账号成功' '删除账号失败'
}


cleanup_ftp_client_ips() {
	#清理闲置3小时没有活动记录的ip白名单(ftp,iptables)
	export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"
	ts_now=$(date '+%s')
	for ip in $(iptables -L -nv|grep -P -e "ACCEPT.*dports 21,5500:5700"|awk '{print $8}'|grep -v -e '101.231.69.78' -e '27.115.13.12'|sort);do
		if ! grep -q -e "\"${ip}\"" /var/log/vsftpd.log ;then
			#该IP没有登陆记录
			continue
		else
			#该IP有登录记录,检查最后活动时间
			last_active_time_str=$(grep -e "\"${ip}\"" /var/log/vsftpd.log|tail -n 1|head -c 24)
			last_active_time_stamp=$(date -d "${last_active_time_str}" '+%s')
			if [ $((${ts_now}-${last_active_time_stamp})) -ge 10800 ] ;then
				#最后活动时间在3小时以前,可以清理了
				iptables -D INPUT -s ${ip} -p tcp -m multiport --dports 21,5500:5700 -j ACCEPT &>/dev/null
				p_ret $? "cleanup ${ip} ok." "cleanup ${ip} fail."|logger
			fi
		fi
	done
}


