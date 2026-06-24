# Matriz de Casos de Prueba Backend

Trazabilidad con el plan unificado: ver [`mapeo_casos_prueba.md`](mapeo_casos_prueba.md).

| ID | ID DOCX | Caso | Tipo | Resultado esperado | Estado | Evidencia |
|---|---|---|---|---|---|---|
| BE-001 | SEC-ROL (web) | Acceder a `/admin/inicio` sin login. | Feature | Redireccion a `/login`. | **Aprobado** | `AdminDashboardTest::test_usuario_no_autenticado_es_redireccionado_al_login` |
| BE-002 | UT-AUTH-01, SEC-ROL-03 | Administrador autenticado entra al dashboard. | Feature | HTTP 200 y contenido del dashboard. | **Aprobado** | `AdminDashboardTest::test_administrador_autenticado_puede_ver_dashboard` |
| BE-003 | SEC-ROL-01 | Operador intenta entrar al panel admin. | Feature | Redireccion a `/operador/inicio`. | **Aprobado** | `AdminDashboardTest::test_operador_no_puede_entrar_al_panel_admin` |
| BE-004 | API (login) | Login API con credenciales validas. | API | HTTP 200 y token Bearer. | **Aprobado** | `ApiAuthBackendTest::test_login_api_devuelve_token_con_credenciales_validas` |
| BE-005 | UT-AUTH-02 | Login API con password incorrecto. | API | HTTP 422 e intento registrado. | **Aprobado** | `ApiAuthBackendTest::test_login_api_rechaza_password_incorrecto_y_registra_intento` |
| BE-006 | UT-AUTH-03, SEC-BRU-01 | Tres intentos fallidos de login API. | API | Usuario bloqueado. | **Aprobado** | `ApiAuthBackendTest::test_login_api_bloquea_usuario_tras_tres_intentos_fallidos` |
| BE-007 | SEC-TOK-03 | Consultar `/api/v1/me` sin token. | Seguridad API | HTTP 401. | **Aprobado** | `ApiAuthBackendTest::test_endpoint_me_requiere_autenticacion` |
| BE-008 | DB-CON-01 | Crear usuario con documento duplicado. | Validacion | Error 422 o validacion equivalente. | Pendiente | — |
| BE-009 | API-USR-01…04 | Buscar vecino por codigo/nombre/documento. | API/BD | Lista filtrada y paginada. | Pendiente | — |
| BE-010 | UT-CALC-01…06, DB-INT-02 | Calcular deuda de vecino. | BD | Desglose correcto de cuota, pendientes y multas. | Pendiente | — |
| BE-011 | UT-PAY-01, API-PAY-01, INT-01 | Registrar cobro correcto. | Integracion | Cobro pagado y comprobante creado. | Pendiente | — |
| BE-012 | UT-PAY-02, API-PAY-02 | Registrar cobro con monto incorrecto. | Validacion | Operacion rechazada sin datos parciales. | Pendiente | — |
| BE-013 | UT-PAY-03, API-PAY-03, DB-CON-02 | Cobro duplicado mismo periodo. | BD | Procedimiento rechaza duplicidad. | Pendiente | — |
| BE-014 | INT-03 | Anular cobro. | Integracion | Deudas y multas vuelven a pendiente. | Pendiente | — |
| BE-015 | INT-01, E2E-02 | Generar comprobante PDF. | Backend/PDF | Descarga y datos correctos. | Pendiente | — |
| BE-016 | INT-04, E2E-04 | Registrar egreso. | Feature/API | Estado correcto segun aprobacion. | Pendiente | — |
| BE-017 | INT-05 | Aprobar egreso. | Feature/API | Estado aprobado y fecha registrada. | Pendiente | — |
| BE-018 | — | Rechazar egreso. | Feature/API | Estado rechazado y motivo guardado. | Pendiente | — |
| BE-019 | INT-02, SEC-ROL-02, E2E-03 | Crear multa/tarifa. | Feature/API | Registro creado e invalidacion de cache. | Pendiente | — |
| BE-020 | INT-04…06, API-REP, DB-CON-03 | Generar reporte mensual. | BD | Totales consistentes con cobros/ingresos/egresos. | Pendiente | — |
| BE-021 | INT-06 | Aprobar reporte mensual. | Feature/API | Estado aprobado y datos oficiales. | Pendiente | — |
| BE-022 | INT-07 | Generar lista de asistencia. | Integracion | Asistencias creadas sin duplicados. | Pendiente | — |
| BE-023 | INT-08 | Confirmar asistencia con ausentes. | Integracion | Lista cerrada y multas aplicadas. | Pendiente | — |
| BE-024 | API-USR-03, SEC-SQL-03 | Enviar payload invalido. | Validacion | HTTP 422 o error controlado. | Pendiente | — |
| BE-025 | — | Carga sobre login/dashboard/cobros. | Rendimiento | P95 aceptable y error menor a 1%. | Pendiente | — |
