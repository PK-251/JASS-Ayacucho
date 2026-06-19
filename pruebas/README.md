# Pruebas Backend - J.A.S.S. Quilcata

Esta carpeta contiene la evidencia de la tarea de pruebas enfocada solo en el backend.

## Alcance

Las pruebas se concentran en:

- Backend Laravel.
- API REST v1.
- Autenticacion y roles.
- Base de datos MariaDB / SQLite de prueba.
- Validaciones del servidor.
- Control de acceso.
- Cobros, egresos, reportes, asistencia, multas y tarifas como logica backend.

## No incluido

- Diseno visual.
- Bootstrap, HTML o CSS.
- Compatibilidad visual en navegadores.
- Cypress E2E basado en interfaz.
- Responsive o experiencia de usuario frontend.

## Archivos principales

- `plan_backend.md`: plan de pruebas convertido a backend.
- `matriz_casos_backend.md`: matriz de casos de prueba.
- `reportes/resultados_backend.md`: resultados de ejecucion.

## Pruebas automatizadas agregadas

Se agregaron pruebas PHPUnit en:

- `backend/tests/Feature/AdminDashboardTest.php`
- `backend/tests/Feature/ApiAuthBackendTest.php`

Estas pruebas validan autenticacion, roles, acceso protegido, login API, bloqueo por intentos fallidos y token API.
