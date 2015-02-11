db.currentOp({"active" : true, "secs_running" : { "$gt" : 0 },"ns" : /^ICCv1./}).inprog.forEach(
  function(op) {
    if(op.secs_running > 3) {
		printjson(db.killOp(op.opid));
	}
  }
)
