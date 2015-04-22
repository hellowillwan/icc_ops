#!/bin/sh
#
# 检查正在使用的脚本是否最新
#

cd /home/wanlong/PKG/ops/scripts/
svn up
svn st

for file_using in /usr/local/sbin/*;do
	file_newest="/home/wanlong/PKG/ops/scripts/${file_using##*/}"
	if ls $file_newest &>/dev/null ;then
		echo "diff $file_newest $file_using"
		diff  $file_newest $file_using
		echo $?
	fi
done
