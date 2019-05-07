#!/bin/bash
#
# push logrotate to App servers
#

# variables
scripts_path="~/ops/gitlabProjects/shell/javaAppLogrotate"
#machine_group="p147:p148:p149"
#machine_group="apiservers"
machine_group="p156:p163:p129:p161:p162:p131:p135"
if_askPass=' -K'
ansible_cli="ansible --sudo $if_askPass $machine_group -f 50 "

pushToServer() {
    # delete /etc/cron.daily/logrotate
    $ansible_cli -m shell \
        -a "rm /etc/cron.daily/logrotate /etc/logrotate.d/tomcat -f" \
        2>/dev/null

    # put /etc/cron.d/logrotate 
    for file in cron-logrotate ; do
        $ansible_cli -m copy \
            -a "src=${scripts_path}/$file dest=/etc/cron.d/logrotate mode=0644 owner=root group=root" \
            2>/dev/null
    done

    # put /usr/local/sbin/logrotate.sh
    for file in logrotate.sh ; do
        $ansible_cli -m copy \
            -a "src=${scripts_path}/$file dest=/usr/local/sbin/logrotate.sh mode=0755 owner=root group=root" \
            2>/dev/null
    done

    # put /etc/logrotate.d/javaApp
    for file in logrotate-javaApp ; do
        $ansible_cli -m copy \
            -a "src=${scripts_path}/$file dest=/etc/logrotate.d/javaApp mode=0644 owner=root group=root" \
            2>/dev/null
    done
}

check() {
    $ansible_cli -m shell \
        -a "md5sum /etc/cron.{d,daily}/logrotate /usr/local/sbin/logrotate.sh /etc/logrotate.d/javaApp|sort" \
        2>/dev/null

    md5sum cron-logrotate  logrotate-javaApp  logrotate.sh|sort
}

# main
# check if ansible in path
if ! which ansible &>/dev/null ; then
    echo "ansible not found,exit."
    exit 1
fi


pushToServer
check
