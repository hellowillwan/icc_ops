# -*-Shell-script-*-
#
# functions     This file contains functions to be used by Commonworker 
# usage		restart_mongos 27017
#
#


# restart mongos and check and report status
DT2="date '+%Y-%m-%d %H:%M:%S'"
ICC_SYS_COLL='/var/lib/icc_sys_coll.list'


#
#mongos相关函数
#

#检查mongos服务状态
check_mongos() {
	if [ -z "$2" ] ;then
		echo "PORT parameter missing."
		return 1
	fi
	MONGO="/home/mongo/mongodb/bin/mongo"
	IP="$1"
	PORT="$2"
	if echo 'db.getName()'|${MONGO} ${IP}:${PORT} &>/dev/null ; then
		echo 100
		return 0
	else
		echo 0
		return 1
	fi
}

#重启mongos服务
restart_mongos() {
	if [ -z "$1" ] ;then
		echo "PORT parameter missing."
		return 1
	fi

	PORT="$1"
	#不检查IP,默认操作本机的mongos
	IP='10.0.0.30'

	#每个mongos实例参数各不相同,注意修改
	if [ "$PORT" = "27017" ];then
		MONGOS_BIN='/home/mongo/mongodb/bin/mongos'
		CONFIG_DB='10.0.0.30:40000,10.0.0.31:40000,10.0.0.32:40000'
		MONGOS_LOG='/home/mongo/log/mongos.log'
	elif [ "$PORT" = "57017" ];then
		MONGOS_BIN='/home/60000/bin/mongos'
		CONFIG_DB='10.0.0.30:60000,10.0.0.31:60000,10.0.0.32:60000'
		MONGOS_LOG='/home/60000/log/mongos.log'
	else
		echo "Bad port parameter."
		return 1
	fi

	#kill mongos
	ps -ef|grep -e "bin/mognos.*port.*${PORT}"|grep -v grep |awk '{print $2}'|xargs kill -9 &>/dev/null
	ps -ef|grep -e "bin/mongos.*port.*${PORT}"|grep -v grep |awk '{print $2}'|xargs kill -9 &>/dev/null
	#check if killed
	if ps -ef|grep -e "bin/mongos.*port.*${PORT}"|grep -v grep &>/dev/null ;then
		echo "$(eval $DT2) Stop mongos ${IP}:${PORT} Fail."
	else
		echo "$(eval $DT2) Stop mongos ${IP}:${PORT} OK."
	fi

	#start mongos
	#mongos --port 27017 --configdb 10.0.0.30:40000,10.0.0.31:40000,10.0.0.32:40000 --logpath /home/mongo/log/mongos.log --logappend --fork
	#mongos --port 57017 --configdb 10.0.0.30:60000,10.0.0.31:60000,10.0.0.32:60000 --logpath /home/60000/log/mongos.log --logappend --fork
	sudo ${MONGOS_BIN} --port ${PORT} --configdb ${CONFIG_DB} --logpath ${MONGOS_LOG} --logappend --fork
	#check
	if [ $? -eq 0 ];then
		echo "$(eval $DT2) Start mongos ${IP}:${PORT} OK."
	else
		echo "$(eval $DT2) Start mongos ${IP}:${PORT} Fail."
	fi

	#check connecting mongos 
	if check_mongos $IP $PORT &>/dev/null ;then
		echo "$(eval $DT2) Check mongos ${IP}:${PORT} OK."
		return 0
	else
		echo "$(eval $DT2) Check mongos ${IP}:${PORT} Fail."
		return 1
	fi 
}

#重启所有mongos服务
restart_all_mongos() {
	if [ -z "$1" ] ;then
		echo "PORT parameter missing."
		return 1
	fi

	PORT="$1"
	local MONGOS_IP_ARY=('10.0.0.30' '10.0.0.31' '10.0.0.32')

	for ip in ${MONGOS_IP_ARY[@]} ;do
		echo ${localkey} restart_mongos ${PORT} | gearman -h 10.0.0.200 -f "CommonWorker_${ip}"
	done

	echo ${localkey} check_services mongos | gearman -h 10.0.0.200 -f "CommonWorker_10.0.0.200"
}


