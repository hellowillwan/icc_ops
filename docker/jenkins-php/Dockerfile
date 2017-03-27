#
# Jenkins-php Dockerfile
#
#
FROM docker.io/centos:latest
MAINTAINER Will Wan <willwan@icatholic.net.cn>

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
#ENV BUILD_TOOLS wget gcc make g++
ENV DEPENDENCY zlib java-1.8.0-openjdk.x86_64 php

# change timezone
RUN rm -f /etc/localtime && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# change yum repository
RUN yum -y install wget && \
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && \
	wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

# add epel repository
RUN wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

# install dependency
RUN yum -y clean all && \
	yum -y makecache && \
	yum -y update && \
	yum -y install ${DEPENDENCY}

# Jenkins home directory is a volume, so configuration and build history 
# can be persisted and survive image upgrades
RUN mkdir -p /var/jenkins_home
VOLUME /var/jenkins_home

# jenkins version being bundled in this docker image
ARG JENKINS_VERSION
ENV JENKINS_VERSION ${JENKINS_VERSION:-2.32.3}

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=a25b9a314ca9e76f9673da7309e1882e32674223

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum 
# see https://github.com/docker/docker/issues/8331
RUN mkdir -p /usr/share/jenkins && \
	curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war && \
	echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha1sum -c -

WORKDIR /root

EXPOSE 8080

#ENTRYPOINT ["java","-jar","/usr/share/jenkins/jenkins.war"]

#
# build
# docker build -t jenkins-php --force-rm .

# run
# docker run -p 8080:8080 --rm jenkins-php

# test
# for i in {1..10};do curl -svx 192.168.5.48:8989 'http://space.yesmywine.com/90006' 2>&1|grep -e '<title>' -e cdn-src-ip -e 'HTTP' -e X-router-s;done|sort |uniq -c
#

