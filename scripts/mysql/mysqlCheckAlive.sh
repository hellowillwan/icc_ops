#!/bin/bash  
#Shell Command For Backup MySQL Database Everyday Automatically By Crontab  
   
USER=root
#PASSWORD="e3*j4_$u&"  
PASSWORD="1E3*dh&y0\$ju&if1"
#PASSWORD="password"
DATABASE="yimi"  
HOSTNAME="localhost"  

#echo $PASSWORD   
   
CHECK_DIR=/data/script 
DATE=`date +%F-%H%M%S`  
LOGFILE=$CHECK_DIR/MysqlCheck--$DATE.log
LOGFILE_ERROR=$CHECK_DIR/MysqlRstart--$DATE.log
MysqlErrorLog=/var/lib/mysql/mysql.err
#mysqldump －help  
echo " " > $LOGFILE  
echo " " >> $LOGFILE  
echo "———————————————–" >> $LOGFILE  
echo "CHECK DATE:" $(date +"%Y-%m-%d %H:%M:%S") >> $LOGFILE  
echo "———————————————– " >> $LOGFILE  

SendEmail() {
    FROMEMAIL=kfb@1mifudao.com
    FROMPASSWORD=YImi223344
    TOEMAIL="long.wan@1mifudao.com"

    $CHECK_DIR/sendEmail  -o tls=no -f $FROMEMAIL -t $TOEMAIL -cc $CCEMAIL -bcc $BCCEMAIL -s smtp.exmail.qq.com -o message-charset=utf8 -xu $FROMEMAIL -xp $FROMPASSWORD -u $TOPICS -m $TOPICS -a ${MysqlErrorLog}

}


UPTIME=`mysql -P37306 -h$HOSTNAME -uroot -p$PASSWORD -e"show status like '%Uptime';" |grep Uptime | awk '{print $2}'`
echo $UPTIME
#UPTIME=1
if [ $UPTIME -lt 300 ]; then
    TOPICS="MYSQL IS HAVING RESTART."
    echo "CHECK DATE:" $(date +"%Y-%m-%d %H:%M:%S") >> ${LOGFILE_ERROR}
    echo $TOPICS >> ${LOGFILE_ERROR}
    SendEmail
else
    rm -rf $LOGFILE

fi


