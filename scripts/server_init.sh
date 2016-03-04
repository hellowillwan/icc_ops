#!/bin/sh

# env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"


# Base Repo from aliyun
#
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# CentOS 7
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# CentOS 6
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo


# EPEL Repo from epel
# http://fedoraproject.org/wiki/EPEL
#
# RHEL 7
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# RHEL 6
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm


# EPEL Repo from aliyun
# http://fedoraproject.org/wiki/EPEL
#
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
# RHEL 7
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# RHEL 6
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo


# Webtatic Repo
# https://webtatic.com/projects/yum-repository/
#
# Webtatic EL7 for CentOS/RHEL 7:
rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
# Webtatic EL6 for CentOS/RHEL 6:
rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm


# RPMForge Repo
# http://repoforge.org/use/


# Other tools
# http://gael.roualland.free.fr/ifstat/ifstat-1.1.tar.gz


# yum cache
yum clean all;yum makecache


# yum update
yum update


# install Base groups
yum -y groupinstall Base 'Development tools'  'Networking Tools'  'System administration tools'


# install tools
yum -y install wget curl lrzsz vim-enhanced nmap-ncat nmap ntpdate sysstat iotop iftop subversion openssh-clients make gcc parted man-db bind-utils tree psmisc lsof strace tcpdump rsync #htop httpry lynx elinks pwgen ipmitool


#set selinux
setenforce 0

if grep 'SELINUX=disabled' /etc/selinux/config > /dev/null ;then
  /usr/sbin/sestatus
else
 cp /etc/selinux/config /etc/selinux/config.`date +%Y-%m-%d_%H-%M-%S`
 sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
fi


#set locale
grep '^LANG="en_US.UTF-8"$' /etc/sysconfig/i18n || sed -i  '/^LANG/c\LANG="en_US.UTF-8"' /etc/sysconfig/i18n

#set timezone
# CentOS 6
cp /etc/sysconfig/clock /etc/sysconfig/clock.`date +%Y-%m-%d_%H-%M-%S`
sed -i '/^ZONE/c\ZONE="Asia/Shanghai"' /etc/sysconfig/clock
sed -i '/^UTC/c\UTC=false' /etc/sysconfig/clock
sed -i '/^ARC/c\ARC=false' /etc/sysconfig/clock

mv /etc/localtime /etc/localtime.`date +%Y-%m-%d_%H-%M-%S`
cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# CentOS 7
ln -f -s /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime

# sync time 
/usr/sbin/ntpdate 10.0.0.200 && hwclock -w
grep ntpdate /var/spool/cron/root &>/dev/null || echo '00 * * * * /usr/sbin/ntpdate 10.0.0.200 >/dev/null 2>&1' >> /var/spool/cron/root
echo -e "\n/usr/sbin/ntpdate 10.0.0.200 && /sbin/hwclock -w\n" >> /etc/rc.local



# disable auto-start services
for i in abrt-ccpp abrtd abrt-oops atd avahi-daemon bluetooth certmonger cpuspeed cups fcoe ip6tables iscsi iscsid ksm ksmtuned libvirt-guests ndo2db NetworkManager ntpdate postfix sendmail webmin wpa_supplicant ;do
	chkconfig $i off
	/etc/init.d/$i stop
done


