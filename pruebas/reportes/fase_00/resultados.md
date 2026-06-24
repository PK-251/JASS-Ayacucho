# Fase 0 — Fundamentos

**Fecha:** 22/06/2026  
**Estado:** En curso

## Entregables

| Item | Estado |
|---|---|
| `phpunit.xml` suite `fast` (SQLite) | Listo |
| `phpunit.integration.xml` suite `integration` (MariaDB) | Listo |
| `tests/Support/SqliteTestCase.php` | Listo |
| `tests/Support/MariaDbTestCase.php` | Listo |
| Traits `AuthenticatesApi`, `CreatesVecinos`, `CreatesCobros` | Listo |
| `VecinoFactory`, `TarifaFactory`, `TestBaselineSeeder` | Listo |
| `composer test` / `composer test:integration` | Listo |
| `composer test:setup-db` | Listo |
| `MariaDbSmokeTest` | Listo (requiere MariaDB) |

## Ejecución

```powershell
cd backend
composer test
composer test:setup-db      # Requiere MariaDB en :3307
composer test:integration
```

## Resultados

### Suite fast (`composer test`)

```
Tests: 9 passed (25 assertions)
Duration: ~2.4s
```

Todos PASS: `AdminDashboardTest`, `ApiAuthBackendTest`, `ExampleTest`, `Unit\ExampleTest`.

### Suite integration (`composer test:integration`)

```
Tests: 2 skipped (MariaDB no disponible en :3307)
```

Con Docker levantado y `composer test:setup-db`, se esperan 2 PASS en `MariaDbSmokeTest`.

## Notas

- Se corrigió `APP_KEY` inválido en `phpunit.xml` que causaba fallos en tests web con sesión/cookies.
- `AdminDashboardTest` y `ApiAuthBackendTest` migrados a `SqliteTestCase`.
