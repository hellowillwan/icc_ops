<html><pre>
发布到 华宝-测试环境
<form action='sync2hbtest.php' method=post>
<textarea rows='12' cols='128' name='items' ></textarea>
<br>
<input type=submit value='提交'>
</form>

<?php
if ( ! empty($_POST['items'] ) ) {
	$items = explode("\n",$_POST['items']);
	// upload
	foreach($items as $item ) {
		$item = trim($item);
		if (! empty($item) ) passthru("/home/cron/sync2hbtest.sh sync " . $item . ' 2>&1');
	}
	// restart tc
	if (preg_match('/\.(class|properties)/',implode(" ",$items))) passthru("/home/cron/sync2hbtest.sh restart tc");
}
