#!/bin/bash
repmgr -f /etc/repmgr.conf  cluster show | grep standby | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/standby.list
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d'  > /etc/postgresql/cluster_hosts.list

USER="postgres"

for PGHOST in $(cat /etc/postgresql/cluster_hosts.list)
do
ssh postgres@$PGHOST 'sh /etc/postgresql/pgbouncer.sh'
done
