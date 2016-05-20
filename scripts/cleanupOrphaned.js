#!/home/60000/bin/mongo --nodb
/*
* 清除ICCv1\bda库所有集合的的孤立文档.
*
*
*/

var db_names = ['ICCv1','bda'];
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
