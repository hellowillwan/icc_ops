#!/bin/bash

initremotely() {
    # 此函数可以安全地重复执行多次
    if [ -z "$1" ];then
        echo "Usage: $0 ip [port user]"
        return
    fi
    local ip="$1"
    local port="${2:-22}"
    local user="${3:-root}"
    if [ "${user}" = 'root' ];then
        local ifsudo=''
    else
        local ifsudo=' sudo '
    fi
    # 部署公钥
    echo "部署公钥到 ${user}@${ip}"
    ssh-copy-id -i ~/.ssh/id_rsa.pub -p ${port} ${user}@${ip}
    # 关闭 selinux
    echo '关闭 selinux'
    ssh -p ${port} ${user}@${ip} ${ifsudo} /usr/sbin/setenforce 0
    ssh -p ${port} ${user}@${ip} ${ifsudo} /usr/sbin/sestatus
    # 创建普通账户并添加 sudo 权限
    local nuser='wanlong'
    local nupwd='ku8diHor'
    echo "创建普通账户 $nuser"
    ssh -p ${port} ${user}@${ip} ${ifsudo} useradd "${nuser}"
    echo "为 $nuser 设置初始密码"
    echo -n ${nupwd} | ssh -p ${port} ${user}@${ip} ${ifsudo} passwd --stdin ${nuser}
    echo "部署公钥到 ${nuser}@${ip} 按提示输入 ${nupwd}"
    if ! ssh-copy-id -i ~/.ssh/id_rsa.pub -p ${port} ${nuser}@${ip} ; then
        ssh -p ${port} ${user}@${ip} ${ifsudo} mkdir -p ~${nuser}/.ssh
        ssh -p ${port} ${user}@${ip} ${ifsudo} cp ~${user}/.ssh/authorized_keys ~${nuser}/.ssh/
        ssh -p ${port} ${user}@${ip} ${ifsudo} chown -R ${nuser}:${nuser} ~${nuser}/.ssh
    fi
    echo "复制秘钥"
    scp -P ${port} ~/.ssh/id_rsa* ${nuser}@${ip}:~/.ssh/
    echo "复制 vimrc"
    scp -P ${port} ~/.vimrc ${nuser}@${ip}:~/
    echo "为 $nuser 添加 sudo 权限"
    echo "${nuser} ALL=(ALL:ALL) ALL" | ssh -p ${port} ${user}@${ip} ${ifsudo} /usr/bin/tee /etc/sudoers.d/${nuser}
    ssh -p ${port} ${user}@${ip} ${ifsudo} cat /etc/sudoers.d/${nuser}
    # 部署初始化脚本
    cd /home/yimi/ops/gitlabProjects/shell/serverInit
    #rsync -tvcz -e "ssh -l ${user} -p ${port} " ./serverInit*.sh ${ip}:~/tmp/
    scp -P ${port} ./serverInit*.sh ${user}@${ip}:/tmp/
}

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin"
initremotely $1 $2 $3
