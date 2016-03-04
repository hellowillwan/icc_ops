#!/bin/sh
#
# 升级Mongodb
#

# 下载
wget -O ~wanlong/PKG/mongodb-3.0/mongodb-linux-x86_64-rhel62-3.0.7.tgz https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.0.7.tgz

# 分发
for ip in 30 31 32 40 41 42 50 51 52;do
	rsync -avc -e ssh  ~wanlong/PKG/mongodb-3.0/mongodb-linux-x86_64-rhel62-3.0.7.tgz 10.0.0.$ip:~wanlong/PKG/mongodb-3.0/
done

# 校验
func 'mongodb*' call command run "md5sum ~wanlong/PKG/mongodb-3.0/mongodb-linux-x86_64-rhel62-3.0.7.tgz"

# 解压
func 'mongodb*' call command run "tar -C /usr/local/ -zxf /home/wanlong/PKG/mongodb-3.0/mongodb-linux-x86_64-rhel62-3.0.7.tgz"

# 检查
func 'mongodb*' call command run "ls /usr/local/mongodb-linux-x86_64-rhel62-3.0.7/bin" 

# 替换软连接
func 'mongodbc*' call command run "rm /home/60000/bin -f; ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.0.7/bin /home/60000/"
func 'mongodbp*' call command run "rm /ssd_volume/60000/bin -f; ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.0.7/bin /ssd_volume/60000/" 

# 检查
func 'mongodbp*' call command run "ls -F /ssd_volume/60000 -l 2>/dev/null|grep bin"
func 'mongodbc*' call command run "ls -F /home/60000 -l 2>/dev/null|grep bin"

# 重启实例
