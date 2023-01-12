ARG VERSION_ALPINE=3.16
FROM alpine:${VERSION_ALPINE}

# Create user
RUN adduser -D -u 1000 -g 1000 -s /bin/sh www && \
    mkdir -p /var/www && \
    chown -R www:www /var/www

# Install tini - 'cause zombies - see: https://github.com/ochinchina/supervisord/issues/60
# (also pkill hack)
RUN apk add --no-cache --update tini

# Install a golang port of supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/bin/supervisord

# Install nginx & gettext (envsubst)
# Create cachedir and fix permissions
RUN apk add --no-cache --update \
    gettext zip unzip git \
    curl ca-certificates \
    nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R www:www /var/cache/nginx && \
    chown -R www:www /var/lib/nginx
    
# Install PHP/FPM + Modules
RUN apk add --no-cache --update \
    php8 \
    php8-cli php8-dev libstdc++ mysql-client bash bash-completion shadow \
    coreutils libpng libmemcached-libs krb5-libs icu-libs \
    icu c-client libzip openldap-clients imap postgresql-client postgresql-libs libcap tzdata sqlite \
    lua-resty-core nginx-mod-http-lua rabbitmq-c \
    php8-apcu \
    php8-bcmath \
    php8-bz2 \
    php8-cgi \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-fpm \
    php8-ftp \
    php8-gd \
    php8-iconv \
    php8-json \
    php8-mbstring \
    php8-pecl-oauth \
    php8-opcache \
    php8-openssl \
    php8-pcntl \
    php8-pecl-msgpack \
    php8-mysqli \
    php8-pdo \
    php8-pdo_mysql \
    php8-phar \
    php8-redis \
    php8-session \
    php8-simplexml \
    php8-tokenizer \
    php8-xdebug \
    php8-xml \
    php8-xmlwriter \
    php8-zip \
    php8-zlib

# Runtime env vars are envstub'd into config during entrypoint

RUN curl http://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
# Alias defaults to empty, example usage:
# SERVER_ALIAS='www.example.com'

COPY ./supervisord.conf /supervisord.conf
COPY ./php-fpm-www.conf /etc/php8/php-fpm.d/www.conf
COPY ./nginx.conf.template /nginx.conf.template
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
USER root
RUN rm -rf /var/www/*
RUN chmod 755 /docker-entrypoint.sh

WORKDIR /var/www
RUN git clone -b 2022.12 https://github.com/Anankke/SSPanel-Uim.git .
RUN composer install
RUN chmod 755 -R *
RUN chown www:www -R *
RUN cp config/appprofile.example.php config/appprofile.php
RUN mv db/migrations/20000101000000_init_database.php.new db/migrations/20000101000000_init_database.php

CMD ["/docker-entrypoint.sh"]
