#!/bin/bash
trigger="/etc/postgresql/disabled"
TEXT="'`hostname -f`_postgresql_disabled_and_don't_be_started.You_must_delete_file_/etc/postgresql/disabled'"
TEXT
if [ -f "$trigger" ]
then
	echo "Current server is disabled"
	sh /etc/postgresql/telegram.sh $TEXT
else

pkill repmgrd
pg_ctl stop
rm -rf  /var/lib/postgresql/9.6/main/*;
mkdir /var/run/postgresql/9.6-main.pg_stat_tmp;
#repmgr -D /var/lib/postgresql/9.6/main  -f /etc/repmgr.conf -d repmgr -p 5433 -U repmgr -R postgres --verbose --force --rsync-only  --copy-external-config-files=pgdata  standby clone -h $(cat /etc/postgresql/current_master.list);
repmgr -h $(cat /etc/postgresql/current_master.list) -p 5433 -U repmgr -d repmgr -D /var/lib/postgresql/9.6/main -f /etc/repmgr.conf --copy-external-config-files=pgdata --verbose standby clone
/usr/lib/postgresql/9.6/bin/pg_ctl -D /var/lib/postgresql/9.6/main --log=/var/log/postgresql/postgres_screen.log start;
/bin/sleep 5;
repmgr -f /etc/repmgr.conf  --force standby register;
echo "Вывод состояния кластера";
repmgr -f /etc/repmgr.conf  cluster show;
sh /etc/postgresql/telegram.sh $TEXT
sh /etc/postgresql/repmgrd.sh;
ps aux | grep repmgrd;
fi
