import sys
import gearman
import datetime
import hashlib

gearman_server=['192.168.5.41:4730']
common_workers=['CommonWorker_192.168.5.41','CommonWorker_192.168.5.48']

key=hashlib.md5(datetime.date.today().isoformat()).hexdigest()
project_code=sys.argv[1].lower()
my_cmd = key + ' svn_checkout ' + project_code + '\n'

gm_client = gearman.GearmanClient(['192.168.5.41:4730'])
for fname in common_workers:
    print 'submiting: ',fname,my_cmd
    gm_client.submit_job(fname, my_cmd, background=True)
