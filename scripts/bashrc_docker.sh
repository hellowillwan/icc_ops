# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias psp="ps -e -o'pcpu,pmem,rsz,pid,comm,args'|sort -k1,2nr|head -n 50"

goto () {
	containers="$(docker ps|awk '{print $NF}'|grep -v -e '^NAMES$')"

	if [ -z $1 ];then
		echo "CONTAINER ID|NAME missing,Usage:"
		for container_name in $containers;do
			echo -e "\t\tgoto ${container_name}"
		done
		return 1
	else
		my_container="$1"
		container_name=$(echo $containers|grep -o -P -e "[^ ]*${my_container}[^ ]*"|head -n 1)
		if [ -z "${container_name}" ];then
			echo "${my_container} not running or not exist."
		else
			echo "goto ${container_name}"
			docker exec -i -t ${container_name} '/bin/bash'
		fi
	fi

}

docker_stop_all_container() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`; do docker stop $ctn;done
}

docker_start_all_container() {
	for ctn in `docker ps -a|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`; do docker start $ctn;done
}

docker_run_a_cmd_on_all_container() {
	if [ -z "$1" ] ;then echo usage:docker_run_a_cmd_on_all_container "cmd";return 1;fi
	for ctn in `docker ps -a|awk '{print $NF}'|grep -v -e '^NAMES'|grep icc_app|tr '\n' ' '`; do
		echo "${ctn} result: "
		docker exec -i ${ctn} bash -c "$1" 
		echo
	done
}

docker_stats() {
	docker stats `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|tr '\n' ' '`
}

ngx_reload() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} reload nginx : "
		docker exec -i ${ctn} /usr/local/tengine/sbin/nginx -s reload
		echo $?
	done
}

ngx_restart() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} restart nginx : "
		docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx -s stop &>/dev/null; /usr/local/tengine/sbin/nginx -s stop &>/dev/null; /usr/local/tengine/sbin/nginx'
		echo $?
	done
}

php_restart() {
	for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'icc_appserver'|tr '\n' ' '`; do
		echo "${ctn} stop nginx : "
		docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx -s stop &>/dev/null; /usr/local/tengine/sbin/nginx -s stop &>/dev/null'
		echo "${ctn} restart php-fpm : "
		docker exec -i ${ctn} /etc/init.d/php-fpm restart
		echo "${ctn} start nginx : "
		docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx'
		echo $?
	done
}

pyweixin_restart() {
	#for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'py_weixin_service'|tr '\n' ' '`; do
	#	#echo "${ctn} restart python_weixin_service: "
	#	docker exec -i ${ctn} bash -c "/usr/bin/supervisorctl -c /etc/supervisor.conf restart 'py_weixin_service:py_weixin_service0'"
	#	#echo $?
	#done
	docker restart py_weixin_service_1
}

pyweixin_status() {
	#for ctn in `docker ps|awk '{print $NF}'|grep -v -e '^NAMES'|grep -e 'py_weixin_service'|tr '\n' ' '`; do
	#	#echo "${ctn} check python_weixin_service: "
	#	docker exec -i ${ctn} bash -c "/usr/bin/supervisorctl -c /etc/supervisor.conf status"
	#	#echo $?
	#done
	docker ps|grep -e 'STATUS' -e 'py_weixin_service'
}

swoolechat_restart() {
	local port="$1"
	local project="$2"
	local ctn=$(docker ps -a|grep "${port}->"|awk '{print $NF}')
	#if 
	#if [ "$port" = '9503' ];then
	#	local ctn='app05_icc_appserver_c09'
	#	local project="160523fg0262"
	#elif [ "$port" = '9504' ];then
	#	local ctn='app05_icc_appserver_c08'
	#	#local project="zhibodemo"
	#	local project="160612fg0304demo"
	#elif [ "$port" = '9505' ];then
	#	local ctn='app05_icc_appserver_c07'
	#	#local project="zhibo"
	#	local project="160612fg0304"
	#else
	#	:
	#fi
	if [ -z "$1" -o -z "$2" -o -z "$ctn" ];then
		echo "parameter missing,nothing done,usage: swoolechat_restart port project"
		return 1
	fi
	
	docker restart ${ctn}
	docker exec ${ctn} bash -c ". /etc/profile;php /home/webs/${project}/swoolchat/webim_server.php &" &
	docker exec ${ctn} bash -c "ps -ef|grep '/home/webs/${project}/swoolchat/webim_server.php'|grep -v -e grep"
	docker exec -i ${ctn} bash -c '/etc/init.d/php-fpm restart' #&>/dev/null
	docker exec -i ${ctn} bash -c '/etc/init.d/php-fpm status' #&>/dev/null
	docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx' # &>/dev/null
	docker exec -i ${ctn} bash -c '/usr/local/tengine/sbin/nginx -s reload' # &>/dev/null
}

swoolechat_status() {
	local port="$1"
	local ctn=$(docker ps -a|grep "${port}->" 2>/dev/null | awk '{print $NF}')
	if [ -z "$1" -o -z "$ctn" ];then
		echo "parameter missing,nothing done,usage: swoolechat_restart port project"
		return 1
	fi
	#docker exec -i ${ctn} bash -c "ps -ef|grep -e 'swoolchat/webim_server.php'|grep -e manager|grep -v -e grep" |tr -d '\n'
	docker exec -i ${ctn} bash -c "ps -ef|grep -e 'swoolchat/webim_server.php'|grep -e manager|grep -v -e grep" \
	| awk '{gsub('/.home.webs.\|.swoo.*$/',"",$9);print $5,$9}' \
	| tr -d '\n'
	
}

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
