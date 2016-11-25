#!/bin/bash

repmgr -f /etc/repmgr.conf  cluster show | grep master | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/current_master.list

for CURMASTER in $(cat /etc/postgresql/current_master.list)
do
ssh postgres@$CURMASTER <<OFF
cd ~/9.6;
/usr/lib/postgresql/9.6/bin/pg_ctl -D /etc/postgresql/9.6/main  -m immediate stop;
touch /etc/postgresql/disabled;
OFF
sh /etc/postgresql/telegram.sh "ТЕКУЩИЙ МАСТЕР ОСТАНОВЛЕН"
done
