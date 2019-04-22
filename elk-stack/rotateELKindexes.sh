
# 删除 elk 中 90 天以前的应用日志

esindexList='/var/lib/esindex.list'

# get indexes 30 天更新一次足以
[ $(date '+%u') -eq 3 ] && \
curl -s 'http://127.0.0.1:9200/_cat/indices?v' | grep -v -e '^health' > ${esindexList}

if ! [ -f ${esindexList} ];then
    echo "fail get esindex list,exit."
    exit 1
fi

for index in $(awk '{print $3}' ${esindexList} \
| grep -v -e .kibana -e logstash-accesslog -e alicdnaccesslog -e room-rs-sta
); do
    # 获取 index 的日期
    dateofIndex="$(echo ${index} | grep -o -e  '20.*' | sed 's#\.#-#g')"
    dateofIndex=$(date -d ${dateofIndex} '+%s')
    [ ${dateofIndex} -gt 0 ] || continue
    dateofNow=$(date +'%s')
    days=$(((${dateofNow}-${dateofIndex})/86400))
    if [ $days -gt 90 ];then
        # 删除 index
        echo "删除 ${index}"
        curl -sv -X DELETE "http://127.0.0.1:9200/${index}"
    fi
done

