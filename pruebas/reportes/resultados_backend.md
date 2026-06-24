# Resultados de Ejecucion Backend

Fecha ultima ejecucion documentada: 18/06/2026  
Actualizacion de trazabilidad: 22/06/2026

## Trazabilidad con plan unificado

Los resultados de esta suite se mapean al plan DOCX v1.0 en [`../mapeo_casos_prueba.md`](../mapeo_casos_prueba.md).

| Test PHPUnit | ID BE | ID(s) DOCX |
|---|---|---|
| `AdminDashboardTest::test_usuario_no_autenticado_es_redireccionado_al_login` | BE-001 | SEC-ROL (web) |
| `AdminDashboardTest::test_administrador_autenticado_puede_ver_dashboard` | BE-002 | UT-AUTH-01, SEC-ROL-03 |
| `AdminDashboardTest::test_operador_no_puede_entrar_al_panel_admin` | BE-003 | SEC-ROL-01 |
| `ApiAuthBackendTest::test_login_api_devuelve_token_con_credenciales_validas` | BE-004 | API (login) |
| `ApiAuthBackendTest::test_login_api_rechaza_password_incorrecto_y_registra_intento` | BE-005 | UT-AUTH-02 |
| `ApiAuthBackendTest::test_login_api_bloquea_usuario_tras_tres_intentos_fallidos` | BE-006 | UT-AUTH-03, SEC-BRU-01 |
| `ApiAuthBackendTest::test_endpoint_me_requiere_autenticacion` | BE-007 | SEC-TOK-03 |
| `ExampleTest::test_la_raiz_redirige_al_login_si_no_hay_sesion` | — | — |

## Pruebas PHPUnit agregadas

| Archivo | Casos cubiertos |
|---|---|
| `backend/tests/Feature/AdminDashboardTest.php` | Acceso sin login, acceso admin, bloqueo de operador en admin. |
| `backend/tests/Feature/ApiAuthBackendTest.php` | Login API correcto, password incorrecto, bloqueo por tres intentos, endpoint protegido sin token. |

## Resultado

### Ejecucion final

Comando:

```powershell
cd backend
$env:LOG_CHANNEL='stderr'
$env:APP_BASE_PATH='C:\Users\poker\Documents\Codex\JASS-Ayacucho-main\backend'
$env:APP_KEY='base64:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
$env:VIEW_COMPILED_PATH='C:\tmp\jass_views'
php C:\tmp\jass_vendor\phpunit\phpunit\phpunit --configuration phpunit.xml --do-not-cache-result
```

Resultado:

```text
PHPUnit 11.5.55 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.2.12
Configuration: C:\Users\poker\Documents\Codex\JASS-Ayacucho-main\backend\phpunit.xml

.........                                                           9 / 9 (100%)

Time: 00:01.438, Memory: 42.00 MB

OK (9 tests, 25 assertions)
```

Interpretacion:

La suite backend se ejecuto correctamente. Se validaron rutas protegidas, roles, autenticacion API, bloqueo por intentos fallidos, endpoint protegido sin token y pruebas base.

### Instalacion de dependencias

Comando:

```powershell
composer install --no-interaction --prefer-dist
```

Resultado:

```text
Composer no pudo instalar dentro de backend/vendor porque el entorno bloqueo la creacion de subcarpetas.
Como alternativa, se instalaron dependencias en C:\tmp\jass_vendor.
```

Interpretacion:

Para ejecutar las pruebas en esta sesion se uso un autoload puente en `backend/vendor/autoload.php` apuntando a `C:\tmp\jass_vendor\autoload.php`.

### Validacion alternativa ejecutada

Se valido sintaxis PHP de los tests agregados:

```powershell
php -l tests\Feature\AdminDashboardTest.php
php -l tests\Feature\ApiAuthBackendTest.php
```

Resultado:

```text
No syntax errors detected in tests\Feature\AdminDashboardTest.php
No syntax errors detected in tests\Feature\ApiAuthBackendTest.php
```

Estado:

```text
PASS en validacion sintactica.
PASS en ejecucion PHPUnit completa.
```

## Observaciones

- Las pruebas crean tablas minimas en memoria porque el proyecto usa SQL completo para MariaDB y no migraciones Laravel para todo el modelo real.
- Se mantiene el alcance solicitado por el docente: backend, API, base de datos, seguridad y validaciones.
- Vite fue desactivado durante pruebas con `withoutVite()` porque el alcance es backend y no frontend.
- Se uso `VIEW_COMPILED_PATH=C:\tmp\jass_views` para evitar escribir vistas compiladas dentro del proyecto durante la ejecucion.
