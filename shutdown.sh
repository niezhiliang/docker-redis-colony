#!/bin/bash

echo '强制停止redis集群容器...'
for port in `seq 7000 7005`; do \
 docker rm redis-${port} -f
done
