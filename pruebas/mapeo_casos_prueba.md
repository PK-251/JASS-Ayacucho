# Mapeo unificado de casos de prueba

Documento de trazabilidad entre el **Plan Unificado v1.0** (`Plan_Pruebas_JASS_Quilcata_v1.docx`), la **matriz backend** (`matriz_casos_backend.md`) y las **pruebas PHPUnit** automatizadas.

**Última actualización:** 22/06/2026

---

## Resumen de cobertura

| Fuente | Total casos | Ejecutados | Aprobados | Pendientes |
|---|---:|---:|---:|---:|
| Plan DOCX (56) | 56 | 10 | 10 | 46 |
| Matriz BE (25) | 25 | 7 | 7 | 18 |
| PHPUnit (suite) | 9 | 9 | 9 | 0 |

Los 10 casos del plan DOCX marcados como aprobados incluyen 7 de la matriz BE más 3 casos adicionales cubiertos por PHPUnit (`ExampleTest`).

---

## Correcciones al plan DOCX (sistema real)

| Tema | Valor en DOCX v1.0 | Valor correcto en el proyecto |
|---|---|---|
| Framework | Laravel 11 | **Laravel 12** (`backend/composer.json`) |
| Login web | `admin@jass.pe` / `Admin2024#` | **`username`**: `admin_jass` / **`admin123`** |
| Login API | No especificado | `POST /api/v1/login` con `username`, `password`, `device_name` |
| Listar usuarios | `GET /api/usuarios` | `GET /api/v1/admin/usuarios` (token Bearer, rol Administrador) |
| Registrar pago | `POST /api/pagos` | `POST /api/v1/admin/cobros` o `POST /api/v1/operador/cobros` |
| Reportes | `GET /api/reportes` | `GET /api/v1/admin/reportes` |
| Perfil autenticado | No listado | `GET /api/v1/me` |
| Panel admin web | Dashboard genérico | `GET /admin/inicio` |
| Panel operador web | Dashboard genérico | `GET /operador/inicio` |

Detalle ampliado en [`correcciones_plan_v1.md`](correcciones_plan_v1.md).

---

## Fase 1 — Pruebas unitarias (15)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Evidencia |
|---|---|---|---|---|---|
| UT-AUTH-01 | Inicio de sesión con credenciales válidas | BE-002 | `AdminDashboardTest::test_administrador_autenticado_puede_ver_dashboard` | **Aprobado** (parcial web) | `backend/tests/Feature/AdminDashboardTest.php` |
| UT-AUTH-02 | Rechazo con credenciales inválidas | BE-005 | `ApiAuthBackendTest::test_login_api_rechaza_password_incorrecto_y_registra_intento` | **Aprobado** (API) | `backend/tests/Feature/ApiAuthBackendTest.php` |
| UT-AUTH-03 | Bloqueo tras 3 intentos fallidos | BE-006 | `ApiAuthBackendTest::test_login_api_bloquea_usuario_tras_tres_intentos_fallidos` | **Aprobado** | `backend/tests/Feature/ApiAuthBackendTest.php` |
| UT-AUTH-04 | Expiración de sesión por inactividad | — | — | Pendiente | — |
| UT-AUTH-05 | Cierre de sesión manual | — | — | Pendiente | — |
| UT-CALC-01 | Cálculo con 1 mes pendiente sin multa | BE-010 | — | Pendiente | — |
| UT-CALC-02 | Cálculo con 3 meses pendientes | BE-010 | — | Pendiente | — |
| UT-CALC-03 | Deuda acumulada + multa activa | BE-010 | — | Pendiente | — |
| UT-CALC-04 | Usuario sin deuda (monto cero) | BE-010 | — | Pendiente | — |
| UT-CALC-05 | Múltiples multas acumuladas | BE-010 | — | Pendiente | — |
| UT-CALC-06 | Tarifa cero (exonerado) | BE-010 | — | Pendiente | — |
| UT-PAY-01 | Inserción correcta de pago en BD | BE-011 | — | Pendiente | — |
| UT-PAY-02 | Rechazo de pago con monto incorrecto | BE-012 | — | Pendiente | — |
| UT-PAY-03 | Rechazo de cobro duplicado mismo periodo | BE-013 | — | Pendiente | — |
| UT-PAY-04 | Rollback ante error en transacción | BE-012 | — | Pendiente | — |

---

