# Docker y Nginx

Esta configuracion levanta la aplicacion Laravel con PHP-FPM, Nginx, MariaDB y phpMyAdmin.

## Servicios

- App Laravel/PHP: `jass_app`
- Nginx: `jass_nginx`
- MariaDB: `jass_mariadb`
- phpMyAdmin: `jass_phpmyadmin`

## URLs

- Aplicacion: http://127.0.0.1:8080/login
- phpMyAdmin: http://127.0.0.1:8081
- MariaDB desde Windows: `127.0.0.1:3307`

## Credenciales Docker

- Base: `jass_quilcata`
- Usuario app: `jass_user`
- Password app: `jass_password`
- Usuario root: `root`
- Password root: `root_password`

## Primer arranque

Desde la carpeta del backend:

```powershell
cd "C:\Users\poker\Desktop\Proyecto aguaa\backend"
docker compose up -d --build
```

Si quieres que Docker arranque con la misma base que usabas en XAMPP, primero exporta tu MariaDB a `docker/mariadb/init/01-jass_quilcata.sql`:

```powershell
C:\xampp\mysql\bin\mysqldump.exe --host=127.0.0.1 --port=3306 --user=root --default-character-set=utf8mb4 --single-transaction --routines --triggers --events --databases jass_quilcata > docker\mariadb\init\01-jass_quilcata.sql
docker compose up -d --build
```

Si ya habias creado el contenedor antes de poner el respaldo:

```powershell
docker compose down -v
docker compose up -d --build
```

## Comandos utiles

```powershell
docker compose ps
docker compose logs -f app
docker compose logs -f nginx
docker compose exec app php artisan route:list
docker compose exec app php artisan config:clear
docker compose down
```

## Nota sobre migraciones

Este proyecto ya tiene una base grande creada con SQL, procedimientos y datos de ejemplo. Por eso el arranque Docker no ejecuta migraciones automaticamente. Lo mas seguro es importar el respaldo SQL completo de `jass_quilcata`.
