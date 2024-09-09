# Freeradius + DaloRadius Dockerfile with External MariaDB
FROM ubuntu:22.04

# Maintainer and metadata
MAINTAINER Mustafa Sahin <admin@bglaf.org>
LABEL Description="Freeradius + daloRADIUS with external MariaDB on Ubuntu 22.04 and PHP8.1." \
      License="GPLv2" \
      Version="1.0"

# Non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Environment Variables
ENV DALORADIUS_CONF_PATH /var/www/daloradius/app/common/includes/daloradius.conf.php
ENV DALORADIUS_PATH /var/www/daloradius
ENV RADIUS_PATH /etc/freeradius/3.0
ENV TZ Europe/Berlin

# Install dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends \
    apache2 \
    libapache2-mod-php \
    php \
    php-common \
    php-gd \
    php-cli \
    php-curl \
    php-mail \
    php-mbstring \
    php-db \
    php-mysql \
    mysql-client \
    freeradius \
    freeradius-mysql \
    freeradius-utils \
    wget \
    unzip \
    nano \
    cron \
    git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /data /tmp/daloradius.log /var/log/apache2/daloradius

# Clone daloRADIUS from GitHub
#RUN git clone https://github.com/lirantal/daloradius.git /var/www/daloradius

# Copy daloRADIUS
ADD .  /var/www/daloradius

# Set file permissions
RUN chown -R www-data:www-data /var/www/daloradius /tmp/daloradius.log /var/log/apache2/daloradius

# Copy Apache and daloRADIUS configurations
COPY contrib/docker/operators.conf /etc/apache2/sites-available/operators.conf
COPY contrib/docker/users.conf /etc/apache2/sites-available/users.conf
RUN a2dissite 000-default.conf && \
    a2ensite users.conf operators.conf && \
    sed -i 's/Listen 80/Listen 80\nListen 8000/' /etc/apache2/ports.conf

# Copy entry point script
COPY run.sh /run.sh
RUN chmod +x /run.sh
# Set the entry point
ENTRYPOINT ["/run.sh"]

# Set the working directory
WORKDIR /var/www/daloradius