#
#查询集合相关信息
#

#集合基本信息
get_collection_info() {
	#可以通过环境变量取得
	#if [ -z "$5" ];then
	#	echo "Parameter missing,usage: $0 MONGO MONGOS_IP MONGOS_PORT DB collection_name"
	#	return 1
	#else
	#	MONGO="$1"
	#	MONGOS_IP="$2"
	#	MONGOS_PORT="$3"
	#	DB="$4"
	#	COLLECTION_NAME="$5"
	#fi
	#
	#下面 project_id , project_name 取值可能错误,因为提供的 COLLECTION_NAME 未必都是 ObjectId, 比如weixin.oauth,weixin.oauthsns
	# mongos> db.getCollection('iDatabase.form').find({'_id':ObjectId('oauthsns')},{'_id':0,'formDesc':1})
	# Fri Apr  3 11:57:38.042 Error: invalid object id: length
	# 这种情况下, project_id , project_name 的值就是个时间值(11:57:38.042)了
	#

	if [ "${DB}" = 'ICCv1' ];then
		col_name=$(echo "db.getCollection('idatabase_collections').find({'_id':ObjectId('${COLLECTION_NAME##*_}')},{'_id':0,'name':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$4);print $4}')
		project_id=$(echo "db.getCollection('idatabase_collections').find({'_id':ObjectId('${COLLECTION_NAME##*_}')},{'_id':0,'project_id':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$5);print $5}')
		project_name=$(echo "db.getCollection('idatabase_projects').find({'_id':ObjectId('${project_id}')},{'_id':0,'name':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$4);print $4}')
	elif [ "${DB}" = 'umav3' ];then
		col_name=$(echo "db.getCollection('iDatabase.form').find({'_id':ObjectId('${COLLECTION_NAME##*.}')},{'_id':0,'formDesc':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$4);print $4}')
		project_id=$(echo "db.getCollection('iDatabase.form').find({'_id':ObjectId('${COLLECTION_NAME##*.}')},{'_id':0,'projectId':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$4);print $4}')
		project_name=$(echo "db.getCollection('iDatabase.project').find({'_id':ObjectId('${project_id}')},{'_id':0,'projectDesc':1})" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk '{gsub("\"","",$4);print $4}')
	fi

	col_count=$(echo "db.getCollection('${COLLECTION_NAME}').stats().count" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' )
	col_indexes=$(echo "db.getCollection('${COLLECTION_NAME}').getIndexes()" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk 'BEGIN{FS=":";ORS=","}/"name"/{gsub("\"","",$2);print $2}' )

	echo "集合:" ${COLLECTION_NAME}
	echo "集合名称:" ${col_name}
	echo "所属项目:" ${project_name} '('${project_id}')'
	echo "文档数量:" ${col_count}
	echo "索引:" ${col_indexes}
}

#查询集合数据
find_collection() {

	#查询条件 字段列表 排序条件
	criteria=$(echo -n "${criteria}"|base64 -d 2>/dev/null) ; if ! echo "${criteria}" | grep -q -e '^\{.*\}$' ; then criteria='{}' ; fi
	projection=$(echo -n "${projection}"|base64 -d 2>/dev/null) ; if ! echo "${projection}" | grep -q -e '^\{.*\}$' ;then projection='{}' ; fi
	sort=$(echo -n "${sort}"|base64 -d 2>/dev/null) ; if ! echo "${sort}" | grep -q -e '^\{.*\}$';then sort='{}' ; fi

	[ -z "${limit}" ] && limit=10
	[ -z "${skip}" ] && skip=0

	#
	#qurey_str="db.getCollection('idatabase_collection_54be1fa1b1752f79168b52ec').find(
	#		{activity_id:'54be203d48961938618b46c0'},	#criteria	e2FjdGl2aXR5X2lkOic1NGJlMjAzZDQ4OTYxOTM4NjE4YjQ2YzAnfQ==
	#		{_id:0,activity_id:1}				#projection	e19pZDowLGFjdGl2aXR5X2lkOjF9
	#	).sort(
	#		{__CREATE_TIME__:-1}				#sort		e19fQ1JFQVRFX1RJTUVfXzotMX0=
	#	).limit(10).skip(0);"
	#
	# 符合查询条件的文档数量
	local query_str_1="db.getCollection('${COLLECTION_NAME}').count(${criteria});"
	local query_rst_1=$(echo "${query_str_1}" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' )
	#echo -e "查询语句:  " ${query_str_1}
	echo -e "符合查询条件的文档数量:  " ${query_rst_1}
	#
	# 符合条件的记录
	#
	local query_str_2="db.getCollection('${COLLECTION_NAME}').find(
			${criteria},
			${projection}
		).sort(
			${sort}
		).limit(${limit}).skip(${skip});"
	local query_rst_2=$(echo "${query_str_2}" \
			|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} \
			|grep -v -e 'MongoDB shell version' -e 'connecting to:' -e '^bye$' -e '^[ |\t]*$' \
			|awk 'BEGIN{ORS="</xmp><br><xmp>"}{print}' |sed 's/<br><xmp>$//' )
	echo -e "查询语句:\n" ${query_str_2}
	echo -e "查询结果:\n<xmp>" ${query_rst_2}
}

#查询集合主逻辑
mongo_query() {
	#查询集合
	if [ -z "$2" ];then
		echo "Parameter missing,usage: $0 DB Collection"
		return 1
	else
		DB="$1"				#umav3,ICCv1
		COLLECTION_LIKE="$2"		#may be just id

		MONGO="/home/60000/bin/mongo"	#这个变量为什么不能弄成全局的呢?因为不同函数可能在不同机器上执行,不同机器的环境(比如Mongo版本)竟然是不同的.
		MONGOS_IP='10.0.0.31'

		if [ "$DB" = "umav3" ];then
			MONGO="/home/mongodb/bin/mongo"
			MONGOS_PORT='40000'
			MONGOS_IP='10.0.0.41'
		elif [ "$DB" = "ICCv1" ] ;then
			MONGOS_PORT='57017'
		elif [ "$DB" = "mapreduce" ] ;then
			MONGOS_PORT='57017'
		elif [ "$DB" = "bda" ] ;then
			MONGOS_PORT='57017'
		elif [ "$DB" = "test" ] ;then
			MONGOS_PORT='57017'
		else
			echo "DB not exist"
			return 2
		fi

		[ $# -ge 3 ] && local criteria="$3"	|| local criteria=''
		[ $# -ge 4 ] && local projection="$4"	|| local projection=''
		[ $# -ge 5 ] && local sort="$5"		|| local sort=''
		[ $# -ge 6 ] && local limit="$6"	|| local limit=10
		[ $# -ge 7 ] && local skip="$7"		|| local skip=0
	fi

	echo 生产环境
	#提供的集合名称,很可能是不带前缀的,这里检查所有匹配的集合,暂时不限制数量了
	MATCHED_COLLECTIONS=$(echo 'show collections'|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} 2>/dev/null|grep ${COLLECTION_LIKE} 2>/dev/null)
	if [ -z "${MATCHED_COLLECTIONS}" ];then
		echo "collection not found in ${DB},nothing done."
		return
	fi
	for COLLECTION_NAME in ${MATCHED_COLLECTIONS} ;do
		if [ ! -z "${COLLECTION_NAME}" ];then
			#集合基本信息
			get_collection_info
			#集合查询
			find_collection
		else
			echo "collection not found in ${DB},nothing done."
		fi
	done
}

# 补全集合名称
format_collection_name () {
	case "$1" in
		ICCv1|ICCv1RO|bda)
		# 根据不同库名 补全集合名称
		if echo -n "$2" |grep -q -e '^idatabase_collection_';then
			echo "$2"
		else
			if grep -q -e "^${2}\$" ${ICC_SYS_COLL};then
				echo "$2"
			else
				echo "idatabase_collection_${2}"
			fi
		fi
		;;
		umav3)
		# 补全集合名称
		if echo -n "$2" |grep -q -e '^iDatabase\.';then
			echo "$2"
		else
			echo "iDatabase.${2}"
		fi
		;;
	esac
}

# 同步Mongdb集合 单个集合,支持指定目的库名和集合名
mongo_sync () {
	if [ -z "$4" ];then
		echo "Parameter missing,usage: $0 download|upload 0|1|2 src_db src_coll [dst_db dst_coll]"
		return 1
	fi

	# 临时目录 存放dump文件 
	WORKINGDIR='/tmp/mongo_sync'
	mkdir -p $WORKINGDIR &>/dev/null

	local DIRECTION="$1"
	local LOG="$2"	# 0: CUT sc 表单手工同步; 1: CUT api supervisor mongo-connector; 2: resync icc2office in supervisor
	local SRC_DB="$3"
	local SRC_COLLECTION=$(echo "$4"|base64 -d 2>/dev/null|sort|uniq|grep -v -P '^[ |\t]*$')

	# 补全源集合名称
	local SRC_COLLECTION=$(format_collection_name "$SRC_DB" "$SRC_COLLECTION")

	# 确定目的库名集合名
	if [ -z "$5" ];then
		local DST_DB=$SRC_DB
	else
		local DST_DB=$5
	fi

	if [ -z "$6" ];then
		local DST_COLLECTION=$SRC_COLLECTION
	else
		local DST_COLLECTION=$(echo "$6"|base64 -d 2>/dev/null|sort|uniq|grep -v -P '^[ |\t]*$')
	fi

	# 补全目的集合名称
	local DST_COLLECTION=$(format_collection_name "$DST_DB" "$DST_COLLECTION")

	if [ "$LOG" -eq 1 ] ;then
		# 记录集合同步状态
		local STATS_FILE='/var/log/mongo_sync.stats'
		# 停止supervisor mongo-connector
		if [ "$DIRECTION" = 'download' ];then
			local proc_name='mongo-connector-prod_iccv1-to-dev_iccv1ro:mongo-connector-prod_iccv1-to-dev_iccv1ro0'
		elif [ "$DIRECTION" = 'upload' ];then
			local proc_name='mongo-connector-bda_from_office:mongo-connector-bda_from_office0'
		else
			:
		fi
		/usr/bin/supervisorctl -c /etc/supervisor.conf stop "${proc_name}" &>/dev/null
	elif [ "$LOG" -eq 2 ] ;then
		:
	else
		# CUT 表单同步 prod_icc-to-dev_icc 没有必要禁止同步了
		:
		## 如果发现手工同步mongo-connector列表中的集合,则禁止
		#if grep -A 5 -e "program:mongo-connector-prod_iccv1-to-dev_iccv1ro" /etc/supervisor.conf \
		#	| grep '^command' | head -n 1 | tr ' |,' '\n'|grep -i -P '^(ICCv1\.)'|sed 's/ICCv1.//' \
		#	| grep -q -e "^${SRC_COLLECTION}\$"
		#then
		#		echo "集合 $SRC_COLLECTION 由 mongo-connector 工具进行实时同步，禁止手工同步."
		#		return
		#fi
	fi

	if [ ${DIRECTION} = 'download' ];then
		SRC_ENV='产生'
		SRC_HOST='10.0.0.31'
		SRC_PORT=57017
		if [ "${SRC_DB}" = 'umav3' ];then
			SRC_HOST='10.0.0.41'
			SRC_PORT=40000
		fi
		DST_ENV='dev'
		DST_HOST='10.0.0.200'
		DST_PORT=37017
		if [ "${DST_DB}" = 'ICCv1RO' ];then
			DST_ENV='dev'
			DST_HOST='10.0.0.200'
			DST_PORT=38017
		fi
	elif [ ${DIRECTION} = 'upload' ];then
		SRC_ENV='dev'
		SRC_HOST='10.0.0.200'
		SRC_PORT=37017
		DST_ENV='生产'
		DST_HOST='10.0.0.31'
		DST_PORT=57017
		if [ "$SRC_DB" = 'ICCv1' ];then
			echo 'upload any collection to ICCv1 was prohibited,nothing done,exit.'
			return 1
		fi
	else
		echo 'unkonw direction.'
		return 1
	fi

	#dump from SRC_HOST:SRC_PORT/SRC_DB SRC_COLLECTION
	[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${SRC_DB}#${SRC_COLLECTION}#dumping" >> $STATS_FILE
	/home/60000/bin/mongodump -h ${SRC_HOST} --port ${SRC_PORT} -d "${SRC_DB}" -c "${SRC_COLLECTION}" -o $WORKINGDIR &> /dev/null
	if [ "$?" -eq 0 ];then
		local dump_result="成功"
		[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${SRC_DB}#${SRC_COLLECTION}#dump_ok" >> $STATS_FILE
	else
		local dump_result="失败"
		[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${SRC_DB}#${SRC_COLLECTION}#dump_fail" >> $STATS_FILE
	fi
	local src_records_number=$(echo "db.getCollection('${SRC_COLLECTION}').count()" \
		| /home/60000/bin/mongo ${SRC_HOST}:${SRC_PORT}/${SRC_DB} 2>/dev/null \
		| grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye')
	
	echo "导出 ${SRC_ENV} 环境 ${SRC_DB}.${SRC_COLLECTION} : ${dump_result} 文档数量 : $src_records_number"

	#restore to DST_HOST:DST_PORT/DST_DB DST_COLLECTION
	[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${DST_DB}#${DST_COLLECTION}#restoring" >> $STATS_FILE
	if [ $src_records_number -gt 0 ] && [ -s "${WORKINGDIR}/${SRC_DB}/${SRC_COLLECTION}.bson" ] ; then
		# 如果bson文件大于零,即集合有数据,进行导入目的环境.导入操作可能会失败,可能需要导入多次,这里设置最多导入2次 or 两边记录数相等
		local restore_times=0	# 计数器
		local dst_records_number=0
		until [ $restore_times -ge 2 ] || [ $dst_records_number -eq $src_records_number ] ;do
			/home/60000/bin/mongorestore --drop -h ${DST_HOST} --port ${DST_PORT} \
			-d "${DST_DB}" -c "${DST_COLLECTION}" ${WORKINGDIR}/"${SRC_DB}"/${SRC_COLLECTION}.bson &> /dev/null
			if [ "$?" -eq 0 ];then
				local restore_result="成功"
				[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${DST_DB}#${DST_COLLECTION}#restore_ok" >> $STATS_FILE
			else
				local restore_result="失败"
				[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${DST_DB}#${DST_COLLECTION}#restore_fail" >> $STATS_FILE
			fi
			local dst_records_number=$(echo "db.getCollection('${DST_COLLECTION}').count()" \
				| /home/60000/bin/mongo ${DST_HOST}:${DST_PORT}/${DST_DB} 2>/dev/null \
				| grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye')
			local restore_times=$((${restore_times}+1))	# 计数器加1
		done

		echo -e "导入 ${DST_ENV} 环境 ${DST_DB}.${DST_COLLECTION} : ${restore_result} 文档数量 : $dst_records_number\n"
	else
		#bson文件为空
		[ "$LOG" -eq 1 ] && echo "$(date)#${DIRECTION}#${DST_DB}#${DST_COLLECTION}#no_file_to_restore" >> $STATS_FILE
		echo -e "导入 ${DST_ENV} 环境 ${DST_DB}.${DST_COLLECTION} : 集合不存在或为空,无法导入\n"
	fi

	if [ "$LOG" -eq 1 ] ;then
		# 启动supervisor mongo-connector
		/usr/bin/supervisorctl -c /etc/supervisor.conf start "${proc_name}" &>/dev/null
	fi
}

# 检查 同步Mongdb集合 的状态(双向：线上到内网、内网到线上)
check_mongo_sync() {
	if [ -z "$3" ];then
		echo "Parameter missing,usage: $0 download|upload db_name_for_sync collections_for_sync"
		return 1
	fi

	local DIRECTION="$1"
	local DB="$2"
	local COLLECTIONS=$(echo -n "$3"|base64 -d 2>/dev/null|sort|uniq|grep -v -P '^[ |\t]*$')
	local STATS_FILE='/var/log/mongo_sync.stats'
	awk -F'#' "/#${DIRECTION}#${DB}#${COLLECTIONS}#/{print \$NF}" $STATS_FILE |tail -n 1
}

# 复制Mongdb集合到另一个集合
mongo_copy () {
	if [ -z "$3" ];then
		echo "Parameter missing,usage: $0 db_name_for_sync src_collections dst_collections"
		return 1
	fi

	WORKINGDIR='/tmp/mongo_sync'
	mkdir -p $WORKINGDIR &>/dev/null
	
	local DB="$1"
	#local COLLECTIONS=$(echo -n "$2"|base64 -d 2>/dev/null|sort|uniq|grep -v -P '^[ |\t]*$')
	local SRC_COLLECTIONS=$(echo -n "$2"|sort|uniq|grep -v -P '^[ |\t]*$')
	local DST_COLLECTIONS=$(echo -n "$3"|sort|uniq|grep -v -P '^[ |\t]*$')
	
	# 补全集合名称
	SRC_COLLECTIONS=$(format_collection_name "$DB" "$SRC_COLLECTIONS")
	DST_COLLECTIONS=$(format_collection_name "$DB" "$DST_COLLECTIONS")
	# 检查源集合 与 目标集合 是否相同
	if [ "${SRC_COLLECTIONS}" = "${DST_COLLECTIONS}" ];then
		echo "源集合与目标集合相同,退出"
		return 1
	fi

	#dump
	echo -n "导出 源集合 ${DB}.${SRC_COLLECTIONS} : "
	/home/60000/bin/mongodump -h 10.0.0.30 --port 57017 -d "${DB}" -c "${SRC_COLLECTIONS}" -o $WORKINGDIR &> /dev/null
	local result=$(p_ret $? "成功" "失败"|tr -d "\n")
	echo -en "$result 文档数量 : "
	echo "db.${SRC_COLLECTIONS}.count()" | /home/60000/bin/mongo 10.0.0.30:57017/${DB}|grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye'
	
	echo
	
	#copy 2 dst_collections
	echo -n "复制到目标集合 ${DB}.${DST_COLLECTIONS} : "
	if [ -s "${WORKINGDIR}/"${DB}"/${SRC_COLLECTIONS}.bson" ] ;then
		#如果bson文件大于零,即集合有数据,进行导入内网
		/home/60000/bin/mongorestore --drop -h 10.0.0.30 --port 57017 \
			-d "${DB}" -c "${DST_COLLECTIONS}" ${WORKINGDIR}/"${DB}"/${SRC_COLLECTIONS}.bson &> /dev/null
		local result=$(p_ret $? "成功" "失败"|tr -d "\n")
		echo -en "$result 文档数量 : "
		echo "db.${DST_COLLECTIONS}.count()" | /home/60000/bin/mongo 10.0.0.30:57017/${DB}|grep -v -e '^MongoDB shell version' -e '^connecting to' -e '^bye'
	else
		#bson文件为空
		echo "源集合不存在或为空,无法复制"
	fi
}

#mongo_query ICCv1 545aee0948961931768b4a6f
#mongo_query ICCv1 54b5fd424996193d0b8b4a6b
#mongo_query ICCv1 idatabase_collection_54be1fa1b1752f79168b52ec \
#	e2FjdGl2aXR5X2lkOic1NGJlMjAzZDQ4OTYxOTM4NjE4YjQ2YzAnfQ== \
#	e19pZDowLGFjdGl2aXR5X2lkOjF9 \
#	e19fQ1JFQVRFX1RJTUVfXzotMX0= 
#mongo_query umav3 52c4d6954a9619450d8b5888

#restart_mongos 57017
#restart_all_mongos 27017

