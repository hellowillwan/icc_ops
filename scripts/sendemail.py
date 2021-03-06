#!/usr/bin/python
from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email import Utils, Encoders
import mimetypes, sys,smtplib,socket,getopt
class SendMail:
      def __init__(self,smtp_server,from_addr,to_addr,user,passwd):
        self.mailserver=smtp_server
        self.from_addr=from_addr
        self.to_addr=to_addr
        self.username=user
        self.password=passwd
      def attachment(self,filename):
        fd=open(filename,'rb')
        filename=filename.split('/')
        mimetype,mimeencoding=mimetypes.guess_type(filename[-1])
        if mimeencoding or (mimetype is None):
         mimetype='application/octet-stream'
         maintype,subtype=mimetype.split('/')
        if maintype=='text':
         retval=MIMEText(fd.read(),_subtype=subtype)
        else:
         retval=MIMEBase(maintype,subtype)
         retval.set_payload(fd.read())
         Encoders.encode_base64(retval)
         retval.add_header('Content-Disposition','attachment',filename=filename[-1])
         fd.close()
         return retval
      def msginfo(self,msg,subject,filename): 
      # message = """Hello, ALL
   #This is test message.
   #--Anonymous"""
       message=msg
       msg=MIMEMultipart()
       msg['To'] = self.to_addr
       msg['From'] = self.from_addr
       msg['Date'] = Utils.formatdate(localtime=1)
       msg['Message-ID'] = Utils.make_msgid()
       if subject:
         msg['Subject'] = subject
       if message:
         body=MIMEText(message,_subtype='plain')
         msg.attach(body)
       #for filename in sys.argv[1:]:
       if filename:
         msg.attach(self.attachment(filename))
       return msg.as_string()
      def send(self,msg=None,subject=None,filename=None):
       try:
         s=smtplib.SMTP(self.mailserver)
         try:
           s.login(self.username,self.password)
         except smtplib.SMTPException,e:
           print "Authentication failed:",e
           sys.exit(1)
         s.sendmail(self.from_addr,self.to_addr.split(','),self.msginfo(msg,subject,filename))
       except (socket.gaierror,socket.error,socket.herror,smtplib.SMTPException),e:
         print "*** Your message may not have been sent!"
         print e
         sys.exit(2)
       else:
         print "Message successfully sent to %d recipient(s)" %len(self.to_addr)
if __name__=='__main__':
     def usage():
       print """Useage:%s [-h] -s <SMTP Server> -f <FROM_ADDRESS> -t <TO_ADDRESS> -u <USER_NAME> -p <PASSWORD> [-S <MAIL_SUBJECT> -m <MAIL_MESSAGE> -F <ATTACHMENT>]
   Mandatory arguments to long options are mandatory for short options too.
     -f, --from=   Sets the name of the "from" person (i.e., the envelope sender of the mail).
     -t, --to=   Addressee's address. -t "test@test.com,test1@test.com".
     -u, --user=   Login SMTP server username.
     -p, --pass=   Login SMTP server password.
     -S, --subject=  Mail subject.
     -m, --msg=   Mail message.-m "msg, ......."
     -F, --file=   Attachment file name.
    
     -h, --help   Help documen.    
   """ %sys.argv[0]
       sys.exit(3)
     try:
       options,args=getopt.getopt(sys.argv[1:],"hs:f:t:u:p:S:m:F:","--help --server= --from= --to= --user= --pass= --subject= --msg= --file=",)
     except getopt.GetoptError:
       usage()
       sys.exit(3)
    
     server=None
     from_addr=None
     to_addr=None
     username=None
     password=None
     subject=None
     filename=None
     msg=None
     for name,value in options:
       if name in ("-h","--help"):
         usage()
       if name in ("-s","--server"):
         server=value
       if name in ("-f","--from"):
         from_addr=value
       if name in ("-t","--to"):
        to_addr=value
       if name in ("-u","--user"):
        username=value
       if name in ("-p","--pass"):
        password=value
       if name in ("-S","--subject"):
        subject=value
       if name in ("-m","--msg"):
        msg=value
       if name in ("-F","--file"):
        filename=value
if server and from_addr and to_addr and username and password:
      test=SendMail(server,from_addr,to_addr,username,password)
      test.send(msg,subject,filename)
else:
      usage()

