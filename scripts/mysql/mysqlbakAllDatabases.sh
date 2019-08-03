#!/bin/bash  
#Shell Command For Backup MySQL Database Everyday Automatically By Crontab  
# Backup All Databases
# 50 3 * * * /data/script/mysqlbakAllDatabases.sh >> /data/backup/data_backup.log 2>&1
#
   
HOSTNAME="localhost"  
USER=xxxx
PASSWORD="xxxx"

BACKUP_DIR=/data/backup/ #备份文件存储路径  
DATE=`date +%F-%H%M%S` #日期格式（作为文件名）  
DUMPFILE=AllDB${DATE}.sql #备份文件名  
OPTIONS="-h $HOSTNAME -u $USER -p"$PASSWORD" --flush-logs --lock-tables -E -R --default-character-set=utf8 --master-data=2 --all-databases"

#判断备份文件存储目录是否存在，否则创建该目录  
[ -d ${BACKUP_DIR} ] || mkdir -p "${BACKUP_DIR}"  
   
#开始备份之前，将备份信息头写入日记文件  
echo " "  
echo " "  
echo "———————————————–"  
echo "BACKUP DATE:" $(date +"%Y-%m-%d %H:%M:%S")  
echo "———————————————– "  
   
#切换至备份目录  
cd ${BACKUP_DIR}  
#使用mysqldump 命令备份制定数据库，并以格式化的时间戳命名备份文件  
/usr/bin/mysqldump ${OPTIONS} > ${DUMPFILE}  
echo "The MariadbSqlFile is $?"=$?
if [[ $? == 0 ]]; then
    echo "/usr/bin/mysqldump ${OPTIONS} > ${DUMPFILE}"
    echo “[AllDATABASE {OPTIONSSP}] Backup Successful!”  
else
    echo “Database Backup Fail!”
fi

#判断数据库备份是否成功  
if [[ $? == 0 ]]; then  
    #创建备份文件的压缩包，删除原始备份文件，只需保留数据库备份文件的压缩包即可  
    echo "Compress DATE:" $(date +"%Y-%m-%d %H:%M:%S")  
    gzip ${DUMPFILE}
    #输入备份成功的消息到日记文件  
    echo “[${DUMPFILE}.gz ] Backup Successful!”  
else  
    echo “Database Backup Fail!”  
fi  
#输出备份过程结束的提醒消息  
echo "Finished DATE:" $(date +"%Y-%m-%d %H:%M:%S")  
echo “Backup Process Done”
