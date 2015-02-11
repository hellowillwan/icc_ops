#/usr/bin/python
# -*- coding: UTF-8 -*-
"""
脚本使用方法：
python monitor_mongo.py --servers 10.0.0.30,10.0.0.31,10.0.0.32 --port 27017 --database umav3 --threshold 5 --notify youngyang@icatholic.net.cn,others@email.com --email sender@email.com --password abcd1234

参数说明：
--servers设定你要监控的mongos，用英文逗号分隔多个
--port设定要监控的mongo的端口号
--database设定要监控的数据库
--threshold设定并发告警与自动索引的阈值
--notify设定通知人员电子邮件，用英文逗号分隔多个
--smtp设定发送告警邮箱的SMTP
--email设定发送告警电子邮件地址
--password设定发送告警的电子邮件密码
--sleep设定扫描的间歇时间，单位秒，默认5秒
--slow设定慢查询的时间阈值，单位秒，默认10秒
"""
from pymongo import MongoClient
from bson.objectid import ObjectId
from pymongo import ASCENDING, DESCENDING
from bson.code import Code
from email.mime.text import MIMEText
from datetime import datetime,date
import smtplib
import time
import json
import optparse
import sys
reload(sys)
sys.setdefaultencoding('UTF-8')


import logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

parser = optparse.OptionParser()
parser.add_option("-s", "--servers", action="store", type="string",
                      dest="servers", default=None,
                      help="""请使用-s --servers设定你要监控的mongos，用英文逗号分隔多个""")

parser.add_option("-p", "--port", action="store", type="int",
                      dest="port", default=None,
                      help="""请使用-p --port设定要监控的mongo的端口号""")

parser.add_option("-d", "--database", action="store", type="string",
                      dest="database", default=None,
                      help="""请使用-d --database设定要监控的数据库""")

parser.add_option("-t", "--threshold", action="store", type="int",
                      dest="threshold", default=5,
                      help="""请使用-t --threshold设定并发告警与自动索引的阈值""")

parser.add_option("-n", "--notify", action="store", type="string",
                      dest="notify", default=None,
                      help="""请使用-n --notify设定通知人员电子邮件，用英文逗号分隔多个""")

parser.add_option("-m", "--smtp", action="store", type="string",
                      dest="smtp", default=None,
                      help="""请使用-m --smtp设定发送告警邮箱的SMTP""")

parser.add_option("-e", "--email", action="store", type="string",
                      dest="email", default=None,
                      help="""请使用-e --email设定发送告警电子邮件地址""")

parser.add_option("-w", "--password", action="store", type="string",
                      dest="password", default=None,
                      help="""请使用-w --password设定发送告警的电子邮件密码""")

parser.add_option("-l", "--sleep", action="store", type="int",
                      dest="sleep", default=5,
                      help="""请使用-l --sleep设定扫描的间歇时间，单位秒，默认5秒""")

parser.add_option("-o", "--slow", action="store", type="int",
                      dest="slow", default=10,
                      help="""请使用-o --slow设定慢查询的时间阈值，单位秒，默认10秒""")

(options, args) = parser.parse_args()

if options.servers is None:
    logging.error('请使用-s --servers设定你要监控的mongos，用英文逗号分隔多个')
    sys.exit(2)
else:
    servers = options.servers.split(',')
    
if options.port is None:
    logging.error('请使用-p --port设定要监控的mongo的端口号')
    sys.exit(2)
else:
    port = options.port
    
if options.database is None:
    logging.error('请使用-d --database设定要监控的数据库')
    sys.exit(2)
else:
    database = options.database
    
if options.notify is None:
    logging.error('请使用-nf --notify设定通知人员电子邮件，用英文逗号分隔多个')
    sys.exit(2)
else:
    notify_emails = options.notify.split(',')
    
if options.smtp is None:
    logging.error('请使用-smtp --smtp设定发送告警邮箱的SMTP')
    sys.exit(2)
    
