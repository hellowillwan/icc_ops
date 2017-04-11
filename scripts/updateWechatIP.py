#!/bin/env python

import httplib
import json
import os

# get wechat access token
conn1 = httplib.HTTPConnection("10.0.0.1:80")
conn1.request("GET", "http://laiyifen.umaman.com/weixin/index/get-access-token")
r1 = conn1.getresponse()
#print(r1.status, r1.reason)
json1 = json.loads(r1.read())
token = json1['result']['access_token']
#print(token)

# get wechat ips
conn2 = httplib.HTTPSConnection("api.weixin.qq.com:443")
conn2.request("GET", "/cgi-bin/getcallbackip?access_token=" + token)
r2 = conn2.getresponse()
#print(r2.status, r2.reason)
json2 = json.loads(r2.read())

# write wechat ips into file with nginx white list format
wechatip=''
myset=set()
wechatip_file='/home/proxy_nginx_conf/wechatip_list.txt'
for ip in json2['ip_list']:
    if ip not in myset:
        wechatip += ip + ' 0;' + '\n'
        myset.add(ip)
#print(wechatip)
file_obj1=open(wechatip_file,'r')
wechatip_old=file_obj1.read()
file_obj1.close()

if wechatip_old != wechatip:
    # update to file
    file_obj2=open(wechatip_file,'w')
    file_obj2.write(wechatip)
    file_obj2.close()
	# reload ngx
    os.system('/usr/local/sbin/RsyncCfg.sh proxy')
else:
    print('nothing changed.')
