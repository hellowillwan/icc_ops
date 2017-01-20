#!/home/60000/bin/mongo --nodb
/*
 * 几个操作 mongodb 的工具函数
 *
 */


/*
 * 列出数据库中大于 1000W 条记录的集合
 */
function listBigColl() {
	var db = connect("192.168.5.40:57017/ICCv1");
	var ICC_COLLECTIONS = db.getCollectionNames();
	for (var i in ICC_COLLECTIONS) {
		//if ( my_collections[i].search(/^idatabase_collection_/i) == 0 ) {
			//var ns = 'ICCv1.' + ICC_COLLECTIONS[i];
			var ns = ICC_COLLECTIONS[i];
			//var count=db.getCollection(ns).stats().count;	// 较慢
			var count=db.getCollection(ns).count();
			if (count >= 1000) {
				print(ns + " count: " + count);
			}
		//}
	}
}


/*
 * 清理孤儿文档
 */
function cleanOrphan() {
	var db_names = ['ICCv1','bda'];		// 需要清理的库
	for ( var i in db_names ) {
		var db_name = db_names[i];
		var db_mongos = connect("10.0.0.30:57017/" + db_name);
		var dbp1 = connect("10.0.0.42:60000/admin");	//第一片主库
		var dbp2 = connect("10.0.0.52:60000/admin");	//第二片主库
		var db_primary_of_shards = [dbp1,dbp2];
		var COLLECTIONS = db_mongos.getCollectionNames();	//获取集合列表
		for (var i in COLLECTIONS) {
			//如果只处理特定名称的集合,在这里做判断
			//if ( my_collections[i].search(/^idatabase_collection_/i) == 0 ) {
				var ns = db_name + '.' + COLLECTIONS[i];		//集合名称
				for( var n in db_primary_of_shards) {
					//依次在两片的主库上执行清除孤立文档的操作
					var db_mongod = db_primary_of_shards[n];
					var nextKey = { };
					var result;
					//循环执行cleanupOrphaned命令,参考:http://docs.mongodb.org/manual/reference/command/cleanupOrphaned/
					while ( nextKey != null ) {
						result = db_mongod.runCommand( { cleanupOrphaned: ns, startingFromKey: nextKey } )
						//记录一下日志,其实 mongod log 里有记录该命令执行结果.
						//The cleanupOrphaned command prints the number of deleted documents to the mongod log.
						//if (result.ok != 1)
						//	print(ns + "\t" + nextKey._id.toString() + "\tUnable to complete at this time: failure or timeout.");
						//printjson(result);
						if ( nextKey._id != null ) {
							print("shard" + n + "\t" + ns + "\t" + nextKey._id.toString() + "\tresult.ok:\t" + result.ok);
						} else {
							print("shard" + n + "\t" + ns + "\t" + nextKey.toString() + "\tresult.ok:\t" + result.ok);
						}
						nextKey = result.stoppedAtKey;
					}
				}
		
				/*
				//执行cleanupOrphaned命令
				var ret1 = dbp1.runCommand({"cleanupOrphaned": ns}).ok;
				var ret2 = dbp2.runCommand({"cleanupOrphaned": ns}).ok;
				print(ns + "\tresult:\t" + ret1 + "\t" + ret2);
				*/
			//}
		}
	}
}


/*
 * 查询数据库 oplog 查询会很耗时 如无必要最好不要执行
 */
function queryOplog() {
	//var masters = ['10.0.0.42:60000','10.0.0.52:60000'];
	var masters = ['10.0.0.52:60000'];
	for ( var i in masters) {
		var db = connect(masters[i]+"/local");
		// Cursor
		var query = { "ns":"ICCv1.idatabase_collection_568f1b6db1752f4c358b54b9","ts":{"$gte":Timestamp(1471881600,00000)} }
		var myCursor = db.oplog.rs.find(query);
		while ( myCursor.hasNext() ) {
			printjson(myCursor.next());
		}
	}
}


/*
 * 按 _id 列表 查询记录
 */
