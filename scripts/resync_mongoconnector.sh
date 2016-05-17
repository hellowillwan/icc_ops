#!/bin/sh
#
# Resyncing the Connector
# https://github.com/mongodb-labs/mongo-connector/wiki/Resyncing%20the%20Connector
# Using mongodump and mongo-connector together. 
# https://github.com/mongodb-labs/mongo-connector/wiki/Usage-with-MongoDB
#

resync_connector() {
	# Parameters
	if [ -z $1 ];then
		echo "Usage: $0 mongo-connector-program-name"
		return 1
	fi
	program_name="$1"
	supervisorcfg='/etc/supervisor.conf'
	if ! grep -q "program:${program_name}" ${supervisorcfg} &>/dev/null ;then
		echo "program:${program_name} not found in ${supervisorcfg}"
		return 2
	fi

	# Generate a mongo-connector timestamp file
	ts_file=$(grep -A 5 -e "program:${program_name}" ${supervisorcfg} | grep '^command'|tr ' ' '\n'|grep -e 'oplog.*timestamp')
	# stop mongo-connector
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	:>${ts_file}	# 清空 然后启动 重新产生新的 timestamp file
	/usr/bin/supervisorctl -c ${supervisorcfg} start "${program_name}:${program_name}0" &>/dev/null
	sleep 30

	# Stop mongo-connector 
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	/usr/bin/supervisorctl -c ${supervisorcfg} stop "${program_name}:${program_name}0" &>/dev/null
	sleep 5
	#
	if /usr/bin/supervisorctl -c ${supervisorcfg} status "${program_name}:${program_name}0" \
	| grep -q STOPPED ;then
		# Dump & restore
		source /usr/local/sbin/sc_mongodb_functions.sh
		for col in $( grep -A 5 -e "program:${program_name}" ${supervisorcfg} \
			| grep '^command'|head -n 1 \
			| tr ' |,' '\n'|grep -i -P '^ICCv1\.' | sed 's/ICCv1.//' # | grep '568f1b7eb1752f4c358b54ed' # | grep -v -e '^idatabase_collection_'
		);do
			col_base64=$(echo -n $col|base64)
			if [ "${program_name}" = 'mongo-connector-prod_icc-to-dev_bda' ];then
				mongo_sync2 download 2 ICCv1 ${col_base64} bda
			elif [ "${program_name}" = 'mongo-connector-prod_icc-to-dev_icc' ];then
				mongo_sync2 download 2 ICCv1 ${col_base64}
			else
				:
			fi
		done

		# Start mongo-connector 
		/usr/bin/supervisorctl -c ${supervisorcfg} start "${program_name}:${program_name}0"
	fi
}

#resync_connector mongo-connector-prod_icc-to-dev_icc
resync_connector mongo-connector-prod_icc-to-dev_bda
