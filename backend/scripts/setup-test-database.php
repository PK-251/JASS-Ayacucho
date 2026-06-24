<?php

/**
 * Prepara jass_quilcata_test para la suite integration de PHPUnit.
 *
 * Pasos:
 *   1. Verifica conexion a MariaDB.
 *   2. Importa Database/jass_quilcata_full.sql si jass_quilcata no existe o esta vacia.
 *   3. Clona jass_quilcata -> jass_quilcata_test (mysqldump + mysql).
 *   4. Instala sp_calcular_deuda_vecino (requerido por la app, ausente en el dump completo).
 *   5. Verifica procedimientos criticos.
 *
 * Uso: composer test:setup-db
 */

declare(strict_types=1);

$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3307';
$user = getenv('DB_USERNAME') ?: 'root';
$password = getenv('DB_PASSWORD') ?: 'root_password';
$targetDatabase = getenv('DB_DATABASE') ?: 'jass_quilcata_test';
$sourceDatabase = 'jass_quilcata';

$fullSqlFile = realpath(__DIR__.'/../../Database/jass_quilcata_full.sql');
$spSqlFile = realpath(__DIR__.'/../database/sql/sp_calcular_deuda_vecino.sql');

if ($fullSqlFile === false || ! is_file($fullSqlFile)) {
    fwrite(STDERR, "No se encontro Database/jass_quilcata_full.sql\n");
    exit(1);
}

if ($spSqlFile === false || ! is_file($spSqlFile)) {
    fwrite(STDERR, "No se encontro database/sql/sp_calcular_deuda_vecino.sql\n");
    exit(1);
}

$mysql = resolveMysqlClient();
$mysqldump = resolveMysqldumpClient($mysql);

$connection = compact('host', 'port', 'user', 'password');

echo "Cliente mysql:    {$mysql}\n";
echo "Cliente mysqldump: {$mysqldump}\n";
echo "Host:             {$host}:{$port}\n";
echo "Origen:           {$sourceDatabase}\n";
echo "Destino:          {$targetDatabase}\n\n";

assertMariaDbReachable($mysql, $connection);

if (! sourceDatabaseIsReady($mysql, $connection, $sourceDatabase)) {
    echo "[1/4] Importando {$sourceDatabase} desde jass_quilcata_full.sql...\n";
    importSqlFile($mysql, $connection, null, $fullSqlFile);
} else {
    echo "[1/4] {$sourceDatabase} ya existe con datos; se omite importacion del dump completo.\n";
}

echo "[2/4] Recreando {$targetDatabase}...\n";
runMysqlCommand(
    $mysql,
    $connection,
    null,
    sprintf('DROP DATABASE IF EXISTS `%s`;', escapeIdentifier($targetDatabase))
);
runMysqlCommand(
    $mysql,
    $connection,
    null,
    sprintf(
        'CREATE DATABASE `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',
        escapeIdentifier($targetDatabase)
    )
);

echo "[3/4] Clonando {$sourceDatabase} -> {$targetDatabase}...\n";
cloneDatabase($mysqldump, $mysql, $connection, $sourceDatabase, $targetDatabase);

echo "[4/4] Instalando sp_calcular_deuda_vecino en {$targetDatabase}...\n";
importSqlFile($mysql, $connection, $targetDatabase, $spSqlFile);

verifyTestDatabase($mysql, $connection, $targetDatabase);

echo "\nBase de datos de pruebas lista: {$targetDatabase}\n";
echo "Ejecute: composer test:integration\n";

function resolveMysqlClient(): string
{
  return resolveBinaryClient('mysql.exe', 'mysql');
}

function resolveMysqldumpClient(string $mysql): string
{
    $mysqldump = str_ireplace('mysql.exe', 'mysqldump.exe', $mysql);

    if (is_file($mysqldump)) {
        return $mysqldump;
    }

    return resolveBinaryClient('mysqldump.exe', 'mysqldump');
}

function resolveBinaryClient(string $windowsName, string $unixName): string
{
    $windowsPath = 'C:\\xampp\\mysql\\bin\\'.$windowsName;

    if (is_file($windowsPath)) {
        return $windowsPath;
    }

    $output = [];
    $exitCode = 0;
    exec(PHP_OS_FAMILY === 'Windows' ? "where {$unixName} 2>nul" : "command -v {$unixName}", $output, $exitCode);

    if ($exitCode === 0 && ! empty($output[0])) {
        return trim($output[0]);
    }

    fwrite(STDERR, "No se encontro {$unixName}. Instale XAMPP o agregue el cliente al PATH.\n");
    exit(1);
}

function assertMariaDbReachable(string $mysql, array $connection): void
{
    runMysqlCommand($mysql, $connection, null, 'SELECT 1;');
}