function queryBy_id() {
	var db = connect("10.0.0.30:57017/ICCv1");
	var mycoll = 'idatabase_collection_578dfae8b1752fb6078b5553';
	var post = {"_id":["582d0d92cff348cc248b4567","582d0d92cff348a3268b4568","582d0d92cff348a2268b4585","582d0d91cff348e41b8b4568","582d0d91cff348a4268b4568","582c87cccff3486f008b456b","582c80f5cff3487a008b4580","582c80eecff3487b008b4569","582c80cccff348c7128b4568","582c626bcff3485d008b4582","582c2adacff3489a338b456a","582c2a8ccff348dead8b457b","582c2a8bcff3485d008b4567","582c2a28cff34824ae8b456a","582c1bf2cff34894738b4576","582c1459cff348b7738b456d","582c142fcff3489a738b45a6","582c13abcff34861008b4567","582c1260cff34818e78b4572","582c1202cff348098f8b4592"],"__PROJECT_ID__":"5649a472af52d5f6168b4582","__COLLECTION_ID__":"578dfae8b1752fb6078b5553","__PLUGIN_ID__":"573e89da311f8a3f058b4570"}	// icc后台操作记录
	var l = [];		// 根据 post 数据 生成 _id ObjectId 列表
	for ( var i=0;i < post._id.length;i++ ) {
			l[i] = ObjectId(post._id[i]);
	}
	var query = {"_id":{$in :l}};
	var projection = {"video_url":1,"__REMOVED__":1,"__MODIFY_TIME__":1};
	//print(tojson(db.getCollection(mycoll).findOne(query,projection)));
	var myCursor = db.getCollection(mycoll).find(query,projection).limit(10);
	while ( myCursor.hasNext() ) {
		//printjson(myCursor.next());
		print(tojson(myCursor.next()));
	}
}


/*
 * 查询数据库当前正在执行的语句 currentop
 *
 */
function showCurrentOp() {
	//var servers = ['10.0.0.30:57017','10.0.0.31:57017','10.0.0.32:57017'];
	var servers = ['10.0.0.42:60000','10.0.0.52:60000'];
	for ( var i in servers) {
		var db = connect(servers[i]+"/ICCv1");
		//var query = {"client" : /^10.0.0.200:/,"ns":"local.oplog.rs","secs_running":{$gte:1500},"connectionId":595348};
		//var query = {"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./};
		var query = {"secs_running":{$gte:1000}};
		var opList = db.currentOp(query).inprog; // Returns a document that contains information on in-progress operations for the database instance.
		opList.forEach(
			function(op) {
				//print(tojson(op));
				print(tojson(op.opid));
				print(tojson(op.op));
				print(tojson(op.ns));
				print(tojson(op.query));
				print(tojson(op.secs_running));
				// killOp
				print(tojson(db.killOp(op.opid)));
			}
		)
		/* 列表循环的另一种方式
		for( j in opList ) {
			var op = opList[j];
			//print(tojson(op));
			print(tojson(op.opid));
			print(tojson(op.op));
			print(tojson(op.ns));
			print(tojson(op.query));
			print(tojson(op.secs_running));
			// killOp
			print(tojson(db.killOp(op.opid)));
		}
		*/
	}
}


/*
 * Mongodb 常用命令
 */
function generalDbTask() {
	var db = connect("10.0.0.30:57017/test");
	//var db = connect("10.0.0.52:60000/test");
	print(
		tojson(
			db.stats()
			//db.getCollectionNames()
			//db.user_info.count()
			//db.user_info.drop()
			//db.runCommand( {"cleanupOrphaned": "ICCv1.idatabase_collection_555013c9b1752fa6418b582b"})
			//db.serverStatus().opcounters
			//db.getReplicationInfo()
			//db.idatabase_collection_541aceaf4a9619444b8b4b6d.stats()
			//sh.isBalancerRunning()	// 这个还有问题 不知如何创建 sh\rs 对象
		)
	);
}


/*
 * Mongodb Cursor 常用方法
 */
function generalCursorTask() {
	var db = connect("10.0.0.32:57017/ICCv1");
	var mycoll = 'idatabase_collection_55078670b1752fad378b4742';
	//var query = {};
	var query = {"__REMOVED__" : false};
	//var query = { "_id" : ObjectId("55079709e3288070a024b213"),"__REMOVED__" : false};
	//var projection = {"__REMOVED__":1,"__MODIFY_TIME__":1};
	var projection = {};
	// Cursor
	var myCursor = db.getCollection(mycoll).find(query,projection);
	//var myFirstDocument = myCursor.hasNext() ? myCursor.next(10) : null;
	// Output
	printjson(
		myCursor.count()
		//myFirstDocument
		//myCursor.toArray()
	);
}
generalCursorTask()


