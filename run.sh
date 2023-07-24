#!/bin/bash
# Executable process script for Freeradius + DaloRadius + MySQL image:
# GitHub: git@github.com:nullsoft8411/freeradius.git
INIT_LOCK=/data/.init_done
if test -f "$INIT_LOCK"; then
    #
    if ! test -f "$DALORADIUS_CONF_PATH" || ! test -s "$DALORADIUS_CONF_PATH"; then
        echo "Init lock file exists but config file does not exist or is 0 bytes, performing initial setup of daloRADIUS."
        /app/init.sh
    fi
    echo "Init lock file exists and config file exists, skipping initial setup of daloRADIUS."
else
    /app/init.sh
    date > $INIT_LOCK
fi



mysqld_safe >/dev/null &
sleep 2
/usr/sbin/freeradius -X
/usr/sbin/apachectl -DFOREGROUND -k start