if options.email is None:
    logging.error('请使用-e --email设定发送告警电子邮件地址')
    sys.exit(2)
    
if options.password is None:
    logging.error('请使用-pwd --password设定发送告警的电子邮件密码')
    sys.exit(2)


def toJsonStr(obj):
    return json.dumps(obj,skipkeys=True,cls=ComplexEncoder)

def send_mail(to_list,sub,content):
    mail_host=options.smtp
    mail_user=options.email
    mail_pass=options.password
    
    me="System Monitor"+"<"+mail_user+">"  
    msg = MIMEText(content,_charset='UTF-8') 
    msg['Subject'] = sub 
    msg['From'] = me  
    msg['To'] = ";".join(to_list)
    try:  
        s = smtplib.SMTP()  
        s.connect(mail_host)  
        s.login(mail_user,mail_pass)  
        s.sendmail(me, to_list, msg.as_string())  
        s.close()  
        return True  
    except Exception, e:  
        logging.debug(str(e))
        return False

class ComplexEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.strftime('%Y-%m-%d %H:%M:%S')
        elif isinstance(obj, date):
            return obj.strftime('%Y-%m-%d')
        elif isinstance(obj, object):
            return str(obj)
        else:
            return json.JSONEncoder.default(self, obj)

loop = 0        
while True:
    loop+=1
    logging.debug('%d'%(loop,))
    slow = '';
    slow_query = {}
    query = {}
    ns = {}
    waitingForLockNumber = 0
    mongos = servers
    #exclude = ['local.oplog.rs','ICCv1.','local.','ICCv1.system.indexes','ICCv1.icc.chunks','mapreduce.system.indexes','','logs.system.indexes','ICCv1.system.namespaces']
    exclude = ['local.oplog.rs','local.','','%s.'%(database,),'%s.system.indexes'%(database,),'%s.system.namespaces'%(database,)]
    for server in mongos:
        client = MongoClient(server, port)
        db = client[database]
        ops = db.current_op()
        for op in ops[u'inprog']:
            if op.has_key(u'ns') and op[u'ns'] not in exclude:
                if op.has_key(u'waitingForLock') and op[u'waitingForLock']:
                    waitingForLockNumber += 1
                
                if op.has_key(u'secs_running'):
                    if int(op[u'secs_running']) >= options.slow:
                        if slow_query.has_key(op[u'ns']):
                            slow_query[op[u'ns']].append(op)
                        else:
                            slow_query[op[u'ns']] = [op]
                    
                    if query.has_key(op[u'ns']):
                        query[op[u'ns']].append(op)
                    else:
                        query[op[u'ns']] = [op]
                    
                if ns.has_key(op[u'ns']):
                    ns[op[u'ns']] += 1
                else:
                    ns[op[u'ns']] = 1
    
    #检查具体的锁语句，并按照执行时间排序
    if slow_query != {}:
        for slow_ns,slow_ops in slow_query.items():
            slow = unicode("%s慢查询语句发生的集合：%s，慢查询数量是：%d\n"%(slow,slow_ns,len(slow_ops)))
            for slow_op in slow_ops:
                slow =  unicode("%s执行时间为：%d秒，慢查询语句为：%s\n")%(slow,int(slow_op[u'secs_running']),json.dumps(slow_op[u'query'],skipkeys=True,cls=ComplexEncoder))
            slow = "%s\n\n"%(slow,)
    
    nsTop = sorted(ns.items(),key=lambda e:e[1],reverse=True)
    warnning = ''
    indexInfo = ''
    for collection in nsTop[:10]:
        if collection[1] >= options.threshold :
            warnning = unicode("%s等待访问集合：%s的数量是：%d\n"%(warnning,collection[0],collection[1]))
            #这样的集合需要添加索引
            if query.has_key(collection[0]):
                for op in query[collection[0]]:
                    readPreference = 'unkown'
                    try:
                        op_query = {}
                        if op[u'query'].has_key(u'$query'):
                            op_query = op[u'query'][u'$query']
                        elif op[u'query'].has_key(u'query'):
                            op_query = op[u'query'][u'query']
                        elif op.has_key(u'query'):
                            op_query = op[u'query']
                        
                        try:
                            readPreference = unicode(op[u'query'][u'$queryOptions'][u'$readPreference'][u'mode'])
                        except KeyError:
                            try:
                                readPreference = unicode(op[u'query'][u'$readPreference'][u'mode'])
                            except KeyError:
                                pass
                            
                    except NameError:
                        pass
                    except KeyError:
                        pass
                    
                    if op.has_key(u'op') and op[u'op'] not in ['insert','update','delete','remove']:
                        if op_query == {}:
                            logging.debug("op_query is empty, really?")
                            logging.debug(toJsonStr(op))
                        if readPreference == 'unkown':
                            logging.debug("op readPreference is unkown, really?")
                            logging.debug(toJsonStr(op))
                    
                    if op_query != {}:
                        warnning = unicode("%s可能问题查询语句为：%s 读取模式为：%s\n")%(warnning,json.dumps(op_query,skipkeys=True,cls=ComplexEncoder),readPreference)
                warnning = "%s\n\n"%(warnning,)
        
        #切换到自动优化索引模式 对于集合进行索引处理
        if  collection[1] >= options.threshold :
            logging.debug("create index start")
            logging.debug(collection)
            create_index_list = []
            if query.has_key(collection[0]):
                logging.debug(toJsonStr(query[collection[0]]))
                for op in query[collection[0]]:
                    if op.has_key(u'query'):
                        query = {}
                        if op[u'query'].has_key(u'$query'):
                            query = op[u'query'][u'$query']
                        if op[u'query'].has_key(u'query'):
                            query = op[u'query'][u'query']
                            
                        logging.debug(toJsonStr(query))
                        if query != {}:
                            index = []
                            for field in query.keys():
                                field = str(field)
                                if field.startswith('$'):
                                    break
                                else:
                                    index.append((field,ASCENDING))
                            
                            logging.debug(toJsonStr(index))
                            if len(index) > 0:
                                if index not in create_index_list:
                                    try:
                                        #检查是否索引已经存在
                                        database_name = str(collection[0]).split('.')[0]
                                        if database_name==database:
                                            collction_name = '.'.join(str(collection[0]).split('.')[1:])
                                            logging.debug(collction_name)
                                            rst = db[collction_name].create_index(index,background=True)
                                            indexes = db[collction_name].index_information()
                                            if not rst in indexes:
                                                create_index_list.append(index)
                                                indexInfo = unicode("%s因性能问题自动为集合：%s，创建索引：%s,执行结果：%s\n")%(indexInfo,collection[0],json.dumps(index,skipkeys=True,cls=ComplexEncoder),json.dumps(rst,skipkeys=True,cls=ComplexEncoder))
                                        else:
                                            indexInfo = unicode("非%s集合：%s"%(database,str(collection[0])))
                                    except Exception,e:
                                        indexInfo = unicode("%s集合%s索引创建失败,试图创建的索引条件为%s,失败原因为%s\n")%(indexInfo,collection[0],json.dumps(index,skipkeys=True,cls=ComplexEncoder),e.strerror)
                                        
                                
            else:
                logging.debug("query does not contain the specified key")
                logging.debug(toJsonStr(query))
            
    
    mailto_list=notify_emails
    if warnning != '':
        send_mail(mailto_list,unicode("并发集合访问频次告警"),warnning)
    if indexInfo != '':
        send_mail(mailto_list,unicode("自动优化查询提醒"),indexInfo)
    if slow != '':
        send_mail(mailto_list,unicode("慢查询语句提醒"),slow)
        
    time.sleep(options.sleep)


