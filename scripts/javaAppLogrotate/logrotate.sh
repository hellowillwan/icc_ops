#!/bin/sh

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:$PATH"
logrotate /etc/logrotate.conf >/dev/null 2>&1
EXITVALUE=$?
if [ $EXITVALUE != 0 ]; then
    logger -t logrotate "ALERT exited abnormally with [$EXITVALUE]"
fi
exit 0
