# Pruebas Backend — J.A.S.S. Quilcata

Índice maestro del plan de pruebas del backend Laravel.

## Alcance

- Backend Laravel 12, API REST v1, autenticación y roles
- Base de datos MariaDB (integración) y SQLite en memoria (rápido)
- Validaciones, control de acceso, cobros, egresos, reportes, asistencia, multas y tarifas

**Fuera de alcance:** diseño visual, CSS, Cypress E2E de interfaz, responsive.

---

## Jerarquía documental

| Archivo | Rol |
|---|---|
| [`plan_implementacion.md`](plan_implementacion.md) | **Roadmap** — fases, cronograma, criterios de cierre |
| [`Plan_Pruebas_JASS_Quilcata_v1.docx`](Plan_Pruebas_JASS_Quilcata_v1.docx) | Plan formal (56 casos) — actualizar al cerrar cada fase |
| [`mapeo_casos_prueba.md`](mapeo_casos_prueba.md) | Trazabilidad DOCX ↔ BE ↔ PHPUnit (fuente viva) |
| [`matriz_casos_backend.md`](matriz_casos_backend.md) | Matriz de 25 casos backend con estado |
| [`correcciones_plan_v1.md`](correcciones_plan_v1.md) | Ajustes al sistema real (rutas, credenciales) |
| [`plan_backend.md`](plan_backend.md) | Redirect → `plan_implementacion.md` |
| [`reportes/`](reportes/) | Evidencia por fase (`fase_00/`, `fase_01/`, …) |

---

## Estado actual (22/06/2026)

| Métrica | Valor |
|---|---|
| Casos plan DOCX | 56 |
| Casos matriz BE | 25 |
| Casos aprobados (DOCX) | 10 |
| Casos aprobados (BE) | 7 |
| Fase en curso | **0 — Fundamentos** |

---

## Comandos de prueba

Desde `backend/`:

```powershell
# Preparar BD de integración: clona jass_quilcata -> jass_quilcata_test + SPs
composer test:setup-db

# Suite rápida — SQLite en memoria (auth, rutas, redirecciones)
composer test

# Suite de integración — MariaDB + procedimientos almacenados
composer test:integration
```

### Requisitos

| Suite | Base de datos | Cuándo usar |
|---|---|---|
| `fast` | SQLite `:memory:` | Desarrollo diario, CI rápido |
| `integration` | `jass_quilcata_test` en MariaDB | Cobros, deuda, reportes, SPs |

MariaDB puede levantarse con Docker (`backend/docker-compose.yml`, puerto **3307**) o XAMPP local.

---

## Estructura de tests

```
backend/tests/
├── Support/           # SqliteTestCase, MariaDbTestCase, traits
├── Feature/           # Suite fast — HTTP/API sin SPs
├── Integration/       # Suite integration — BD y SPs
└── Unit/
```

---

## Flujo de actualización

1. Ejecutar `composer test` y/o `composer test:integration`
2. Registrar resultado en `reportes/fase_XX/resultados.md`
3. Actualizar `mapeo_casos_prueba.md` y `matriz_casos_backend.md`
4. Al cerrar una fase, actualizar el DOCX si aplica

Ver [`plan_implementacion.md`](plan_implementacion.md) para el cronograma completo.
