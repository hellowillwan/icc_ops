#!/home/60000/bin/mongo --nodb
/*
*
*
*
*/


/*
 * 清理孤儿文档
 *
var db = connect("10.0.0.30:57017/ICCv1");
var dbp1 = connect("10.0.0.42:60000/admin");
var dbp2 = connect("10.0.0.52:60000/admin");
var ICC_COLLECTIONS = db.getCollectionNames();
for (var i in ICC_COLLECTIONS) {
	//if ( my_collections[i].search(/^idatabase_collection_/i) == 0 ) {
		var ns = 'ICCv1.' + ICC_COLLECTIONS[i];
		//执行cleanupOrphaned命令
		var ret1 = dbp1.runCommand({"cleanupOrphaned": ns});
		var ret2 = dbp2.runCommand({"cleanupOrphaned": ns});
		print(ns + "\tresult:\t" + ret1 + "\t" + ret2);
	//}
}
*/


/*
 * 查 Oplog
 *
//var masters = ['10.0.0.42:60000','10.0.0.52:60000'];
var masters = ['10.0.0.52:60000'];
for ( var i in masters) {
	var master = masters[i];
	var db = connect(master+"/local");
	// Cursor
	var myCursor = db.oplog.rs.find({"ns":"ICCv1.idatabase_collection_568f1b6db1752f4c358b54b9","ts":{"$gte":Timestamp(1471881600,00000)}});
	// killOp like this
	//db.currentOp({"client" : /^10.0.0.200:/,"ns":"local.oplog.rs","secs_running":{$gte:1500},"connectionId":595348})
	while ( myCursor.hasNext() ) {
		printjson(myCursor.next());
	}
} 
*/


/*
 * 按 _id 列表 查询记录
var db = connect("10.0.0.30:57017/ICCv1");
var post = {"_id":["582d0d92cff348cc248b4567","582d0d92cff348a3268b4568","582d0d92cff348a2268b4585","582d0d91cff348e41b8b4568","582d0d91cff348a4268b4568","582c87cccff3486f008b456b","582c80f5cff3487a008b4580","582c80eecff3487b008b4569","582c80cccff348c7128b4568","582c626bcff3485d008b4582","582c2adacff3489a338b456a","582c2a8ccff348dead8b457b","582c2a8bcff3485d008b4567","582c2a28cff34824ae8b456a","582c1bf2cff34894738b4576","582c1459cff348b7738b456d","582c142fcff3489a738b45a6","582c13abcff34861008b4567","582c1260cff34818e78b4572","582c1202cff348098f8b4592"],"__PROJECT_ID__":"5649a472af52d5f6168b4582","__COLLECTION_ID__":"578dfae8b1752fb6078b5553","__PLUGIN_ID__":"573e89da311f8a3f058b4570"}	// icc后台操作记录
var l = [];		// 根据 post 数据 生成 _id ObjectId 列表
for ( var i=0;i < post._id.length;i++ ) {
		l[i] = ObjectId(post._id[i]);
}
var myCursor = db.idatabase_collection_578dfae8b1752fb6078b5553.find({"_id":{$in :l}},{"__REMOVED__":1,"__MODIFY_TIME__":1})
while ( myCursor.hasNext() ) {
	printjson(myCursor.next());
}
*/


var db = connect("10.0.0.32:57017/test");
//var db = connect("10.0.0.41:60002/test");
//db.help();
//
//Cursor
//var myCursor = db.idatabase_collection_54be1fa1b1752f79168b52ec.find().limit(10);
//var myFirstDocument = myCursor.hasNext() ? myCursor.next(10) : null;
//
//Output
printjson(
	//db.stats()
	//db.getCollectionNames()
	//db.user_info.count()
	//db.user_info.drop()
	//db.runCommand( {"cleanupOrphaned": "ICCv1.idatabase_collection_555013c9b1752fa6418b582b"})
	//db.serverStatus().opcounters
	//db.printReplicationInfo()
	//db.idatabase_collection_541aceaf4a9619444b8b4b6d.stats()
	//
	db.currentOP({"secs_running":{$gt:3600}})
	//
	//sh.isBalancerRunning()
	//
	//myFirstDocument
	//myCursor.toArray()
	//
);
