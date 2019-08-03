#!/bin/bash
#
# 服务器云服务器初始化步骤
# 适用于CentOS-6/7
#
#


# disable selinux
checkSelinux() {
    /sbin/getenforce
    grep -e '^SELINUX' /etc/selinux/config
}
disableSelinux() {
    setenforce 0 &>/dev/null
    sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config &>/dev/null
    echo "${FUNCNAME[0]} done. result: $(checkSelinux)"
}

# set hostname
setHostname() {
    if [ -z "$1" -o "$1" = 'default' ];then
        :
    else
        hostname "$1"
        if [ -f /etc/hostname ];then
            echo "$1" > /etc/hostname
        else
            sed -i "/^HOSTNAME/c\HOSTNAME=$1" /etc/sysconfig/network
        fi
    fi
}

# set dns server
setDns() {
    for dnsServer in 223.5.5.5 223.6.6.6;do
        if grep -q $dnsServer /etc/resolv.conf;then
            sed -i "/$dnsServer/c\nameserver $dnsServer" /etc/resolv.conf
        else
            echo "nameserver $dnsServer" >> /etc/resolv.conf
        fi
    done
}

# get os version
getCentosVersion() {
    grep -o -P -e '[ |\t]+[6-7]\.' /etc/redhat-release|tr -d ' |.'
}

# install yum repos
setBaseRepoAliyun() {
    local osVersion="$(getCentosVersion)"
    # set baseRepo to aliyun
    rpm -q wget || yum -y install wget
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    wget -O /etc/yum.repos.d/CentOS-Base.repo "http://mirrors.aliyun.com/repo/Centos-${osVersion}.repo"
}
installEpelRpoAliyun() {
    local osVersion="$(getCentosVersion)"
    # install epel Repo and set to aliyun
    rpm -Uvh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${osVersion}.noarch.rpm"
    mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
    mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
    wget -O /etc/yum.repos.d/epel.repo "http://mirrors.aliyun.com/repo/epel-${osVersion}.repo"
}
installElRepos() {
    # el repo
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
}
installWebtaticRepos() {
    local osVersion="$(getCentosVersion)"
    # webtatic repo
    rpm -q epel-release &>/dev/null || installEpelRpoAliyun
    if [ $osVersion -eq 7 ];then
        pm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
    elif [ $osVersion -eq 6 ];then
        pm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
    fi
}
installOelRepos() {
    # Oracle Linux 7 http://public-yum.oracle.com/getting-started.html
    # 这个 repo 没有验证过是否能用
    wget -O /etc/yum.repos.d/public-yum-ol7.repo http://yum.oracle.com/public-yum-ol7.repo
}
installNuxRepos() {
    # Nux Dextop Repo http://li.nux.ro/download/nux/dextop/
    rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-1.el7.nux.noarch.rpm
}
installMariadbRepo() {
    # https://downloads.mariadb.org/mariadb/repositories/#mirror=tuna&distro=CentOS&distro_release=centos7-amd64--centos7&version=10.1
    # sudo yum install MariaDB-server MariaDB-client
    cat > /etc/yum.repos.d/mariadb.repo << EOF
# MariaDB 10.1 CentOS repository list - created 2017-05-08 11:28 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
#baseurl = http://yum.mariadb.org/10.1/centos7-amd64
baseurl = https://mirrors.aliyun.com/mariadb/mariadb-10.1.23/yum/centos73-amd64/
#baseurl = https://mirrors.tuna.tsinghua.edu.cn/mariadb/mariadb-10.1.23/yum/rhel73-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF
}
installRepos() {
    setBaseRepoAliyun
    installEpelRpoAliyun
    #installElRepos
    #installWebtaticRepos
    #installMariadbRepo
}

# yum update
yumUpdate() {
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-{CentOS,EPEL}-[6-7]
    yum clean all;yum makecache
    yum update -y
}

# yum makecache weekly
yumMakecacheweekly() {
    cat > /etc/cron.d/yummakecache << EOF
# Run yum makecache once a week on Monday at 4am by default
0 4 * * 1 root /usr/bin/yum makecache &> /var/log/yummakecache.log 2>&1
EOF
}

# install toos
installTools() {
    yum -y install wget curl \
        lrzsz vim-enhanced git \
        nmap-ncat nmap ntpdate \
        dstat sysstat iotop iftop htop \
        openssh-clients dmidecode \
        autoconf automake make gcc gcc-c++ \
        parted man-db bind-utils \
        tree psmisc lsof strace tcpdump mtr \
        rsync inotify-tools mlocate\
        net-tools libtool apr-devel yasm \
        libffi-devel python-devel openssl-devel \
        openvpn openvpn-auth-ldap lvm2 #htop httpry lynx elinks pwgen ipmitool
}

# replace Firewalld wiht Iptables
replaceFirewalldIptables() {
    systemctl disable firewalld
    systemctl stop firewalld
    #wget -c http://cbs.centos.org/kojifiles/packages/etcd/0.4.6/7.el7.centos/x86_64/etcd-0.4.6-7.el7.centos.x86_64.rpm
    #yum -y localinstall etcd-0.4.6-7.el7.centos.x86_64.rpm
    rpm -q iptables-services || yum -y install iptables-services
    systemctl enable iptables
    systemctl start iptables
    iptables -F
    iptables-save
    sed -i 's/22/1:65535/' /etc/sysconfig/iptables
    systemctl restart iptables
}

