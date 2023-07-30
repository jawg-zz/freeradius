# Freeradius + DaloRadius + MySQL Dockerfile
# GitHub: https://github.com/nullsoft8411/freeradius
#
# Build image:
# 1. git pull git@github.com:nullsoft8411/freeradius.git
# 2. docker build . -t myfreeradius
#
# Run the container:
# 1. docker run -p 80:80 -p 8000:8000 -d myfreeradius
# 2. docker run --name freeradius  -p 8888:80 -p 8000:8000 -p 3307:3306 -p 1812:1812/udp -p 1813:1813/udp -p 1812:1812/tcp -p 1813:1813/tcp -v data:/data -v mysql:/var/lib/mysql -d myfreeradius
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
ENV MYSQL_HOST 127.0.0.1
ENV MYSQL_PORT 3306
ENV MYSQL_DATABASE radiusdb
ENV MYSQL_USER raduser
ENV MYSQL_PASSWORD passw0rd
# default timezone
ENV TZ Europe/Berlin 

#Set MySQL root password
RUN echo mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD | debconf-set-selections;\
  echo mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD | debconf-set-selections;

#install
RUN apt-get update \
  && apt-get install --yes --no-install-recommends ca-certificates apt-utils  \
  tzdata apache2 libapache2-mod-php net-tools php php-common php-gd php-cli php-curl php-mail \
  php-dev php-mail-mime php-mbstring php-db php-mysql php-zip mysql-client default-libmysqlclient-dev \
  unzip wget nano curl freeradius-utils freeradius freeradius-mysql mysql-server cron\
  && rm -rf /var/lib/apt/lists/*

ADD contrib/docker/operators.conf /etc/apache2/sites-available/operators.conf
ADD contrib/docker/users.conf /etc/apache2/sites-available/users.conf
RUN a2dissite 000-default.conf && \
    a2ensite users.conf operators.conf && \
    sed -i 's/Listen 80/Listen 80\nListen 8000/' /etc/apache2/ports.conf

# Create directories
# /data should be mounted as volume to avoid recreation of database entries
RUN mkdir /data

# Copy Daloradius to image
ADD .  /var/www/daloradius

#RUN touch /var/www/html/library/daloradius.conf.php
RUN chown -R www-data:www-data /var/www/daloradius

# Remove the original sample web folder
RUN rm -rf /var/www/html
#
# Create daloRADIUS Log file
RUN touch /tmp/daloradius.log && chown -R www-data:www-data /tmp/daloradius.log
RUN mkdir -p /var/log/apache2/daloradius && chown -R www-data:www-data /var/log/apache2/daloradius

#
## Run the script which executes Apache2 in the foreground as a running process
CMD ["/bin/bash", "/var/www/daloradius/run.sh"]
WORKDIR /var/www/daloradius
