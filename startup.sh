<<<<<<< HEAD
=======
#!/bin/bash

#服务器内网ip
ip="172.31.220.158"
#redis镜像版本
version="5.0.0"

#集群文件防止目录
redisdir="/home/redis-cluster"

#判断问加减是否存在 如果存在删除后创建，不存在创建
if [ -f "${redisdir}"} ];then
	rm -f -r ${redisdir}
fi
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
>>>>>>> 0e572304a43e093c9f3d53562f9047ebfc01de2c
for port in `seq 7000 7005`; do \
  docker run -d -ti -p ${port}:${port} -p 1${port}:1${port} \
  -v ${redisdir}/${port}/conf/redis.conf:/usr/local/etc/redis/redis.conf \
  -v ${redisdir}/${port}/data:/data \
  --restart always --name redis-${port} --net redis-net \
  --sysctl net.core.somaxconn=1024 redis:${version} redis-server /usr/local/etc/redis/redis.conf; \
done
