#!/home/60000/bin/mongo --nodb
/*
 * *
 * *
 * *
 * */

var db = connect("10.0.0.30:57017/ICCv1");
db.currentOp({"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./}).inprog.forEach(
  function(op) {
    if(op.secs_running > 0) {
		printjson(db.killOp(op.opid));
	}
  }
)
var db = connect("10.0.0.31:57017/ICCv1");
db.currentOp({"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./}).inprog.forEach(
  function(op) {
    if(op.secs_running > 0) {
		printjson(db.killOp(op.opid));
	}
  }
)
var db = connect("10.0.0.32:57017/ICCv1");
db.currentOp({"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./}).inprog.forEach(
  function(op) {
    if(op.secs_running > 0) {
		printjson(db.killOp(op.opid));
	}
  }
)
var db = connect("10.0.0.42:60000/ICCv1");
db.currentOp({"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./}).inprog.forEach(
  function(op) {
    if(op.secs_running > 0) {
		printjson(db.killOp(op.opid));
	}
  }
)
