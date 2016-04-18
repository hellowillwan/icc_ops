#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

readonly PROGNAME=$(basename $0|sed 's/\.sh$//;s/_/ /g')
readonly third_api_domain_list='/var/lib/third_api_domain_list'	#第三方接口的域名列表
readonly hosts_file='/tmp/xdebug_log_dir/.hosts'
readonly local_proxy_ip='10.0.0.1'
readonly app_nginx_conf='/home/app_nginx_conf/'


cat ${third_api_domain_list} | while read hostname ;do
	ipaddr=$(dig @116.228.111.118 $hostname 2>/dev/null | grep -P '\tA\t' 2>/dev/null | head -n 1 |awk '{print $NF}' \
		|grep -P -e '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' 2>/dev/null)
	#echo -e "${ipaddr}\t${hostname}"
	if [ -z "$ipaddr" ];then
		#ip地址解析失败,什么也不做
		:
	else
		if grep -q -P -e "^${ipaddr}\t${hostname}\$" $hosts_file ;then
			#如果解析到记录与hosts文件里的相同,也就是DNS没有更新,什么也不做
			:
		else
			if grep -q -P -e "^[^#]*[ |\t]${hostname}\$" $hosts_file ;then
				#如果hosts文件里有这个域名的记录,但IP不同,在这里更新
				sed -i -e "/${hostname}/c\\${ipaddr}\t${hostname}" $hosts_file
				logger "$PROGNAME update ${ipaddr} ${hostname} return code:$?"
			else
				#如果hosts文件里没有这个域名的记录,这里添加
				echo -e "${ipaddr}\t${hostname}" >> $hosts_file
				logger "$PROGNAME add ${ipaddr} ${hostname} return code:$?"
			fi
		fi
	fi
done



#配置在集群上的域名
#
for my_hostname in `grep -hr -P -e '^[ |\t]*server_name[ |\t]' ${app_nginx_conf} \
			|sed 's#server_name##;s#;.*$##' \
			|tr ' |\t' '\n' \
			|sort|uniq \
			|grep -P -e '\.(com|cn|org|net)'`
do
	if grep -q -P -e "^${local_proxy_ip}\t${my_hostname}\$" $hosts_file ;then
		#如果记录与hosts文件里的相同,也就是有这条记录,什么也不做
		:
	else
		if grep -q -P -e "^[^#]*[ |\t]${my_hostname}\$" $hosts_file ;then
			#如果hosts文件里有这个域名的记录,但IP不同,在这里更新
			sed -i -e "/${my_hostname}/c\\${local_proxy_ip}\t${my_hostname}" $hosts_file
			logger "$PROGNAME update ${local_proxy_ip} ${my_hostname} return code:$?"
		else
			#如果hosts文件里没有这个域名的记录,这里添加
			echo -e "${local_proxy_ip}\t${my_hostname}" >> $hosts_file
			logger "$PROGNAME add ${local_proxy_ip} ${my_hostname} return code:$?"
		fi
	fi

done


#localhost
#
/bin/grep -q -e '^127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4$' ${hosts_file} || \
/bin/sed -i '1i127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' ${hosts_file}


# 检查容器内hosts文件是否已更新
# 
#func 'app*' call command run \
#	". ~/.bashrc ;docker_run_a_cmd_on_all_container '[ -r /var/log/xdebug_log_dir/.hosts -a -s /var/log/xdebug_log_dir/.hosts ] && md5sum /etc/hosts'" \
#	| grep -o `md5sum  /tmp/xdebug_log_dir/.hosts |awk '{print $1}'`|sort |uniq -c

