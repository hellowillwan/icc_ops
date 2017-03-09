# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Evn
export HIVE_HOME=/home/hadoop/hive
export HIVE_CONF_DIR=/home/hadoop/hive/conf
export CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:/home/hadoop/hive/lib:/home/hadoop/oozie/lib:/home/hadoop/oozie/libext:/home/hadoop/spark/lib

# User specific aliases and functions
alias python27='/home/hadoop/anaconda/bin/python2.7'
alias hive='/home/hadoop/hive/bin/hive'
alias rm='rm -i'
alias mv='mv -i'
alias vihu='vim /home/hadoop/hue/desktop/conf/pseudo-distributed.ini'
goto () {
	if [ -z $1 ];then
		echo "IP parameter missing."
	elif [ $1 -gt 254 ] 2>/dev/null ;then
		echo "IP not exist."
	else
		IP="192.168.5.${1}"
		ssh ${IP}
	fi
}
check_huesrv() {
	huepid=$(ps -ef|grep '/home/hadoop/hue/build/env/bin/supervisor'|grep -v -e grep|awk '{print $2}')
	ps -ef|grep $huepid|grep -v -e grep
	netstat -natpl|grep 8000
}

run_on_all() {
	if [ -z "$1" ] ;then
	echo "usage: $0 cmd"
	return 1
	fi
	cmd="$1"
	for host in $(cat /home/hadoop/hadoop/etc/hadoop/slaves |tr '\n' ' ');do
		echo "run ${cmd} on ${host}"
		ssh $host "${cmd}"
		echo
	done
}

sync_file() {
	if echo "$1" | grep -q  -e '^$' -e '^/$' -e '\/$' ;then
		echo "usage: $0 /path/to/file"
		return 1
	fi

	src_file="${1}"
	dst_file="${1%/*}/"
	cat /home/hadoop/hadoop/etc/hadoop/slaves |while read host ;do
	echo "send ${src_file} to $host ${dst_file}"
	#rsync -avc -e ssh ${src_file} $host:${dst_file}
	rsync --delete -avc -e ssh ${src_file} $host:${dst_file}
	done
}

start_jobhistoryserver() {
	mr-jobhistory-daemon.sh start historyserver
}
stop_jobhistoryserver() {
	ps -ef|grep JobHistoryServer|grep -v -e grep|awk '{print $2}'|xargs kill -9
	ps -ef|grep JobHistoryServer|grep -v -e grep|awk '{print $2}'|xargs kill -9
	ps -ef|grep JobHistoryServer|grep -v -e grep|awk '{print $2}'|xargs kill -9
}
restart_jobhistoryserver() {
	stop_jobhistoryserver
	start_jobhistoryserver
}
check_jobhistoryserver() {
	ps -ef|grep JobHistoryServer|grep -v -e 'grep'
	netstat -natpl 2>/dev/null |grep -i ':10020.*listen.*java'
}

restart_hadoop() {
	stop-dfs.sh && stop-yarn.sh && start-dfs.sh && start-yarn.sh
}

start_huesrv() {
	/home/hadoop/hue/build/env/bin/supervisor -d
}

kill_huesrv() {
	huepid=$(ps -ef|grep '/home/hadoop/hue/build/env/bin/supervisor'|grep -v -e grep|awk '{print $2}')
	ps -ef|grep $huepid|grep -v -e grep|awk '{print $2}'|xargs kill -9
	ps -ef|grep $huepid|grep -v -e grep|awk '{print $2}'|xargs kill -9 || true
}
restart_huesrv() {
	kill_huesrv && start_huesrv && check_huesrv
}


kill_hiveserver2() {
	kill $(netstat -natpl 2>/dev/null |grep -i ':10000.*listen.*java'|grep -v -e grep|awk '{print $NF}' |awk -F'/' '{print $1}')
	kill $(netstat -natpl 2>/dev/null |grep -i ':10000.*listen.*java'|grep -v -e grep|awk '{print $NF}' |awk -F'/' '{print $1}')
	kill $(netstat -natpl 2>/dev/null |grep -i ':10000.*listen.*java'|grep -v -e grep|awk '{print $NF}' |awk -F'/' '{print $1}')
}
start_hiveserver2(){
	cd /home/hadoop/hive/
	nohup bin/hive --config /home/hadoop/hive/conf --service hiveserver2 >> hiveserver2.out 2>&1 &
}
restart_hiveserver2(){
	kill_hiveserver2 ; sleep 3; start_hiveserver2
}
check_hiveserver2(){
	netstat -natpl 2>/dev/null |grep -i ':10000.*listen.*java'
}
restart_oozie() {
	/home/hadoop/oozie/bin/oozie-stop.sh
	sleep 5
	/home/hadoop/oozie/bin/oozie-start.sh
}
check_oozie() {
	netstat -natpl 2>/dev/null |grep -i ':11000.*listen.*java'
}
export PATH=/home/hadoop/spark/bin/:/home/hadoop/anaconda/bin:$PATH

