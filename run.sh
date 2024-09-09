#!/bin/bash
# Main startup script for Freeradius + DaloRadius + MySQL setup

echo "Starting Freeradius + daloRADIUS + MySQL setup"

# Log current date and time
date +"%d-%m-%y - %H:%M"

# Start Apache
service apache2 start

# Start FreeRADIUS
service freeradius stop
echo "Starting FreeRADIUS in debug mode..."
/usr/sbin/freeradius -X &

# Wait for MySQL Server to be ready
echo -n "Waiting for external MariaDB ($MYSQL_HOST)..."
while ! mysqladmin ping -h"$MYSQL_HOST" -p"$MYSQL_PASSWORD" --silent; do
    sleep 5
done
echo "MariaDB is ready."

# Initialize if required
INIT_LOCK=/data/.init_done

# if [ -e "$INIT_LOCK" ]; then
#   echo "Initialization already done, skipping..."
# else
    echo "First-time setup: Running init script..."
    /var/www/daloradius/init.sh
    date > "$INIT_LOCK"
    echo "Initialization completed."
#fi

# Keep FreeRADIUS and Apache running in the foreground
echo "Services started. Keeping container running."
tail -f /var/log/apache2/access.log /var/log/freeradius/radius.log
