#!/bin/bash
pkill pgbouncer
pgbouncer -d --verbose /etc/pgbouncer/pgbouncer.ini
netstat -4ln | grep 6432;