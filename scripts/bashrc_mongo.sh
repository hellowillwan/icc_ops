# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
alias psp='ps -e -o'\''pcpu,pmem,rss,pid,comm,args'\''|sort -k1,2nr|head -n 50'
alias hc='history -c;clear'

top_slow_query() {
	if [ -z $1 ];then
		TOP_NUMBER=20
	else
		TOP_NUMBER=$1
	fi
	MONGOD_LOG_FILE='/ssd_volume/60000/log/mongod.log'
	grep -P  "$(date -I).*[0-9]+ms\$" ${MONGOD_LOG_FILE} \
	| grep -o 'query ICCv1.idatabase_collection_.* query' \
	| awk '{print $2}' \
	| sort |uniq -c |sort -k1,1nr |head  -n ${TOP_NUMBER}
}
