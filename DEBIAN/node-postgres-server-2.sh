echo 'PATH=/usr/lib/postgresql/9.5/bin:$PATH' >> /var/lib/postgresql/.bash_profile

scp -r node-psql01.example.com:/root/{.pgpass,.ssh} /root/
cp -r /root/{.pgpass,.ssh} /var/lib/postgresql/
chown -R postgres:postgres /var/lib/postgresql/.pgpass /var/lib/postgresql/.ssh
 
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
