#!/bin/bash
#
FROMEMAIL="kfb@1mifudao.com"
FROMPASSWORD="YImi223344"
TOEMAIL="nina.wei@1mifudao.com bo.he@1mifudao.com"
CCEMAIL="long.wan@1mifudao.com haibin.zhong@1mifudao.com"
#BCCEMAIL="long.wan@1mifudao.com"
#TOEMAIL="long.wan@1mifudao.com"

TOPICS=mysql-slow-digest
RUNDIR=/data/script/mysql-slow-digest
MYSQLSLOW=/var/lib/mysql/mysql-slow
#MYSQLSLOW=/var/lib/mysql/mysql-slow2
MYSQLSLOWRS=$RUNDIR/mysql-slow--`date +%F--%H%M%S`.log
MYSQLSLOWDGLOG=$RUNDIR/mysql-slow-digest-`date +%F--%H%M%S`.log
MYSQLSLOWDGLOGTAR=$RUNDIR/mysql-slow-digest-`date +%F--%H%M%S`.log.tar.gz

rsync -av $MYSQLSLOW $MYSQLSLOWRS ; sync
rsync -av $MYSQLSLOW $MYSQLSLOWRS ; sync
:> $MYSQLSLOW

/usr/bin/pt-query-digest $MYSQLSLOWRS > $MYSQLSLOWDGLOG
echo tar zcvf $MYSQLSLOWDGLOGTAR $MYSQLSLOWDGLOG
tar zcvf $MYSQLSLOWDGLOGTAR $MYSQLSLOWDGLOG


$RUNDIR/sendEmail -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m  "mysql-slow-digest" -a $MYSQLSLOWDGLOGTAR

tar zcvf $MYSQLSLOWRS.tar.gz $MYSQLSLOWRS
exit 0
