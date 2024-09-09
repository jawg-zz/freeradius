FROM ubuntu:22.04
MAINTAINER Mustafa Sahin <admin@bglaf.org>
LABEL Description="Freeradius + daloRADIUS + MySQL on ubuntu 22.04 and PHP8.1." \
    License="GPLv2" \
    Usage="docker build . -t myfreeradius && docker run -d -p 80:80 -p 8000:8000 -p 1812:1812/udp -p 1813:1813/udp myfreeradius" \
    Version="1.0"

ENV DEBIAN_FRONTEND noninteractive
ENV DALORADIUS_CONF_PATH /var/www/daloradius/app/common/includes/daloradius.conf.php
ENV DALORADIUS_PATH /var/www/daloradius
ENV RADIUS_PATH /etc/freeradius/3.0
ENV MYSQL_ROOT_PASSWORD passw0rd
ENV DEFAULT_CLIENT_SECRET testing123
ENV MYSQL_HOST mysql
ENV MYSQL_PORT 3306
ENV MYSQL_DATABASE radiusdb
ENV MYSQL_USER raduser
ENV MYSQL_PASSWORD passw0rd
ENV TZ Europe/Berlin 

# Set MySQL root password
RUN echo mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD | debconf-set-selections;\
    echo mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD | debconf-set-selections;

# Install necessary packages
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates apt-utils  \
    tzdata apache2 libapache2-mod-php net-tools php php-common php-gd php-cli php-curl php-mail \
    php-dev php-mail-mime php-mbstring php-db php-mysql php-zip mysql-client default-libmysqlclient-dev \
    unzip wget nano curl freeradius-utils freeradius freeradius-mysql mysql-server cron \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache
ADD contrib/docker/operators.conf /etc/apache2/sites-available/operators.conf
ADD contrib/docker/users.conf /etc/apache2/sites-available/users.conf
RUN a2dissite 000-default.conf && \
    a2ensite users.conf operators.conf && \
    sed -i 's/Listen 80/Listen 80\nListen 8000/' /etc/apache2/ports.conf

# Create directories
RUN mkdir /data

# Copy Daloradius to image
ADD .  /var/www/daloradius

# Adjust permissions
RUN chown -R www-data:www-data /var/www/daloradius
RUN rm -rf /var/www/html
RUN touch /tmp/daloradius.log && chown -R www-data:www-data /tmp/daloradius.log
RUN mkdir -p /var/log/apache2/daloradius && chown -R www-data:www-data /var/log/apache2/daloradius

# Copy init and run scripts
COPY init.sh /var/www/daloradius/init.sh
COPY run.sh /var/www/daloradius/run.sh
RUN chmod +x /var/www/daloradius/init.sh /var/www/daloradius/run.sh

# Use run.sh as the entry point
ENTRYPOINT ["/var/www/daloradius/run.sh"]
WORKDIR /var/www/daloradius
