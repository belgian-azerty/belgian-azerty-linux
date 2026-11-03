#!/bin/bash
V=$1; N=r1-$V
docker rm -f $N >/dev/null 2>&1
docker run -d --name $N --privileged --network host --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v $WORK/probe:/probe:ro -v $WORK/out:/out r2-u2404 /sbin/init >/dev/null
for i in $(seq 60); do s=$(docker exec $N systemctl is-system-running 2>/dev/null); [ "$s" = running ] || [ "$s" = degraded ] && break; sleep 1; done
docker exec $N bash -c 'useradd -m tester; chmod 777 /out'
docker exec $N runuser -u tester -- timeout 240 /probe/t1.sh $V
docker rm -f $N >/dev/null
