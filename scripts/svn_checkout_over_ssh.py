#!/usr/bin/env python    
import sys
import paramiko  
         
hostname='192.168.5.41'    
username='root'
password='123456QWEqaswe'
port=22    
projectname=sys.argv[1].lower()
#version=sys.argv[2]

if __name__=='__main__':    
    paramiko.util.log_to_file('paramiko.log')    
    s=paramiko.SSHClient()    
    #s.load_system_host_keys()    
    s.set_missing_host_key_policy(paramiko.AutoAddPolicy())    
    s.connect(hostname,port,username, password)
    #if version == '1' or version == '0':
    #cmdline = '/usr/bin/svn checkout https://192.168.5.40/svn/' + projectname + ' /home/wwwroot/' + projectname + ' --username young --password 123456 2>&1' + ' ; echo $? ; ' + 'chown -R apache /home/wwwroot/' + projectname + ' 2>&1 ; echo $? ; ' + '/etc/init.d/httpd reload &>/dev/null ; echo $?'
    #else:
    cmdline = '/usr/bin/svn checkout https://192.168.5.40/svn/' + projectname + ' /home/wwwroot/' + projectname + ' --username young --password 123456 > /var/log/svn-' + projectname + '_$(date "+%H_%M").log 2>&1' + ' ; echo $? ; ' + 'chown -R apache /home/wwwroot/' + projectname + ' 2>&1 ; echo $?'
	#print cmdline
    stdin,stdout,stderr=s.exec_command(cmdline)
    print stdout.read()
    s.close()
