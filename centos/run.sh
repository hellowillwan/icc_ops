#!/bin/bash
#
# 脚本功能：
# - 更新|分发 ulimit 相关配置文件
# - 手工执行相关命令（不是必需的）
#

# variables
scripts_path="~/ops/gitlabProjects/conf/centos"
#machine_group="roomservers"
machine_group="p161:p162"
if_askPass=' -K'
ansible_cli="ansible --sudo $if_askPass $machine_group -f 50 "

pushToServer() {
    # put limits.conf 90-nfile.conf 90-nproc.conf
    $ansible_cli -m copy \
        -a "src=${scripts_path}/limits.conf dest=/etc/security/limits.conf mode=0644 owner=root group=root" \
        2>/dev/null
    $ansible_cli -m shell -a "rm /etc/security/limits.d/* -rf"
    for file in 90-nfile.conf 90-nproc.conf;do
        $ansible_cli -m copy \
        -a "src=${scripts_path}/${file} dest=/etc/security/limits.d/${file} mode=0644 owner=root group=root" \
        2>/dev/null
    done
}

check() {
    echo '检查 limits.conf 90-nfile.conf 90-nproc.conf'
    $ansible_cli -m shell \
    -a "md5sum /etc/security/limits.conf /etc/security/limits.d/90-nfile.conf /etc/security/limits.d/90-nproc.conf " 2>/dev/null

    md5sum limits.conf 90-nfile.conf 90-nproc.conf
}


## main
# check if ansible in path
if ! which ansible &>/dev/null ; then
    echo "ansible not found,exit."
    exit 1
fi
pushToServer
check


## test
# 检查
#$ansible_cli -m shell -a "ulimit -u -n -p"

