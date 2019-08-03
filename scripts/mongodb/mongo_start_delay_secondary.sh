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


# 2015-07-21 更新
# 已创建
#for port in 40101 40102 60101 60102 60201 60202 ;do
#	mkdir -p /home/${port}/{data,log}
#	ln -s /usr/local/mongodb-linux-x86_64-rhel62-3.0.4/bin /home/${port}/
#done


# 4W shard1
/home/40101/bin/mongod --shardsvr --replSet shard1 --port 40101 --dbpath /home/40101/data --replIndexPrefetch none --logpath /home/40101/log/mongod.log --logappend --nssize 2000 --fork
/home/40102/bin/mongod --shardsvr --replSet shard1 --port 40102 --dbpath /home/40102/data --replIndexPrefetch none --logpath /home/40102/log/mongod.log --logappend --nssize 2000 --fork


# 6W shard1
/home/60101/bin/mongod --port 60101 --shardsvr --replSet 6w_shard1 --oplogSize 153600 --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --replIndexPrefetch none  --dbpath /home/60101/data --logpath /home/60101/log/mongod.log --logappend --nssize 2000 --fork

/home/60102/bin/mongod --port 60102 --shardsvr --replSet 6w_shard1 --oplogSize 51200  --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --replIndexPrefetch none --dbpath /home/60102/data --logpath /home/60102/log/mongod.log --logappend --nssize 2000 --fork


# 6W shard2
/home/60201/bin/mongod --port 60201 --shardsvr --replSet 6w_shard2 --oplogSize 153600 --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --replIndexPrefetch none --dbpath /home/60201/data --logpath /home/60201/log/mongod.log --logappend --nssize 2000 --fork

/home/60202/bin/mongod --port 60202 --shardsvr --replSet 6w_shard2 --oplogSize 51200  --setParameter failIndexKeyTooLong=false --storageEngine wiredTiger --wiredTigerCacheSizeGB 1 --noIndexBuildRetry --replIndexPrefetch none --dbpath /home/60202/data --logpath /home/60202/log/mongod.log --logappend --nssize 2000 --fork

# 参考：http://docs.mongodb.org/manual/reference/program/mongod/

