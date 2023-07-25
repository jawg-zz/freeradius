#!/bin/bash
# Executable process script for Freeradius + DaloRadius + MySQL image:
# GitHub: git@github.com:nullsoft8411/freeradius.git

service mysql start
echo "Start init"
function init_daloradius {
    echo "Starting daloRADIUS initialization"
    if ! test -f "$DALORADIUS_CONF_PATH" || ! test -s "$DALORADIUS_CONF_PATH"; then
        cp "$DALORADIUS_CONF_PATH.sample" "$DALORADIUS_CONF_PATH"
    fi
    [ -n "$MYSQL_HOST" ] && sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '$MYSQL_HOST';/" $DALORADIUS_CONF_PATH || MYSQL_HOST=localhost
    [ -n "$MYSQL_PORT" ] && sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '$MYSQL_PORT';/" $DALORADIUS_CONF_PATH
    [ -n "$MYSQL_PASSWORD" ] && sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '$MYSQL_PASSWORD';/" $DALORADIUS_CONF_PATH || MYSQL_PASSWORD=radpass
    [ -n "$MYSQL_USER" ] && sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '$MYSQL_USER';/" $DALORADIUS_CONF_PATH || MYSQL_USER=raduser
    [ -n "$MYSQL_DATABASE" ] && sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '$MYSQL_DATABASE';/" $DALORADIUS_CONF_PATH || MYSQL_DATABASE=raddb
    sed -i "s/\$configValues\['FREERADIUS_VERSION'\] = .*;/\$configValues\['FREERADIUS_VERSION'\] = '3';/" $DALORADIUS_CONF_PATH
    [ -n "$PASSWORD_MIN_LENGTH" ] && sed -i "s/\$configValues\['CONFIG_DB_PASSWORD_MIN_LENGTH'\] = .*;/\$configValues\['CONFIG_DB_PASSWORD_MIN_LENGTH'\] = '$PASSWORD_MIN_LENGTH';/" $DALORADIUS_CONF_PATH
    [ -n "$PASSWORD_MAX_LENGTH" ] && sed -i "s/\$configValues\['CONFIG_DB_PASSWORD_MAX_LENGTH'\] = .*;/\$configValues\['CONFIG_DB_PASSWORD_MAX_LENGTH'\] = '$PASSWORD_MAX_LENGTH';/" $DALORADIUS_CONF_PATH

    [ -n "$DEFAULT_FREERADIUS_SERVER" ] \
        && sed -i "s/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSERVER'\] = .*;/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSERVER'\] = '$DEFAULT_FREERADIUS_SERVER';/" $DALORADIUS_CONF_PATH \
        || sed -i "s/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSERVER'\] = .*;/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSERVER'\] = 'radius';/" $DALORADIUS_CONF_PATH
    [ -n "$DEFAULT_FREERADIUS_PORT" ] && sed -i "s/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSPORT'\] = .*;/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSPORT'\] = '$DEFAULT_FREERADIUS_PORT';/" $DALORADIUS_CONF_PATH
    [ -n "$DEFAULT_CLIENT_SECRET" ] && sed -i "s/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSECRET'\] = .*;/\$configValues\['CONFIG_MAINT_TEST_USER_RADIUSSECRET'\] = '$DEFAULT_CLIENT_SECRET';/" $DALORADIUS_CONF_PATH

    [ -n "$MAIL_SMTPADDR" ] && sed -i "s/\$configValues\['CONFIG_MAIL_SMTPADDR'\] = .*;/\$configValues\['CONFIG_MAIL_SMTPADDR'\] = '$MAIL_SMTPADDR';/" $DALORADIUS_CONF_PATH
    [ -n "$MAIL_PORT" ] && sed -i "s/\$configValues\['CONFIG_MAIL_SMTPPORT'\] = .*;/\$configValues\['CONFIG_MAIL_SMTPPORT'\] = '$MAIL_PORT';/" $DALORADIUS_CONF_PATH
    [ -n "$MAIL_FROM" ] && sed -i "s/\$configValues\['CONFIG_MAIL_SMTPFROM'\] = .*;/\$configValues\['CONFIG_MAIL_SMTPFROM'\] = '$MAIL_FROM';/" $DALORADIUS_CONF_PATH
    [ -n "$MAIL_AUTH" ] && sed -i "s/\$configValues\['CONFIG_MAIL_SMTPAUTH'\] = .*;/\$configValues\['CONFIG_MAIL_SMTPAUTH'\] = '$MAIL_AUTH';/" $DALORADIUS_CONF_PATH
    sed -i "s/\$configValues\['CONFIG_LOG_FILE'\] = .*;/\$configValues\['CONFIG_LOG_FILE'\] = '\/tmp\/daloradius.log';/" $DALORADIUS_CONF_PATH

    echo "daloRADIUS initialization completed."
}