## Fase 2 — Pruebas de integración (8)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Evidencia |
|---|---|---|---|---|---|
| INT-01 | Flujo completo: login → búsqueda → cobro → comprobante | BE-011, BE-015 | — | Pendiente | — |
| INT-02 | Aplicar multa y recalcular deuda del vecino | BE-010, BE-019 | — | Pendiente | — |
| INT-03 | Anular cobro y restaurar deuda pendiente | BE-014 | — | Pendiente | — |
| INT-04 | Registrar egreso y reflejo en reporte mensual | BE-016, BE-020 | — | Pendiente | — |
| INT-05 | Aprobar egreso y actualizar totales | BE-017, BE-020 | — | Pendiente | — |
| INT-06 | Generar y aprobar reporte mensual | BE-020, BE-021 | — | Pendiente | — |
| INT-07 | Generar lista de asistencia sin duplicados | BE-022 | — | Pendiente | — |
| INT-08 | Confirmar asistencia con ausentes y multas | BE-023 | — | Pendiente | — |

---

## Fase 3 — Pruebas API REST (9)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Evidencia |
|---|---|---|---|---|---|
| API-USR-01 | `GET /api/v1/admin/usuarios` con token válido | BE-009 | — | Pendiente | — |
| API-USR-02 | `GET /api/v1/admin/usuarios/{id}` usuario existente | BE-009 | — | Pendiente | — |
| API-USR-03 | `GET /api/v1/admin/usuarios/{id}` usuario inexistente | BE-024 | — | Pendiente | — |
| API-USR-04 | Búsqueda/filtro de usuarios (vecinos) | BE-009 | — | Pendiente | — |
| API-PAY-01 | `POST /api/v1/admin/cobros` pago válido | BE-011 | — | Pendiente | — |
| API-PAY-02 | `POST` cobro con monto incorrecto | BE-012 | — | Pendiente | — |
| API-PAY-03 | `POST` cobro duplicado mismo periodo | BE-013 | — | Pendiente | — |
| API-REP-01 | `GET /api/v1/admin/reportes` listado | BE-020 | — | Pendiente | — |
| API-REP-02 | Generar reporte parcial mensual | BE-020 | — | Pendiente | — |

**Caso API adicional cubierto (no listado en DOCX):**

| Endpoint | ID BE | Test PHPUnit | Estado |
|---|---|---|---|
| `POST /api/v1/login` credenciales válidas | BE-004 | `ApiAuthBackendTest::test_login_api_devuelve_token_con_credenciales_validas` | **Aprobado** |
| `GET /api/v1/me` sin token | BE-007 | `ApiAuthBackendTest::test_endpoint_me_requiere_autenticacion` | **Aprobado** |

---

## Fase 4 — Pruebas de base de datos (7)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Evidencia |
|---|---|---|---|---|---|
| DB-INT-01 | Integridad referencial usuarios–roles | — | — | Pendiente | — |
| DB-INT-02 | `sp_calcular_deuda_vecino` resultado correcto | BE-010 | — | Pendiente | — |
| DB-INT-03 | `sp_registrar_cobro` genera serie única | BE-011 | — | Pendiente | — |
| DB-INT-04 | Trigger de auditoría en cobros | — | — | Pendiente | — |
| DB-CON-01 | Constraint documento único en vecinos | BE-008 | — | Pendiente | — |
| DB-CON-02 | Rechazo cobro duplicado (procedimiento) | BE-013 | — | Pendiente | — |
| DB-CON-03 | Consistencia totales en reporte mensual | BE-020 | — | Pendiente | — |

---

## Fase 5 — Pruebas E2E (6)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Notas |
|---|---|---|---|---|---|
| E2E-01-CHROME | Flujo completo de cobro en Chrome | — | — | Pendiente | Fuera de alcance backend (`pruebas/README.md`) |
| E2E-01-EDGE | Flujo completo de cobro en Edge | — | — | Pendiente | Fuera de alcance backend |
| E2E-02 | Generar y descargar comprobante PDF | BE-015 | — | Pendiente | Manual / E2E |
| E2E-03 | Módulo de multas desde interfaz admin | BE-019 | — | Pendiente | Manual / E2E |
| E2E-04 | Registrar egreso y verificar en reporte | BE-016, BE-020 | — | Pendiente | Manual / E2E |

---

## Fase 6 — Pruebas de seguridad (11)

