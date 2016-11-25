#!/bin/bash

USERID="you_user_id"
CLUSTERNAME="PGCLUSTER_test"
KEY="bot_key_telegram"
TIMEOUT="10"
EXEPT_USER="root"
URL="https://api.telegram.org/bot$KEY/sendMessage"
DATE_EXEC="$(date "+%d %b %Y %H:%M")"
TMPFILE='/etc/postgresql/ipinfo-$DATE_EXEC.txt'
        IP=$(echo $SSH_CLIENT | awk '{print $1}')
        PORT=$(echo $SSH_CLIENT | awk '{print $3}')
        HOSTNAME=$(hostname -f)
        IPADDR=$(hostname -I | awk '{print $1}')
        curl http://ipinfo.io/$IP -s -o $TMPFILE
        #ORG=$(cat $TMPFILE | jq '.org' | sed 's/"//g')
        TEXT="ВНИМАНИЕ!!! $HOSTNAME закончила процедуру восстановления данных."
        for IDTELEGRAM in $USERID
        do
        curl -s --max-time $TIMEOUT -d "chat_id=$IDTELEGRAM&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
        done
        #python /usr/bin/message_.py "galushko.a.v scherbakov.da" "$TEXT" 
        rm $TMPFILE


