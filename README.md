# docker 环境下的redis cluster 集群搭建




### 1.redis镜像下载，这里使用的是redis 5.0.0的版本

```
docker pull redis:5.0.0
```

### 2.创建搭建集群所需的conf文件，这里暂时命名为`redis-cluster.tmpl`

```shell
port ${PORT}   #redis端口
protected-mode no  #关闭保护模式，允许外网访问
cluster-enabled yes   # 开启集群模式 
cluster-config-file nodes.conf  #集群配置名
cluster-node-timeout 5000 #超时时间 
cluster-announce-ip ${IP}  #搭建集群主机的内网ip
cluster-announce-port ${PORT} #节点映射端口
cluster-announce-bus-port 1${PORT} #节点总线端
appendonly yes  #持久化模式
```

### 3.创建集群和节点运行所需文件夹和文件

```shell
#这里是搭建集群的主机的内网ip
ip=xxx.xxx.xx.xx
#集群文件目录
redisdir="/home/redis-cluster"

#为6个节点分别创建文件夹7000-7005，data文件夹和conf文件，这里会将`redis-cluster.tmpl`中的${IP}和${PORT}替换成相应的值
for port in `seq 7000 7005`; do \
  mkdir -p ${redisdir}/${port}/conf \
  && PORT=${port} IP=${ip} envsubst < ./redis-cluster.tmpl > ${redisdir}/${port}/conf/redis.conf \
  && mkdir -p ${redisdir}/${port}/data; \
done

```

### 4.创建docker自定义网桥

```shell

docker network create redis-net

#查看docker所有的网桥

docker network ls

```

### 5.运行redis各节点容器

```shell

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

#将拼接好的命令打印到控制台,后面进入到redis容器中需要用到
echo ${execsh}

```

![运行img](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/shell.png)

![运行img](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/run.png)

### 6.通过命令进入redis-7000的容器内部,并输入创建容器时打印出的shell命令

```shell

docker exec -it redis-7000 bash 

/usr/local/bin/redis-cli --cluster create 172.22.0.2:7000 172.22.0.3:7001 172.22.0.4:7002 172.22.0.5:7003 172.22.0.6:7004 172.22.0.7:7005 --cluster-replicas 1


```

![搭建成功图片](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/success.png)

### 7.进入容器中的redis，校验搭建是否成功

```shell

redis-cli -p 7000 -c

```

### 8.确保搭建成功，我们先退出容器，并把刚才跳转到的节点容器关掉，再进入redis-7000容器,看redis是否还能正常保存获取数据

```shell
#关闭7002节点
docker rm redis-7002 -f

```

![搭建成功图片](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/su.png)


## 至此我们redis集群环境成功搭建完成，作为一个患有懒人综合征的来说，这么多步骤太烦太烦，就不能输入一两条命令就给我安装完嘛。 哈哈哈，为了偷懒，我把这些命令写成了一个脚本，只需要输入几条命令，就能搭建完成

> 特别注意：`修改initup.sh中ip=xxxxx  将其改为你服务器的内网ip`

- 拉取脚本项目

```

git clone https://github.com/niezhiliang/docker-redis-colony

cd docker-redis-colony

//执行初始换脚本（这个就是在第一次搭建时候运行，如果搭建成功后，千万别执行该脚本，会发生什么我也不知道）

./initup.sh

//脚本执行过程中会自动进入redis-7000容器中，在dat目录下会有个exe.sh脚本，这个是我将docker容器运行时的命令输入到了这个脚本中，我们只要执行就好

./exe.sh

//执行完后，会让我们输入yes or no   我们输入yes嘛输入完耐心等待吧，不出意外，最后几行命令是绿的就成功啦。绿绿更健康 哈哈😝

```
- redis集群关闭脚本
```shell

./shutup.sh 

```

- 集群搭建成功后，`以后启动集群都只需启动startup脚本，签完不要手贱去执行initup.sh`

```shell

./startup.sh

```

项目源码：https://github.com/niezhiliang/docker-redis-colony


#### 集群安装gif

![脚本演示gif](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/install.gif)


#### 集群功能实现gif

![脚本演示gif](https://github.com/niezhiliang/docker-redis-colony/blob/master/imgs/show.gif)


