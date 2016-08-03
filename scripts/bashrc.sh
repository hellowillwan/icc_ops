# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
alias rm='rm -i'
alias grep='grep --color'
alias gearadmin='gearadmin -h 10.0.0.200 '
alias mongo='/home/mongodb/bin/mongo'
alias goto5.41='ssh -p 8389 wanlong@127.0.0.1'
alias mongo5.40='/home/60000/bin/mongo 127.0.0.1:37017'
alias redis-cli='/home/redis-cluster/bin/redis-cli'
alias psp="ps -e -o'pcpu,pmem,rsz,pid,comm,args'|sort -k1,2nr|head -n 50"
alias hdp='su root -c "su - hadoop"'
alias vanke='echo "connecting to 121.40.150.104";ssh root@121.40.150.104'
alias hqvanke='echo "connecting to 139.196.54.21"; ssh root@139.196.54.21'
alias huabao='echo "connecting to huabao xintuo"; ssh -p 8390 root@127.0.0.1'
alias check='/usr/local/sbin/check_services.sh'
goto () {
	if [ -z $1 ];then
		echo "IP parameter missing."
		return 1
	elif [ $1 -gt 200 ];then
		echo "IP not exist."
		return 1
	else
		IP="10.0.0.${1}"
	fi

	IP="10.0.0.${1}"
	echo "Connecting to ${IP}"
	ssh wanlong@${IP}
}

check_all_ntpdate_cronjob() {
	func '*' call command run "crontab -l|grep ntpdat"
}

sync_time_to_all() {
	func '*' call command run "/usr/sbin/ntpdate  10.0.0.200 "
}

check_containers_hosts() {
	md5sum /tmp/xdebug_log_dir/.hosts
	echo
	func 'app*' call command run \
	". ~/.bashrc; \
	docker_run_a_cmd_on_all_container 'md5sum /etc/hosts' \
	| grep -v -e ':' -e '^\$' | sort | uniq -c"
}

sync_hosts_to_containers() {
	func 'app*' call command run \
	". ~/.bashrc; \
	docker_run_a_cmd_on_all_container \
	'[ -r /var/log/xdebug_log_dir/.hosts -a -s /var/log/xdebug_log_dir/.hosts ] && cat /var/log/xdebug_log_dir/.hosts > /etc/hosts;echo \$?' \
	| grep -v -e ':' -e '^\$' | sort | uniq -c"
	check_containers_hosts
}

check_containers_profile() {
	md5sum /tmp/xdebug_log_dir/.profile
	echo
	func 'app*' call command run \
	". ~/.bashrc; \
	docker_run_a_cmd_on_all_container 'md5sum /etc/profile' \
	| grep -v -e ':' -e '^\$' | sort | uniq -c"
}

sync_profile_to_containers() {
	func 'app*' call command run \
	". ~/.bashrc; \
	docker_run_a_cmd_on_all_container \
	'[ -r /var/log/xdebug_log_dir/.profile -a -s /var/log/xdebug_log_dir/.profile ] && cat /var/log/xdebug_log_dir/.profile > /etc/profile;echo \$?' \
	| grep -v -e ':' -e '^\$' | sort | uniq -c"
	check_containers_profile
}

check_apps_bashrc() {
	md5sum /home/wanlong/PKG/ops/scripts/bashrc_docker.sh
	echo
	func 'app*' call command run "md5sum ~/.bashrc"
}

sync_bashrc_to_apps() {
	func 'app*' call command run \
	"su wanlong -c 'svn up /home/wanlong/PKG/ops/scripts/bashrc_docker.sh'; \
	cat /home/wanlong/PKG/ops/scripts/bashrc_docker.sh > /root/.bashrc;echo \$?"
	check_apps_bashrc
}

check_all_containers() {
	for url in http://iwebsite2.umaman.com/invoke/index/mongodb http://iwebsite2.umaman.com/invoke/index/redis http://iwebsite2.umaman.com/invoke/index/memcache http://scrm.umaman.com/admin/index/phpinfo http://icc.umaman.com/login ;do
		echo $url
		for i in {1..100};do curl -sx 10.0.0.1:80 $url -o /dev/null -D -|grep -e X-router-s -e '^HTT';done|sort |uniq -c
		echo
	done
}

check_containers_outgoingconnections() {
	func 'app*' call command run \
	". ~/.bashrc; \
	docker_run_a_cmd_on_all_container \"ss -nt|grep -v -e '^State' -e 'LISTEN' -e '10.0.0' -e '172.18.1' -e '127.0.0.1' | wc -l\" \
	| tr '\n' ' '"
}

sync_zabbix_cfg_bins() {
	# 分发配置文件和检查脚本
	for f in \
		/usr/local/zabbix-2.2.3/etc/zabbix_agentd.conf \
		/usr/local/zabbix-2.2.3/etc/zabbix_agentd.conf.d/hostname.conf \
		/usr/local/zabbix-2.2.3/etc/zabbix_agentd.conf.d/userparams.conf \
		/usr/local/sbin/redis-cli \
		/usr/local/sbin/zabbix_low_discovery.sh \
		/usr/local/sbin/check_hardware.sh \
		/usr/local/sbin/check_http.sh \
		/usr/local/sbin/check_misc.sh \
		/usr/local/sbin/es_query_status.sh \
		/usr/local/sbin/check_url.sh
	do
		func "proxy*;app*;mongo*" copyfile --file=${f} --remotepath=${f}
	done
	# 修改差异部分并重启服务
	func 'proxy*;app*;mongo*' call command run \
	"sed -i -e \"/^Hostname/c\Hostname=\$(hostname)\" /usr/local/zabbix-2.2.3/etc/zabbix_agentd.conf.d/hostname.conf
	/etc/init.d/zabbix_agentd restart"
}

check_weshopfiles() {
        if [ -z "$1" ];then
                local PROJECTS=$(cat /var/lib/weshop_enabled_hosts)
        else
                local PROJECTS="$1"
        fi

        for p in ${PROJECTS} ;do
		echo $p|grep -q -e 'demo$' && local weshopdir=weshopdemo || local weshopdir=weshop
		echo $p
		for f in $(cat /var/lib/weshop_filelist);do
			diff -r         /home/webs/${weshopdir}/$f /home/webs/$p/$f &>/dev/null \
			|| echo diff -r /home/webs/${weshopdir}/$f /home/webs/$p/$f
		done
		echo
	done
}

sync_syscfgs() {
	set -x
	# 删除
	func 'app*;proxy*;mongo*;host200' call command run 'rm /etc/security/limits.conf /etc/security/limits.d/* /etc/sysctl.conf /etc/sysctl.d/* -rf'
	# 分发配置文件
	for file in	/etc/security/limits.conf \
			/etc/security/limits.d/90-nproc.conf \
			/etc/security/limits.d/90-nfile.conf \
			/etc/sysctl.conf
	do
		local src_file=/home/wanlong/PKG/ops/centos/${file##*/}
		local dst_file=$file
		func 'app*;proxy*;mongo*;host200' copyfile --file=${src_file} --remotepath=${dst_file}
	done
	# 生效
	#func 'app*;proxy*;mongo*;host200' call command run '/sbin/sysctl -p /etc/sysctl.conf'
	set +x
}
