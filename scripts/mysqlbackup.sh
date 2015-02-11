#!/bin/bash

DBS="$(/usr/bin/mysql -uroot -psjeiSYEU6JUwa8qw -e 'show databases'|grep -v -e '^Database$' -e '^information_schema$' -e '^test$' -e '^mysql$')"
DAYS=60

mysqlbackup ()
{
	if [ -z "$1" ] ; then
		echo "DB Parameter missing."
		return 1
	else
		DB="$1"
	fi
	

	DIR="/home/backup/mysqlbackup/${DB}"

	[ -d ${DIR} ] || mkdir -p ${DIR}

	/usr/bin/mysqldump -uroot -psjeiSYEU6JUwa8qw $DB > ${DIR}/$DB.`date -I`.sql

	if [ $? -eq 0 ] ; then
		find $DIR -ctime +$DAYS|xargs rm -rf
		gzip ${DIR}/*.sql
	else
		return 1
	fi
}

#for DB in ${DBS} ; do
for DB in zabbix cacti ; do
	printf "%-40s %-6s %-20s %-7s"  "$(date)" 'Backup' "$DB" "result:"
	mysqlbackup $DB
	echo "$?"
done


echo
