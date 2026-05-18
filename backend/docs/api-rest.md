# API REST v1 - JASS Quilcata

Base local:

```text
http://127.0.0.1:8000/api/v1
```

## Autenticacion

### Login

```http
POST /api/v1/login
Accept: application/json
Content-Type: application/json

{
  "username": "admin_jass",
  "password": "admin123",
  "device_name": "postman"
}
```

Respuesta: devuelve `access_token`. En las siguientes peticiones usar:

```http
Authorization: Bearer TU_TOKEN
Accept: application/json
```

Usuarios demo:

- Administrador: `admin_jass / admin123`
- Operador: `joacim_huanca / operador123`

### Perfil y salida

```http
GET /api/v1/me
POST /api/v1/logout
```

## Rutas comunes

```http
GET /api/v1/catalogos
```

## Administrador

```http
GET    /api/v1/admin/dashboard
GET    /api/v1/admin/usuarios
POST   /api/v1/admin/usuarios
GET    /api/v1/admin/usuarios/{usuario}
PATCH  /api/v1/admin/usuarios/{usuario}
DELETE /api/v1/admin/usuarios/{usuario}
GET    /api/v1/admin/usuarios/{usuario}/deuda?anio=2026&mes=5

GET    /api/v1/admin/cobros
POST   /api/v1/admin/cobros
GET    /api/v1/admin/cobros/{cobro}
GET    /api/v1/admin/cobros/usuarios/{usuario}/deuda?anio=2026&mes=5
POST   /api/v1/admin/cobros/usuarios/{usuario}/pendiente

GET    /api/v1/admin/ingresos
POST   /api/v1/admin/ingresos
PATCH  /api/v1/admin/ingresos/{ingreso}
DELETE /api/v1/admin/ingresos/{ingreso}

GET    /api/v1/admin/egresos
POST   /api/v1/admin/egresos
PATCH  /api/v1/admin/egresos/{egreso}
DELETE /api/v1/admin/egresos/{egreso}
POST   /api/v1/admin/egresos/{egreso}/aprobar
POST   /api/v1/admin/egresos/{egreso}/rechazar

GET    /api/v1/admin/multas-tarifas
POST   /api/v1/admin/multas
PUT    /api/v1/admin/multas/{multa}
DELETE /api/v1/admin/multas/{multa}
POST   /api/v1/admin/tarifas

GET    /api/v1/admin/reportes
POST   /api/v1/admin/reportes/parcial
GET    /api/v1/admin/reportes/{reporte}
POST   /api/v1/admin/reportes/{reporte}/aprobar
POST   /api/v1/admin/reportes/{reporte}/rechazar

GET    /api/v1/admin/asistencia
GET    /api/v1/admin/asistencia/{evento}
POST   /api/v1/admin/asistencia/{evento}/generar-lista
PATCH  /api/v1/admin/asistencia/marca/{asistencia}
POST   /api/v1/admin/asistencia/{evento}/confirmar
```

## Operador

```http
GET  /api/v1/operador/dashboard
GET  /api/v1/operador/cobros
POST /api/v1/operador/cobros/iniciar-jornada
POST /api/v1/operador/cobros/cerrar-jornada
GET  /api/v1/operador/cobros/usuarios/{usuario}/deuda?anio=2026&mes=5
POST /api/v1/operador/cobros/usuarios/{usuario}/pendiente
POST /api/v1/operador/cobros
GET  /api/v1/operador/cobros/{cobro}

GET   /api/v1/operador/asistencia
GET   /api/v1/operador/asistencia/{evento}
PATCH /api/v1/operador/asistencia/marca/{asistencia}
POST  /api/v1/operador/asistencia/{evento}/confirmar
```

## Ejemplo: registrar cobro

```http
POST /api/v1/admin/cobros
Authorization: Bearer TU_TOKEN
Accept: application/json
Content-Type: application/json

{
  "vecino_id": 2,
  "periodo_anio": 2026,
  "periodo_mes": 5,
  "monto_recibido": 4.00,
  "metodo_pago": "efectivo",
  "observaciones": "Pago desde API"
}
```

La API reutiliza procedimientos almacenados para cobros, deuda, reportes y auditoria.
