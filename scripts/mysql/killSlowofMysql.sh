#!/bin/bash
#
# kill long query of mysql
#

DB_HOST="localhost"
DB_PORT=37306
DB_USER="root"
DB_PASS=''
maxtime=120
slowpid=$(/usr/bin/mysqladmin processlist -h${DB_HOST} -p${DB_PASS} \
    | sed -e "s/\s//g" \
    | awk -F'|' '{print $2,$7,substr(toupper($9),1,6)}' | tee /tmp/processlit \
    | awk '{if($2>'"$maxtime"' && $3=="SELECT"){print $1}}'
)

for pid in $slowpid ; do
    echo "$(date) killing ${pid}"
    /usr/bin/mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} -e "kill ${pid};"
done

