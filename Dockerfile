# Base image: Ubuntu
FROM ubuntu:22.04

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    php \
    php-mysql \
    libapache2-mod-php \
    git \
    wget \
    curl \
    unzip \
    mysql-client \
    freeradius \
    freeradius-mysql \
    freeradius-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Clone daloRADIUS from GitHub
RUN git clone https://github.com/lirantal/daloradius.git /var/www/daloradius

# Set up daloRADIUS configuration
WORKDIR /var/www/daloradius
RUN cp daloradius.conf.php.sample daloradius.conf.php \
    && chown -R www-data:www-data /var/www/daloradius \
    && chmod 644 /var/www/daloradius/library/daloradius.conf.php \
    && ln -s /var/www/daloradius /var/www/html/daloradius

# Enable Apache rewrite module
RUN a2enmod rewrite

# Copy the run.sh script to handle startup processes
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Set up entrypoint to run the main script at startup
ENTRYPOINT ["/run.sh"]
