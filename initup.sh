#!/bin/bash

#服务器内网ip
ip="172.16.252.126"
#redis镜像版本
version="5.0.0"

#集群文件防止目录
redisdir="/home/redis-cluster"

#判断问加减是否存在 如果存在删除后创建，不存在创建
rm -f -r ${redisdir}
# if [ -f "${redisdir}"} ];then
# 	rm -f -r ${redisdir}
# fi
mkdir -p ${redisdir}

echo "构建redis集群目录..."

for port in `seq 7000 7005`; do \
  mkdir -p ${redisdir}/${port}/conf \
  && PORT=${port} IP=${ip} envsubst < ./redis-cluster.tmpl > ${redisdir}/${port}/conf/redis.conf \
  && mkdir -p ${redisdir}/${port}/data; \
done

echo "拉取redis:${version}镜像..."

#拉取redis镜像
docker pull redis:${version}

#为redis集群创建docker网桥
docker network create redis-net

echo "创建网桥..."
#查看docker所有的网桥
docker network ls

echo "创建并运行redis集群容器..."

#定义一个初始值变量，用于叠加ip
execsh='/usr/local/bin/redis-cli --cluster create '
#创建redis运行容器
for port in `seq 7000 7005`; do \
  docker run -d -ti -p ${port}:${port} -p 1${port}:1${port} \
  -v ${redisdir}/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
  -v ${redisdir}/${port}/data:/data \
  --restart always --name redis-${port} --net redis-net \
  --sysctl net.core.somaxconn=1024 redis:${version} redis-server /usr/local/etc/redis/redis.conf; \
  #获取docker分配的ip
  execsh=${execsh}`docker inspect redis-${port} | grep "IPAddress" | grep --color=auto -P '(\d{1,3}.){3}\d{1,3}' -o`:${port}' '
done

execsh=${execsh}'--cluster-replicas 1'

#将拼接好的命令打印到控制台
echo ${execsh}

#将控制台的打印命令写入exe.sh脚本，docker容器直接执行就好
echo "${execsh}" > ${redisdir}/7000/data/exe.sh

#给exe.sh权限
chmod 777 ${redisdir}/7000/data/exe.sh

#进入第一个redis容器内
docker exec -it redis-7000 bash 

