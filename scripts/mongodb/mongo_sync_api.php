<?php

/* api.php的调用参数列表:
*  module mongodb
*  action sync | list | stats
*  direction download |upload
*  collections ICCv1.idatabase_collection_58d26060b1752fb5428b4db1,ICCv1.idatabase_collection_58d26060b1752f37dd8b4567, ...
*
*/

/*if ( extension_loaded('xdebug') ) {
	//xdebug_disable();
	ini_set('xdebug.default_enable',0);
	//ini_set('xdebug.var_display_max_data',4096);
	//ini_set('xdebug.var_display_max_depth',10);
}*/

ini_set('error_reporting', E_ALL);
ini_set("display_errors","On");
ini_set("display_startup_errors","On");
header("Pragma:no-cache");
header("Cache-control:no-cache");
//require_once('./include/config_inc.php');

// gearman 函数
function gearman_commonworker($target_node,$cmd,$parameter,$isbackground = 0) {
	session_write_close(); //在耗时操作执行之前关闭 session ,避免阻塞后续请求
	$commonworker_key = md5(date('Y-m-d'));
	$ifbackground = ($isbackground === 'run_background')? ' -b ' : ''; 
	$gearmand_ip = preg_match( '/^192.168.5.4/',$target_node ) ? '192.168.5.41' : '10.0.0.200';
	$function_name = 'CommonWorker_'.$target_node;
	$tip = exec("echo {$commonworker_key} {$cmd} {$parameter} | /usr/bin/gearman -h {$gearmand_ip} -f {$function_name} {$ifbackground}",$output,$ret);
	if ( $isbackground === 'run_background' ) { 
		return array('命令已提交');
	} else {
		//return (empty($output)) ? array('命令没有成功执行,请重试') : $output;
		return $output;
	}
}

// 添加集合到同步列表
function add_coll_to_list($direction,$coll_name) {
	$coll_list_file='/var/lib/mongodb_collections_sync_from_api.list';
	if (! check_coll_in_list($direction,$coll_name)) {
		file_put_contents($coll_list_file,file_get_contents($coll_list_file) . $direction . ' ' . $coll_name . PHP_EOL);
	}
	return true;
}

// 检查集合是否在同步列表
function check_coll_in_list($direction,$coll_name) {
	$coll_list_file='/var/lib/mongodb_collections_sync_from_api.list';
	return stripos(file_get_contents($coll_list_file),$direction . ' ' . $coll_name . PHP_EOL) !== false;
}

//检查集合是否已经添加到mongo-connector命令行
function check_coll_in_cmdline($direction,$coll_name) {
	$target_node = ( $direction === 'download' )? '10.0.0.200' : '192.168.5.41';
	$cmd = "list_collections";
	$parameter = $direction;
	$colls_ary = explode(' ',implode(' ',gearman_commonworker($target_node,$cmd,$parameter)));
	//gearman可能执行失败返回一个空的数组,出现这种情况就记录一下日志,看看是否这种情况造成的集合名重复
	if ( empty($colls_ary[0]) ) {
		error_log("check_coll_in_cmdline -> gearman_commonworker $target_node,$cmd,$parameter return empty array.not testing");
	}
	return (in_array($coll_name,$colls_ary)) ? true : false;
}

//dump集合
function dump_coll($direction,$coll_name) {
	// dump背景执行OK;
	$target_node = ( $direction === 'download' )? '10.0.0.200' : '192.168.5.41';
	$cmd = "mongo_sync";
	$db_coll_ary = explode('.',$coll_name); $src_db = $db_coll_ary[0]; $src_collection = base64_encode(trim($db_coll_ary[1]));
	$dst_db = ( $direction === 'download' ) ? 'ICCv1RO' : '';
	$parameter = $direction . ' 1 ' . $src_db . ' ' . $src_collection . ' ' . $dst_db;
	gearman_commonworker($target_node,$cmd,$parameter,'run_background');	//dump集合,提交就可以了,不需要获取结果
}

//检查集合是否已经dump完成
function check_coll_dumped($direction,$coll_name) {
	$target_node = ( $direction === 'download' )? '10.0.0.200' : '192.168.5.41';
	$cmd = "check_mongo_sync";
	$db_coll_ary = explode('.',$coll_name); $db = $db_coll_ary[0]; $collection = base64_encode($db_coll_ary[1]);
	$parameter = $direction . ' ' . $db . ' ' . $collection;
	$result = trim(implode(' ',gearman_commonworker($target_node,$cmd,$parameter)));
	return empty($result)? 'not_found' : $result;
}

//检查用户提交的集合名,输入格式是 db.coll,db.coll,返回结果：true(都合法),false(至少有一个不合法)
function check_coll_name($collections_ary){
	foreach($collections_ary as $coll_name) {
		if ( 
			//(stripos($coll_name,'ICCv1.') !== 0 and stripos($coll_name,'bda.') !== 0)
			preg_match("/ICCv1\.|ICCv1RO\.|bda\./",$coll_name) === 0
			or
			preg_match('/[]|\||\\|\/|\'|\"|\;|\ |\<|\>|\(|\)|\{|\}|\?|#|[]/',$coll_name) !== 0
		) {
			return false;
		}
	}
	return true;
}



//获取用户传过来的参数
if (empty($_GET['module'])) {
	$USER_PARAMETERS = $_POST;
} elseif (empty($_POST['module'])) {
	$USER_PARAMETERS = $_GET;
} else {
	display(json_encode(array('error' => 'module parameters confusion')),0);
	exit;
}

