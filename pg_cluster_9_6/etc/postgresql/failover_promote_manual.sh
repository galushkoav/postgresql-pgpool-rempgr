#!/bin/bash
#repmgr standby promote -f /etc/repmgr.conf;
echo "Отправка оповещений";
sh /etc/postgresql/failover_notify_master.sh;
/bin/sleep 1;

repmgr -f /etc/repmgr.conf  cluster show | grep FAILED | awk ' {print $6} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/failed_host.list
repmgr -f /etc/repmgr.conf  cluster show | grep master | awk ' {print $7} ' | sed "s/host=//g" | sed "s/>//g" > /etc/postgresql/current_master.list

echo "Рестартуем repmgrd на других нодах"
sh /etc/postgresql/repmgrd_restart.sh

for FH in $(cat /etc/postgresql/failed_host.list)
do

echo "scp /etc/postgresql/failed_host.list postgres@$FH:/etc/postgresql";
scp /etc/postgresql/failed_host.list postgres@$FH:/etc/postgresql;
echo "/etc/postgresql/current_master.list postgres@$FH:/etc/postgresql";
scp /etc/postgresql/current_master.list postgres@$FH:/etc/postgresql;
done


NODENUMBER=`cat /etc/postgresql/nodenumber`
CLUSTER_NAME="etagi_cluster1"
echo "$FAILED_HOST"
echo "НАчинаю процедуру ввода выпавшего сервера обратно в класте"

for FH in $(cat /etc/postgresql/failed_host.list)
do
ssh postgres@$FH <<OFF

cd ~/9.6;
rm -rf main/*;
echo "Следуем за новым местером"

		sh /etc/postgresql/failover_notify_begin_restoring.sh;
		#repmgr -D /var/lib/postgresql/9.6/main  -f /etc/repmgr.conf -d repmgr -p 5433 -U repmgr -R postgres --verbose --force --rsync-only  --copy-external-config-files=pgdata  standby clone -h $(cat /etc/postgresql/current_master.list);

		repmgr  -p 5433 -U repmgr -d repmgr -D /var/lib/postgresql/9.6/main -f /etc/repmgr.conf --copy-external-config-files=pgdata --verbose standby clone -h $(cat /etc/postgresql/current_master.list);


/bin/sleep 1;
echo "Запускаем сервер";
/usr/lib/postgresql/9.6/bin/pg_ctl -D /var/lib/postgresql/9.6/main --log=/var/log/postgresql/postgres_screen.log start;
sh /etc/postgresql/failover_notify_pg_started.sh;
echo "Статус сервера";
pg_ctl status;
/bin/sleep 30;
echo "Регистрируемся в кластере";
sh /etc/postgresql/register.sh
repmgr -f /etc/repmgr.conf  --force standby register;
echo "Вывод состояния кластера";
repmgr -f /etc/repmgr.conf  cluster show;

##########Обновляем файл /etc/repmgr.conf################################
#cat <<OEF>> /etc/repmgr.conf
#cluster=$CLUSTER_NAME" 
#node=$NODENUMBER" 
#node_name=$FAILED_HOST" 
#use_replication_slots=6" 
#onninfo='host=$FAILED_HOST port=5433  user=repmgr dbname=repmgr'
#pg_bindir=/usr/lib/postgresql/9.6/bin" 

#######АВТОМАТИЧЕСКИЙ FAILOVER#######ТОЛЬКО НА STAND BY##################" 
#master_response_timeout=100"
#reconnect_attempts=3"
#reconnect_interval=5"
#failover=automatic"
#promote_command='sh /etc/postgresql/failover_promote.sh'
#follow_command='sh /etc/postgresql/failover_follow.sh'
OEF

sh /etc/postgresql/repmgrd.sh

sh /etc/postgresql/failover_notify_restoring_ended.sh;
OFF
done
kill $(ps aux | grep repmgrd)
#pg_ctl -D /etc/postgresql/9.6/main  -m immediate stop