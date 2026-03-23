# syntax=docker/dockerfile:1

FROM php:8.4-fpm-alpine AS base

WORKDIR /var/www/html

RUN apk add --no-cache \
      autoconf \
      g++ \
      make \
      libpng-dev \
      libzip-dev \
      oniguruma-dev \
      postgresql-dev \
      curl \
    && docker-php-ext-install \
      pdo \
      pdo_pgsql \
      pgsql \
      mbstring \
      exif \
      pcntl \
      bcmath \
      gd \
      zip \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /tmp/pear /tmp/autoconf*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ── Stage development ──────────────────────────────────────────────────────────
FROM base AS development

COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-interaction

COPY . .

EXPOSE 9000
CMD ["php-fpm"]

# ── Stage production ───────────────────────────────────────────────────────────
FROM base AS production

COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-interaction --no-dev --prefer-dist

COPY . .
RUN composer dump-autoload --optimize --classmap-authoritative \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]