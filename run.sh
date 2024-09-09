#!/bin/bash
# Start script for Freeradius + DaloRadius + MySQL

date +"%d-%m-%y - %H:%M"

# Start MySQL service
service mysql start

# Wait for MySQL to be ready
echo -n "Waiting for mysql ($MYSQL_HOST)..."
while ! mysqladmin ping -h"$MYSQL_HOST" -p"$MYSQL_PASSWORD" --silent; do
    sleep 20
done
echo "ok"

# Check if initialization is needed
INIT_LOCK=/data/.init_done

if [ -e "$INIT_LOCK" ]; then
    echo "Init lock file exists"
    if [ ! -e "$DALORADIUS_CONF_PATH" ] || [ ! -s "$DALORADIUS_CONF_PATH" ]; then
        echo "Config file does not exist or is 0 bytes, performing initial setup of daloRADIUS."
        /var/www/daloradius/init.sh
        date > $INIT_LOCK
    fi
else
    echo "Init lock file does not exist. Running first-time initialization."
    /var/www/daloradius/init.sh
    date > $INIT_LOCK
fi

# Start Apache
service apache2 start

# Start Freeradius in debug mode
/usr/sbin/freeradius -X
