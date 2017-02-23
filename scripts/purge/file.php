<?php

/*file.php的调用形式为:
上传文件: file.php?act=upload
下载文件: file.php?act=download
删除文件: file.php?act=del
*/

die();
ini_set('error_reporting', E_ALL);
ini_set("display_errors","On");
ini_set("display_startup_errors","On");
header("Pragma:no-cache");
header("Cache-control:no-cache");


//HTTP 基本验证 
if (       !isset($_SERVER['PHP_AUTH_USER'])
	|| !isset($_SERVER['PHP_AUTH_PW'])
	|| $_SERVER['PHP_AUTH_USER'] !== 'lrk'
	|| $_SERVER['PHP_AUTH_PW'] !== 'l_P@ssw0rd.rk' )
{
	Header("WWW-Authenticate: Basic realm=\"Login\"");
	Header("HTTP/1.0 401 Unauthorized");
	echo '<html><body><h1>Rejected!</h1>Wrong Username or Password!</body></html>';
	exit;
}

$upload_dir = '/tmp/lrk/';
$output = "<html>
<head>
<meta http-equiv='content-type' content='text/html; charset=UTF-8'/>
<title>upload</title>
</head>
<body>
";

@$action = $_GET['act'];
switch ($action) {
case "upload":
	if (empty($_FILES['attachment'])) {header('Location: ' . $_SERVER['PHP_SELF']);}
	//处理附件上传
	if ( $_FILES['attachment']['error'] == 0 ) {
		if ( move_uploaded_file($_FILES['attachment']['tmp_name'],$upload_dir.$_FILES['attachment']['name']) ) {
			$output = "文件上传完成.<meta http-equiv='refresh' content='1;URL=file.php'>";
		} else {
			$output = "文件上传发生错误:move_uploaded_file()失败,请联系管理员.";
		}
	
	} elseif ( $_FILES['attachment']['error'] != 4 ) {
		$output = "文件上传发生错误,错误码:{$_FILES['attachment']['error']},请联系管理员.";
	}
	break;

case "download":
	$file_id = (int) trim($_GET['id']);
	$dao = new DataAccess($dbhost, $dbuser, $pass, $db);
	$task = new TaskModel($dao);
	$file_array = $task->general_query('tms_task_attachment','stor_path,file_name,file_size'," where id={$file_id} "," limit 1 ");
	$file_name = (stripos($_SERVER['HTTP_USER_AGENT'],'msie') === false) ? $file_array[0]['file_name'] : iconv("UTF-8","GB2312",$file_array[0]['file_name']);
	$file_size = $file_array[0]['file_size']; 
	$file_contents = file_get_contents($tms_upload_dir.$file_array[0]['stor_path']);
	header("Content-Disposition: attachment; filename=\"{$file_name}\"");
	header("Content-Length: {$file_size}");
	header("Content-Type: application/octet-stream");
	echo $file_contents;
	unset($dao,$task);
	break;

case "del":
	if($_SESSION['user_role_number'] < 2) {
		$task_id = (int) trim($_GET['task_id']);
		$attach_id = (int) trim($_GET['id']);
		$user_id = $_SESSION['user_id'];
		if( empty($task_id) or empty($attach_id) or empty($user_id) ) {
			$output = 'id参数错误,文件删除失败.';
		} else {
			$dao = new DataAccess($dbhost, $dbuser, $pass, $db);
			$task = new TaskModel($dao);
			if($task->delattachment($task_id,$attach_id,$user_id)) {
				$output = "文件删除成功.<meta http-equiv='refresh' content='1;URL={$_SERVER['HTTP_REFERER']}'>";
			} else {
				$output = "文件删除失败.";
			}
			unset($dao,$task);
		}
	} else {
		$output = "权限错误,文件删除失败.";
	}
	break;

default:
	//输出上传文件的表单
	$output .= '<div>';
	$max_filesize = ini_get('upload_max_filesize');
	$max_filesize_in_byte = $max_filesize * 1024 * 1024;
	$output .= "<br><form action='./file.php?act=upload' method=post enctype='multipart/form-data'>";
	$output .= "<input type='hidden' name='MAX_FILE_SIZE' value='{$max_filesize_in_byte}' />";
	$output .= "上传文件(最大大小:{$max_filesize}) <input type=file name=attachment /> <input type=submit value=上传文件 /> </form></div>";
	break;
}

echo $output;
