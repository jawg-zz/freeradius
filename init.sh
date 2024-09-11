#!/usr/bin/env bash
# Executable process script for Freeradius + DaloRadius + External MariaDB

set -e  # Exit script if any command fails
set -o pipefail  # Catch errors in pipes

echo "Starting initialization..."

# Function to log errors and exit
function error_exit {
    echo "$1" >&2
    exit 1
}

# Check if all required environment variables are set
if [ -z "${MYSQL_HOST}" ] || [ -z "${MYSQL_USER}" ] || [ -z "${MYSQL_PASSWORD}" ] || [ -z "${MYSQL_DATABASE}" ]; then
  error_exit "Error: Missing one or more required environment variables. Make sure MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE are set."
fi

# Database availability check with timeout (max 5 minutes)
DB_WAIT_TIMEOUT=300  # 5 minutes
DB_WAIT_INTERVAL=10  # Check every 10 seconds
SECONDS=0

echo -n "Waiting for external MariaDB (${MYSQL_HOST})..."

while ! mysqladmin ping -h"${MYSQL_HOST}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    if [ ${SECONDS} -ge ${DB_WAIT_TIMEOUT} ]; then
        error_exit "Error: Timeout while waiting for MariaDB to become available."
    fi
    echo -n "."
    sleep ${DB_WAIT_INTERVAL}
done

echo "Database is available."

# Function to initialize daloRADIUS configuration
function init_daloradius {
    echo "Starting daloRADIUS initialization..."

    if [ ! -f "${DALORADIUS_CONF_PATH}" ] || [ ! -s "${DALORADIUS_CONF_PATH}" ]; then
        if [ -f "${DALORADIUS_CONF_PATH}.sample" ]; then
            cp "${DALORADIUS_CONF_PATH}.sample" "${DALORADIUS_CONF_PATH}"
        else
            error_exit "Error: daloRADIUS sample config file not found."
        fi
    fi

    # Configure daloRADIUS for external MariaDB
    sed -i "s/\$configValues\['CONFIG_DB_HOST'\] = .*;/\$configValues\['CONFIG_DB_HOST'\] = '${MYSQL_HOST}';/" "${DALORADIUS_CONF_PATH}"
    sed -i "s/\$configValues\['CONFIG_DB_PORT'\] = .*;/\$configValues\['CONFIG_DB_PORT'\] = '${MYSQL_PORT}';/" "${DALORADIUS_CONF_PATH}"
    sed -i "s/\$configValues\['CONFIG_DB_PASS'\] = .*;/\$configValues\['CONFIG_DB_PASS'\] = '${MYSQL_PASSWORD}';/" "${DALORADIUS_CONF_PATH}"
    sed -i "s/\$configValues\['CONFIG_DB_USER'\] = .*;/\$configValues\['CONFIG_DB_USER'\] = '${MYSQL_USER}';/" "${DALORADIUS_CONF_PATH}"
    sed -i "s/\$configValues\['CONFIG_DB_NAME'\] = .*;/\$configValues\['CONFIG_DB_NAME'\] = '${MYSQL_DATABASE}';/" "${DALORADIUS_CONF_PATH}"
    sed -i "s/\$configValues\['FREERADIUS_VERSION'\] = .*;/\$configValues\['FREERADIUS_VERSION'\] = '3';/" "${DALORADIUS_CONF_PATH}"

    echo "daloRADIUS initialization completed."
}

# Function to initialize Freeradius configuration
function init_freeradius {
    echo "Starting Freeradius initialization..."

    # Enable SQL in Freeradius
    sed -i 's|driver = "rlm_sql_null"|driver = "rlm_sql_mysql"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|dialect = "sqlite"|dialect = "mysql"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|#\s*read_clients = yes|read_clients = yes|' "${RADIUS_PATH}/mods-available/sql"

    # Set Database connection for Freeradius
    sed -i 's|^#\s*server = .*|server = "'${MYSQL_HOST}'"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|^#\s*port = .*|port = "'${MYSQL_PORT}'"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|radius_db = .*|radius_db = "'${MYSQL_DATABASE}'"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|^#\s*login = .*|login = "'${MYSQL_USER}'"|' "${RADIUS_PATH}/mods-available/sql"
    sed -i 's|^#\s*password = .*|password = "'${MYSQL_PASSWORD}'"|' "${RADIUS_PATH}/mods-available/sql"

    echo "Freeradius initialization completed."
}

# Function to initialize the MariaDB database
function init_database {
    echo "Starting MySQL initialization..."

    # Create database and run schema scripts
    mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
    mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < "${DALORADIUS_PATH}/contrib/db/fr3-mysql-freeradius.sql" || error_exit "Error: Failed to import Freeradius SQL schema."
    mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < "${DALORADIUS_PATH}/contrib/db/mysql-daloradius.sql" || error_exit "Error: Failed to import daloRADIUS SQL schema."
    mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < "${RADIUS_PATH}/mods-config/sql/main/mysql/schema.sql" || error_exit "Error: Failed to import Freeradius main SQL schema."
    mysql -h "${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" < "${RADIUS_PATH}/mods-config/sql/ippool/mysql/schema.sql" || error_exit "Error: Failed to import IP pool SQL schema."

    echo "Database initialization for Freeradius & daloRADIUS completed."
}

# Call the functions in order
init_database
init_freeradius
init_daloradius

echo "Initialization process completed successfully."
