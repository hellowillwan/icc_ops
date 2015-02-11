#!/bin/sh

#v2.4.5
MONGOD4w='/usr/local/mongodb-linux-x86_64-2.4.5/bin/mongod'
#v2.4.9
MONGOD5w='/usr/local/mongodb-linux-x86_64-2.4.9/bin/mongod'

${MONGOD4w} \
--shardsvr \
--replSet shard1 \
--bind_ip 10.0.0.2 \
--port 40001 \
--dbpath /data/mongodb/40000shared1 \
--logpath /var/log/40000shared1.log \
--logappend \
--nssize 2000 \
--fork

${MONGOD4w} \
--shardsvr \
--replSet shard2 \
--bind_ip 10.0.0.2 \
--port 40002 \
--dbpath /data/mongodb/40000shared2 \
--logpath /var/log/40000shared2.log \
--logappend \
--nssize 2000 \
--fork

${MONGOD5w} \
--shardsvr \
--replSet shard1 \
--bind_ip 10.0.0.2 \
--port 50001 \
--dbpath /data/mongodb/50000shared1 \
--logpath /var/log/50000shared1.log \
--logappend \
--nssize 2000 \
--fork

${MONGOD5w} \
--shardsvr \
--replSet shard2 \
--bind_ip 10.0.0.2 \
--port 50002 \
--dbpath /data/mongodb/50000shared2 \
--logpath /var/log/50000shared2.log \
--logappend \
--nssize 2000 \
--fork
