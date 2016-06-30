#!/bin/bash
sed -i.orig \
-e "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" \
-e "s/^#shared_preload_libraries = ''/shared_preload_libraries = 'repmgr_funcs'/" \
-e "s/^#wal_level = minimal/wal_level = hot_standby/" \
-e "s/^#archive_mode = off/archive_mode = on/" \
-e "s@^#archive_command = ''@archive_command = 'cd .'@" \
-e "s/^#max_wal_senders = 0/max_wal_senders = 1/" \
-e "s/^#wal_keep_segments = 0/wal_keep_segments = 5000/" \
-e "s/^#\(wal_sender_timeout =.*\)/\1/" \
-e "s/^#hot_standby = off/hot_standby = on/" \
-e "s/^#log_min_duration_statement = -1/log_min_duration_statement = 0/" \
-e "s/^log_line_prefix = '< %m >'/log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '/" \
-e "s/^#log_checkpoints =.*/log_checkpoints = on/" \
-e "s/^#log_connections =.*/log_connections = on/" \
-e "s/^#log_disconnections =.*/log_disconnections = on/" \
-e "s/^#log_lock_waits = off/log_lock_waits = on/" \
-e "s/^#log_statement = 'none'/log_statement = 'all'/" \
-e "s/^#log_temp_files = -1/log_temp_files = 0/" \
/etc/postgresql/9.5/main/postgresql.conf

cat >> /etc/postgresql/9.5/main/pg_hba.conf << EOF
host    all             admin           0.0.0.0/0               md5
host    all             all             10.1.9.0/24          md5
host    all             all             10.4.1.0/24          md5
# node-psql01
host    repmgr          repmgr          10.1.9.223/32        trust
host    replication     repmgr          10.1.9.223/32        trust
# node-psql02
host    repmgr          repmgr          10.1.9.224/32        trust
host    replication     repmgr          10.1.9.224/32        trust
EOF
 
for SERVER in node1-psql01 node-psql02 node-pgpool-ha node-pgpool01 node-pgpool02; do
  echo "$SERVER.example.com:5432:postgres:admin:password123" >> ~/.pgpass
  echo "$SERVER.example.com:5432:repmgr:repmgr:repmgr_password" >> ~/.pgpass
done 
chmod 0600 ~/.pgpass
cp ~/.pgpass /var/lib/postgresql/
chown postgres:postgres /var/lib/postgresql/.pgpass

#Configure repmgr
mkdir /var/lib/postgresql/repmgr
rm /etc/postgresql-common/repmgr.conf
touch /etc/postgresql-common/repmgr.conf
cat > /etc/postgresql-common/repmgr.conf << EOF
cluster=pgsql_cluster
node=1
node_name=node-psql01
conninfo='host=node-psql01.example.com user=repmgr dbname=repmgr'
pg_bindir=/usr/lib/postgresql/9.5/bin
master_response_timeout=5
reconnect_attempts=2
reconnect_interval=2
failover=manual
promote_command='/usr/lib/postgresql/9.5/bin/repmgr standby promote -f /etc/postgresql-common/repmgr.conf'
follow_command='/usr/lib/postgresql/9.5/bin/repmgr standby follow -f /etc/postgresql-common/repmgr.conf'
EOF
 

chown -R postgres:postgres /var/lib/postgresql/
 
echo 'PATH=/usr/lib/postgresql/9.5/bin:$PATH' >> /var/lib/postgresql/.bash_profile
service postgresql start 

#Add users
sudo -u postgres psql -c "CREATE ROLE admin SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION LOGIN ENCRYPTED PASSWORD 'password123';"
sudo -u postgres psql -c "CREATE USER repmgr SUPERUSER LOGIN ENCRYPTED PASSWORD 'repmgr_password';"
sudo -u postgres psql -c "CREATE DATABASE repmgr OWNER repmgr;"

#Register DB instance as master
su - postgres -c "repmgr -f /etc/postgresql-common/repmgr.conf --verbose master register"

echo "Настройте соединие по ssh между нодами без пароля для user'a - postgresq"
