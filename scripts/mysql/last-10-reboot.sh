# 最近 10 次重启时提到的 SQL
## method 1
grep -A 65 -e 'got signal' /var/lib/mysql/mysql.err | grep -e 'got signal' -e '^Query' | tail -n 20 | sed 's/^17/\n\n/'
## method 2
sed -n '/mysqld got signal/,/^Connection ID/p' /var/lib/mysql/mysql.err|sed -n '/^Query/,/^Connection ID/p' |grep -v -e '^Connection ID'

# 最近 10 次重启前后的慢查询
for ts in $(grep 'got signal' /var/lib/mysql/mysql.err \
    | tail -n 10 \
    | awk '{print $1,$2}' \
    | while read datetime ;do date -d "${datetime}" '+%s' ;done \
    | sed 's/..$//'
);do
    sed -n "/^SET timestamp=${ts}/,/;/p" /var/lib/mysql/mysql-slow
done
