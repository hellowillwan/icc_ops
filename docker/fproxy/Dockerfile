#
# Forward Proxy Dockerfile
#
#
FROM docker.io/centos:latest
MAINTAINER Will Wan <willwan@icatholic.net.cn>

ENV TENGINE_VERSION 2.2.0
ENV BUILD_TOOLS wget gcc make g++
ENV DEPENDENCY pcre-devel openssl-devel zlib-devel

# change yum repository

# build & install tengine
RUN yum -y update && \
	yum -y install ${BUILD_TOOLS} ${DEPENDENCY} && \
	wget -q http://tengine.taobao.org/download/tengine-${TENGINE_VERSION}.tar.gz -O tengine.tar.gz && \
	tar -xzf tengine.tar.gz && \
	cd tengine-${TENGINE_VERSION} && \
	./configure && \
	make && \
	make install && \
	cd && \
	rm -rf tengine*

# tengine config file
COPY nginx.conf /usr/local/nginx/conf/
COPY fproxy.conf /usr/local/nginx/conf/


WORKDIR /root

EXPOSE 8989

ENTRYPOINT ["/usr/local/nginx/sbin/nginx"]

#
# build
# docker build -t fproxy --force-rm .

# run
# docker run -p 8989:8989 --rm fproxy

# test
# for i in {1..10};do curl -svx 192.168.5.48:8989 'http://space.yesmywine.com/90006' 2>&1|grep -e '<title>' -e cdn-src-ip -e 'HTTP' -e X-router-s;done|sort |uniq -c
#

