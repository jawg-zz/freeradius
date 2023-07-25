#!/bin/bash
# Executable process script for Freeradius + DaloRadius + MySQL image:
# GitHub: git@github.com:nullsoft8411/freeradius.git

INIT_LOCK=/data/.init_done

if test -f "$INIT_LOCK"; then
    if ! test -f "$DALORADIUS_CONF_PATH" || ! test -s "$DALORADIUS_CONF_PATH"; then
        echo "Init lock file exists but config file does not exist or is 0 bytes, performing initial setup of daloRADIUS."
        /var/www/daloradius/init.sh
    fi
    echo "Init lock file exists and config file exists, skipping initial setup of daloRADIUS."
else
    /var/www/daloradius/init.sh
    date >$INIT_LOCK
fi

service mysql start
# wait for MySQL-Server to be ready
echo -n "Waiting for mysql ($MYSQL_HOST)..."
while ! mysqladmin ping -h"$MYSQL_HOST" -p"$MYSQL_PASSWORD" --silent; do
    sleep 20
done
echo "MySQL - Done"
service apache2 start
/usr/sbin/freeradius -X