-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 7: Reportes Mensuales
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 21: reportes_mensuales
-- Reportes consolidados auto-generados al cierre de cada mes.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reportes_mensuales (
    id                              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    periodo_anio                    SMALLINT UNSIGNED NOT NULL,
    periodo_mes                     TINYINT UNSIGNED NOT NULL,
    fecha_inicio_periodo            DATE NOT NULL,
    fecha_fin_periodo               DATE NOT NULL,

    estado                          ENUM('en_proceso','pendiente_aprobacion','aprobado','rechazado')
                                    NOT NULL DEFAULT 'en_proceso',

    total_ingresos                  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    num_cobros                      INT UNSIGNED NOT NULL DEFAULT 0,
    num_ingresos_manuales           INT UNSIGNED NOT NULL DEFAULT 0,
    total_cuotas                    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_multas_cobradas           DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_cuotas_extraordinarias    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_donaciones                DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_otros_ingresos            DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    total_egresos                   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    num_egresos                     INT UNSIGNED NOT NULL DEFAULT 0,
    total_materiales                DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_personal                  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_mantenimiento             DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_combustible               DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_servicios                 DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total_otros_egresos             DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    balance_neto                    DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    num_vecinos_total               INT UNSIGNED NOT NULL DEFAULT 0,
    num_vecinos_al_dia              INT UNSIGNED NOT NULL DEFAULT 0,
    num_vecinos_morosos             INT UNSIGNED NOT NULL DEFAULT 0,
    deuda_acumulada                 DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    porcentaje_morosidad            DECIMAL(5,2) NOT NULL DEFAULT 0.00,

    delta_ingresos                  DECIMAL(12,2) NULL,
    delta_egresos                   DECIMAL(12,2) NULL,
    delta_balance                   DECIMAL(12,2) NULL,
    delta_morosos                   INT NULL,

    desglose_ingresos_json          JSON NULL,
    desglose_egresos_json           JSON NULL,
    top_morosos_json                JSON NULL,
    proyeccion_siguiente_mes_json   JSON NULL,

    fecha_generacion                TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    generado_por_sistema            BOOLEAN NOT NULL DEFAULT TRUE,
    es_reporte_parcial              BOOLEAN NOT NULL DEFAULT FALSE,

    aprobado_por                    BIGINT UNSIGNED NULL,
    fecha_aprobacion                TIMESTAMP NULL,
    observaciones_admin             VARCHAR(2000) NULL,

    rechazado_por                   BIGINT UNSIGNED NULL,
    fecha_rechazo                   TIMESTAMP NULL,
    motivo_rechazo                  VARCHAR(2000) NULL,
    areas_revisar_json              JSON NULL,
    version                         TINYINT UNSIGNED NOT NULL DEFAULT 1,

    ruta_pdf_borrador               VARCHAR(500) NULL,
    ruta_pdf_oficial                VARCHAR(500) NULL,
    hash_pdf_oficial                VARCHAR(64) NULL,

    created_at                      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_reportes_aprobador FOREIGN KEY (aprobado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_reportes_rechazador FOREIGN KEY (rechazado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_reporte_periodo CHECK (periodo_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_reporte_balance CHECK (balance_neto = total_ingresos - total_egresos),

    UNIQUE KEY uk_reporte_periodo (periodo_anio, periodo_mes, es_reporte_parcial),

    INDEX idx_reportes_periodo (periodo_anio, periodo_mes),
    INDEX idx_reportes_estado (estado),
    INDEX idx_reportes_fechas (fecha_inicio_periodo, fecha_fin_periodo),
    INDEX idx_reportes_generacion (fecha_generacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Reportes mensuales auto-generados';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);

INSERT INTO reportes_mensuales
    (periodo_anio, periodo_mes, fecha_inicio_periodo, fecha_fin_periodo, estado,
     total_ingresos, num_cobros, num_ingresos_manuales,
     total_cuotas, total_multas_cobradas, total_cuotas_extraordinarias,
     total_donaciones, total_otros_ingresos,
     total_egresos, num_egresos,
     total_materiales, total_personal, total_mantenimiento,
     total_combustible, total_servicios, total_otros_egresos,
     balance_neto,
     num_vecinos_total, num_vecinos_al_dia, num_vecinos_morosos,
     deuda_acumulada, porcentaje_morosidad,
     delta_ingresos, delta_egresos, delta_balance, delta_morosos,
     desglose_ingresos_json, desglose_egresos_json, top_morosos_json,
     proyeccion_siguiente_mes_json,
     fecha_generacion, ruta_pdf_borrador)
VALUES (
    2026, 5, '2026-05-01', '2026-05-31', 'pendiente_aprobacion',
    1840.00, 129, 27,
    1548.00, 92.00, 130.00, 50.00, 20.00,
    620.50, 18,
    220.00, 180.00, 120.00, 60.50, 78.00, 40.00,
    1219.50,
    124, 87, 37, 348.00, 29.84,
    12.5, -8.1, 27.0, -4,
    JSON_OBJECT(
        'cuotas_mensuales', JSON_OBJECT('total', 1548.00, 'porcentaje', 84.1),
        'multas_cobradas', JSON_OBJECT('total', 92.00, 'porcentaje', 5.0),
        'cuotas_extraordinarias', JSON_OBJECT('total', 130.00, 'porcentaje', 7.1),
        'donaciones', JSON_OBJECT('total', 50.00, 'porcentaje', 2.7),
        'otros', JSON_OBJECT('total', 20.00, 'porcentaje', 1.1)
    ),
    JSON_OBJECT(
        'materiales', JSON_OBJECT('total', 220.00, 'porcentaje', 35.5),
        'personal', JSON_OBJECT('total', 180.00, 'porcentaje', 29.0),
        'mantenimiento', JSON_OBJECT('total', 120.00, 'porcentaje', 19.3),
        'combustible', JSON_OBJECT('total', 60.50, 'porcentaje', 9.7),
        'servicios', JSON_OBJECT('total', 78.00, 'porcentaje', 12.6),
        'otros', JSON_OBJECT('total', 40.00, 'porcentaje', 6.5)
    ),
    JSON_ARRAY(
        JSON_OBJECT('codigo', 'U-0007', 'nombre', 'Ana Flores', 'deuda', 24.00, 'meses_pendientes', 6),
        JSON_OBJECT('codigo', 'U-0006', 'nombre', 'Rosa Mamani', 'deuda', 16.00, 'meses_pendientes', 2),
        JSON_OBJECT('codigo', 'U-0004', 'nombre', 'Lucia Condori', 'deuda', 8.00, 'meses_pendientes', 1)
    ),
    JSON_OBJECT(
        'ingresos_esperados', 1852.00,
        'deudas_a_cobrar', 348.00,
        'egresos_comprometidos', 580.00
    ),
    '2026-05-31 23:59:00',
    '/storage/reportes/2026/borrador_mayo_2026_v1.pdf'
)
ON DUPLICATE KEY UPDATE
    estado = VALUES(estado),
    total_ingresos = VALUES(total_ingresos),
    num_cobros = VALUES(num_cobros),
    num_ingresos_manuales = VALUES(num_ingresos_manuales),
    total_cuotas = VALUES(total_cuotas),
    total_multas_cobradas = VALUES(total_multas_cobradas),
    total_cuotas_extraordinarias = VALUES(total_cuotas_extraordinarias),
    total_donaciones = VALUES(total_donaciones),
    total_otros_ingresos = VALUES(total_otros_ingresos),
    total_egresos = VALUES(total_egresos),
    num_egresos = VALUES(num_egresos),
    total_materiales = VALUES(total_materiales),
    total_personal = VALUES(total_personal),
    total_mantenimiento = VALUES(total_mantenimiento),
    total_combustible = VALUES(total_combustible),
    total_servicios = VALUES(total_servicios),
    total_otros_egresos = VALUES(total_otros_egresos),
    balance_neto = VALUES(balance_neto),
    num_vecinos_total = VALUES(num_vecinos_total),
    num_vecinos_al_dia = VALUES(num_vecinos_al_dia),
    num_vecinos_morosos = VALUES(num_vecinos_morosos),
    deuda_acumulada = VALUES(deuda_acumulada),
    porcentaje_morosidad = VALUES(porcentaje_morosidad),
    delta_ingresos = VALUES(delta_ingresos),
    delta_egresos = VALUES(delta_egresos),
    delta_balance = VALUES(delta_balance),
    delta_morosos = VALUES(delta_morosos),
    desglose_ingresos_json = VALUES(desglose_ingresos_json),
    desglose_egresos_json = VALUES(desglose_egresos_json),
    top_morosos_json = VALUES(top_morosos_json),
    proyeccion_siguiente_mes_json = VALUES(proyeccion_siguiente_mes_json),
    fecha_generacion = VALUES(fecha_generacion),
    ruta_pdf_borrador = VALUES(ruta_pdf_borrador),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO reportes_mensuales
    (periodo_anio, periodo_mes, fecha_inicio_periodo, fecha_fin_periodo, estado,
     total_ingresos, num_cobros, num_ingresos_manuales,
     total_egresos, num_egresos,
     balance_neto,
     num_vecinos_total, num_vecinos_al_dia, num_vecinos_morosos,
     deuda_acumulada, porcentaje_morosidad,
     fecha_generacion, aprobado_por, fecha_aprobacion, observaciones_admin,
     ruta_pdf_oficial, hash_pdf_oficial)
VALUES
(2026, 4, '2026-04-01', '2026-04-30', 'aprobado',
 1635.00, 102, 18, 675.00, 22, 960.00,
 124, 83, 41, 380.00, 33.06,
 '2026-04-30 23:59:00', @admin_jass_id, '2026-05-02 10:30:00',
 'Reporte revisado y conforme. Aprobado para presentacion en asamblea.',
 '/storage/reportes/2026/oficial_abril_2026.pdf',
 'a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef1234567890'),
(2026, 3, '2026-03-01', '2026-03-31', 'aprobado',
 1720.00, 118, 12, 610.00, 16, 1110.00,
 124, 90, 34, 320.00, 27.42,
 '2026-03-31 23:59:00', @admin_jass_id, '2026-04-03 14:15:00',
 'Aprobado en sesion.',
 '/storage/reportes/2026/oficial_marzo_2026.pdf',
 'b2c3d4e5f67890a1bcdef234567890abcdef1234567890abcdef1234567890ab'),
(2026, 2, '2026-02-01', '2026-02-28', 'aprobado',
 1640.00, 110, 14, 590.00, 17, 1050.00,
 124, 88, 36, 340.00, 29.03,
 '2026-02-28 23:59:00', @admin_jass_id, '2026-03-02 09:00:00',
 'OK',
 '/storage/reportes/2026/oficial_febrero_2026.pdf',
 'c3d4e5f67890a1b2cdef34567890abcdef1234567890abcdef1234567890abc1'),
(2026, 1, '2026-01-01', '2026-01-31', 'aprobado',
 1560.00, 105, 10, 520.00, 15, 1040.00,
 122, 86, 36, 312.00, 29.51,
 '2026-01-31 23:59:00', @admin_jass_id, '2026-02-03 11:30:00',
 'Primer reporte del ano fiscal 2026.',
 '/storage/reportes/2026/oficial_enero_2026.pdf',
 'd4e5f67890a1b2c3def4567890abcdef1234567890abcdef1234567890abcd12')
ON DUPLICATE KEY UPDATE
    estado = VALUES(estado),
    total_ingresos = VALUES(total_ingresos),
    num_cobros = VALUES(num_cobros),
    num_ingresos_manuales = VALUES(num_ingresos_manuales),
    total_egresos = VALUES(total_egresos),
    num_egresos = VALUES(num_egresos),
    balance_neto = VALUES(balance_neto),
    num_vecinos_total = VALUES(num_vecinos_total),
    num_vecinos_al_dia = VALUES(num_vecinos_al_dia),
    num_vecinos_morosos = VALUES(num_vecinos_morosos),
    deuda_acumulada = VALUES(deuda_acumulada),
    porcentaje_morosidad = VALUES(porcentaje_morosidad),
    aprobado_por = VALUES(aprobado_por),
    fecha_aprobacion = VALUES(fecha_aprobacion),
    observaciones_admin = VALUES(observaciones_admin),
    ruta_pdf_oficial = VALUES(ruta_pdf_oficial),
    hash_pdf_oficial = VALUES(hash_pdf_oficial),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO reportes_mensuales
    (periodo_anio, periodo_mes, fecha_inicio_periodo, fecha_fin_periodo, estado,
     total_ingresos, total_egresos, balance_neto,
     num_vecinos_total, num_vecinos_al_dia, num_vecinos_morosos,
     deuda_acumulada, porcentaje_morosidad,
     fecha_generacion, rechazado_por, fecha_rechazo, motivo_rechazo,
     areas_revisar_json, version)
VALUES
(2025, 12, '2025-12-01', '2025-12-31', 'rechazado',
 1420.00, 480.00, 940.00,
 120, 78, 42, 420.00, 35.00,
 '2025-12-31 23:59:00', @admin_jass_id, '2026-01-04 10:00:00',
 'Inconsistencia en egresos: faltan dos boletas de combustible no registradas. Revisar y regenerar.',
 JSON_ARRAY('inconsistencia_egresos', 'comprobantes_faltantes'),
 1)
ON DUPLICATE KEY UPDATE
    estado = VALUES(estado),
    total_ingresos = VALUES(total_ingresos),
    total_egresos = VALUES(total_egresos),
    balance_neto = VALUES(balance_neto),
    num_vecinos_total = VALUES(num_vecinos_total),
    num_vecinos_al_dia = VALUES(num_vecinos_al_dia),
    num_vecinos_morosos = VALUES(num_vecinos_morosos),
    deuda_acumulada = VALUES(deuda_acumulada),
    porcentaje_morosidad = VALUES(porcentaje_morosidad),
    rechazado_por = VALUES(rechazado_por),
    fecha_rechazo = VALUES(fecha_rechazo),
    motivo_rechazo = VALUES(motivo_rechazo),
    areas_revisar_json = VALUES(areas_revisar_json),
    version = VALUES(version),
    updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_reporte_generar_snapshot $$
CREATE PROCEDURE sp_reporte_generar_snapshot(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED,
    IN p_es_parcial BOOLEAN,
    OUT p_reporte_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_fin DATE;
    DECLARE v_total_ingresos DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_egresos DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_num_cobros INT UNSIGNED DEFAULT 0;
    DECLARE v_num_ingresos INT UNSIGNED DEFAULT 0;
    DECLARE v_num_egresos INT UNSIGNED DEFAULT 0;
    DECLARE v_total_vecinos INT UNSIGNED DEFAULT 0;
    DECLARE v_num_morosos INT UNSIGNED DEFAULT 0;
    DECLARE v_deuda DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_reporte_existente BIGINT UNSIGNED DEFAULT NULL;

    IF p_mes NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mes de reporte no valido';
    END IF;

    SET v_inicio = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');
    SET v_fin = LAST_DAY(v_inicio);

    SELECT COALESCE(SUM(monto), 0),
           SUM(CASE WHEN origen = 'cobro' THEN 1 ELSE 0 END),
           SUM(CASE WHEN origen = 'manual' THEN 1 ELSE 0 END)
    INTO v_total_ingresos, v_num_cobros, v_num_ingresos
    FROM vista_ingresos_completa
    WHERE YEAR(fecha_ingreso) = p_anio
      AND MONTH(fecha_ingreso) = p_mes
      AND estado IN ('pagado', 'activo');

    SELECT COALESCE(SUM(monto), 0), COUNT(*)
    INTO v_total_egresos, v_num_egresos
    FROM egresos
    WHERE YEAR(fecha_egreso) = p_anio
      AND MONTH(fecha_egreso) = p_mes
      AND estado = 'aprobado';

    SELECT COUNT(*)
    INTO v_total_vecinos
    FROM vecinos
    WHERE deleted_at IS NULL;

    SELECT COUNT(*), COALESCE(SUM(deuda_total), 0)
    INTO v_num_morosos, v_deuda
    FROM (
        SELECT
            v.id,
            COALESCE(pp.deuda_cuotas, 0) + COALESCE(ma.deuda_multas, 0) AS deuda_total
        FROM vecinos v
        LEFT JOIN (
            SELECT vecino_id, SUM(monto_pendiente) AS deuda_cuotas
            FROM pagos_pendientes
            WHERE estado = 'pendiente'
            GROUP BY vecino_id
        ) pp ON pp.vecino_id = v.id
        LEFT JOIN (
            SELECT vecino_id, SUM(monto_aplicado) AS deuda_multas
            FROM multas_aplicadas
            WHERE estado = 'pendiente'
            GROUP BY vecino_id
        ) ma ON ma.vecino_id = v.id
        WHERE v.deleted_at IS NULL
    ) deuda
    WHERE deuda_total > 0;

    SELECT id
    INTO v_reporte_existente
    FROM reportes_mensuales
    WHERE periodo_anio = p_anio
      AND periodo_mes = p_mes
      AND es_reporte_parcial = p_es_parcial
    LIMIT 1;

    IF v_reporte_existente IS NULL THEN
        INSERT INTO reportes_mensuales (
            periodo_anio, periodo_mes, fecha_inicio_periodo, fecha_fin_periodo,
            estado, total_ingresos, num_cobros, num_ingresos_manuales,
            total_egresos, num_egresos, balance_neto,
            num_vecinos_total, num_vecinos_al_dia, num_vecinos_morosos,
            deuda_acumulada, porcentaje_morosidad, es_reporte_parcial
        ) VALUES (
            p_anio, p_mes, v_inicio, v_fin,
            'pendiente_aprobacion', v_total_ingresos, COALESCE(v_num_cobros, 0), COALESCE(v_num_ingresos, 0),
            v_total_egresos, v_num_egresos, v_total_ingresos - v_total_egresos,
            v_total_vecinos, v_total_vecinos - v_num_morosos, v_num_morosos,
            v_deuda, IF(v_total_vecinos = 0, 0, ROUND(v_num_morosos * 100.0 / v_total_vecinos, 2)),
            p_es_parcial
        );
        SET p_reporte_id = LAST_INSERT_ID();
    ELSE
        UPDATE reportes_mensuales
        SET estado = 'pendiente_aprobacion',
            total_ingresos = v_total_ingresos,
            num_cobros = COALESCE(v_num_cobros, 0),
            num_ingresos_manuales = COALESCE(v_num_ingresos, 0),
            total_egresos = v_total_egresos,
            num_egresos = v_num_egresos,
            balance_neto = v_total_ingresos - v_total_egresos,
            num_vecinos_total = v_total_vecinos,
            num_vecinos_al_dia = v_total_vecinos - v_num_morosos,
            num_vecinos_morosos = v_num_morosos,
            deuda_acumulada = v_deuda,
            porcentaje_morosidad = IF(v_total_vecinos = 0, 0, ROUND(v_num_morosos * 100.0 / v_total_vecinos, 2)),
            fecha_generacion = CURRENT_TIMESTAMP,
            version = version + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_reporte_existente;
        SET p_reporte_id = v_reporte_existente;
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_reporte_aprobar $$
CREATE PROCEDURE sp_reporte_aprobar(
    IN p_reporte_id BIGINT UNSIGNED,
    IN p_aprobado_por BIGINT UNSIGNED,
    IN p_observaciones_admin VARCHAR(2000),
    IN p_ruta_pdf_oficial VARCHAR(500),
    IN p_hash_pdf_oficial VARCHAR(64)
)
BEGIN
    UPDATE reportes_mensuales
    SET estado = 'aprobado',
        aprobado_por = p_aprobado_por,
        fecha_aprobacion = CURRENT_TIMESTAMP,
        observaciones_admin = p_observaciones_admin,
        ruta_pdf_oficial = p_ruta_pdf_oficial,
        hash_pdf_oficial = p_hash_pdf_oficial,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_reporte_id
      AND estado = 'pendiente_aprobacion';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reporte pendiente no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_reporte_rechazar $$
CREATE PROCEDURE sp_reporte_rechazar(
    IN p_reporte_id BIGINT UNSIGNED,
    IN p_rechazado_por BIGINT UNSIGNED,
    IN p_motivo_rechazo VARCHAR(2000),
    IN p_areas_revisar_json JSON
)
BEGIN
    UPDATE reportes_mensuales
    SET estado = 'rechazado',
        rechazado_por = p_rechazado_por,
        fecha_rechazo = CURRENT_TIMESTAMP,
        motivo_rechazo = p_motivo_rechazo,
        areas_revisar_json = p_areas_revisar_json,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_reporte_id
      AND estado = 'pendiente_aprobacion';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reporte pendiente no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_reportes_pendientes $$
CREATE PROCEDURE sp_reportes_pendientes()
BEGIN
    SELECT
        CONCAT(
            CASE periodo_mes
                WHEN 1 THEN 'Enero'
                WHEN 2 THEN 'Febrero'
                WHEN 3 THEN 'Marzo'
                WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Mayo'
                WHEN 6 THEN 'Junio'
                WHEN 7 THEN 'Julio'
                WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Septiembre'
                WHEN 10 THEN 'Octubre'
                WHEN 11 THEN 'Noviembre'
                WHEN 12 THEN 'Diciembre'
            END,
            ' ',
            periodo_anio
        ) AS periodo,
        DATE_FORMAT(fecha_generacion, '%d/%m/%Y') AS generado,
        total_ingresos,
        total_egresos,
        balance_neto,
        CONCAT(num_vecinos_morosos, '/', num_vecinos_total) AS morosidad,
        estado
    FROM reportes_mensuales
    WHERE estado = 'pendiente_aprobacion'
    ORDER BY periodo_anio DESC, periodo_mes DESC;
END $$

DROP PROCEDURE IF EXISTS sp_reportes_tendencia $$
CREATE PROCEDURE sp_reportes_tendencia(
    IN p_limite INT UNSIGNED
)
BEGIN
    SELECT
        CONCAT(periodo_anio, '-', LPAD(periodo_mes, 2, '0')) AS periodo,
        total_ingresos,
        total_egresos,
        balance_neto,
        estado
    FROM reportes_mensuales
    WHERE estado IN ('aprobado', 'pendiente_aprobacion')
    ORDER BY periodo_anio DESC, periodo_mes DESC
    LIMIT p_limite;
END $$

DROP PROCEDURE IF EXISTS sp_reportes_resumen_anual $$
CREATE PROCEDURE sp_reportes_resumen_anual(
    IN p_anio SMALLINT UNSIGNED
)
BEGIN
    SELECT
        SUM(total_ingresos) AS total_recaudado_anio,
        SUM(total_egresos) AS total_egresos_anio,
        SUM(balance_neto) AS balance_acumulado,
        COUNT(*) AS reportes_generados,
        SUM(CASE WHEN estado = 'aprobado' THEN 1 ELSE 0 END) AS aprobados,
        SUM(CASE WHEN estado = 'pendiente_aprobacion' THEN 1 ELSE 0 END) AS pendientes
    FROM reportes_mensuales
    WHERE periodo_anio = p_anio;
END $$

DROP PROCEDURE IF EXISTS sp_reportes_historial $$
CREATE PROCEDURE sp_reportes_historial()
BEGIN
    SELECT
        CONCAT(
            CASE periodo_mes
                WHEN 1 THEN 'Enero'
                WHEN 2 THEN 'Febrero'
                WHEN 3 THEN 'Marzo'
                WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Mayo'
                WHEN 6 THEN 'Junio'
                WHEN 7 THEN 'Julio'
                WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Septiembre'
                WHEN 10 THEN 'Octubre'
                WHEN 11 THEN 'Noviembre'
                WHEN 12 THEN 'Diciembre'
            END,
            ' ',
            periodo_anio
        ) AS periodo,
        DATE_FORMAT(fecha_generacion, '%d/%m/%Y') AS generado,
        total_ingresos,
        total_egresos,
        balance_neto,
        r.estado,
        COALESCE(CONCAT(u.nombres, ' ', u.apellidos), '-') AS aprobado_por_nombre
    FROM reportes_mensuales r
    LEFT JOIN users u ON r.aprobado_por = u.id
    WHERE r.es_reporte_parcial = FALSE
    ORDER BY r.periodo_anio DESC, r.periodo_mes DESC;
END $$

DROP PROCEDURE IF EXISTS sp_reporte_json_resumen $$
CREATE PROCEDURE sp_reporte_json_resumen(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        JSON_EXTRACT(desglose_ingresos_json, '$.cuotas_mensuales.total') AS cuotas,
        JSON_EXTRACT(desglose_ingresos_json, '$.multas_cobradas.total') AS multas,
        JSON_EXTRACT(desglose_egresos_json, '$.materiales.total') AS materiales,
        JSON_EXTRACT(top_morosos_json, '$[0].nombre') AS top_moroso
    FROM reportes_mensuales
    WHERE periodo_anio = p_anio
      AND periodo_mes = p_mes
    LIMIT 1;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_reportes_pendientes();
-- CALL sp_reportes_tendencia(6);
-- CALL sp_reportes_resumen_anual(2026);
-- CALL sp_reportes_historial();
-- CALL sp_reporte_json_resumen(2026, 5);
