<?php

if(!empty($_POST['cut_act_str']) and strlen($_POST['cut_act_str']) > 500 ) {
	$ret = file_put_contents('./accounts.php',$_POST['cut_act_str']);
	echo (string)$ret;
} else {
	header("HTTP/1.0 403 Forbidden");
}
