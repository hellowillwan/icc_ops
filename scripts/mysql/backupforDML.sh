#!/bin/bash
#
#

backupDML() {
    if [ -z "$1" -o ! -f "$1" ];then
        echo "parameter missing or sqlFile not exist,nothing done"
        return 1
    else
        sqlFile="$1"
    fi
    tables="$(cat $sqlFile \
        | sed 's/`/ /g' \
        | sed 's/\./ /g' \
        | sed 's/(\|)/ /g' \
        | sed 's/ yimi / /g' \
        | sed 's/\<ignore\|low_priority\|high_priority\|delayed\>/ /g I' \
        | awk 'BEGIN{IGNORECASE=1}
        {
            if ($1 ~ /\<alter\>/) {print $3}
            else if ($1 ~ /\<update\>/) {print $2}
            else if ($1 ~ /\<delete\>/) {print $3}
            else if ($1 ~ /\<insert\>/) {print $3} }' \
        | sed -e 's/;.*//' \
        | sort -u
    )"

    mkdir backup &>/dev/null
    for t in $tables ;do
        echo "mysqldump yimi ${t} > backup/${t}.`date +%s`.sql"
        mysqldump yimi ${t} > backup/${t}.`date +%s`.sql
        echo
    done
    ls -lhrR backup
}
