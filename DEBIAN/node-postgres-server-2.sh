#!/bin/bash
echo'PATH=/usr/lib/postgresql/9.5/bin:$PATH' >> /var/lib/postgresql/.bash_profile

for SERVER in node1-psql01 node-psql02 node-pgpool-ha node-pgpool01 node-pgpool02; do
  echo "$SERVER.example.local:5432:postgres:admin:password123" >> ~/.pgpass
  echo "$SERVER.example.local:5432:repmgr:repmgr:repmgr_password" >> ~/.pgpass
done 
chmod 0600 ~/.pgpass
cp ~/.pgpass /var/lib/postgresql/
chown -R -v postgres:postgres /var/lib/postgresql/.pgpass

#Check the connection to primary node
su - postgres -c "psql --username=repmgr --dbname=repmgr --host node-psql01.example.com -w -l"

#Replicate the DB from the master mode
su - postgres -c "repmgr -D /var/lib/postgresql/9.5/ -d repmgr -p 5432 -U repmgr -R postgres --verbose standby clone node-psql01.example.com"

#Configure the repmgr
touch /etc/postgresql-common/repmgr.conf
cat > /etc/postgresql-common/repmgr.conf << EOF
cluster=pgsql_cluster
node=2
node_name=node-psql02
conninfo='host=node-psql02.example.com user=repmgr dbname=repmgr'
pg_bindir=/usr/lib/postgresql/9.5/bin
master_response_timeout=5
reconnect_attempts=2
reconnect_interval=2
failover=manual
promote_command='/usr/lib/postgresql/9.5/bin/repmgr standby promote -f /etc/postgresql-common/repmgr.conf'
follow_command='/usr/lib/postgresql/9.5/bin/repmgr standby follow -f /etc/postgresql-common/repmgr.conf'
EOF

chown -R postgres:postgres /etc/postgresql-common/repmgr.conf

EOF
/etc/init.d/postgresql restart

#Register the DB instance as slave
su - postgres -c "/usr/lib/postgresql/9.5/bin/repmgr -f /etc/postgresql-common/repmgr.conf --verbose standby register"
