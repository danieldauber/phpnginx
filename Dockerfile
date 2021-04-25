FROM php:7.4.9-fpm-alpine as phpfpm

RUN apk add --update \
    autoconf \
    g++ \
    libtool \
    make

RUN apk add --no-cache shadow

RUN apk add mysql-client --no-cache openssl
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install mysqli
RUN apk add --update icu-dev
RUN docker-php-ext-install intl

RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install xdebug-2.9.8 \
    && docker-php-ext-enable xdebug

RUN apk add --no-cache zip libzip-dev
RUN docker-php-ext-configure zip 
RUN docker-php-ext-install zip

RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
    docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
    docker-php-ext-install -j$(nproc) gd && \
    apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# #OPCACHE
# RUN set -eux; \
#     docker-php-ext-enable opcache; \
#     { \
#     echo 'opcache.memory_consumption=256'; \
#     echo 'opcache.interned_strings_buffer=8'; \
#     echo 'opcache.max_accelerated_files=4000'; \
#     echo 'opcache.revalidate_freq=60'; \
#     echo 'opcache.file_cache = "/tmp/";'\
#     echo 'opcache.fast_shutdown=1'; \
#     } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN docker-php-ext-install calendar && docker-php-ext-configure calendar

RUN pecl install redis-5.1.1 || pecl install redis-2.2.8
RUN docker-php-ext-enable redis

RUN pecl install apcu
RUN echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini

RUN pecl install igbinary
RUN echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini

# RUN rm /etc/localtime ; \
#     ln -s /usr/share/zoneinfo/Brazil/East /etc/localtime

RUN docker-php-ext-install intl
RUN apk add nginx
RUN mkdir -p /run/nginx

WORKDIR /var/www/html/
COPY ./.docker/php/php.ini /usr/local/etc/php/php.ini
COPY . /var/www/html/

RUN rm /etc/nginx/conf.d/default.conf
COPY ./.docker/nginx/nginx.conf /etc/nginx/conf.d

RUN chown www-data:www-data -R * 

EXPOSE 9000 80
CMD nginx -g "pid /tmp/nginx.pid; daemon off;" & php-fpm
