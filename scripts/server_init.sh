#!/bin/sh

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

# install tools
yum -y install wget curl lrzsz vim-enhanced nc nmap ntpdate sysstat iotop subversion openssh-clients make gcc parted man bind-utils tree psmisc lsof strace tcpdump #htop httpry 
# Local Repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
#wget -O /etc/yum.repos.d/CentOS6-Base-163.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo 
wget -O /etc/yum.repos.d/CentOS-Base-sohu.repo http://mirrors.sohu.com/help/CentOS-Base-sohu.repo
yum clean all;yum makecache
# Base groups
yum -y groupinstall Base 'Development tools'  'Networking Tools'  'System administration tools'
yum -y update

#Othoer Repo
#http://fedoraproject.org/wiki/EPEL
#http://repoforge.org/use/

#Other tools
#http://gael.roualland.free.fr/ifstat/ifstat-1.1.tar.gz


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
cp /etc/sysconfig/clock /etc/sysconfig/clock.`date +%Y-%m-%d_%H-%M-%S`
sed -i '/^ZONE/c\ZONE="Asia/Shanghai"' /etc/sysconfig/clock
sed -i '/^UTC/c\UTC=false' /etc/sysconfig/clock
sed -i '/^ARC/c\ARC=false' /etc/sysconfig/clock

mv /etc/localtime /etc/localtime.`date +%Y-%m-%d_%H-%M-%S`
cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# sync time 
/usr/sbin/ntpdate 10.0.0.200 && hwclock -w
grep ntpdate /var/spool/cron/root &>/dev/null || echo '00 * * * * /usr/sbin/ntpdate 10.0.0.200 >/dev/null 2>&1' >> /var/spool/cron/root
echo -e "\n/usr/sbin/ntpdate 10.0.0.200 && /sbin/hwclock -w\n" >> /etc/rc.local



# disable auto-start services
for i in abrt-ccpp abrtd abrt-oops atd avahi-daemon bluetooth certmonger cpuspeed cups fcoe ip6tables iscsi iscsid ksm ksmtuned libvirt-guests ndo2db NetworkManager ntpdate postfix sendmail webmin wpa_supplicant ;do
	chkconfig $i off
	/etc/init.d/$i stop
done