//解析用户传过来的参数
foreach( $USER_PARAMETERS as $key => $val ) {
	$key = trim($key);
	$val = trim($val);
	eval("\$$key = '$val';");
	//api.php?module=mongodb&action=sync&direction=download&collections=ICCv1.idatabase_collection_58b1,ICCv1.idatabase_collection_58d7
}

//主逻辑
if (!empty($module) && $module == 'mongodb') {
	if ($direction !== 'download' and $direction !== 'upload') {
		display(json_encode(array('error' => 'direction parameters confusion')),0);
		exit;
	}
	//根据$_GET['action']值做相应的事情
	switch($action) {
	case 'list':
		$target_node = ( $direction === 'download' )? '10.0.0.200' : '192.168.5.41';
		$cmd = "list_collections";
		$parameter = $direction;
		$output_ary = gearman_commonworker($target_node,$cmd,$parameter);
		$output = explode(' ',implode(' ',$output_ary));
		break;
	case 'sync':
		//整理用户提交的集合到一个数组并去重,输入格式是 db.coll,db.coll
		// 检查用户输入 方法: 用 " |\t|\n" 字符拆分字符串为数组,再用空字符合并成新的字符串
		$collections_ary = array_unique(explode(',',implode(preg_split("/ |\t|\n/",urldecode($collections)))));

		//检查用户提交的集合名是否包含非法字符,包含就直接返回
		if( ! check_coll_name($collections_ary) ) {
			$output = array('error' => 'collections illegal');
			break;
		}

		// upload 处理逻辑: 即时上传,结束
		if ( $direction === 'upload' ) {
			//准备返回结果
			$reusult_ary = array();
			//操作：dump集合 并 记录过程
			foreach($collections_ary as $coll_name) {
				dump_coll($direction,$coll_name);		//不需要同步获得结果,下面主动检查添加的情况
				sleep(3);
				//检查集合是否已经dump完成
				$result_ary[$coll_name]['sync_result'] = check_coll_dumped($direction,$coll_name);
			}
			$output = $result_ary;
			break;
		}

		// 以下是 download 处理逻辑
		/* mongo-connector 目前已经没有在运行了,注释下面这段
		//检查用户提交的集合是否已经在mongo-connector命令行了,如果在的话则去除
		foreach($collections_ary as $key => $coll_name) {
			if( check_coll_in_cmdline($direction,$coll_name) ) {
				unset($collections_ary[$key]);
			}
		}
		*/
		//没有集合了,直接返回
		if(empty($collections_ary)) {
			$output = array('error' => 'no collections or all collections are configured');
			break;
		}

		//把通过检查的集合名用逗号连接成字符串
		$collections = implode(',',$collections_ary);	//逗号间隔的库名.集合名

		/*
		//操作1：将集合列表 添加到 添加supervisor相应的mongo-connector项目并执行 supervisor update
		$target_node = ( $direction === 'download' )? '10.0.0.200' : '192.168.5.41';
		$cmd = "add_collections";
		$parameter = $direction . ' ' . $collections;
		gearman_commonworker($target_node,$cmd,$parameter);	//不需要获得结果,下面主动检查添加的情况,但不要run_background
		*/

		//操作2：dump集合 停止对应的mongo-connector进程->dump集合并记录过程->启动对应的mongo-connector进程
		foreach($collections_ary as $coll_name) {
			dump_coll($direction,$coll_name);		//不需要同步获得结果,下面主动检查添加的情况
		}

		//操作3: 记录集合到 mongodb_collections_sync_from_api.list
		foreach($collections_ary as $coll_name) {
			add_coll_to_list($direction,$coll_name);
		}

		//准备返回结果
		$reusult_ary = array();
		//检查集合是否已经添加到mongo-connector命令行,是否已经dump完成
		foreach($collections_ary as $coll_name) {
			//$result_ary[$coll_name]['configured'] = check_coll_in_cmdline($direction,$coll_name);
			$result_ary[$coll_name]['configured'] = check_coll_in_list($direction,$coll_name);
			//$result_ary[$coll_name]['sync_result'] = check_coll_dumped($direction,$coll_name);
		}
		$output = $result_ary;
		break;
	case 'stats':
		//整理用户提交的集合到一个数组并去重,输入格式是 db.coll,db.coll
		//$collections_ary = array_unique(explode(',',trim(urldecode($collections))));
		$collections_ary = array_unique(explode(',',implode(preg_split("/ |\t|\n/",urldecode($collections)))));

		//检查用户提交的集合名是否包含非法字符,包含就直接返回
		if( ! check_coll_name($collections_ary) ) {
			$output = array('error' => 'collections illegal');
			break;
		}

		//没有集合了,直接返回
		if(empty($collections_ary)) {
			$output = array('error' => 'no collections received');
			break;
		}

		//准备返回结果
		$reusult_ary = array();
		//检查集合是否已经添加到mongo-connector命令行,是否已经dump完成
		foreach($collections_ary as $coll_name) {
			//$result_ary[$coll_name]['configured'] = check_coll_in_cmdline($direction,$coll_name);
			$result_ary[$coll_name]['configured'] = check_coll_in_list($direction,$coll_name);
			$result_ary[$coll_name]['sync_result'] = check_coll_dumped($direction,$coll_name);
		}
		$output = $result_ary;
		break;
	default:
		$output = array('error' => 'unknown action');
	}
} else {
	$output = array('error' => 'unknown module');
}

//输出
if ( empty($output)) $output = array();
echo json_encode($output);
