#!/bin/bash
trigger="/etc/postgresql/disabled"
TEXT="'`hostname -f`_postgresql_disabled_and_don't_be_started.You_must_delete_file_/etc/postgresql/disabled'"

if [ -f "$trigger" ]
then
	echo "$TEXT";
else
/usr/lib/postgresql/9.6/bin/pg_ctl -D /var/lib/postgresql/9.6/main --log=/var/log/postgresql/postgres_screen.log start;
pkill pgbouncer;
sh /etc/postgresql/pgbouncer.sh;
echo "Вывод состояния кластера";
repmgr -f /etc/repmgr.conf  cluster show;
sh /etc/postgresql/repmgrd.sh;
ps aux | grep repmgrd;
fi
