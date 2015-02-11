<?php

function dir_tree($directory) {
	$mydir = dir($directory);
	static $loopcount , $output_str; $output_str .= "<ul>";
	while($file = $mydir->read()) {
		if ( ($file != ".") && ($file != "..") && ($file != ".svn") ) {
			if((is_dir("$directory/$file"))) {
				//$output_str .= "<a href='$directory/$file'><li><font color=\"#3366ff\"><b>$file</b></font></li></a>\n";
				//$output_str .= "<li title='蓝色的是目录，勾选目录，该目录下的文件和子目录都会被发布.'><input type=checkbox name=items[] value='$directory/$file'><font color=\"#3366ff\"><b>$file</b></font></li>";
				$output_str .= "<li><input type=checkbox name=items[] value='$directory/$file'><font color=\"#DC650A\"><b>$file</b></font>";
					//if ( $loopcount >= 3 ) break;
					dir_tree("$directory/$file");
					$output_str .= "</li>";
					//$loopcount += 1;
			} else {
				$output_str .= "<li><input type=checkbox name=items[] value='$directory/$file'>$file</li>";
			}
		}
	}
	$output_str .= "</ul>";
	$mydir->close();
	return $output_str;
}

@$directory = trim($_SERVER['argv'][1]);
if ( empty($directory) or ! is_dir($directory) ) die("parameter missing or not a dir.\n");
echo dir_tree($directory);

?>
