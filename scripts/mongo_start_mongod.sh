#!/bin/sh

mongod_4w ()
{
	/home/mongo/mongodb/bin/mongod \
	--shardsvr --replSet shard1 \
	--bind_ip 10.0.0.40 --port 40000 \
	--dbpath /home/mongo/data \
	--logpath /home/mongo/log/10.0.0.40.log \
	--logappend \
	--nssize 2000 \
	--fork


	echo -en "\n\n\nret:$? 4w-mongod Logfile: /home/mongo/log/10.0.0.40.log\n\n"
}

mongod_5w ()
{
	/home/50000/mongodb/bin/mongod \
	--shardsvr --replSet shard1 \
	--bind_ip 10.0.0.40 --port 50000 \
	--dbpath /home/50000/data \
	--logpath /home/50000/log/10.0.0.40.log \
	--logappend \
	--nssize 2000 \
	--fork


	echo -en "\n\n\nret:$? 5w-mongod Logfile: /home/50000/log/10.0.0.40.log\n\n"
}

mongod_6w ()
{
	ulimit -u 65536
	/home/60000/bin/mongod --port 60000 \
	--shardsvr --replSet shard1 \
	--setParameter failIndexKeyTooLong=false \
	--storageEngine wiredTiger \
	--dbpath /home/60000/data \
	--logpath /home/60000/log/mongod.log \
	--logappend \
	--fork


	echo -en "\n\n\nret:$? 6w-mongod Logfile: /home/60000/log/mongod.log\n\n"
}


if grep -q -P -e "^${1}[ |\t]?\(\)[ |\t]?\{?" $0 ;then
	$1
else
	echo "cmd not found,nothing done."
	exit 1
fi
