#!/bin/bash
pkill repmgrd
rm /var/run/postgresql/repmgrd.pid;
repmgrd -f /etc/repmgr.conf -p /var/run/postgresql/repmgrd.pid  -m -d -v >> /var/log/postgresql/repmgr.log 2>&1;
ps aux | grep repmgrd;
