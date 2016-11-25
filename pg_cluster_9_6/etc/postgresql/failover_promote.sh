#!/bin/bash
CLHOSTS="10.1.1.195 10.1.1.196 10.1.1.197 10.1.1.198 10.1.1.205"
repmgr standby promote -f /etc/repmgr.conf;
echo "Отправка оповещений";
sh /etc/postgresql/failover_notify_master.sh;
echo "Выводим список необходимых хостов в файл"
repmgr -f /etc/repmgr.conf  cluster show | grep node | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d'  > /etc/postgresql/cluster_hosts.list
repmgr -f /etc/repmgr.conf  cluster show | grep FAILED | awk ' {print $6} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/failed_host.list
repmgr -f /etc/repmgr.conf  cluster show | grep master | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/current_master.list
repmgr -f /etc/repmgr.conf  cluster show | grep standby | awk ' {print $7} ' | sed "s/host=//g" | sed '/port/d' > /etc/postgresql/standby_host.list


####КОПИРУЮ ИНФО ФАЙЛЫ И ФАЙЛЫ-ТРИГГЕРЫ НА ДРУГИЕ НОДЫ КЛАСТЕРА#####################
for CLHOST in $CLHOSTS
do
rsync -arvzSH  --include "*.list" --exclude "*" /etc/\postgresql/ postgres@$CLHOST:/etc/postgresql/
done


echo "Начинаю процедуру восстановления упавшего сервера,если не триггера /etc/postgresql/disabled"

for FH in $(cat /etc/postgresql/failed_host.list)
do
ssh postgres@$FH <<OFF
sh /etc/postgresql/register.sh;
echo "Рестартуем repmgrd на других нодах"
sh /etc/postgresql/repmgrd.sh;
sh /etc/postgresql/failover_notify_restoring_ended.sh;
OFF
done

echo "Стопаем repmgrd на ноде, ставшей мастером"
pkill repmgrd


echo "Работаем с Keepalived"
sh /etc/postgresql/keepalived-check.sh;