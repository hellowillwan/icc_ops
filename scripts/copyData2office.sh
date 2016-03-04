#!/bin/sh

WORKINGDIR='/home/wanlong/PKG/copyData2office/'

cd $WORKINGDIR

DB='ICCv1'

COLLECTIONS='
system_account
system_account_project_acl
system_role
system_resource
system_setting
idatabase_indexes 
idatabase_collections 
idatabase_structures 
idatabase_projects 
idatabase_plugins 
idatabase_plugins_collections 
idatabase_plugins_structures 
idatabase_plugins_datas 
idatabase_project_plugins 
idatabase_views 
idatabase_statistic 
idatabase_promission 
idatabase_keys 
idatabase_collection_orderby 
idatabase_mapping 
idatabase_lock 
idatabase_quick 
idatabase_dashboard 
idatabase_files 
idatabase_plugins_indexes 
idatabase_plugins_statistic 
idatabase_logs' 

#dump
for coll_name in $COLLECTIONS ;do
	echo -n "dumping $coll_name ..."
	/home/60000/bin/mongodump -h 10.0.0.30 --port 57017 -d "${DB}" -c "${coll_name}" -o $WORKINGDIR &> /dev/null
	echo "$? done."
done

echo

#restore 2 office
for coll_name in $COLLECTIONS ;do
	#
	echo -n "restoring $coll_name ..."
	/home/60000/bin/mongorestore --drop -h 10.0.0.200 --port 37017 \
		-d "${DB}" -c "${coll_name}" ${WORKINGDIR}/"${DB}"/${coll_name}.bson &> /dev/null
	echo -en "$? done. count: "
	echo "db.${coll_name}.count()" | /home/60000/bin/mongo 127.0.0.1:37017/ICCv1|grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye'
done
