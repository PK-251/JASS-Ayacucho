#!/usr/bin/env bash
set -e

cd /var/www/html

if [ ! -f .env ] && [ -f .env.docker ]; then
    cp .env.docker .env
fi

mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
chmod -R ug+rw storage bootstrap/cache 2>/dev/null || true

if [ ! -d vendor ]; then
    composer install --no-interaction --prefer-dist
fi

if [ -f .env ] && ! grep -q "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

php artisan storage:link >/dev/null 2>&1 || true

php -r '
$host = getenv("DB_HOST") ?: "mariadb";
$port = getenv("DB_PORT") ?: "3306";
$db = getenv("DB_DATABASE") ?: "jass_quilcata";
$user = getenv("DB_USERNAME") ?: "jass_user";
$pass = getenv("DB_PASSWORD") ?: "jass_password";
$deadline = time() + 60;
do {
    try {
        new PDO("mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4", $user, $pass);
        exit(0);
    } catch (Throwable $e) {
        if (time() >= $deadline) { fwrite(STDERR, $e->getMessage() . PHP_EOL); exit(1); }
        sleep(2);
    }
} while (true);
'

if [ "${APP_ENV}" = "production" ]; then
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache
else
    php artisan config:clear  >/dev/null 2>&1 || true
    php artisan route:clear   >/dev/null 2>&1 || true
    php artisan view:clear    >/dev/null 2>&1 || true
fi

exec "$@"
