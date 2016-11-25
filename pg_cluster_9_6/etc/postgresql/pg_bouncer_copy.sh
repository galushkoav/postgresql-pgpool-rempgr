#!/bin/bash
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d'  > /etc/postgresql/cluster_hosts.list
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $6} ' | sed "s/host=//g" | sed '/|/d'  > /etc/postgresql/witness_hosts.list

for HOST in $(cat /etc/postgresql/cluster_hosts.list)
do
echo "COPY TO $HOST"
rsync -arvzSH  --del --include "*.ini" --exclude "*" /etc/\postgresql/ $USER@$HOST:/etc/postgresql/
rsync -arvzSH /etc/postgresql/pgbouncer.ini $USER@$HOST:/etc/pgbouncer/
done
echo "Перезапускаем Pgbouncer на нодах `cat /etc/postgresql/cluster_hosts.list`"
sh /etc/postgresql/pgbouncer_restart.sh
