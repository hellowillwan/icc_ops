<?php

//ini_set('error_reporting', E_ALL);
ini_set("display_errors",0);
ini_set("display_startup_errors",0);

/*接受一个或一批批URL、目录、域名,清除前端代理设备的缓存
*
*/

//检查客户端IP
$allowips = array_map('trim',file('white.list'));
if ( strpos($_SERVER['REMOTE_ADDR'],'10.0.0.') !== 0 && array_search($_SERVER['REMOTE_ADDR'],$allowips) === false){
	echo "<html><body><h1>Rejected!</h1>You are not allowed to enter from IP:{$_SERVER['REMOTE_ADDR']}.</body></html>";
	exit;
}
//HTTP 基本验证 
require('./accounts.php');

if (	   !isset($_SERVER['PHP_AUTH_USER']) 
	|| !isset($_SERVER['PHP_AUTH_PW'])
	|| $accounts_array[$_SERVER['PHP_AUTH_USER']] !== md5($_SERVER['PHP_AUTH_PW']) )
{
	Header("WWW-Authenticate: Basic realm=\"Login\"");
	Header("HTTP/1.0 401 Unauthorized");
	echo '<html><body><h1>Rejected!</h1>Wrong Username or Password!</body></html>';
	exit;
}

$proxy_ary = array('10.0.0.1:80','10.0.0.2:80');

//需要特殊处理的使用'proxy_cache_key $host$uri$is_args$args$cookie_fileModifyTime;'的域名列表,这些无法通过URL直接purge,只能截取到location清除.
//取得这些列表的shell命令行# grep server_name `grep -rl cookie_fileModifyTime /home/ngx_proxy_conf/`|sed -e 's/.*server_name//' -e 's/;//'|tr ' ' '\n'|sort|grep -v -e '^$'|uniq|sed -e "s/^/'/" -e "s/$/'/"|tr '\n' ','|sed 's/,$/\n/'
//$chosts = array('ac.umaman.com','allsun-sh.umaman.com','c3m.umaman.com','cloud.umaman.com','cocacola-redpa.umaman.com','dev.umaman.com','dumexmedical.umaman.com','dumex.umaman.com','heuer.umaman.com','images.philips-avent.com.cn','iwebsite.umaman.com','laiyifen201306.umaman.com','philip.umaman.com','redirect.umaman.com','scrm2.umaman.com','scrm.umaman.com','scrm.umaman.com','shiguangji.umaman.com','t3m.umaman.com','wyeth2.umaman.com','wyeth.umaman.com');
$chosts = array('ac.umaman.com','allsun-sh.umaman.com','c3m.umaman.com','chcedo.img.umaman.com','cocacola-redpa.umaman.com','dev.umaman.com','dumexall.umaman.com','dumex.umaman.com','heuer.umaman.com','images.philips-avent.com.cn','iwebsite.umaman.com','laiyifen201306.umaman.com','philip.umaman.com','redirect.umaman.com','scrm2.umaman.com','scrm.umaman.com','shiguangji.umaman.com','t3m.umaman.com','wyeth2.umaman.com','wyeth.umaman.com');
$purge_status_array = array(0 => '清除失败或缓存不存在',1 => '清除不完整或缓存不存在',2 => '清除成功',
				3 => '未提交到所以列队',
				6 => '已提交到所有列队',
			);

function chkurl($val) {
	if ( strlen($val) > 5 && strpos($val,'http://') === 0 && strpos($val,' ') === false && strpos($val,"\t") === false ) {
		return true;
	} else {
		return false;
	}
}

class Proxy {
/* Usage:
* $url_array['url'][] = array('http://test.domain.com/img/1.jpg',);
* $url_array['dir'][] = array('http://test.domain.com/Scripts/','http://test.domain.com/',);
* Proxy::purgecache($url_array);
*/

	public static function purgecache($url) {
		if(!is_array($url)) {
			$url_array[] = $url;
		} else {
			$url_array = $url;
		}
		return Proxy::ngxpurge($url_array);
		//return Proxy::ccpurge($url_array);
		}

