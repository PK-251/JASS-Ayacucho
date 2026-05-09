-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 5: Ingresos Manuales
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 15: categorias_ingreso
-- Catalogo de categorias de ingreso.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias_ingreso (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL UNIQUE,
    descripcion     VARCHAR(255) NULL,
    es_manual       BOOLEAN NOT NULL DEFAULT TRUE
                    COMMENT 'TRUE = manual. FALSE = viene de cobros',
    icono           VARCHAR(50) NULL,
    color_hex       VARCHAR(7) NULL DEFAULT '#10B981',
    activa          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_cat_ingreso_activa (activa),
    INDEX idx_cat_ingreso_manual (es_manual)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorias de ingreso';

-- ------------------------------------------------------------
-- TABLA 16: ingresos
-- Ingresos manuales. Los cobros viven en la tabla cobros.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ingresos (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_serie            VARCHAR(20) NOT NULL UNIQUE
                            COMMENT 'Auto-generado: ING-2026-0001',
    categoria_id            INT UNSIGNED NOT NULL,
    vecino_id               BIGINT UNSIGNED NULL,

    concepto                VARCHAR(255) NOT NULL,
    descripcion             VARCHAR(1000) NULL,
    monto                   DECIMAL(10,2) NOT NULL,
    metodo_pago             ENUM('efectivo','transferencia','yape','plin','otro')
                            NOT NULL DEFAULT 'efectivo',
    fecha_ingreso           DATE NOT NULL,

    comprobante_archivo     VARCHAR(500) NULL,
    comprobante_nombre      VARCHAR(150) NULL,

    estado                  ENUM('activo','anulado') NOT NULL DEFAULT 'activo',

    motivo_anulacion        VARCHAR(500) NULL,
    anulado_por             BIGINT UNSIGNED NULL,
    fecha_anulacion         TIMESTAMP NULL,
    devolver_dinero         BOOLEAN NULL,

    motivo_ultima_edicion   VARCHAR(500) NULL,
    editado_por             BIGINT UNSIGNED NULL,
    fecha_ultima_edicion    TIMESTAMP NULL,

    observaciones           VARCHAR(500) NULL,

    created_by              BIGINT UNSIGNED NOT NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_ingresos_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias_ingreso(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ingresos_vecino FOREIGN KEY (vecino_id)
        REFERENCES vecinos(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_ingresos_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_ingresos_editor FOREIGN KEY (editado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_ingresos_anulador FOREIGN KEY (anulado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_ingreso_monto_positivo CHECK (monto > 0),

    INDEX idx_ingresos_serie     (numero_serie),
    INDEX idx_ingresos_categoria (categoria_id),
    INDEX idx_ingresos_vecino    (vecino_id),
    INDEX idx_ingresos_fecha     (fecha_ingreso),
    INDEX idx_ingresos_estado    (estado),
    INDEX idx_ingresos_periodo   (fecha_ingreso, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ingresos manuales';

-- ------------------------------------------------------------
-- VISTA: vista_ingresos_completa
-- Combina cobros pagados + ingresos manuales.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vista_ingresos_completa AS
SELECT
    c.id AS id,
    c.numero_serie AS numero_serie,
    'cobro' AS origen,
    DATE(c.fecha_cobro) AS fecha_ingreso,
    c.fecha_cobro AS fecha,
    c.hora_cobro AS hora,
    v.id AS vecino_id,
    CONCAT(v.nombres, ' ', v.apellidos) AS vecino_nombre,
    v.codigo AS vecino_codigo,
    CASE
        WHEN c.monto_multas > 0 AND c.monto_deuda_anterior > 0
            THEN CONCAT('Cuota ', c.periodo_mes, '/', c.periodo_anio, ' + Deuda + Multas')
        WHEN c.monto_multas > 0
            THEN CONCAT('Cuota ', c.periodo_mes, '/', c.periodo_anio, ' + Multa')
        WHEN c.monto_deuda_anterior > 0
            THEN CONCAT('Cuota ', c.periodo_mes, '/', c.periodo_anio, ' + Deuda anterior')
        ELSE CONCAT('Cuota mensual ', c.periodo_mes, '/', c.periodo_anio)
    END AS concepto,
    'Cuota mensual' AS categoria,
    c.metodo_pago AS metodo_pago,
    c.monto_recibido AS monto,
    c.estado AS estado,
    c.operador_id AS registrado_por_id
FROM cobros c
INNER JOIN vecinos v ON c.vecino_id = v.id
WHERE c.estado = 'pagado'

UNION ALL

SELECT
    i.id AS id,
    i.numero_serie AS numero_serie,
    'manual' AS origen,
    i.fecha_ingreso AS fecha_ingreso,
    i.fecha_ingreso AS fecha,
    NULL AS hora,
    i.vecino_id AS vecino_id,
    COALESCE(CONCAT(v.nombres, ' ', v.apellidos), '(Sin vecino)') AS vecino_nombre,
    v.codigo AS vecino_codigo,
    i.concepto AS concepto,
    ci.nombre AS categoria,
    i.metodo_pago AS metodo_pago,
    i.monto AS monto,
    i.estado AS estado,
    i.created_by AS registrado_por_id
FROM ingresos i
INNER JOIN categorias_ingreso ci ON i.categoria_id = ci.id
LEFT JOIN vecinos v ON i.vecino_id = v.id;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);

INSERT INTO categorias_ingreso (nombre, descripcion, es_manual, icono, color_hex, activa) VALUES
('Cuota mensual', 'Cobro mensual estandar proveniente del modulo Cobros', FALSE, 'Wallet', '#0891B2', TRUE),
('Multa cobrada', 'Multas cobradas a vecinos provenientes del modulo Cobros', FALSE, 'AlertCircle', '#F59E0B', TRUE),
('Cuota extraordinaria', 'Cuota especial aprobada en asamblea', TRUE, 'Zap', '#8B5CF6', TRUE),
('Donacion', 'Aportes voluntarios de vecinos o terceros', TRUE, 'Heart', '#10B981', TRUE),
('Venta', 'Venta de bienes, materiales reusables u otros', TRUE, 'Tag', '#06B6D4', TRUE),
('Reintegro', 'Devolucion de dinero por proveedores u otros', TRUE, 'RotateCcw', '#64748B', TRUE),
('Otro', 'Otros ingresos no clasificados', TRUE, 'MoreHorizontal', '#94A3B8', TRUE)
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    es_manual = VALUES(es_manual),
    icono = VALUES(icono),
    color_hex = VALUES(color_hex),
    activa = VALUES(activa),
    updated_at = CURRENT_TIMESTAMP;

SET @cat_donacion = (SELECT id FROM categorias_ingreso WHERE nombre = 'Donacion' LIMIT 1);
SET @cat_cuota_extra = (SELECT id FROM categorias_ingreso WHERE nombre = 'Cuota extraordinaria' LIMIT 1);
SET @cat_reintegro = (SELECT id FROM categorias_ingreso WHERE nombre = 'Reintegro' LIMIT 1);

INSERT INTO ingresos
    (numero_serie, categoria_id, vecino_id, concepto, descripcion, monto,
     metodo_pago, fecha_ingreso, estado, created_by)
VALUES
('ING-2026-0023', @cat_donacion, NULL, 'Donacion don Carlos', 'Donacion voluntaria de don Carlos para apoyo de la obra del reservorio', 50.00, 'transferencia', '2026-05-05', 'activo', @admin_jass_id),
('ING-2026-0022', @cat_cuota_extra, NULL, 'Cuota extraordinaria obra', 'Cuota aprobada en asamblea del 15/04/2026 - Vecino Mendoza', 80.00, 'efectivo', '2026-05-04', 'activo', @admin_jass_id),
('ING-2026-0021', @cat_reintegro, NULL, 'Reintegro proveedor', 'Devolucion de Ferreteria Sol por compra duplicada de tuberia', 20.00, 'efectivo', '2026-05-03', 'activo', @admin_jass_id)
ON DUPLICATE KEY UPDATE
    categoria_id = VALUES(categoria_id),
    vecino_id = VALUES(vecino_id),
    concepto = VALUES(concepto),
    descripcion = VALUES(descripcion),
    monto = VALUES(monto),
    metodo_pago = VALUES(metodo_pago),
    fecha_ingreso = VALUES(fecha_ingreso),
    estado = VALUES(estado),
    updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_ingreso_generar_serie $$
CREATE PROCEDURE sp_ingreso_generar_serie(
    IN p_anio SMALLINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM ingresos
    WHERE numero_serie LIKE CONCAT('ING-', p_anio, '-%');

    SET p_numero_serie = CONCAT('ING-', p_anio, '-', LPAD(v_numero, 4, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_categoria_ingreso_crear $$
CREATE PROCEDURE sp_categoria_ingreso_crear(
    IN p_nombre VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_es_manual BOOLEAN,
    IN p_icono VARCHAR(50),
    IN p_color_hex VARCHAR(7),
    OUT p_categoria_id INT UNSIGNED
)
BEGIN
    IF EXISTS (SELECT 1 FROM categorias_ingreso WHERE nombre = p_nombre) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria de ingreso ya existe';
    END IF;

    INSERT INTO categorias_ingreso (nombre, descripcion, es_manual, icono, color_hex, activa)
    VALUES (p_nombre, p_descripcion, p_es_manual, p_icono, COALESCE(p_color_hex, '#10B981'), TRUE);

    SET p_categoria_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_ingreso_crear $$
CREATE PROCEDURE sp_ingreso_crear(
    IN p_categoria_id INT UNSIGNED,
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_concepto VARCHAR(255),
    IN p_descripcion VARCHAR(1000),
    IN p_monto DECIMAL(10,2),
    IN p_metodo_pago VARCHAR(20),
    IN p_fecha_ingreso DATE,
    IN p_comprobante_archivo VARCHAR(500),
    IN p_comprobante_nombre VARCHAR(150),
    IN p_observaciones VARCHAR(500),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_ingreso_id BIGINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF p_metodo_pago NOT IN ('efectivo', 'transferencia', 'yape', 'plin', 'otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metodo de pago no valido';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM categorias_ingreso
        WHERE id = p_categoria_id AND activa = TRUE AND es_manual = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria manual no encontrada o inactiva';
    END IF;

    CALL sp_ingreso_generar_serie(YEAR(p_fecha_ingreso), p_numero_serie);

    INSERT INTO ingresos (
        numero_serie, categoria_id, vecino_id, concepto, descripcion,
        monto, metodo_pago, fecha_ingreso, comprobante_archivo,
        comprobante_nombre, observaciones, estado, created_by
    ) VALUES (
        p_numero_serie, p_categoria_id, p_vecino_id, p_concepto, p_descripcion,
        p_monto, p_metodo_pago, p_fecha_ingreso, p_comprobante_archivo,
        p_comprobante_nombre, p_observaciones, 'activo', p_created_by
    );

    SET p_ingreso_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_ingreso_actualizar $$
CREATE PROCEDURE sp_ingreso_actualizar(
    IN p_ingreso_id BIGINT UNSIGNED,
    IN p_categoria_id INT UNSIGNED,
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_concepto VARCHAR(255),
    IN p_descripcion VARCHAR(1000),
    IN p_monto DECIMAL(10,2),
    IN p_metodo_pago VARCHAR(20),
    IN p_fecha_ingreso DATE,
    IN p_comprobante_archivo VARCHAR(500),
    IN p_comprobante_nombre VARCHAR(150),
    IN p_observaciones VARCHAR(500),
    IN p_motivo_ultima_edicion VARCHAR(500),
    IN p_editado_por BIGINT UNSIGNED
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF p_metodo_pago NOT IN ('efectivo', 'transferencia', 'yape', 'plin', 'otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metodo de pago no valido';
    END IF;

    UPDATE ingresos
    SET categoria_id = p_categoria_id,
        vecino_id = p_vecino_id,
        concepto = p_concepto,
        descripcion = p_descripcion,
        monto = p_monto,
        metodo_pago = p_metodo_pago,
        fecha_ingreso = p_fecha_ingreso,
        comprobante_archivo = p_comprobante_archivo,
        comprobante_nombre = p_comprobante_nombre,
        observaciones = p_observaciones,
        motivo_ultima_edicion = p_motivo_ultima_edicion,
        editado_por = p_editado_por,
        fecha_ultima_edicion = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_ingreso_id
      AND estado = 'activo';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ingreso activo no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_ingreso_anular $$
CREATE PROCEDURE sp_ingreso_anular(
    IN p_ingreso_id BIGINT UNSIGNED,
    IN p_motivo_anulacion VARCHAR(500),
    IN p_anulado_por BIGINT UNSIGNED,
    IN p_devolver_dinero BOOLEAN
)
BEGIN
    UPDATE ingresos
    SET estado = 'anulado',
        motivo_anulacion = p_motivo_anulacion,
        anulado_por = p_anulado_por,
        fecha_anulacion = CURRENT_TIMESTAMP,
        devolver_dinero = p_devolver_dinero,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_ingreso_id
      AND estado = 'activo';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ingreso activo no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_ingresos_listar $$
CREATE PROCEDURE sp_ingresos_listar(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED,
    IN p_origen VARCHAR(20)
)
BEGIN
    SELECT
        numero_serie,
        fecha,
        hora,
        origen,
        vecino_nombre,
        concepto,
        categoria,
        metodo_pago,
        monto,
        estado
    FROM vista_ingresos_completa
    WHERE YEAR(fecha_ingreso) = p_anio
      AND MONTH(fecha_ingreso) = p_mes
      AND (p_origen IS NULL OR origen = p_origen)
    ORDER BY fecha DESC, hora DESC;
END $$

DROP PROCEDURE IF EXISTS sp_ingresos_kpis $$
CREATE PROCEDURE sp_ingresos_kpis(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        COUNT(*) AS total_transacciones,
        COALESCE(SUM(monto), 0) AS total_ingresos_mes,
        ROUND(COALESCE(AVG(monto), 0), 2) AS ticket_promedio,
        SUM(CASE WHEN origen = 'cobro' THEN 1 ELSE 0 END) AS de_cobros,
        SUM(CASE WHEN origen = 'manual' THEN 1 ELSE 0 END) AS manuales
    FROM vista_ingresos_completa
    WHERE YEAR(fecha_ingreso) = p_anio
      AND MONTH(fecha_ingreso) = p_mes
      AND estado IN ('pagado', 'activo');
END $$

DROP PROCEDURE IF EXISTS sp_ingresos_distribucion_categoria $$
CREATE PROCEDURE sp_ingresos_distribucion_categoria(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        categoria,
        COUNT(*) AS cantidad,
        SUM(monto) AS total,
        ROUND(SUM(monto) * 100.0 / SUM(SUM(monto)) OVER (), 1) AS porcentaje
    FROM vista_ingresos_completa
    WHERE YEAR(fecha_ingreso) = p_anio
      AND MONTH(fecha_ingreso) = p_mes
      AND estado IN ('pagado', 'activo')
    GROUP BY categoria
    ORDER BY total DESC;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_ingresos_kpis(2026, 5);
-- CALL sp_ingresos_distribucion_categoria(2026, 5);
-- CALL sp_ingresos_listar(2026, 5, NULL);

