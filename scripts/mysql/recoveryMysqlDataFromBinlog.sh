#!/bin/bash
#
# recover for  delete from period_pay_info where planNo!=181
# reffer: http://www.cnblogs.com/gomysql/p/3582058.html
#

# 从 binglog 找到 delete 语句
mysqlbinlog --no-defaults --base64-output=decode-rows -v -v  \
    /var/lib/mysql/mysql-bin.000070 \
    | sed -n '/### DELETE FROM `yimi`.`period_pay_info`/,/COMMIT/p' \
    > mysql-bin.000070.sql

# 将 delete 语句转为 insert 语句 其中 @18 这个数字是表的列数
cat mysql-bin.000070.sql \
    | sed -n '/###/p' \
    | sed 's/### //g;s/\/\*.*/,/g;s/DELETE FROM/INSERT INTO/g;s/WHERE/SELECT/g;' \
    | sed -r 's/(@18.*),/\1;/g' \
    | sed 's/@[1-9]\+=//g' > mysql-bin.000070.sql2

