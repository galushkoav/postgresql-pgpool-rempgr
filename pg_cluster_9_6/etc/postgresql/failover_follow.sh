repmgr standby follow -f /etc/repmgr.conf;
echo "Отправка оповещений";
sh /etc/postgresql/failover_notify_standby.sh;
pkill repmgrd;
repmgrd -f /etc/repmgr.conf -p /var/run/postgresql/repmgrd.pid  -m -d -v >> /var/log/postgresql/repmgr.log 2>&1;