# set time and ntp
checkTimeNtp() {
    ls -l /etc/localtime |grep 'Asia/Shanghai'
}
setTimeNtp() {
    timedatectl set-timezone Asia/Shanghai
    rpm -q ntpdate || yum install -y ntpdate
    for ntpserver in time.windows.com 0.asia.pool.ntp.org 1.asia.pool.ntp.org 2.asia.pool.ntp.org 3.asia.pool.ntp.org;do
        if /usr/sbin/ntpdate -s $ntpserver ;then
            clock -w
            break
        fi
    done
    # crontal -e
    grep -q '0 \* \* \* \*  for ntpserver in time.windows.com 0.asia.pool.ntp.org 1.asia.pool.ntp.org 2.asia.pool.ntp.org 3.asia.pool.ntp.org;do /usr/sbin/ntpdate -s $ntpserver && break;done' /var/spool/cron/root 2>/dev/null || \
    echo '0 * * * *  for ntpserver in time.windows.com 0.asia.pool.ntp.org 1.asia.pool.ntp.org 2.asia.pool.ntp.org 3.asia.pool.ntp.org;do /usr/sbin/ntpdate -s $ntpserver && break;done' >> /var/spool/cron/root
}

editProfile() {
    cat >>/etc/profile<<ENDF
export HISTTIMEFORMAT='%F %T '
export HISTSIZE=10000
export HISTFILESIZE=10000
ENDF
    source /etc/profile
}

modifyLimits() {
    cat >> /etc/security/limits.conf << ENDF
* hard nofile 1000000
* soft nofile 1000000
* soft core unlimited
* soft stack 10240
* hard noproc 65535
ENDF
}

modifySysctl() {
    cat >> /etc/sysctl.conf << ENDF
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=99999999
net.nf_conntrack_max = 655360
ENDF
    sysctl -p
    cat /proc/sys/fs/file-max /proc/sys/fs/inotify/max_user_instances /proc/sys/fs/inotify/max_user_watches
}

# modidy ssh_config & sshd_config
modifySshCfg() {
    # ssh_config
    cp -a /etc/ssh/ssh_config /etc/ssh/ssh_config.`date '+%Y%m%d%H%M%S'` && \
    sed -i '/^#\? \+Port /c\Port 22876' /etc/ssh/ssh_config
    # sshd_config
    cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.`date '+%Y%m%d%H%M%S'` && \
    sed -i '/^#\?Port /c\Port 22876' /etc/ssh/sshd_config
    sed -i '/^#\?UseDNS /c\UseDNS no' /etc/ssh/sshd_config
    sed -i '/^#\?GSSAPIAuthentication /c\GSSAPIAuthentication no' /etc/ssh/sshd_config
    systemctl restart sshd
}

setEnv() {
    if [ -z "$1" ];then
        local envName='prod'
    else
        local envName="$1"
    fi
    if grep -q -e 'APPLICATION_ENV' /etc/profile ;then
        sed -i "/APPLICATION_ENV/c\export APPLICATION_ENV='$envName'" /etc/profile
    else
        echo "export APPLICATION_ENV='$envName'" >> /etc/profile
    fi
}


installNTPD() {
    time for ntpserver in time.windows.com 0.asia.pool.ntp.org 1.asia.pool.ntp.org 2.asia.pool.ntp.org 3.asia.pool.ntp.org;do /usr/sbin/ntpdate $ntpserver && break;done
    rpm -q ntp || yum install ntp -y
    cat >> /etc/ntp.conf << ENDF
server 0.asia.pool.ntp.org iburst
server 1.asia.pool.ntp.org iburst
server 2.asia.pool.ntp.org iburst
server 3.asia.pool.ntp.org iburst
ENDF
    systemctl start ntpd
    systemctl enable ntpd
}

installLogwatch() {
    rpm -q logwatch || yum -y install logwatch
    rpm -q sendmail || yum -y install sendmail
    ln -s /usr/share/logwatch/default.conf/logwatch.conf /etc/logwatch/conf/logwatch.conf
    sed -i 's/MailTo = root/MailTo = long.wan@1mifudao.com/g' /etc/logwatch/conf/logwatch.conf
    sed -i 's/MailFrom = Logwatch/MailFrom = Logwatch/g' /etc/logwatch/conf/logwatch.conf
    echo 'root:wanlong@1mifudao.com' >> /etc/aliases
    echo '0 1 * * * /usr/bin/perl /usr/share/logwatch/scripts/logwatch.pl >/dev/null 2>&1' >> /var/spool/cron/root 2>/dev/null
    
    sed -i 's/Output = stdout/Output = mail/g' /etc/logwatch/conf/logwatch.conf
    #sed -i 's/Format = text/#Format = text/g' /etc/logwatch/conf/logwatch.conf
    #sed -i 's/Encode = none/#Encode = none/g' /etc/logwatch/conf/logwatch.conf
    
    /usr/bin/perl /usr/share/logwatch/scripts/logwatch.pl
    
}

installIfstat() {
    test -f ifstat-*.tar.gz || wget http://gael.roualland.free.fr/ifstat/ifstat-1.1.tar.gz
    tar zxf ifstat-1.1.tar.gz
    cd ifstat-1.1;./configure &>/dev/null && make &>/dev/null && make install &>/dev/null
    local ret=$?
    if [ $ret = 0 ];then
        ln -s /usr/local/bin/ifstat /bin/
        echo "ifstat install ok."
    else
        echo "ifstat install fail."
    fi
}

installNginx() {
    cat >> /etc/yum.repos.d/nginx.repo << EOD
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOD
    yum -y --enablerepo=nginx install nginx
}

disableDefaultServices() {
    for srvName in postfix.service auditd.service tuned.service ;do 
        systemctl disable $srvName
        systemctl stop $srvName
    done
}

