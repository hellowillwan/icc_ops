#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

readonly PROGNAME=$(basename $0)
readonly FILE='/etc/hosts'
#readonly FILE='./hosts'


#第三方接口的域名
hostnames='
oauth.dianping.com
api.dianping.com
open.weixin.qq.com
'

for hostname in $hostnames ;do
	ipaddr=$(dig @202.96.209.133 $hostname 2>/dev/null|grep -e "^${hostname}.*A" 2>/dev/null |awk '{print $NF}' \
		|grep -P -e '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' 2>/dev/null)
	#echo -e "${ipaddr}\t${hostname}"
	if [ -z "$ipaddr" ];then
		#ip地址解析失败,什么也不做
		:
	else
		if grep -q -P -e "^${ipaddr}\t${hostname}\$" $FILE ;then
			#如果解析到记录与hosts文件里的相同,也就是DNS没有更新,什么也不做
			:
		else
			if grep -q -P -e "^[^#]*[ |\t]${hostname}\$" $FILE ;then
				#如果hosts文件里有这个域名的记录,但IP不同,在这里更新
				sed -i -e "/${hostname}/c\\${ipaddr}\t${hostname}" $FILE
				logger "$PROGNAME update ${ipaddr} ${hostname} return code:$?"
			else
				#如果hosts文件里没有这个域名的记录,这里添加
				echo -e "${ipaddr}\t${hostname}" >> $FILE
				logger "$PROGNAME add ${ipaddr} ${hostname} return code:$?"
			fi
		fi
	fi
done



#配置在集群上的域名

readonly my_ipaddr='10.0.0.1'
for my_hostname in `grep -hr -P -e '^[ |\t]*server_name[ |\t]' /etc/nginx/ \
			|sed 's#server_name##;s#;.*$##' \
			|tr ' |\t' '\n' \
			|sort|uniq \
			|grep -P -e '\.(com|cn|org|net)'`
do
	if grep -q -P -e "^${my_ipaddr}\t${my_hostname}\$" $FILE ;then
		#如果记录与hosts文件里的相同,也就是有这条记录,什么也不做
		:
	else
		if grep -q -P -e "^[^#]*[ |\t]${my_hostname}\$" $FILE ;then
			#如果hosts文件里有这个域名的记录,但IP不同,在这里更新
			sed -i -e "/${my_hostname}/c\\${my_ipaddr}\t${my_hostname}" $FILE
			logger "$PROGNAME update ${my_ipaddr} ${my_hostname} return code:$?"
		else
			#如果hosts文件里没有这个域名的记录,这里添加
			echo -e "${my_ipaddr}\t${my_hostname}" >> $FILE
			logger "$PROGNAME add ${my_ipaddr} ${my_hostname} return code:$?"
		fi
	fi

done
