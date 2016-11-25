#!/bin/bash

echo "Выводим список необходимых хостов в файл"
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d'  > /etc/postgresql/cluster_hosts.list
repmgr -f /etc/repmgr.conf  cluster show | grep FAILED | awk ' {print $6} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/failed_host.list
repmgr -f /etc/repmgr.conf  cluster show | grep master | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/current_master.list
repmgr -f /etc/repmgr.conf  cluster show | grep standby | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d' > /etc/postgresql/standby_host.list



for STANDBYHOST in $(cat /etc/postgresql/standby_host.list)
do
ssh root@$STANDBYHOST <<OFF
/etc/init.d/keepalived stop;
sh /etc/postgresql/telegram.sh KEEPALIVED_ON_HOST_STOPED_$STANDBYHOST
OFF
done

for FH in $(cat /etc/postgresql/failed_host.list)
do
ssh root@$FH <<OFF
/etc/init.d/keepalived stop;
sh /etc/postgresql/telegram.sh KEEPALIVED_ON_HOST_STOPED_$FH
OFF
done

for MASTERHOST in $(cat /etc/postgresql/current_master.list)
do
ssh root@$MASTERHOST <<OFF
/etc/init.d/keepalived restart;/etc/init.d/keepalived reload;
sh /etc/postgresql/telegram.sh KEEPALIVED_ON_HOST_STARTED_$MASTERHOST 
OFF
done