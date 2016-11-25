#!/bin/bash
repmgr -f /etc/repmgr.conf  cluster show | grep standby | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/standby.list


USER="postgres"

for PGHOST in $(cat /etc/postgresql/standby.list)
do
ssh postgres@$PGHOST 'sh /etc/postgresql/repmgrd.sh'
done
