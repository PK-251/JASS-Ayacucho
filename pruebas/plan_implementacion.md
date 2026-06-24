# Plan de implementación — Pruebas JASS Quilcata

Roadmap de ejecución del plan formal ([`Plan_Pruebas_JASS_Quilcata_v1.docx`](Plan_Pruebas_JASS_Quilcata_v1.docx)). El estado vivo de cada caso está en [`mapeo_casos_prueba.md`](mapeo_casos_prueba.md) y [`matriz_casos_backend.md`](matriz_casos_backend.md).

**Última actualización:** 22/06/2026

---

## Situación actual

| Elemento | Estado |
|---|---|
| Casos DOCX (56) | 10 aprobados, 46 pendientes |
| Matriz BE (25) | 7 aprobados, 18 pendientes |
| PHPUnit | Suite `fast` (SQLite) + suite `integration` (MariaDB) |
| Entorno | `fast` para auth/rutas; `integration` obligatoria para SPs financieros |

---

## Jerarquía documental

```
Plan_Pruebas_JASS_Quilcata_v1.docx
        ↓
plan_implementacion.md  ← este archivo
        ↓
mapeo_casos_prueba.md
        ↓
matriz_casos_backend.md
        ↓
reportes/fase_XX/
```

| Archivo | Rol |
|---|---|
| [`README.md`](README.md) | Índice maestro, comandos, enlaces |
| [`plan_implementacion.md`](plan_implementacion.md) | Fases, cronograma, criterios de cierre |
| [`Plan_Pruebas_JASS_Quilcata_v1.docx`](Plan_Pruebas_JASS_Quilcata_v1.docx) | Plan formal — actualizar al cerrar cada fase |
| [`mapeo_casos_prueba.md`](mapeo_casos_prueba.md) | Trazabilidad DOCX ↔ BE ↔ PHPUnit |
| [`matriz_casos_backend.md`](matriz_casos_backend.md) | Vista resumida BE con estado |
| [`correcciones_plan_v1.md`](correcciones_plan_v1.md) | Referencia técnica (rutas, credenciales) |
| [`reportes/fase_XX/`](reportes/) | Evidencia por fase |

### Convención de IDs y estados

- **DOCX:** `UT-AUTH-01`, `INT-01`, `API-USR-01`, etc.
- **BE:** `BE-001` … `BE-025`
- **PHPUnit:** `tests/Feature/Api/CobroApiTest.php::test_registra_cobro_valido`

Estados: `Pendiente` → `EnProceso` → `Aprobado` | `Fallido` | `Bloqueado`

---

## Fase 0 — Fundamentos

**Objetivo:** Infraestructura reproducible antes de escribir tests de negocio.

**Entregables:**

1. BD `jass_quilcata_test` en MariaDB (puerto 3307, ver [`backend/.env.testing`](../backend/.env.testing))
2. Dos suites PHPUnit: `fast` (SQLite) e `integration` (MariaDB)
3. Clases base en `backend/tests/Support/`
4. Factories mínimos y `TestBaselineSeeder`
5. Scripts `composer test` y `composer test:integration`

**Criterio de cierre:** `composer test` y `composer test:integration` ejecutan sin error; al menos 1 test de humo en MariaDB (`SELECT 1` + `CALL sp_calcular_deuda_vecino`).

**Comandos:**

```powershell
cd backend
composer test:setup-db      # Clona jass_quilcata -> jass_quilcata_test + SPs
composer test               # Suite fast (SQLite)
composer test:integration   # Suite integration (MariaDB)
```

`test:setup-db` importa el dump completo solo si `jass_quilcata` no existe; luego clona a `jass_quilcata_test` e instala `sp_calcular_deuda_vecino`.

---

## Fase 1 — Auth y seguridad base

**Duración:** 3–5 días | **Entorno:** SQLite + MariaDB

| Casos DOCX | Casos BE | Archivos PHPUnit |
|---|---|---|
| UT-AUTH-04, UT-AUTH-05 | — | `Feature/Web/LoginWebTest.php` |
| SEC-TOK-01, SEC-TOK-02 | BE-024 (parcial) | `Feature/Api/AuthApiTest.php` |
| SEC-ROL-02 | BE-019 (acceso) | `Feature/Web/RoleAccessTest.php` |
| SEC-SQL-01 … SEC-SQL-03 | BE-024 | `Feature/Security/SqlInjectionTest.php` |

**Criterio de cierre:** 8 casos DOCX adicionales; suite `fast` ≥ 20 tests.

---

## Fase 2 — Vecinos, validaciones y API usuarios

**Duración:** 5–7 días | **Entorno:** MariaDB

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| API-USR-01 … API-USR-04 | BE-009 | `Feature/Api/UsuarioApiTest.php` |
| DB-CON-01 | BE-008 | `Integration/Database/VecinoConstraintsTest.php` |

**Criterio de cierre:** CRUD/listado/filtro vía API; documento duplicado rechazado con 422.

---

## Fase 3 — Cálculo de deuda y cobros (crítico)

