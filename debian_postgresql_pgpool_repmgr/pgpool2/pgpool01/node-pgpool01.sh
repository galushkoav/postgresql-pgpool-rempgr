sed \
-e "s/^wd_hostname =.*/wd_hostname = 'node-pgpool01.example.com'/" \
-e "s/^heartbeat_destination0 =.*/heartbeat_destination0 = 'node-pgpool02.example.com'/" \
-e "s/^#other_pgpool_hostname0 =.*/other_pgpool_hostname0 = 'node-pgpool02.example.com'/" \
-i /etc/pgpool2/pgpool.conf
/etc/init.d/pgpool2 restart
