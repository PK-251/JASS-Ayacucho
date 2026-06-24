# Correcciones al Plan de Pruebas Unificado v1.0

Este documento lista los ajustes necesarios en `Plan_Pruebas_JASS_Quilcata_v1.docx` para alinearlo con el sistema **J.A.S.S. Quilcata** tal como está implementado en el repositorio.

**Fecha de revisión:** 22/06/2026

---

## 1. Metadatos del plan

| Campo | Valor actual en DOCX | Corrección sugerida |
|---|---|---|
| Framework | Laravel 11 (PHP) | **Laravel 12** (PHP 8.2+) |
| Fecha del documento | Junio 2025 | **Junio 2026** |
| Estado | En ejecución | Mantener; 10/56 casos aprobados (ver `mapeo_casos_prueba.md`) |

---

## 2. Autenticación web (`routes/web.php`)

El formulario de login usa el campo **`username`**, no correo electrónico.

| Campo DOCX | Corrección |
|---|---|
| Usuario: `admin@jass.pe` | **Username:** `admin_jass` |
| Contraseña: `Admin2024#` | **Contraseña:** `admin123` |
| Mensaje esperado: "Credenciales incorrectas" | Mensaje real: validación Laravel / mensaje de error del `LoginController` |

**Rutas web relevantes:**

- Login: `GET/POST /login`
- Dashboard administrador: `GET /admin/inicio`
- Dashboard operador: `GET /operador/inicio`
- Raíz: `GET /` → redirige a `/login` si no hay sesión

---

## 3. API REST (`routes/api.php`)

Prefijo base: **`/api/v1`**. Autenticación con **Laravel Sanctum** (header `Authorization: Bearer {token}`).

### Endpoints del plan vs. implementación

| Descripción en DOCX | Endpoint correcto | Rol requerido |
|---|---|---|
| `GET /api/usuarios` | `GET /api/v1/admin/usuarios` | Administrador |
| `GET /api/usuarios/{id}` | `GET /api/v1/admin/usuarios/{usuario}` | Administrador |
| `POST /api/pagos` | `POST /api/v1/admin/cobros` o `POST /api/v1/operador/cobros` | Admin / Operador |
| `GET /api/reportes` | `GET /api/v1/admin/reportes` | Administrador |
| Login API (no listado) | `POST /api/v1/login` | Público |
| Perfil autenticado | `GET /api/v1/me` | Cualquier usuario autenticado |
| Deuda de vecino | `GET /api/v1/admin/usuarios/{usuario}/deuda` | Administrador |
| Reporte parcial | `POST /api/v1/admin/reportes/parcial` | Administrador |

### Ejemplo de login API

```json
POST /api/v1/login
{
  "username": "admin_jass",
  "password": "admin123",
  "device_name": "postman"
}
```

Respuesta esperada: HTTP 200, `data.access_token`, `data.token_type: "Bearer"`.

---

## 4. Módulos y rutas admin web

| Módulo DOCX | Ruta web real (admin) |
|---|---|
| Gestión de tarifas | `/admin/multas` (pestaña tarifas) |
| Gestión de multas | `/admin/multas` |
| Cobros | `/admin/cobros` |
| Egresos | `/admin/egresos` |
| Reportes | `/admin/reportes` |
| Asistencia | `/admin/asistencia` |
| Usuarios / vecinos | `/admin/usuarios` |

El operador accede a cobros y asistencia bajo `/operador/*`.

---

## 5. Base de datos

| DOCX | Proyecto |
|---|---|
| MariaDB (Docker) | Correcto — ver `backend/docker-compose.yml` y scripts en `Database/` |
| Pruebas PHPUnit | Usan **SQLite en memoria** (`phpunit.xml`) con esquema mínimo manual |
| Procedimientos (`sp_registrar_cobro`, `sp_calcular_deuda_vecino`) | Definidos en SQL de MariaDB; **no se ejecutan** en tests PHPUnit actuales |

Para pruebas de BD con procedimientos reales, usar MariaDB de Docker y `.env.testing`.

---

## 6. Casos ya ejecutados (actualizar en DOCX)

Marcar como **Aprobado** en el DOCX los siguientes casos, con evidencia en `reportes/resultados_backend.md`:

| ID DOCX | Resultado obtenido (resumen) | Evidencia |
|---|---|---|
| UT-AUTH-01 | Admin autenticado accede a `/admin/inicio` (HTTP 200) | PHPUnit `AdminDashboardTest` |
| UT-AUTH-02 | API rechaza password incorrecto (HTTP 422) | PHPUnit `ApiAuthBackendTest` |
| UT-AUTH-03 | Usuario bloqueado tras 3 intentos (API) | PHPUnit `ApiAuthBackendTest` |
| SEC-BRU-01 | Igual que UT-AUTH-03 | PHPUnit `ApiAuthBackendTest` |
| SEC-TOK-03 | `GET /api/v1/me` sin token → HTTP 401 | PHPUnit `ApiAuthBackendTest` |
| SEC-ROL-01 | Operador en `/admin/inicio` → redirect `/operador/inicio` | PHPUnit `AdminDashboardTest` |
| SEC-ROL-03 | Admin accede al dashboard (parcial: solo `/admin/inicio`) | PHPUnit `AdminDashboardTest` |

Además, cubiertos por PHPUnit pero sin ID DOCX directo:

- Acceso sin login a `/admin/inicio` → BE-001
- `POST /api/v1/login` exitoso → BE-004
- `GET /` sin sesión → redirect `/login`

---

## 7. Próximos pasos recomendados

1. Aplicar las correcciones de texto en el DOCX (framework, credenciales, endpoints).
2. Completar columnas **Resultado Obtenido**, **Estado** y **Evidencia** usando `mapeo_casos_prueba.md`.
3. Priorizar automatización de BE-008 a BE-014 (validaciones y cobros).
4. Ejecutar casos E2E y de compatibilidad de navegadores de forma manual, fuera del alcance PHPUnit.