function sourceDatabaseIsReady(string $mysql, array $connection, string $sourceDatabase): bool
{
    $sql = sprintf(
        "SELECT COUNT(*) AS total FROM information_schema.tables WHERE table_schema = '%s' AND table_name = 'vecinos';",
        str_replace("'", "''", $sourceDatabase)
    );

    $output = runMysqlCommand($mysql, $connection, null, $sql, captureOutput: true);

    if (! isset($output[1])) {
        return false;
    }

    return str_contains($output[1], '1');
}

function verifyTestDatabase(string $mysql, array $connection, string $targetDatabase): void
{
    $checks = [
        'vecinos' => sprintf(
            "SELECT COUNT(*) AS total FROM `%s`.vecinos;",
            escapeIdentifier($targetDatabase)
        ),
        'sp_calcular_deuda_vecino' => sprintf(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES
             WHERE ROUTINE_SCHEMA = '%s' AND ROUTINE_NAME = 'sp_calcular_deuda_vecino' LIMIT 1;",
            str_replace("'", "''", $targetDatabase)
        ),
        'sp_registrar_cobro' => sprintf(
            "SELECT ROUTINE_NAME FROM information_schema.ROUTINES
             WHERE ROUTINE_SCHEMA = '%s' AND ROUTINE_NAME = 'sp_registrar_cobro' LIMIT 1;",
            str_replace("'", "''", $targetDatabase)
        ),
    ];

    $vecinoOutput = runMysqlCommand($mysql, $connection, null, $checks['vecinos'], captureOutput: true);
    if (! isset($vecinoOutput[1]) || (int) $vecinoOutput[1] < 1) {
        fwrite(STDERR, "Verificacion fallida: no hay vecinos en {$targetDatabase}.\n");
        exit(1);
    }

    foreach (['sp_calcular_deuda_vecino', 'sp_registrar_cobro'] as $procedure) {
        $output = runMysqlCommand($mysql, $connection, null, $checks[$procedure], captureOutput: true);
        if (! isset($output[1]) || trim($output[1]) === '') {
            fwrite(STDERR, "Verificacion fallida: falta el procedimiento {$procedure}.\n");
            exit(1);
        }
    }
}

function cloneDatabase(
    string $mysqldump,
    string $mysql,
    array $connection,
    string $sourceDatabase,
    string $targetDatabase
): void {
    $dump = buildMysqlArgs($mysqldump, $connection)
        .' --routines --triggers --single-transaction --default-character-set=utf8mb4 '
        .escapeCliArg($sourceDatabase);

    $import = buildMysqlArgs($mysql, $connection)
        .' --default-character-set=utf8mb4 '
        .escapeCliArg($targetDatabase);

    if (PHP_OS_FAMILY === 'Windows') {
        $command = 'cmd /c "'.$dump.' | '.$import.'"';
    } else {
        $command = $dump.' | '.$import;
    }

    runShellCommand($command);
}

function importSqlFile(string $mysql, array $connection, ?string $database, string $sqlFile): void
{
    $command = buildMysqlArgs($mysql, $connection).' --default-character-set=utf8mb4';

    if ($database !== null) {
        $command .= ' '.escapeCliArg($database);
    }

    if (PHP_OS_FAMILY === 'Windows') {
        $command = 'cmd /c "'.$command.' < '.str_replace('"', '""', $sqlFile).'"';
    } else {
        $command .= ' < '.escapeshellarg($sqlFile);
    }

    runShellCommand($command);
}

function runMysqlCommand(
    string $mysql,
    array $connection,
    ?string $database,
    string $sql,
    bool $captureOutput = false
): array {
    $command = buildMysqlArgs($mysql, $connection).' --default-character-set=utf8mb4';

    if ($database !== null) {
        $command .= ' '.escapeCliArg($database);
    }

    $command .= ' -e '.escapeCliArg($sql);

    $output = [];
    $exitCode = 0;
    exec($command, $output, $exitCode);

    if ($exitCode !== 0) {
        fwrite(STDERR, "Error al ejecutar mysql:\n".implode("\n", $output)."\n");
        exit($exitCode);
    }

    return $captureOutput ? $output : [];
}

function buildMysqlArgs(string $binary, array $connection): string
{
    return escapeshellarg($binary)
        .' --host='.escapeshellarg($connection['host'])
        .' --port='.escapeshellarg($connection['port'])
        .' --user='.escapeshellarg($connection['user'])
        .' --password='.escapeshellarg($connection['password']);
}

function escapeCliArg(string $value): string
{
    if (PHP_OS_FAMILY === 'Windows') {
        return '"'.str_replace('"', '""', $value).'"';
    }

    return escapeshellarg($value);
}

function escapeIdentifier(string $identifier): string
{
    return str_replace('`', '``', $identifier);
}

function runShellCommand(string $command): void
{
    $output = [];
    $exitCode = 0;
    exec($command, $output, $exitCode);

    if ($exitCode !== 0) {
        fwrite(STDERR, "Error al ejecutar comando:\n{$command}\n");
        if ($output !== []) {
            fwrite(STDERR, implode("\n", $output)."\n");
        }
        exit($exitCode);
    }
}
