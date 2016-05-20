#!/bin/sh
#
# 从 Mongodb ReplSet DelaySecondary 获得某个时间点的数据 的相关命令行;
#

# 计算给定时间 距离 此刻 的秒数,用于从 DelaySecondary 获得某个时间点的数据;
#
ts1=$(date -d "$1" '+%s')	# $1 -> '2016-05-13 00:00'
ts2=$(date '+%s')
echo $(date -d @"$ts1") : $ts1
echo now : $ts2
echo diff: $[$ts2-$ts1]

# 设置 DelaySecondary Delay 时间到 上面计算得到的差值, 并 reconfig ReplSet ,开始追溯 
#
# 6w_shard1:PRIMARY> cfg.members[4].slaveDelay=231885
# 6w_shard1:PRIMARY> rs.reconfig(cfg);

# 当 DelaySecondary 追溯到预期的时间点时,再次设置Delay 时间到一个很长的值, 并 reconfig ReplSet,这样可以停止追溯.
#
# 6w_shard1:PRIMARY> cfg.members[4].slaveDelay=231885
# 6w_shard1:PRIMARY> rs.reconfig(cfg);

# 观察 DelaySecondary 追溯到什么时间点了
#
#$ watch -d -n 1 bash -c "clear;echo 'db.printSlaveReplicationInfo()'|/home/60000/bin/mongo 10.0.0.42:60000"

# 从 DelaySecondary dump 出数据
#
# mkdir -p /tmp/0517;/home/60102/bin/mongodump -h 10.0.0.24 --port 60102 -d bda -c idatabase_collection_569459f3af52d5f9398b4569  -o /tmp/0517
# mkdir -p /tmp/0518;/home/60102/bin/mongodump -h 10.0.0.24 --port 60102 -d bda -c idatabase_collection_569459f3af52d5f9398b4569  -o /tmp/0518

# 恢复 数据到临时集合
# /home/60102/bin/mongorestore --drop -h 10.0.0.30 --port 57017 -d ICCv1 -c idatabase_collection_573eb5c0311f8afe048b4597  /tmp/0517/bda/idatabase_collection_569459f3af52d5f9398b4569.bson
# /home/60102/bin/mongorestore --drop -h 10.0.0.30 --port 57017 -d ICCv1 -c idatabase_collection_573eb5c0311f8afe048b4597  /tmp/0518/bda/idatabase_collection_569459f3af52d5f9398b4569.bson


