FROM php:8.4-fpm-bookworm

ARG UID=1000
ARG GID=1000

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        curl \
        git \
        unzip \
        zip \
        mariadb-client \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libonig-dev \
        libxml2-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) pdo_mysql bcmath gd zip opcache pcntl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN groupadd -g ${GID} laravel \
    && useradd -u ${UID} -g laravel -m laravel

COPY docker/php/local.ini /usr/local/etc/php/conf.d/99-local.ini
COPY docker/app/entrypoint.sh /usr/local/bin/laravel-entrypoint
RUN chmod +x /usr/local/bin/laravel-entrypoint

COPY --chown=laravel:laravel . .

RUN mkdir -p storage bootstrap/cache \
    && chown -R laravel:laravel storage bootstrap/cache

USER laravel

ENTRYPOINT ["laravel-entrypoint"]
CMD ["php-fpm"]
