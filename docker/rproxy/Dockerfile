#
# TCP Proxy Dockerfile
#
#
FROM docker.io/centos:latest
MAINTAINER WanLong <long.wan@1mifudao.com>

ENV BUILD_TOOLS wget gcc make g++
ENV DEPENDENCY pcre-devel openssl-devel zlib-devel

# add nginx yum repository
COPY nginx.repo /etc/yum.repos.d/

# build & install tengine
RUN yum -y update && \
	yum -y install ${BUILD_TOOLS} ${DEPENDENCY} && \
    yum -y install nginx

# tengine config file
COPY nginx.conf /etc/nginx/
COPY rproxy.conf /etc/nginx/

WORKDIR /root

EXPOSE 5122

ENTRYPOINT ["/usr/sbin/nginx"]

#
# build
# docker build -t rproxy --force-rm .

# run
# docker run -d -p 5122:5122 --rm rproxy

# test
#

