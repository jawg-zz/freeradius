#!/bin/bash
# Executable process script for Freeradius + DaloRadius + MySQL image:
# GitHub: git@github.com:nullsoft8411/freeradius.git

date +"%d-%m-%y - %H:%M"

service mysql start

# wait for MySQL-Server to be ready
echo -n "Waiting for mysql ($MYSQL_HOST)..."
while ! mysqladmin ping -h"$MYSQL_HOST" -p"$MYSQL_PASSWORD" --silent; do
        sleep 20
done
echo "ok"

INIT_LOCK=/data/.init_done

if [ -e "$INIT_LOCK" ]; then
        if [ ! -e "$DALORADIUS_CONF_PATH" ] || [ ! -s "$DALORADIUS_CONF_PATH" ]; then
                echo "Init lock file exists but config file does not exist or is 0 bytes, performing initial setup of daloRADIUS."
                /var/www/daloradius/init.sh
                date >$INIT_LOCK
        fi
else
        echo "init lock file not exsist. run first time init"
        /var/www/daloradius/init.sh
        date >$INIT_LOCK
fi

service apache2 start
service freeradius start
#/usr/sbin/freeradius -X