**Duración:** 7–10 días | **Entorno:** MariaDB obligatorio

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| UT-CALC-01 … UT-CALC-06 | BE-010 | `Integration/Database/DeudaCalculationTest.php` |
| UT-PAY-01 … UT-PAY-04 | BE-011…013 | `Feature/Api/CobroApiTest.php` |
| API-PAY-01 … API-PAY-03 | BE-011…013 | mismo |
| DB-INT-02, DB-INT-03, DB-CON-02 | BE-010, BE-013 | `Integration/Database/CobroStoredProcTest.php` |

**Criterio de cierre:** 15 casos DOCX; cobro feliz + rechazos sin datos parciales verificados en BD.

---

## Fase 4 — Egresos, ingresos y anulaciones

**Duración:** 5–7 días | **Entorno:** MariaDB

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| INT-03 | BE-014 | `Feature/Api/CobroAnulacionTest.php` |
| INT-04, INT-05 | BE-016…018 | `Feature/Api/EgresoApiTest.php` |
| DB-INT-04 | — | `Integration/Database/AuditLogTest.php` |

---

## Fase 5 — Multas y tarifas

**Duración:** 4–5 días | **Entorno:** MariaDB

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| INT-02 | BE-019 | `Feature/Api/MultaTarifaApiTest.php` |
| SEC-ROL-02 (completo) | BE-019 | `Feature/Web/MultaAccessTest.php` |

---

## Fase 6 — Reportes mensuales

**Duración:** 5–7 días | **Entorno:** MariaDB

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| API-REP-01, API-REP-02 | BE-020 | `Feature/Api/ReporteApiTest.php` |
| INT-06 | BE-021 | mismo |
| DB-CON-03 | BE-020 | `Integration/Database/ReporteConsistencyTest.php` |

---

## Fase 7 — Asistencia e integración de flujos

**Duración:** 5–7 días | **Entorno:** MariaDB

| Casos DOCX | Casos BE | Tests |
|---|---|---|
| INT-07 | BE-022 | `Feature/Api/AsistenciaApiTest.php` |
| INT-08 | BE-023 | mismo |
| INT-01 | BE-011, BE-015 | `Feature/Integration/CobroCompletoTest.php` |
| DB-INT-01 | — | `Integration/Database/ReferentialIntegrityTest.php` |

---

## Fase 8 — Cierre, PDF, rendimiento y reporte final

**Duración:** 3–5 días

| Casos DOCX | Enfoque |
|---|---|
| BE-015, E2E-02 | `Feature/Web/CobroPdfTest.php` |
| BE-025 | Script k6 en `pruebas/load/` |
| E2E-01/03/04 | Checklist manual en `pruebas/manual/checklist_e2e.md` |
| Sección 10 DOCX | Reporte final con métricas de `mapeo_casos_prueba.md` |

**Criterio de cierre:** 56/56 casos documentados; `composer test` + `composer test:integration` en CI local.

---

## Estructura PHPUnit objetivo

```
backend/tests/
├── Support/
│   ├── SqliteTestCase.php
│   ├── MariaDbTestCase.php
│   └── Concerns/
│       ├── AuthenticatesApi.php
│       ├── CreatesVecinos.php
│       └── CreatesCobros.php
├── Feature/
│   ├── Api/
│   ├── Web/
│   ├── Security/
│   └── Integration/
├── Integration/
│   └── Database/
└── Unit/
```

---

## Flujo de trabajo por fase

1. Implementar tests y helpers
2. Ejecutar `composer test` y/o `composer test:integration`
3. Actualizar `mapeo_casos_prueba.md` y `matriz_casos_backend.md`
4. Registrar resultado en `reportes/fase_XX/resultados.md`
5. No avanzar con casos **Fallido** sin defecto registrado

---

## Cronograma sugerido

| Fase | Contenido | Casos nuevos ~ | Semanas |
|---|---|---:|---|
| 0 | Fundamentos | 1 humo | 1 |
| 1 | Auth/Seguridad | 8 | 1 |
| 2 | Vecinos/API | 5 | 1 |
| 3 | Deuda/Cobros | 15 | 1.5 |
| 4 | Egresos/Anulación | 6 | 1 |
| 5 | Multas | 3 | 0.5 |
| 6 | Reportes | 5 | 1 |
| 7 | Asistencia/Integración | 5 | 1 |
| 8 | Cierre/PDF/k6 | 8 | 0.5 |
| **Total** | | **~46 pendientes** | **~8 semanas** |

---

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| SPs no disponibles en SQLite | Suite `integration` obligatoria desde Fase 3 |
| Tests lentos con MariaDB | `fast` para CI rápido; `integration` en pre-commit o nightly |
| Esquema manual duplicado en SQLite | Centralizar en `SqliteTestCase::createMinimalSchema()` |
| DOCX desincronizado | Solo actualizar al cerrar fase; estado vivo en markdown |
| `UserFactory` desactualizado | Corregido en Fase 0 |
