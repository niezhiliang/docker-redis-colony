#!/bin/bash

#集群文件防止目录
redisdir="/home/redis-cluster"
#redis镜像版本
version="5.0.0"

for port in `seq 7000 7005`; do \
  docker run -d -ti -p ${port}:${port} -p 1${port}:1${port} \
  -v ${redisdir}/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
  -v ${redisdir}/${port}/data:/data \
  --restart always --name redis-${port} --net redis-net \
  --sysctl net.core.somaxconn=1024 redis:${version} redis-server /usr/local/etc/redis/redis.conf; \
done
