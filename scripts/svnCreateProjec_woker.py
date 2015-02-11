import gearman
import time
import re
import subprocess

def svnCreateHook(hook_path,project_code):
    post_commit_content = '''@echo off 

SET PROJECT=140523fg0220

SET WORKING_COPY=E:\website\%PROJECT%

"C:\Program Files (x86)\VisualSVN Server\\bin\svn.exe" checkout https://192.168.5.40/svn/%PROJECT% %WORKING_COPY% --username young --password 123456

IF ERRORLEVEL 0 goto hhaa

:hhaa
c:\Python27\python.exe E:\Repositories\python\svn_checkout_over_ssh.py %PROJECT% %2'''
    pre_commit_content = '''php d:\php-svn-hook-master\svn_pre_commit_hook.php %1 %2 --include=EmptyComment:NoTabs:Syntax --exclude=EmptyComment:NoTabs'''
    f_post_commit = open(hook_path,'w')
    #ret = f_post_commit.write(content.replace('140523fg0220',project_code))
    f_post_commit.write(post_commit_content.replace('140523fg0220',project_code))
    f_post_commit.close()
    f_pre_commit = open(hook_path.replace('post-commit','pre-commit'),'w')
    f_pre_commit.write(pre_commit_content)
    f_pre_commit.close()
    return


def svnCreateProject(x):
    if (re.search('^create:',x)):
        project_code = x.split(':')[1]
        cmdline = 'svnadmin create E:\\Repositories\\' + project_code
        ret = subprocess.call(cmdline)
        if (ret == 0):
            hookret = svnCreateHook('E:\\Repositories\\' + project_code + '\\hooks\\post-commit.bat',project_code)
            #return 'Successful created svn ' + project_code + ' Hook: ' + hookret
            return 'Successful created svn ' + project_code
        else:
            return 'Failed to create svn ' + project_code
    else:
        return 'Invalid string.'


gm_worker = gearman.GearmanWorker(['192.168.5.41:4730'])

def task_listener_visualsvnadmin(gearman_worker, gearman_job):
    print '%-20s Receive: %-16s' % (time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())),gearman_job.data)
    ret = svnCreateProject(gearman_job.data)
    print '%-20s %-32s\n' % (time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time())),ret)
    return ret

# gm_worker.set_client_id is optional
gm_worker.set_client_id('python-worker-5.40')
gm_worker.register_task('visualsvnadmin', task_listener_visualsvnadmin)

# Enter our work loop and call gm_worker.after_poll() after each time we timeout/see socket activity
gm_worker.work()