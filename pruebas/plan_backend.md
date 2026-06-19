# Plan de Pruebas Backend

## Objetivo

Validar que el backend del sistema J.A.S.S. Quilcata funcione correctamente, proteja los datos y mantenga consistencia en la base de datos.

## Modulos a probar

| Modulo | Validacion backend |
|---|---|
| Autenticacion | Login, logout, bloqueo por intentos, token API y sesiones. |
| Roles | Acceso diferenciado para Administrador y Operador. |
| Usuarios / vecinos | Registro, busqueda, filtros, baja logica y deuda asociada. |
| Cobros | Registro de pago, deuda, pendientes, anulacion y comprobantes. |
| Ingresos | Registro manual, validaciones y totales. |
| Egresos | Registro, aprobacion, rechazo y anulacion. |
| Multas y tarifas | CRUD, vigencia, cache de catalogos y aplicacion en calculos. |
| Reportes | Generacion parcial, aprobacion, rechazo y consolidado mensual. |
| Asistencia | Generacion de lista, marcado, confirmacion y multas por ausencia. |
| API REST | Respuestas JSON, codigos HTTP, validaciones y token Bearer. |
| Base de datos | Integridad referencial, transacciones, constraints y procedimientos. |

## Herramientas

| Herramienta | Uso |
|---|---|
| PHPUnit / Laravel Testing | Pruebas Unit y Feature del backend. |
| Postman / Newman | Pruebas de endpoints API REST. |
| MariaDB / phpMyAdmin | Verificacion de datos persistidos. |
| k6 | Pruebas de rendimiento en endpoints criticos. |
| Docker Compose | Entorno reproducible para backend, Nginx y base de datos. |

## Criterios de aceptacion

- Las rutas protegidas rechazan usuarios no autenticados.
- El login correcto crea sesion o token valido.
- Los roles no pueden acceder a zonas no permitidas.
- Los datos invalidos son rechazados con errores controlados.
- Los cobros y reportes mantienen consistencia en base de datos.
- No deben existir registros financieros duplicados o corruptos.
- Los endpoints criticos deben mantener tasa de error menor a 1% bajo carga controlada.

## Criterios de rechazo

- Un operador puede entrar a rutas administrativas.
- Un usuario sin token accede a endpoints protegidos.
- Un cobro queda guardado parcialmente ante error.
- El calculo de deuda no coincide con cuotas, pendientes y multas.
- El reporte mensual no coincide con ingresos y egresos registrados.
