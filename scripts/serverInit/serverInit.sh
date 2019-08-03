#!/bin/bash
#
# 服务器云服务器初始化步骤
# 适用于CentOS-6/7
#
#


# load functions
source serverInit_BaseFunctions.sh

# main
if [ "$(whoami)" != 'root' -o -z "$2" ];then
    echo "Usage: $0 hostName appType [envType]"
    echo "    hostName: default|qcloud-cd-bgp-1"
    echo "    appType: $(grep -e '^ \+[a-zA-Z1-9]\+)$' $0 | sed 's/ //g;s/)//g'|tr '\n' '|'|sed 's/|$//')"
    echo "    [envType: dev|demo|prod]"
    echo "script must be run with root permission."
    exit 1
else
    export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
    hostName="$1"
    appType="$2"
    envName="$3"
fi

# 系统层面的公共基础设置
disableSelinux
setHostname "$hostName"
setDns
installRepos
yumUpdate
yumMakecacheweekly
installTools
replaceFirewalldIptables
setTimeNtp
installIfstat
updatedb
disableDefaultServices

# 不同类型的服务器做不同的配置
case "$appType" in
    appServer)
        setEnv "$envName"
        ;;
    roomServer)
        ;;
    tcpProxy)
        installNginx
        ;;
    *)
        echo "unknow appType: $appType, nothing done."
        exit 1
        ;;
esac

# 最后修改 ssh 配置 会重启 ssh 服务
modifySshCfg

