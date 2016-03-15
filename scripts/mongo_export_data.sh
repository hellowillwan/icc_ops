#!/bin/sh
#
#导出mongodb指定库指定集合的数据到csv文件,转码并压缩
#

MONGO='/home/60000/bin/mongo'
MONGOEXPORT='/home/60000/bin/mongoexport'
MONGOS_IP='10.0.0.30'
TMP_DIR="/tmp/"

get_collection_fields() {
	# 采用mapreduce方法获取集合的字段列表
	# 测试: for c in weixin.project weixin.oauth iDatabase.51592f6a4996191e0900296d ;do get_collection_fields $c ;done
	#
	if [ -z "$2" ];then
		echo "Parameter missing: $0 DB Collection"
		exit 1
	else
		DB="$1"
		COLLECTION="$2"
	fi

	result=$(echo " 
	mr_collection_fields = db.runCommand({
		'mapreduce' : '${COLLECTION}',
		'map' : function() {
				for (var key in this) { emit(key, null); }
			},
		'reduce' : function(key, stuff) { return null; }, 
		'out': 'my_collection' + '_keys'
	})
	
	db[mr_collection_fields.result].distinct('_id')" \
	| ${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} 2>/dev/null )

	collection_fields=$(echo ${result} | sed -e "s/^.*\[//;s/\].*$//"|sed -e "s/[ |\t]//g;s/\"//g")

	#如果上面的方法获取字段列表失败,才采用下面这种方法取字段列表(可能不完整).
	[ -z "${collection_fields}" ] && \
	collection_fields=$(echo "db.getCollection('${COLLECTION}').findOne()" \
		|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} 2>/dev/null \
		|awk 'BEGIN{ORS=","} /"/{gsub("\"","");print $1}'|sed "s/,$//")

	echo $collection_fields
}

export_data () {
	#把集合导出成CSV文件并转码为GBK编码
	if [ -z "$2" ];then
		echo "Parameter missing: $0 DB Collection"
		exit 1
	else
		DB="$1"
		COLLECTION="$2"
		TMP_FILE="${TMP_DIR}${DB}.${COLLECTION}.$(date '+%Y-%m-%d-%H_%M_%S')"
		DATA_FILE="${TMP_FILE}_gbk.csv.gz"
	fi

	# 根据不同版本设定type参数
	type_parameter=' --csv '
	test "${DB}" = 'ICCv1' && type_parameter=' --type=csv '

	#字段列表
	FIELDS=$(get_collection_fields ${DB} ${COLLECTION})
	
	#导出
		#-q '{$or:[{"hid":"4446fcecdf854721b8388f323c6fe4d2"},{"hid":"29769ba0b41f4576bef5be0807e8c4c2"}]}' \
		#-q '{ "hid": { $in: ["4446fcecdf854721b8388f323c6fe4d2","29769ba0b41f4576bef5be0807e8c4c2" ] } }' \
	${MONGOEXPORT} -h ${MONGOS_IP} --port ${MONGOS_PORT} \
		-d ${DB} -c ${COLLECTION} \
		${type_parameter} \
		-f ${FIELDS} \
		-o ${TMP_FILE}

	if [ -f ${TMP_FILE} ];then
		#转码压缩
		cat ${TMP_FILE} |iconv -f utf-8 -t gb18030 |gzip > ${DATA_FILE}
		echo "Data exported to ${DATA_FILE} return code:$?"
	else
		echo "mongoexport faild,file not found."
		exit 3
	fi
}


#main

if [ -z "$2" ];then
	echo "Parameter missing: $0 DB Collection"
	exit 1
else
	DB="$1"			#umav3,ICCv1
	COLLECTION="$2"

	if [ "$DB" = "umav3" ];then
		MONGO='/home/mongodb/bin/mongo'
		MONGOEXPORT='/home/mongodb/bin/mongoexport'
		MONGOS_IP='10.0.0.41'	#uma数据库有变更:sharded cluster --> replset,这里是主库ip:port
		MONGOS_PORT='40000'
	elif [ "$DB" = "ICCv1" ] ;then
		MONGOS_PORT='57017'
	else
		echo "DB not exist"
		exit 2
	fi
fi

#提供的集合名称,很可能是不带前缀的,这里检查所有匹配的集合,暂时不限制数量了
for col in "$(echo 'show collections'|${MONGO} ${MONGOS_IP}:${MONGOS_PORT}/${DB} 2>/dev/null|grep ${COLLECTION} 2>/dev/null)";do
	if [ ! -z "${col}" ];then
		echo "exporting $DB $col pls wait."
		export_data $DB $col
	else
		echo "collection not found in ${DB}."
	fi
done