function init_freeradius {
    echo "Staring Freeradius initialization"
    # Enable SQL in freeradius
	sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' $RADIUS_PATH/mods-available/sql
	sed -i 's|dialect = "sqlite"|dialect = "mysql"|' $RADIUS_PATH/mods-available/sql
	sed -i 's|dialect = ${modules.sql.dialect}|dialect = "mysql"|' $RADIUS_PATH/mods-available/sqlcounter # avoid instantiation error
	sed -i 's|#\s*read_clients = yes|read_clients = yes|' $RADIUS_PATH/mods-available/sql
	sed -i 's|$INCLUDE ${modconfdir}/${.:name}/main/${dialect}/queries.conf|$INCLUDE /etc/freeradius/3.0/mods-config/sql/main/mysql/queries.conf|' $RADIUS_PATH/mods-available/sql
	ln -s $RADIUS_PATH/mods-available/sql $RADIUS_PATH/mods-enabled/sql
	ln -s $RADIUS_PATH/mods-available/sqlcounter $RADIUS_PATH/mods-enabled/sqlcounter
	ln -s $RADIUS_PATH/mods-available/sqlippool $RADIUS_PATH/mods-enabled/sqlippool
	sed -i 's|instantiate {|instantiate {\nsql|' $RADIUS_PATH/radiusd.conf # mods-enabled does not ensure the right order
	sed -i '86,96d' $RADIUS_PATH/mods-available/sql
        sed -i 's|ipaddr = 127.0.0.1|ipaddr = \*|' $RADIUS_PATH/clients.conf

	# Enable used tunnel for unifi
	sed -i 's|use_tunneled_reply = no|use_tunneled_reply = yes|' $RADIUS_PATH/mods-available/eap

	# Enable status in freeadius
	ln -s $RADIUS_PATH/sites-available/status $RADIUS_PATH/sites-enabled/status

	# Set Database connection
	sed -i 's|^#\s*server = .*|server = "'$MYSQL_HOST'"|' $RADIUS_PATH/mods-available/sql
	sed -i 's|^#\s*port = .*|port = "'$MYSQL_PORT'"|' $RADIUS_PATH/mods-available/sql
	sed -i '1,$s/radius_db.*/radius_db="'$MYSQL_DATABASE'"/g' $RADIUS_PATH/mods-available/sql
	sed -i 's|^#\s*password = .*|password = "'$MYSQL_PASSWORD'"|' $RADIUS_PATH/mods-available/sql
	sed -i 's|^#\s*login = .*|login = "'$MYSQL_USER'"|' $RADIUS_PATH/mods-available/sql

	if [ -n "$DEFAULT_CLIENT_SECRET" ]; then
		sed -i 's|testing123|'$DEFAULT_CLIENT_SECRET'|' $RADIUS_PATH/mods-available/sql
	fi
	 
    echo "Freeradius initialization completed."

}

function init_database {
    echo "Staring MySQL initialization"
    echo ""
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $MYSQL_DATABASE;"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost'";
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < $DALORADIUS_PATH/contrib/db/fr3-mysql-freeradius.sql
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < $DALORADIUS_PATH/contrib/db/mysql-daloradius.sql
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < $RADIUS_PATH/mods-config/sql/main/mysql/schema.sql
	mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" < $RADIUS_PATH/mods-config/sql/ippool/mysql/schema.sql
	
    # Insert a client for the current subnet (to allow daloradius to perform checks)
	CIDR="127.0.0.1"
	SECRET=testing123
	if [ -n "$DEFAULT_CLIENT_SECRET" ]; then
		SECRET=$DEFAULT_CLIENT_SECRET
	fi
	echo "Adding client for $CIDR with default secret $SECRET"
	mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "INSERT INTO nas (nasname,shortname,type,ports,secret,server,community,description) VALUES ('$CIDR','DOCKER NET','other',0,'$SECRET',NULL,'','')"
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "INSERT INTO nas (nasname,shortname,type,ports,secret,server,community,description) VALUES ('localhost','DOCKER NET2','other',0,'$SECRET',NULL,'','')"
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "INSERT INTO nas (nasname,shortname,type,ports,secret,server,community,description) VALUES ('0.0.0.0/0','DOCKER NET3','other',0,'$SECRET',NULL,'','')"

    echo "Database initialization for freeradius & daloRADIUS completed."
}



# wait for MySQL-Server to be ready
echo -n "Waiting for mysql ($MYSQL_HOST)..."
while ! mysqladmin ping -h"$MYSQL_HOST" -p"$MYSQL_PASSWORD" --silent; do
    sleep 20
done
echo "ok"


init_database
init_freeradius
init_daloradius

# Start Apache2 in the foreground
service apache2 start
/usr/sbin/freeradius -X
