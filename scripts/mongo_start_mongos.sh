#!/bin/sh

mongos_4w ()
{
	/home/mongo/mongodb/bin/mongos \
	--configdb 10.0.0.30:40000,10.0.0.31:40000,10.0.0.32:40000 \
	--logpath /home/mongo/log/mongos.log \
	--logappend \
	--fork


	echo -en "\n\n\nret:$? 4w-mongos Logfile: /home/mongo/log/mongos.log\n\n"
}


mongos_5w ()
{
	/home/50000/mongodb/bin/mongos --port 57017 \
	--configdb 10.0.0.30:50000,10.0.0.31:50000,10.0.0.32:50000 \
	--logpath /home/50000/log/mongos.log \
	--logappend \
	--fork


	echo -en "\n\n\nret:$? 5w-mongos Logfile: /home/50000/log/mongos.log\n\n"
}


configdb_4w ()
{
	/home/mongo/mongodb/bin/mongod \
	--bind_ip 10.0.0.30 --port 40000 \
	--configsvr \
	--dbpath /home/mongo/config \
	--logpath /home/mongo/log/10.0.0.30.config.log \
	--logappend \
	--nssize 2000 \
	--fork


	echo -en "\n\n\nret:$? 4w-configdb Logfile: /home/mongo/log/10.0.0.30.config.log\n\n"
}



configdb_5w ()
{
	/home/50000/mongodb/bin/mongod \
	--bind_ip 10.0.0.30 --port 50000 \
	--configsvr \
	--dbpath /home/50000/config \
	--logpath /home/50000/log/10.0.0.30.config.log \
	--logappend \
	--nssize 2000 \
	--fork


	echo -en "\n\n\nret:$? 5w-configdb Logfile: /home/50000/log/10.0.0.30.config.log\n\n"
}


$1

