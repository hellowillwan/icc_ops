<html>
<head><title>hadoop job</title>
<meta http-equiv='refresh' content='10;URL=hadoop_job.php'>
</head>
<pre>
<?php
$commonworker_key = md5(date('Y-m-d'));

/*
* mapred
echo 'mapred job list :<br>';
system("echo {$commonworker_key} mapred_job_list | /usr/bin/gearman -f CommonWorker_192.168.5.41 | sed 's|\(job_[^ ]*\)|<a title=\"kill job\" href=http://192.168.5.41/hadoop_job.php\?job_id=\\1>\\1</a>|' ");
if ( !empty($_GET['job_id']) ) {
	$job_id = trim($_GET['job_id']);
	echo "mapred job kill: $job_id <br>";
	system("echo {$commonworker_key} mapred_job_kill {$job_id} | /usr/bin/gearman -f CommonWorker_192.168.5.41 ");
}
CommonWorker:
    mapred_job_list)
        #su hadoop -c '~/hadoop/bin/mapred job -list'
        su hadoop -c '~/hadoop/bin/yarn application -list'
        ;;  
    mapred_job_kill)
        if [ -z "${p3}" ];then echo job id missing;return 1;fi
        #su hadoop -c "~/hadoop/bin/mapred job -kill $p3"
        su hadoop -c "~/hadoop/bin/yarn application -kill $p3"
*/

// yarn
echo 'yarn application list :<br>';
system("echo {$commonworker_key} mapred_job_list | /usr/bin/gearman -f CommonWorker_192.168.5.41 | sed 's|\(application_[^ |\t]\+\)|<a title=\"kill application\" href=http://192.168.5.41/hadoop_job.php\?application_id=\\1>\\1</a>|' ");
if ( !empty($_GET['application_id']) ) {
	$application_id = trim($_GET['application_id']);
	echo "yarn application kill: $application_id <br>";
	system("echo {$commonworker_key} mapred_job_kill {$application_id} | /usr/bin/gearman -f CommonWorker_192.168.5.41 ");
}
?>
<pre></html>
