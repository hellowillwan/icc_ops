#!/bin/sh

#
# nohup /usr/bin/php /home/webs/iwebsite2demo/scripts/cronjob.php controller=weixincard action=deposite-code > /tmp/iwebsite2demo_cron.log 2>/tmp/iwebsite2demo_cron.err &
#

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"


keys=(54c62a33608dd3f8cff1618a 54c726bb608dd3f8cff508f2 54c726d9608dd3f8cff8aaa2 54c726f3608dd3f8cffc4c52 54c72716608dd3f8cf000443 54c7275b608dd3f8cf038fb2 54c72783608dd3f8cf073162 54c727a0608dd3f8cf0ad312 54c727bd608dd3f8cf0e74c2 54c727d8608dd3f8cf121672 54c727f3608dd3f8cf15b821)

n=${#keys[@]}
m=$(($n-2))

for i in `seq 0 $m`;do
	j=$(($i+1))
	#echo -e ${keys[$i]} "\t" ${keys[$j]};
	cmdline="/usr/bin/php /home/webs/iwebsite2demo/scripts/cronjob.php controller=weixincard action=deposite-code start=${keys[$i]} end=${keys[$j]}"
	#echo ${cmdline}
	logfile="/tmp/iwebsite2demo_cron_${keys[$i]}.log"
	logerr="/tmp/iwebsite2demo_cron_${keys[$i]}.err"
	#touch ${logfile}
	#echo 1 > ${logfile}

	if ps -ef|grep "${cmdline}"|grep -q -v -e 'grep' ;then
		#在运行,退出
		echo "$(date) $0 : job is running,nothing done."
		continue
	else
		if [ -s "${logfile}" ] ;then	#FILE exists and has a size greater than zero
			#:>${logfile}
			nohup ${cmdline} >${logfile} 2>${logerr} &
			ret=$?
			echo "$(date) $0 : job not running,${logfile} not empty,starting job, ret: $ret."
			continue
		else
			echo "$(date) $0 : job not running,${logfile} is empty,job supposed completed."
			continue
		fi
	fi

done
