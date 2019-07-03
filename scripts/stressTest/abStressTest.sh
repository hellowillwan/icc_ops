
# curl 测试示例

##curl -sv -D - -d '
#curl -sv -D - -o /dev/null -d '
#{
#  "addPrefix": false,
#  "ids": [
#    "00000fcf-aa92-11e6-8cf7-00e04c6f6690",
#  "0000692e-b5af-11e6-b872-00e04c6f6690"
#  ]
#}
#' -H  'Content-Type: application/json;charset=UTF-8' \
#http://10.30.237.204:9040/question/queryByIds
#
##curl -sv -D - -d '
#curl -sv -D - -o /dev/null -d '
#{
#  "arg1": "72d35b1f-20d7-422f-8c31-d6bc75fe48b3",
#  "arg2": "D9C54AEA-5780-4110-A445-9B390BB2DECF"
#}
#' -H  'Content-Type: application/json;charset=UTF-8' \
#http://10.30.237.204:9040/question/questionRecommend


curl -sv -D - -o /dev/null -d '
{
"phone": "13112141127",
"stuName": "张一",
"grade": "五年级",
"subject": "语文",
"sn": "12345646464XQ"
}
' -H  'Content-Type: application/json;charset=UTF-8' \
http://101.132.254.61:9119/bbk/new


# ab 压测示例
#echo '
#{
#  "addPrefix": false,
#  "ids": [
#    "00000fcf-aa92-11e6-8cf7-00e04c6f6690",
#  "0000692e-b5af-11e6-b872-00e04c6f6690"
#  ]
#}
#' > argsForUrl1
#
#echo '
#{
#  "arg1": "72d35b1f-20d7-422f-8c31-d6bc75fe48b3",
#  "arg2": "D9C54AEA-5780-4110-A445-9B390BB2DECF"
#}
#' > argsForUrl2

echo '
{
"phone": "13112141127",
"stuName": "张一",
"grade": "五年级",
"subject": "语文",
"sn": "12345646464XQ"
}
' > argsForUrl3

#ab -k -r -s 20 -n 1 -t 60 -c 50 \
#-T 'application/json;charset=UTF-8' \
#-p argsForUrl1 \
#http://10.30.237.204:9040/question/queryByIds

#ab -k -r -s 20 -n 1 -t 60 -c 500 \
#-T 'application/json;charset=UTF-8' \
#-p argsForUrl2 \
#http://10.30.237.204:9040/question/questionRecommend

ab -k -r -s 20 -n 1 -t 60 -c 500 \
-T 'application/json;charset=UTF-8' \
-p argsForUrl3 \
http://111.111.111.11:9119/bbk/new

