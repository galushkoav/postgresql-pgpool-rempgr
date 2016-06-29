cp /etc/pgpool2/pcp.conf.sample /etc/pgpool2/pcp.conf
echo "admin:`pg_md5 password123`" >> /etc/pgpool2/pcp.conf

sed \
-e "s/^listen_addresses = .localhost./listen_addresses = '*'/" \
-e "s/^log_destination = .stderr./log_destination = 'syslog'/" \
-e "s/^port = .*/port = 5432/" \
-e "s/^backend_hostname0 =.*/backend_hostname0 = 'node-psql01.example.com'/" \
-e "s/^#backend_flag0/backend_flag0/" \
-e "s/^#backend_hostname1 =.*/backend_hostname1 = 'node-psql02.example.com'/" \
-e "s/^#backend_port1 = 5433/backend_port1 = 5432/" \
-e "s/^#backend_weight1/backend_weight1/" \
-e "s/^#backend_data_directory1 =.*/backend_data_directory1 = '\/var\/lib\/postgresql\/9.5'/" \
-e "s/^#backend_flag1/backend_flag1/" \
-e "s/^log_hostname =.*/log_hostname = on/" \
-e "s/^syslog_facility =.*/syslog_facility = 'daemon.info'/" \
-e "s/^sr_check_user =.*/sr_check_user = 'admin'/" \
-e "s/^sr_check_password =.*/sr_check_password = 'password123'/" \
-e "s/^health_check_period =.*/health_check_period = 10/" \
-e "s/^health_check_user =.*/health_check_user = 'admin'/" \
-e "s/^health_check_password =.*/health_check_password = 'password123'/" \
-e "s/^use_watchdog =.*/use_watchdog = on/" \
-e "s/^delegate_IP =.*/delegate_IP = '10.1.9.250'/" \
-e "s/^netmask 255.255.255.0/netmask 255.255.255.128/" \
-e "s/^heartbeat_device0 =.*/heartbeat_device0 = 'eth0'/" \
-e "s/^#other_pgpool_port0 =.*/other_pgpool_port0 = 5432/" \
-e "s/^#other_wd_port0 = 9000/other_wd_port0 = 9000/" \
-e "s/^load_balance_mode = off/load_balance_mode = on/" \
-e "s/^master_slave_mode = off/master_slave_mode = on/" \
-e "s/^master_slave_sub_mode =.*/master_slave_sub_mode = 'stream'/" \
-e "s@^failover_command = ''@failover_command = '/etc/pgpool2/failover_stream.sh %d %H'@" \
-e "s/^recovery_user = 'nobody'/recovery_user = 'admin'/" \
-e "s/^recovery_password = ''/recovery_password = 'password123'/" \
-e "s/^recovery_1st_stage_command = ''/recovery_1st_stage_command = 'basebackup.sh'/" \
-e "s/^sr_check_period = 0/sr_check_period = 10/" \
-e "s/^delay_threshold = 0/delay_threshold = 10000000/" \
-e "s/^log_connections = off/log_connections = on/" \
-e "s/^log_statement = off/log_statement = on/" \
-e "s/^log_per_node_statement = off/log_per_node_statement = on/" \
-e "s/^log_standby_delay = 'none'/log_standby_delay = 'always'/" \
-e "s/^enable_pool_hba = off/enable_pool_hba = on/" \
/etc/pgpool2/pgpool.conf.sample > /etc/pgpool2/pgpool.conf

cat > /etc/pgpool2/failover_stream.sh << \EOF
#!/bin/sh
# Failover command for streaming replication.
#
# Arguments: $1: failed node id. $2: new master hostname.
 
failed_node=$1
new_master=$2
 
(
date
echo "Failed node: $failed_node"
set -x
 
# Promote standby/slave to be a new master (old master failed) 
/usr/bin/ssh -T -l postgres $new_master "/usr/pgsql-9.3/bin/repmgr -f /var/lib/pgsql/repmgr/repmgr.conf standby promote 2>/dev/null 1>/dev/null <&-"
 
exit 0;
) 2>&1 | tee -a /tmp/failover_stream.sh.log
EOF
chmod 755 /etc/pgpool2/failover_stream.sh
 
cp /etc/pgpool2/pool_hba.conf.sample /etc/pgpool2/pool_hba.conf
echo "host    all         all         0.0.0.0/0             md5" >> /etc/pgpool2/pool_hba.conf
 
mkdir -p /var/lib/postgresql/9.5/main
groupadd -g 26 -o -r postgres
useradd -M -n -g postgres -o -r -d /var/lib/postgresql/9.5/main -s /bin/bash -c "PostgreSQL Server" -u 26 postgres
 
cp -R /root/.ssh /var/lib/postgresql/
sed -i '/^User /d' /var/lib/postgresql/.ssh/config

pg_md5 -m -u admin password123
 
chown -R postgres:postgres /var/lib/postgresql/ /etc/pgpool2/pool_passwd
 
chmod 6755 /sbin/ifconfig
chmod 6755 /sbin/arping
 
chkconfig pgpool-II-93 on
