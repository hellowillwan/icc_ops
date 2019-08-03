#!/bin/bash   

#contact:long.wan@1mifudao.com
#file:MysqlSlaveStatus.sh
#time:2016/10/09  05:00
#Check MySQL Slave's Runnning Status  
#Crontab time 00:10
# */10 * * * * /data/MysqlSlaveStatus/MysqlSlaveStatus.sh

FROMEMAIL=kfb@1mifudao.com
FROMPASSWORD=YImi223344
TOEMAIL="maintain@1mifudao.com long.wan@1mifudao.com"
#TOEMAIL="long.wan@1mifudao.com"
HOSTNAME=`hostname`
AttachmentsErr="/data/script/MysqlSlaveStatus/mysqlerr"
SENDEMAIL=/data/script/MysqlSlaveStatus/sendEmail

MYSQLPID=`netstat -na|grep "LISTEN"|grep "37306"|grep -v grep |wc -l`  
MYSQLIP=`/sbin/ifconfig tun0|grep "inet addr" | awk -F[:" "]+ '{print $4}'`  
TOPICS_ERR="WARN! server: $MYSQLIP $HOSTNAME mysql may stop." 
TOPICS="$MYSQLIP $HOSTNAME mysql slave status may stop." 

STATUS=$(/usr/bin/mysql -uroot -p'1E3*dh&y0$ju&if1' -S /var/lib/mysql/mysql.sock -e "show slave status\G" | grep -i "running")  
IOenv=`echo $STATUS | grep IO | awk  ' {print $2}'`  
SQLenv=`echo $STATUS | grep SQL | awk  '{print $4}'`  
RUNTIME=`date +"%y-%m-%d %H:%M:%S"`  

function checkMysqlStatus(){  
    if [ "$MYSQLPID" == "1" ]  
    then  
        /usr/bin/mysql -uroot -p'1E3*dh&y0$ju&if1' --connect_timeout=5 -e "show databases;" &>/dev/null 2>&1  
        if [ $? -ne 0 ]  
        then  
            echo "####### RunTime is  $RUNTIME #########"
            echo "Server: $MYSQLIP $HOSTNAME mysql is down, please try to restart mysql by manual!" >> ${AttachmentsErr} 
            ${SENDEMAIL} -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -bcc $BCCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m $TOPICS_ERR -a $AttachmentsErr

        else
            echo "####### RunTime is  $RUNTIME #########"
            echo "mysql is running..."  
        fi  
    else  
            echo "####### RunTime is  $RUNTIME #########"
        ${SENDEMAIL} -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -bcc $BCCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m $TOPICS_ERR
    fi  
}  

#Run checkMysqlStatus
checkMysqlStatus


if [ "$SQLenv" == "Yes" ]  
then   
  echo "####### RunTime is $RUNTIME #########"
  echo "####### SQL env $SQLenv #########"  
  echo "MySQL Slave is running!"  
else  
  echo "####### $RUNTIME #########"  
  echo "####### SQL env $SQLenv #########"  
  echo "MySQL Slave SQL ENV is not running!" 
  ${SENDEMAIL}  -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -bcc $BCCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m $TOPICS_ERR

fi

if [ "$IOenv" == "Yes" ]
then
  echo "####### RunTime is $RUNTIME #########"
  echo "####### IO env $IOenv #########"  
  echo "MySQL Slave is running!"  
else
  echo "####### RunTime is $RUNTIME #########"
  echo "####### IO env $IOenv #########"  
  echo "MySQL Slave IO is not running!"
  ${SENDEMAIL} -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -bcc $BCCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m $TOPICS_ERR

fi