	private static function ngxpurge($url_array){
		$okstr = 'HTTP/1.1 200 OK';
		global $proxy_ary; 
		$result_ary = array();
		$gmc= new GearmanClient();
		$gmc->addServer('10.0.0.200',4730);

		// 清理单个url
		if (!empty($url_array['url']) && count($url_array['url']) !== 0 ) {
		foreach($url_array['url'] as $url) {
			//这里将URL变为小写并确保末尾的'/'字符,但未对URL合法性做检查,没有找到好方法
			//$url_fmt = (substr($url,-1,1) === '/')? strtolower($url) : strtolower($url).'/';
			$url_fmt = $url;//FOR ICC 
			//这里在host和面加入'/purge'字符串,并在query前加'?'字符
			$url_parsed = parse_url($url_fmt);
			$hostname = $url_parsed['host'];	//用于清理CDN缓存
			$location = empty($url_parsed['query'])? $url_parsed['path'] : $url_parsed['path'].'?'.$url_parsed['query'];	//用于清理CDN缓存
			unset($url_parsed['scheme']);
			$url_parsed['host'] = 'http://'.$url_parsed['host'].'/purge';
			if(!empty($url_parsed['query'])) $url_parsed['query'] = '?'.$url_parsed['query'];
			//这里是根据nginx proxy_cache_key 规则格式化后的URL
			$url_fmt = implode('',$url_parsed);

			$result_ary[$url] = 0;
			foreach($proxy_ary as $proxy) {
				//curlpurge()返回的true 会取值为1 false 会取值为0
				$result_ary[$url] += (int)Proxy::curlpurge($url_fmt,$okstr,$proxy);
			}

			// 刷新CDN
			$function_name_s = 'CommonWorker_10.0.0.200';
			$localkey_s = md5(date('Y-m-d'));
			$workload_s = $localkey_s.' flush_alicdn '.$hostname.' '.$location."\n";
			$gmc->doBackground($function_name_s,$workload_s);
			//var_dump($workload_s,$gmc->returnCode() == GEARMAN_SUCCESS);
		}
		}

		// 清理目录
		if (!empty($url_array['dir']) && count($url_array['dir']) !== 0 ) {
		foreach($url_array['dir'] as $url) {
			//准备传递给gearman worker 的 "host path\n"
			//$url_parsed = parse_url(strtolower($url));
			$url_parsed = parse_url($url);	//FOR ICC
			$workload_d= $url_parsed['host'].' '.$url_parsed['path']."\n";

			$result_ary[$url] = 0;

			foreach($proxy_ary as $proxy) {
				//gearman worker 的函数名 purge_10.0.0.1|2
				$function_name_d = 'purge_'.substr($proxy,0,stripos($proxy,':'));
				$gmc->doBackground($function_name_d,$workload_d);
				if ($gmc->returnCode() == GEARMAN_SUCCESS) {
					$result_ary[$url] += 3;
				}
			}
		}
		}

		return $result_ary;
	}

	private static function ccpurge($url_array){
		//disable
		return 0;
		$okstr = 'whatsup: content="succeed"';
		//组织请求ChinaCache刷新接口的URL
		if(!empty($url_array['url'])) {
			$urls = (count($url_array['url']) > 1) ? implode('%0D%0A',$url_array['url']) : $url_array['url'][0];
			$urls = 'urls='.$urls;
		}
		if(!empty($url_array['dir'])) {
			$dirs = (count($url_array['dir']) > 1) ? implode('%0D%0A',$url_array['dir']) : $url_array['dir'][0];
			$dirs = 'dirs='.$dirs;
		}
		$url = 'http://ccms.chinacache.com/index.jsp?user=&pswd=&ok=ok&'.$urls.'&'.$dirs;

		//刷新并返回
		if(Proxy::curlpurge($url,$okstr)) {
			return 2;
		}else{
			return 0;
		}
	}

	private static function curlpurge($url,$okstr,$proxy='') {
		$options = array(
			CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_0 ,
			CURLOPT_TIMEOUT => 10 ,
			CURLOPT_RETURNTRANSFER => 1 ,
			CURLOPT_HEADER => 1 ,
			CURLOPT_URL => $url ,
			CURLOPT_USERAGENT => 'User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; CIBA; .NET CLR 1.1.4322; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; InfoPath.2)' ,
		);
		if(!empty($proxy)){
			$options[CURLOPT_PROXY] = $proxy ;
		}

		$ch = curl_init();
		curl_setopt_array($ch,$options);
		$output = curl_exec($ch);
		curl_close($ch);

		if(strpos($output,$okstr) === false) {
			//查看curl请求的结果
			//echo '<pre>';var_dump($output);
			return false;
		}else{
			return true;
		}
	}
}


$output = "<html>
<head>
<meta http-equiv='content-type' content='text/html; charset=UTF-8'/>
<title>Purge Cache</title>
</head>
<body>";
$dt = date('Y-m-d H:i:s');//.' '.microtime(1);
$output .= '<div>'.$dt.'</div>';


