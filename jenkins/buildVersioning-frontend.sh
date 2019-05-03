#
# 这段脚本的功能：构建并将构建物保存到版本库
#

jenkinsWorkSpace='/var/lib/jenkins/workspace'
timestamp="$(date '+%Y-%m-%d_%H-%M-%S.%N')"    # 迁出源代码的时间戳 精确到纳秒
version="$(echo ${Version} | tr -d '\t' | tr -d ' ' | tr -d '\n')"  # 暂时没有对 version 进行合规性检查
appName="${JOB_NAME#*-}"
sshUser='wanlong'
sshKey='/var/lib/jenkins/.ssh/id_rsa_wanlong'
sshCli="ssh -l ${sshUser} -p 22876 -C -o CompressionLevel=9 -o StrictHostKeyChecking=no -i ${sshKey}"
atifactoryServer='192.168.1.247'
newLine='
'

# 构建
# 找到 package.json 路径,在同级目录执行 yarn 命令
packageJsonFile="$(find ${jenkinsWorkSpace}/${JOB_NAME} -iname package.json | head -n 1)"
pathTorunNpmBuild="${packageJsonFile%/*}"
cd ${pathTorunNpmBuild}
date '+%Y-%m-%d %H:%M:%S.%N'
yarn --non-interactive --no-progress --registry http://192.168.1.106:8081/repository/npm-public/ install 2>&1 | tee build.log
date '+%Y-%m-%d %H:%M:%S.%N'
yarn --non-interactive --no-progress --registry http://192.168.1.106:8081/repository/npm-public/ build 2>&1 | tee -a build.log
date '+%Y-%m-%d %H:%M:%S.%N'

# 判断构建是否成功
if grep -q -i error build.log ;then
    echo '构建失败'
    # 邮件通知内容
    emailSubject="Jenkins [构建失败] 应用: ${appName} 分支: ${GIT_BRANCH} 版本: ${version} 构建时间：${timestamp}"
    emailContent="构建失败。未能将构建物保存到版本仓库。${newLine}本次构建的链接：${BUILD_URL} ${newLine}构建日志如下："
else
    echo '构建成功'
    artifactVersionedName="${appName}-${version}.${timestamp}.tgz"
    if [ -d dist ];then    # 检查是否有 dist 目录
        # 保存到版本库
        tar zcf ${artifactVersionedName} dist
        ${sshCli} ${atifactoryServer} mkdir -p /data/artifactory/${appName}/${version}
        for i in {1..2} ; do    # 防止传输有问题
            rsync -e "${sshCli}" -vc \
            ${artifactVersionedName} \
            ${atifactoryServer}:/data/artifactory/${appName}/${version}/${artifactVersionedName}    
        done

        # 邮件通知内容
        emailSubject="Jenkins [构建成功] 应用: ${appName} 分支: ${GIT_BRANCH} 版本: ${version} 构建时间：${timestamp}"
        emailContent="本次构建物（包）：${artifactVersionedName}${newLine}"
        emailContent="${emailContent}构建物仓库地址：http://${atifactoryServer}/artifactory/${appName}/${version}/${newLine}"
        emailContent="${emailContent}本次构建的链接：${BUILD_URL} ${newLine}"
        emailContent="${emailContent}构建日志如下：${newLine}"
    else
        # 邮件通知内容
        emailSubject="Jenkins [构建成功] 应用: ${appName} 分支: ${GIT_BRANCH} 版本: ${version} 构建时间：${timestamp}"
        emailContent="没有找到 dist 目录，未能将构建物保存到版本仓库。 ${newLine}本次构建的链接：${BUILD_URL} ${newLine}构建日志如下："
    fi
fi

# 发送邮件通知
source /usr/local/sbin/function_sendemail.sh
sendemail "${emailAddress}" "${emailSubject}" "${emailContent}$(cat build.log)"
