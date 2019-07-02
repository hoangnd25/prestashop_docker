FROM php:7.2-apache

ENV PS_VERSION 1.7.5.2
ENV PS_DOMAIN="<to be defined>" \
    DB_SERVER="<to be defined>" \
    DB_PORT=3306 \
    DB_NAME=prestashop \
    DB_USER=root \
    DB_PASSWD=admin \
    DB_PREFIX=ps_ \
    ADMIN_MAIL=demo@prestashop.com \
    ADMIN_PASSWD=prestashop_demo \
    PS_LANGUAGE=en \
    PS_COUNTRY=GB \
    PS_ALL_LANGUAGES=0 \
    PS_INSTALL_AUTO=0 \
    PS_DEV_MODE=0 \
    PS_HOST_MODE=0 \
    PS_DEMO_MODE=0 \
    PS_ENABLE_SSL=0 \
    PS_HANDLE_DYNAMIC_DOMAIN=0 \
    PS_FOLDER_ADMIN=admin \
    PS_FOLDER_INSTALL=install

RUN apt-get update \
	&& apt-get install -y \
        libmcrypt-dev \
		libjpeg62-turbo-dev \
		libpcre3-dev \
		libpng-dev \
		libfreetype6-dev \
		libxml2-dev \
		libicu-dev \
		libzip-dev \
		mysql-client \
		wget \
		unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install iconv intl pdo_mysql mbstring soap gd zip opcache

RUN pecl install mcrypt-1.0.2 apcu-5.1.11 && \
    pecl clear-cache && \
    docker-php-ext-enable \
        mcrypt \
		apcu \
		opcache

RUN cd /tmp \
    && curl -o /tmp/mod-pagespeed.deb https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-beta_current_amd64.deb \
    && dpkg -i /tmp/mod-pagespeed.deb \
    && apt-get -f install

# Apache configuration
RUN if [ -x "$(command -v apache2-foreground)" ]; then a2enmod rewrite; fi

# PHP configuration
COPY config_files/php.ini /usr/local/etc/php/

# Prepare install and CMD script
COPY config_files/ps-extractor.sh config_files/docker_run.sh /tmp/

# If handle dynamic domain
COPY config_files/docker_updt_ps_domains.php /tmp/

# PHP env for dev / demo modes
COPY config_files/defines_custom.inc.php /tmp/
RUN chown www-data:www-data /tmp/defines_custom.inc.php

# Get PrestaShop
ADD "https://www.prestashop.com/download/old/prestashop_${PS_VERSION}.zip" /tmp/prestashop.zip

# Extract
RUN mkdir -p /tmp/data-ps \
	&& unzip -q /tmp/prestashop.zip -d /tmp/data-ps/ \
	&& bash /tmp/ps-extractor.sh /tmp/data-ps \
	&& rm /tmp/prestashop.zip

# Run
CMD ["/tmp/docker_run.sh"]
