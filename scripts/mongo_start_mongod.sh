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


$1