if(!empty($_POST)){
	//有POST,处理清除缓存操作
	//对用户输入的URLs进行trim、变形到数组、去重、去掉空值
	$urls = array_filter(array_unique(explode("\r\n",trim($_POST['urls']))),'chkurl');

	//if ( !empty($urls) and ( $_POST['type'] == 'ICC' or $_POST['type'] == 'ChinaCache' ) ) {
	if ( !empty($urls) ) {
		//先把URL分成2类
		foreach($urls as $url){
			$url_ary = parse_url($url);
			if ( empty($url_ary['query']) and substr($url_ary['path'],-1,1) == '/') {
				$url_array['dir'][] = $url;
			}else {
				//如果属于需要特殊处理的域名 并且 该url不是静态资源
				if ( array_search($url_ary['host'],$chosts) !== false
				&& preg_match("/\.(jpg|jpeg|gif|bmp|png|ico|css|js|flv|ogg|mp3|mp4|swf|webm|avi|wma|wmv)$/",$url) === 0 ) {
					//修改url，保留到最后一层目录
					$url = substr($url,0,strrpos($url,'/')+1);
					$url_array['dir'][] = $url;
				} else {
					$url_array['url'][] = $url;
				}
			}
		}

		//处理URLs并返回结果
		//$result = Proxy::purgecache($url_array,$_POST['type']);
		$result = Proxy::purgecache($url_array);
		//输出结果
		$output .= '<div id=urls>';
		$output .= "清除结果如下：";
		if(is_array($result)){
			$output .= '<br>';
			foreach($result as $url => $nb) {
				$url = htmlspecialchars($url,ENT_COMPAT | ENT_HTML401 ,'UTF-8');
				# 检查域名是否开启了CDN,如果开启了给出不同提示
				$hostname = parse_url($url)['host'];
				$cdn_enabled_hosts = file('/var/lib/cdn_enabled_hosts');
				if ( array_search($hostname."\n",$cdn_enabled_hosts) === false ) {
					$output .= "<span>{$url}</span> <span>{$purge_status_array[$nb]}</span> <br>";
				} else {
					$output .= "<span>{$url}</span>";
					$output .= " <span>源站：{$purge_status_array[$nb]}；</span>";
					$output .= " <span>CDN：已提交到队列</span>";
					$output .= " <br>";
				}
			}
		}else{
			$output .= "{$purge_status_array[$result]} <br>";
		}
		$output .= '</div>';

	} else {
		$output .= '<div id=urls>';
		$output .= "URL不合法或为空.";
		$output .= '</div>';
	}
	$output .= "<meta http-equiv='refresh' content='3;URL=index.php'>";

} else {
	//输出提交URL|path|domain的表单
	$output .= "
<div><b>清除缓存</b>
<form action='./index.php' method=post><table border=0 style='border-collapse:collapse'>
<tr><td>URLs</td>
<td title='每行一个URL，举例如下：&#10;&#10;清除指定URL： http://test.domian.com/img/1.jpg&#10;清除指定目录： http://test.domain.com/Scripts/&#10;清除整站缓存： http://test.domain.com/'>
<textarea rows=16 cols=128 name=urls></textarea>
</td></tr>
<tr><td colspan=2>
<!--
<input type=radio name=type value='ICC' checked='checked' /><span title='清除ICC前端代理的缓存,需要3-5分钟左右,清除后,如果想在本机看是否生效,请清除浏览器缓存'>ICC Porxy</span><br>
<input type=radio name=type value='ChinaCache' /><span title='清除ChinaCache的缓存,url需要3-5分钟,目录需要20分钟左右,清除后,如果想在本机看是否生效,请清除浏览器缓存'>ChinaCache</span>
-->
</td></tr>
<tr><td colspan=2>对于开启了CDN的域名：会先清理源站的缓存，然后再刷新CDN缓存，CDN全网刷新缓存需要几分钟时间，提交后耐心等待几分钟后再进行测试。</td></tr>
<tr><td colspan=2><input type=submit value='提交'> <input type=reset></td></tr>
</table></form></div>
<div>
<br>
注意事项:
<p>
1,每行一个URL，举例如下：<br>清除指定URL: http://test.domian.com/img/1.jpg<br>清除指定目录: http://test.domain.com/Scripts/<br>清除整站缓存: http://test.domain.com/
</p><p>
2，对于支持多个域名的站点，清除整站和目录不成功的问题：通过修改worker脚本<font color='#3366ff'>已解决</font>。
</p><p>
3，清除整站或目录比较慢的问题：由于缓存目录有时候会很大(10G+),查找和删除操作会比较耗时，有时甚至需要15min+，另外，清除指定目录比清除整站慢。
</p>
</div>
";
}

echo $output."\n";
