#!/bin/bash
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d'  > /etc/postgresql/cluster_hosts.list
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $6} ' | sed "s/host=//g" | sed '/|/d'  > /etc/postgresql/witness_hosts.list
for HOST in $(cat /etc/postgresql/cluster_hosts.list)
do
echo "COPY TO $HOST"
rsync -arvzSH  --del --include "*.sh" --exclude "*" /etc/\postgresql/ $USER@$HOST:/etc/postgresql/
rsync -arvzSH /etc/postgresql/9.6/main/start.conf $USER@$HOST:/etc/postgresql/9.6/main/ 
done

for HOST in $(cat /etc/postgresql/witness_hosts.list)
do
echo "COPY TO $HOST"
rsync -arvzSH  --include "*.sh" --exclude "*" /etc/\postgresql/ $USER@$HOST:/etc/postgresql/
done
