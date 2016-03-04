# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
alias rm='rm -i'
alias gearadmin='gearadmin -h 10.0.0.200 '
alias mongo='/home/mongodb/bin/mongo'
alias goto5.41='ssh -p 8389 wanlong@127.0.0.1'
alias mongo5.40='/home/60000/bin/mongo 127.0.0.1:37017'
alias redis-cli='/home/redis-cluster/bin/redis-cli'
alias psp="ps -e -o'pcpu,pmem,rsz,pid,comm,args'|sort -k1,2nr|head -n 50"
alias hdp='su root -c "su - hadoop"'
alias vanke='ssh root@121.40.150.104'
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

