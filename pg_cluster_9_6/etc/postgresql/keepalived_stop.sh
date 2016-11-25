for STANDBYHOST in $(cat /etc/postgresql/standby_host.list)
do
ssh root@$STANDBYHOST <<OFF
/etc/init.d/keepalived stop;
sh /etc/postgresql/telegram.sh KEEPALIVED_ON_HOST_STOPED_`hostname -f`
OFF
done
