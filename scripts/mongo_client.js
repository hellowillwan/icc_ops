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