| ID DOCX | Descripción (plan) | ID BE | Test PHPUnit | Estado | Evidencia |
|---|---|---|---|---|---|
| SEC-SQL-01 | Login rechaza inyección SQL | — | — | Pendiente | — |
| SEC-SQL-02 | Búsqueda rechaza inyección SQL | — | — | Pendiente | — |
| SEC-SQL-03 | ID en URL rechaza inyección SQL | BE-024 | — | Pendiente | — |
| SEC-BRU-01 | Bloqueo tras 3 intentos fallidos | BE-006 | `ApiAuthBackendTest::test_login_api_bloquea_usuario_tras_tres_intentos_fallidos` | **Aprobado** | `backend/tests/Feature/ApiAuthBackendTest.php` |
| SEC-BRU-02 | Desbloqueo tras tiempo configurado | — | — | Pendiente | — |
| SEC-TOK-01 | API rechaza token expirado | — | — | Pendiente | — |
| SEC-TOK-02 | API rechaza token malformado | — | — | Pendiente | — |
| SEC-TOK-03 | API rechaza solicitud sin token | BE-007 | `ApiAuthBackendTest::test_endpoint_me_requiere_autenticacion` | **Aprobado** | `backend/tests/Feature/ApiAuthBackendTest.php` |
| SEC-ROL-01 | Operador no accede a panel admin | BE-003 | `AdminDashboardTest::test_operador_no_puede_entrar_al_panel_admin` | **Aprobado** | `backend/tests/Feature/AdminDashboardTest.php` |
| SEC-ROL-02 | Operador no accede a gestión de multas | BE-019 | — | Pendiente | — |
| SEC-ROL-03 | Administrador acceso completo | BE-002 | `AdminDashboardTest::test_administrador_autenticado_puede_ver_dashboard` | **Aprobado** (parcial) | `backend/tests/Feature/AdminDashboardTest.php` |

**Caso de seguridad web adicional:**

| Caso | ID BE | Test PHPUnit | Estado |
|---|---|---|---|
| Acceso a `/admin/inicio` sin sesión | BE-001 | `AdminDashboardTest::test_usuario_no_autenticado_es_redireccionado_al_login` | **Aprobado** |
| Raíz `/` redirige a login | — | `ExampleTest::test_la_raiz_redirige_al_login_si_no_hay_sesion` | **Aprobado** |

---

## Matriz BE → DOCX (inversa)

| ID BE | Caso | ID(s) DOCX | Estado |
|---|---|---|---|
| BE-001 | Acceso `/admin/inicio` sin login | SEC-ROL (web), UT-AUTH | **Aprobado** |
| BE-002 | Admin entra al dashboard | UT-AUTH-01, SEC-ROL-03 | **Aprobado** |
| BE-003 | Operador bloqueado en admin | SEC-ROL-01 | **Aprobado** |
| BE-004 | Login API válido | API (login) | **Aprobado** |
| BE-005 | Login API password incorrecto | UT-AUTH-02 | **Aprobado** |
| BE-006 | Tres intentos fallidos API | UT-AUTH-03, SEC-BRU-01 | **Aprobado** |
| BE-007 | `/api/v1/me` sin token | SEC-TOK-03 | **Aprobado** |
| BE-008 | Documento duplicado | DB-CON-01 | Pendiente |
| BE-009 | Búsqueda vecinos | API-USR-01…04 | Pendiente |
| BE-010 | Calcular deuda | UT-CALC-01…06, DB-INT-02 | Pendiente |
| BE-011 | Registrar cobro | UT-PAY-01, API-PAY-01, INT-01 | Pendiente |
| BE-012 | Cobro monto incorrecto | UT-PAY-02, API-PAY-02 | Pendiente |
| BE-013 | Cobro duplicado | UT-PAY-03, API-PAY-03, DB-CON-02 | Pendiente |
| BE-014 | Anular cobro | INT-03 | Pendiente |
| BE-015 | PDF comprobante | INT-01, E2E-02 | Pendiente |
| BE-016 | Registrar egreso | INT-04, E2E-04 | Pendiente |
| BE-017 | Aprobar egreso | INT-05 | Pendiente |
| BE-018 | Rechazar egreso | — | Pendiente |
| BE-019 | Multa/tarifa | INT-02, SEC-ROL-02, E2E-03 | Pendiente |
| BE-020 | Reporte mensual | INT-04…06, API-REP, DB-CON-03 | Pendiente |
| BE-021 | Aprobar reporte | INT-06 | Pendiente |
| BE-022 | Lista asistencia | INT-07 | Pendiente |
| BE-023 | Confirmar asistencia | INT-08 | Pendiente |
| BE-024 | Payload inválido | API-USR-03, SEC-SQL-03 | Pendiente |
| BE-025 | Carga / rendimiento | — | Pendiente |

---

## Cómo mantener sincronizado

1. Al ejecutar un caso manualmente, actualizar **Estado** y **Evidencia** en este archivo y en el DOCX.
2. Al agregar un test PHPUnit, registrar el método en la columna **Test PHPUnit** y marcar **Aprobado**.
3. Usar `composer test` en `backend/` para revalidar los casos automatizados.
4. El reporte de ejecución detallado está en [`reportes/resultados_backend.md`](reportes/resultados_backend.md).
