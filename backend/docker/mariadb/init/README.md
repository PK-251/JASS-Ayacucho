# Inicializacion de MariaDB

Coloca aqui el respaldo SQL de la base `jass_quilcata` si quieres que Docker la importe automaticamente la primera vez que crea el volumen.

Nombre recomendado:

```text
01-jass_quilcata.sql
```

Ejemplo desde XAMPP en Windows:

```powershell
C:\xampp\mysql\bin\mysqldump.exe --host=127.0.0.1 --port=3306 --user=root --default-character-set=utf8mb4 --single-transaction --routines --triggers --events --databases jass_quilcata > docker\mariadb\init\01-jass_quilcata.sql
```

Importante: MariaDB solo lee esta carpeta cuando el volumen `mariadb_data` se crea por primera vez. Si agregas el respaldo despues, reinicia limpio con:

```powershell
docker compose down -v
docker compose up -d --build
```
