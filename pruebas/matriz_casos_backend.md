# Matriz de Casos de Prueba Backend

| ID | Caso | Tipo | Resultado esperado |
|---|---|---|---|
| BE-001 | Acceder a `/admin/inicio` sin login. | Feature | Redireccion a `/login`. |
| BE-002 | Administrador autenticado entra al dashboard. | Feature | HTTP 200 y contenido del dashboard. |
| BE-003 | Operador intenta entrar al panel admin. | Feature | Redireccion a `/operador/inicio`. |
| BE-004 | Login API con credenciales validas. | API | HTTP 200 y token Bearer. |
| BE-005 | Login API con password incorrecto. | API | HTTP 422 e intento registrado. |
| BE-006 | Tres intentos fallidos de login API. | API | Usuario bloqueado. |
| BE-007 | Consultar `/api/v1/me` sin token. | Seguridad API | HTTP 401. |
| BE-008 | Crear usuario con documento duplicado. | Validacion | Error 422 o validacion equivalente. |
| BE-009 | Buscar vecino por codigo/nombre/documento. | API/BD | Lista filtrada y paginada. |
| BE-010 | Calcular deuda de vecino. | BD | Desglose correcto de cuota, pendientes y multas. |
| BE-011 | Registrar cobro correcto. | Integracion | Cobro pagado y comprobante creado. |
| BE-012 | Registrar cobro con monto incorrecto. | Validacion | Operacion rechazada sin datos parciales. |
| BE-013 | Cobro duplicado mismo periodo. | BD | Procedimiento rechaza duplicidad. |
| BE-014 | Anular cobro. | Integracion | Deudas y multas vuelven a pendiente. |
| BE-015 | Generar comprobante PDF. | Backend/PDF | Descarga y datos correctos. |
| BE-016 | Registrar egreso. | Feature/API | Estado correcto segun aprobacion. |
| BE-017 | Aprobar egreso. | Feature/API | Estado aprobado y fecha registrada. |
| BE-018 | Rechazar egreso. | Feature/API | Estado rechazado y motivo guardado. |
| BE-019 | Crear multa/tarifa. | Feature/API | Registro creado e invalidacion de cache. |
| BE-020 | Generar reporte mensual. | BD | Totales consistentes con cobros/ingresos/egresos. |
| BE-021 | Aprobar reporte mensual. | Feature/API | Estado aprobado y datos oficiales. |
| BE-022 | Generar lista de asistencia. | Integracion | Asistencias creadas sin duplicados. |
| BE-023 | Confirmar asistencia con ausentes. | Integracion | Lista cerrada y multas aplicadas. |
| BE-024 | Enviar payload invalido. | Validacion | HTTP 422 o error controlado. |
| BE-025 | Carga sobre login/dashboard/cobros. | Rendimiento | P95 aceptable y error menor a 1%. |
