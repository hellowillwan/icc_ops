#!/bin/sh

#
# nohup /usr/bin/php /home/webs/141112fg0532/scripts/cronjob.php controller=laiyifen action=do2 > /tmp/141112fg0532_cron.log 2>/tmp/141112fg0532_cron.err &
#

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"


if [ -z "$3" ];then
	echo "parameter mising.usage: $0 project_code controller action"
	exit 1
else
	project_code=$1
	controller=$2
	action=$3
fi

#命令行
PHP='/usr/bin/php'
CRONJOB_FILE="/home/webs/${project_code}/scripts/cronjob.php"
LOG1="/tmp/${project_code}_${controller}_${action}_cron.log"
LOG2="/tmp/${project_code}_${controller}_${action}_cron.err"

if [ -f "$CRONJOB_FILE" ];then
	CMDLINE="${PHP} ${CRONJOB_FILE} controller=${controller} action=${action}"
else
	echo "cronjob.php not fund for project ${project_code},nothing done."
	exit 1
fi

#检查并运行
if ps -ef|grep "${CMDLINE}"|grep -q -v -e 'grep' ;then
	#在运行,退出
	echo "$(date) $0 job(${project_code} ${controller} ${action}) is running,nothing done." #|logger
	exit 0
else
	#没在运行,运行之
		nohup ${CMDLINE} > ${LOG1} 2>${LOG2} &
		ret=$?
		#echo "nohup ${CMDLINE} > ${LOG1} 2>${LOG2} &"
		echo "$(date) $0 job(${project_code} ${controller} ${action}) not running,starting job, ret: $ret." #|logger
		exit $ret
fi

#	if [ -s ${LOG1} ] ;then	#FILE exists and has a size greater than zero
#		#:>${LOG1}
#		nohup ${CMDLINE} > ${LOG1} 2>${LOG2} &
#		ret=$?
#		echo "nohup ${CMDLINE} > ${LOG1} 2>${LOG2} &"
#		echo "$ret"
#		#echo "$(date) $0 job(${project_code} ${controller} ${action}) not running,${LOG1} not empty,starting job, ret: $ret." #|logger
#		exit $ret
#	else
#		echo "$(date) $0 job(${project_code} ${controller} ${action}) not running,${LOG1} is empty,job supposed completed." #|logger
#		exit 0
#	fi

