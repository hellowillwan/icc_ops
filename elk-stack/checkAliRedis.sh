

memused=$(echo 'info memory' \
| /usr/bin/redis-cli -h r-xxxxxxxxxxxxxxxx.redis.rds.aliyuncs.com -p 6379 -n 101 -a xxxxxxxxxxxxxxxx \
| grep -P -e 'used_memory:[0-9]+' \
| sed 's/^.*://;s/\r//')

echo "memused: |${memused}|"
if [ ${memused} -ge 2000000000 ];then
    # 空间占用接近 2GB 时清理日志数据
    echo 'keys *' | /usr/bin/redis-cli -h r-xxxxxxxxxxxxxxxx.redis.rds.aliyuncs.com -p 6379 -n 101 -a xxxxxxxxxxxxxxxx
    echo 'flushdb' | /usr/bin/redis-cli -h r-xxxxxxxxxxxxxxxx.redis.rds.aliyuncs.com -p 6379 -n 101 -a xxxxxxxxxxxxxxxx
    echo "flushed db 101."
fi
