<?php
/**
 * 从 dump 出的集合的 metadata.json 文件中获取集合的索引信息,生成 创建索引的语句
 *
 *
 *
 *
 */

//要创建索引的集合列表,一行一个集合
$active_coll_list=file('./active_collections.txt');
$i = 0;		//测试用
//对每一个集合的索引进行处理
foreach($active_coll_list as $coll_name) {
	$coll_name = trim($coll_name);
	$index_ary = json_decode(file_get_contents('./ICCv1/ICCv1/'.$coll_name.'.metadata.json'));	//这是 dump 出来的 metadata.json 文件
	//print_r($index_ary);die();
	//对每一个索引进行检查
	foreach($index_ary->indexes as $single_index_ary) {
		//print_r($single_index_ary);

		//检查 index ,如果是 {_id:xxx} 索引,忽略
		$key_ary = $single_index_ary->key;
		if ( count($key_ary) === 1 and isset($key_ary->_id) ) {
			//如果只有一个键，并且是_id
			continue;
		}
		//index
		$index_str = json_encode($key_ary);

		//检查 index options 
		$option_ary = array();
		foreach($single_index_ary as $key => $value){
			//var_dump($key);die();
			if ( $key === 'v' or $key === 'key' or $key === 'ns' or $key === 'name' or $key === 'background' ) {
				//忽略一些属性
				continue;
			}
			$option_ary[$key] = $value;
		}
		//index options
		$option_str = json_encode($option_ary);

		//组织重新创建索引的语句
		$index_and_option_str = ( count($option_ary) == 0 )? $index_str : $index_str.','.$option_str;
		echo "printjson('$coll_name');\n";
		echo "printjson(db.getCollection('$coll_name').createIndex($index_and_option_str));\n";
	}
	/*
	$i++;
	echo $i."\t".$coll_name."\n";
	if ($i >= 10) {break;};
	*/
}


