# Base image for freeradius
FROM freeradius/freeradius-server:3.0.25 AS freeradius_base

# Install required packages for freeradius, apache, php, and dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    php \
    php-mysql \
    libapache2-mod-php \
    git \
    wget \
    curl \
    unzip \
    mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install daloRADIUS from GitHub
RUN git clone https://github.com/lirantal/daloradius.git /var/www/daloradius

# Set up daloRADIUS
WORKDIR /var/www/daloradius
RUN cp daloradius.conf.php.sample daloradius.conf.php \
    && chown -R www-data:www-data /var/www/daloradius \
    && chmod 644 /var/www/daloradius/library/daloradius.conf.php \
    && ln -s /var/www/daloradius /var/www/html/daloradius

# Expose FreeRADIUS ports and configure apache
EXPOSE 80/tcp 1812/udp 1813/udp

# Add the run.sh script to handle startup and initialization
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Enable Apache rewrite module for daloRADIUS
RUN a2enmod rewrite

# FreeRADIUS specific configurations
WORKDIR /etc/freeradius/3.0/

# Set up entrypoint to run the main script at startup
ENTRYPOINT ["/run.sh"]
