-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 6: Egresos, Categorias y Proveedores
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 17: categorias_egreso
-- Catalogo de categorias para salidas de dinero.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias_egreso (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre              VARCHAR(50) NOT NULL UNIQUE,
    descripcion         VARCHAR(255) NULL,
    requiere_aprobacion BOOLEAN NOT NULL DEFAULT FALSE,
    icono               VARCHAR(50) NULL,
    color_hex           VARCHAR(7) NULL DEFAULT '#EF4444',
    activa              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_cat_egreso_activa (activa),
    INDEX idx_cat_egreso_aprobacion (requiere_aprobacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorias de egreso';

-- ------------------------------------------------------------
-- TABLA 18: configuracion_egresos
-- Parametros del modulo de egresos.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS configuracion_egresos (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    clave               VARCHAR(80) NOT NULL UNIQUE,
    valor               VARCHAR(255) NOT NULL,
    descripcion         VARCHAR(255) NULL,
    actualizado_por     BIGINT UNSIGNED NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_config_egresos_actualizador FOREIGN KEY (actualizado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_config_egresos_clave (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Configuracion del modulo de egresos';

-- ------------------------------------------------------------
-- TABLA 19: proveedores
-- Personas o empresas frecuentes para egresos.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS proveedores (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tipo            ENUM('persona','empresa') NOT NULL,
    ruc             VARCHAR(11) NULL UNIQUE,
    dni             VARCHAR(8) NULL UNIQUE,
    nombre          VARCHAR(150) NOT NULL,
    telefono        VARCHAR(30) NULL,
    email           VARCHAR(150) NULL,
    direccion       VARCHAR(255) NULL,
    activo          BOOLEAN NOT NULL DEFAULT TRUE,

    created_by      BIGINT UNSIGNED NULL,
    updated_by      BIGINT UNSIGNED NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMP NULL,

    CONSTRAINT fk_proveedores_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_proveedores_updater FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_proveedor_documento CHECK (
        (tipo = 'empresa' AND ruc IS NOT NULL) OR
        (tipo = 'persona' AND dni IS NOT NULL)
    ),

    INDEX idx_proveedores_tipo (tipo),
    INDEX idx_proveedores_nombre (nombre),
    INDEX idx_proveedores_activo (activo),
    INDEX idx_proveedores_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Proveedores frecuentes';

-- ------------------------------------------------------------
-- TABLA 20: egresos
-- Salidas de dinero aprobadas, pendientes o anuladas.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS egresos (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_serie            VARCHAR(20) NOT NULL UNIQUE
                            COMMENT 'Auto-generado: EGR-2026-0001',
    categoria_id            INT UNSIGNED NOT NULL,
    proveedor_id            BIGINT UNSIGNED NULL,

    concepto                VARCHAR(255) NOT NULL,
    descripcion             VARCHAR(1000) NULL,
    monto                   DECIMAL(10,2) NOT NULL,
    metodo_pago             ENUM('efectivo','transferencia','yape','plin','otro')
                            NOT NULL DEFAULT 'efectivo',
    fecha_egreso            DATE NOT NULL,

    comprobante_tipo        ENUM('boleta','factura','recibo','ticket','sin_comprobante','otro')
                            NOT NULL DEFAULT 'sin_comprobante',
    comprobante_numero      VARCHAR(50) NULL,
    comprobante_archivo     VARCHAR(500) NULL,
    comprobante_nombre      VARCHAR(150) NULL,

    estado                  ENUM('pendiente_aprobacion','aprobado','rechazado','anulado')
                            NOT NULL DEFAULT 'aprobado',
    requiere_aprobacion     BOOLEAN NOT NULL DEFAULT FALSE,

    aprobado_por            BIGINT UNSIGNED NULL,
    fecha_aprobacion        TIMESTAMP NULL,
    rechazado_por           BIGINT UNSIGNED NULL,
    fecha_rechazo           TIMESTAMP NULL,
    motivo_rechazo          VARCHAR(500) NULL,

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

    CONSTRAINT fk_egresos_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias_egreso(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedores(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_aprobador FOREIGN KEY (aprobado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_rechazador FOREIGN KEY (rechazado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_anulador FOREIGN KEY (anulado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_egresos_editor FOREIGN KEY (editado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_egreso_monto_positivo CHECK (monto > 0),

    INDEX idx_egresos_serie (numero_serie),
    INDEX idx_egresos_categoria (categoria_id),
    INDEX idx_egresos_proveedor (proveedor_id),
    INDEX idx_egresos_fecha (fecha_egreso),
    INDEX idx_egresos_estado (estado),
    INDEX idx_egresos_periodo (fecha_egreso, estado),
    INDEX idx_egresos_aprobacion (requiere_aprobacion, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Egresos del sistema';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);

INSERT INTO categorias_egreso (nombre, descripcion, icono, color_hex, activa) VALUES
('Materiales', 'Compra de materiales: cloro, tuberias y accesorios', 'Package', '#0891B2', TRUE),
('Personal', 'Pago de operarios, tecnicos y personal de la junta', 'Users', '#10B981', TRUE),
('Mantenimiento', 'Reparaciones, limpieza y mantenimiento de infraestructura', 'Wrench', '#F59E0B', TRUE),
('Combustible', 'Combustible para motobomba, vehiculos y generadores', 'Fuel', '#EF4444', TRUE),
('Servicios', 'Pago de servicios publicos: luz, agua e internet', 'Zap', '#8B5CF6', TRUE),
('Otros', 'Egresos no clasificados: insumos de oficina y varios', 'MoreHorizontal', '#94A3B8', TRUE)
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    icono = VALUES(icono),
    color_hex = VALUES(color_hex),
    activa = VALUES(activa),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO configuracion_egresos (clave, valor, descripcion, actualizado_por) VALUES
('umbral_aprobacion', '200.00', 'Monto en soles que requiere aprobacion del administrador', @admin_jass_id),
('comprobante_obligatorio', 'true', 'Si TRUE, todo egreso requiere comprobante adjunto', @admin_jass_id)
ON DUPLICATE KEY UPDATE
    valor = VALUES(valor),
    descripcion = VALUES(descripcion),
    actualizado_por = VALUES(actualizado_por),
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO proveedores (tipo, ruc, nombre, telefono, direccion, activo, created_by) VALUES
('empresa', '20100100200', 'Ferreteria Sol', '054-555-100', 'Av. Comercio 234, Sara-Sara', TRUE, @admin_jass_id),
('empresa', '20100100201', 'Distribuidora Quilca', '054-555-101', 'Jr. Mercaderes 45, Sara-Sara', TRUE, @admin_jass_id),
('empresa', '20100100202', 'Grifo Sara-Sara', '054-555-102', 'Carretera Central km 2', TRUE, @admin_jass_id),
('empresa', '20100100203', 'Electrocentro S.A.', '054-555-103', 'Sucursal Pauza', TRUE, @admin_jass_id),
('empresa', '20100100204', 'Libreria Central', '054-555-104', 'Plaza de Armas 12, Sara-Sara', TRUE, @admin_jass_id)
ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    telefono = VALUES(telefono),
    direccion = VALUES(direccion),
    activo = VALUES(activo),
    updated_by = @admin_jass_id,
    updated_at = CURRENT_TIMESTAMP,
    deleted_at = NULL;

INSERT INTO proveedores (tipo, dni, nombre, telefono, activo, created_by) VALUES
('persona', '45112233', 'Pedro Huaman', '999-100-200', TRUE, @admin_jass_id),
('persona', '45223344', 'Tecnico Mendoza', '999-100-201', TRUE, @admin_jass_id)
ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    telefono = VALUES(telefono),
    activo = VALUES(activo),
    updated_by = @admin_jass_id,
    updated_at = CURRENT_TIMESTAMP,
    deleted_at = NULL;

SET @cat_materiales = (SELECT id FROM categorias_egreso WHERE nombre = 'Materiales' LIMIT 1);
SET @cat_personal = (SELECT id FROM categorias_egreso WHERE nombre = 'Personal' LIMIT 1);
SET @cat_mantenimiento = (SELECT id FROM categorias_egreso WHERE nombre = 'Mantenimiento' LIMIT 1);
SET @cat_combustible = (SELECT id FROM categorias_egreso WHERE nombre = 'Combustible' LIMIT 1);
SET @cat_servicios = (SELECT id FROM categorias_egreso WHERE nombre = 'Servicios' LIMIT 1);
SET @cat_otros = (SELECT id FROM categorias_egreso WHERE nombre = 'Otros' LIMIT 1);

SET @prov_ferreteria_sol = (SELECT id FROM proveedores WHERE ruc = '20100100200' LIMIT 1);
SET @prov_distribuidora = (SELECT id FROM proveedores WHERE ruc = '20100100201' LIMIT 1);
SET @prov_grifo = (SELECT id FROM proveedores WHERE ruc = '20100100202' LIMIT 1);
SET @prov_electrocentro = (SELECT id FROM proveedores WHERE ruc = '20100100203' LIMIT 1);
SET @prov_libreria = (SELECT id FROM proveedores WHERE ruc = '20100100204' LIMIT 1);
SET @prov_pedro = (SELECT id FROM proveedores WHERE dni = '45112233' LIMIT 1);
SET @prov_mendoza = (SELECT id FROM proveedores WHERE dni = '45223344' LIMIT 1);

INSERT INTO egresos
    (numero_serie, categoria_id, proveedor_id, concepto, descripcion,
     monto, metodo_pago, fecha_egreso, comprobante_tipo, comprobante_numero,
     estado, requiere_aprobacion, aprobado_por, fecha_aprobacion, created_by)
VALUES
('EGR-2026-0011', @cat_materiales, @prov_ferreteria_sol, 'Compra de tuberia PVC 2"', 'Tuberia PVC para reparacion general', 100.00, 'efectivo', '2026-05-02', 'boleta', 'B001-1234', 'anulado', FALSE, @admin_jass_id, '2026-05-02 10:00:00', @admin_jass_id),
('EGR-2026-0012', @cat_otros, @prov_libreria, 'Insumos de oficina', 'Papel A4, lapiceros, archivadores', 22.00, 'efectivo', '2026-05-03', 'boleta', 'B001-5678', 'aprobado', FALSE, @admin_jass_id, '2026-05-03 11:00:00', @admin_jass_id),
('EGR-2026-0013', @cat_mantenimiento, @prov_mendoza, 'Reparacion bomba (urgente)', 'Reparacion de motobomba principal del reservorio', 250.00, 'efectivo', '2026-05-04', 'recibo', 'R-0089', 'pendiente_aprobacion', TRUE, NULL, NULL, @admin_jass_id),
('EGR-2026-0014', @cat_servicios, @prov_electrocentro, 'Pago energia electrica', 'Recibo de electricidad del reservorio - Abril 2026', 78.00, 'transferencia', '2026-05-04', 'recibo', 'EC-202604', 'aprobado', FALSE, @admin_jass_id, '2026-05-04 09:00:00', @admin_jass_id),
('EGR-2026-0015', @cat_combustible, @prov_grifo, 'Combustible motobomba', 'Combustible para motobomba 15L', 45.50, 'efectivo', '2026-05-05', 'boleta', 'B001-2233', 'aprobado', FALSE, @admin_jass_id, '2026-05-05 08:30:00', @admin_jass_id),
('EGR-2026-0016', @cat_materiales, @prov_distribuidora, 'Compra de cloro (2 sacos)', 'Cloro granulado para tratamiento de agua', 120.00, 'efectivo', '2026-05-05', 'factura', 'F001-0145', 'aprobado', FALSE, @admin_jass_id, '2026-05-05 14:00:00', @admin_jass_id),
('EGR-2026-0017', @cat_personal, @prov_pedro, 'Pago operario mensual', 'Pago de Pedro Huaman por mantenimiento mensual', 180.00, 'efectivo', '2026-05-06', 'recibo', 'R-0090', 'aprobado', FALSE, @admin_jass_id, '2026-05-06 09:00:00', @admin_jass_id),
('EGR-2026-0018', @cat_mantenimiento, @prov_ferreteria_sol, 'Reparacion tuberia sector C', 'Compra de accesorios y mano de obra', 85.00, 'efectivo', '2026-05-06', 'boleta', 'B001-3344', 'aprobado', FALSE, @admin_jass_id, '2026-05-06 14:30:00', @admin_jass_id)
ON DUPLICATE KEY UPDATE
    categoria_id = VALUES(categoria_id),
    proveedor_id = VALUES(proveedor_id),
    concepto = VALUES(concepto),
    descripcion = VALUES(descripcion),
    monto = VALUES(monto),
    metodo_pago = VALUES(metodo_pago),
    fecha_egreso = VALUES(fecha_egreso),
    comprobante_tipo = VALUES(comprobante_tipo),
    comprobante_numero = VALUES(comprobante_numero),
    estado = VALUES(estado),
    requiere_aprobacion = VALUES(requiere_aprobacion),
    aprobado_por = VALUES(aprobado_por),
    fecha_aprobacion = VALUES(fecha_aprobacion),
    updated_at = CURRENT_TIMESTAMP;

UPDATE egresos
SET motivo_anulacion = 'Compra duplicada - Ferreteria Sol devolvio el dinero registrado en ING-2026-0021',
    anulado_por = @admin_jass_id,
    fecha_anulacion = '2026-05-03 16:00:00'
WHERE numero_serie = 'EGR-2026-0011';

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_egreso_generar_serie $$
CREATE PROCEDURE sp_egreso_generar_serie(
    IN p_anio SMALLINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM egresos
    WHERE numero_serie LIKE CONCAT('EGR-', p_anio, '-%');

    SET p_numero_serie = CONCAT('EGR-', p_anio, '-', LPAD(v_numero, 4, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_categoria_egreso_crear $$
CREATE PROCEDURE sp_categoria_egreso_crear(
    IN p_nombre VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_requiere_aprobacion BOOLEAN,
    IN p_icono VARCHAR(50),
    IN p_color_hex VARCHAR(7),
    OUT p_categoria_id INT UNSIGNED
)
BEGIN
    IF EXISTS (SELECT 1 FROM categorias_egreso WHERE nombre = p_nombre) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria de egreso ya existe';
    END IF;

    INSERT INTO categorias_egreso (
        nombre, descripcion, requiere_aprobacion, icono, color_hex, activa
    ) VALUES (
        p_nombre, p_descripcion, p_requiere_aprobacion, p_icono,
        COALESCE(p_color_hex, '#EF4444'), TRUE
    );

    SET p_categoria_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_proveedor_crear $$
CREATE PROCEDURE sp_proveedor_crear(
    IN p_tipo VARCHAR(20),
    IN p_ruc VARCHAR(11),
    IN p_dni VARCHAR(8),
    IN p_nombre VARCHAR(150),
    IN p_telefono VARCHAR(30),
    IN p_email VARCHAR(150),
    IN p_direccion VARCHAR(255),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_proveedor_id BIGINT UNSIGNED
)
BEGIN
    IF p_tipo NOT IN ('persona', 'empresa') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de proveedor no valido';
    END IF;

    IF p_tipo = 'empresa' AND p_ruc IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El RUC es obligatorio para empresas';
    END IF;

    IF p_tipo = 'persona' AND p_dni IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El DNI es obligatorio para personas';
    END IF;

    INSERT INTO proveedores (
        tipo, ruc, dni, nombre, telefono, email, direccion, activo, created_by
    ) VALUES (
        p_tipo, p_ruc, p_dni, p_nombre, p_telefono, p_email, p_direccion, TRUE, p_created_by
    );

    SET p_proveedor_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_egreso_crear $$
CREATE PROCEDURE sp_egreso_crear(
    IN p_categoria_id INT UNSIGNED,
    IN p_proveedor_id BIGINT UNSIGNED,
    IN p_concepto VARCHAR(255),
    IN p_descripcion VARCHAR(1000),
    IN p_monto DECIMAL(10,2),
    IN p_metodo_pago VARCHAR(20),
    IN p_fecha_egreso DATE,
    IN p_comprobante_tipo VARCHAR(30),
    IN p_comprobante_numero VARCHAR(50),
    IN p_comprobante_archivo VARCHAR(500),
    IN p_comprobante_nombre VARCHAR(150),
    IN p_observaciones VARCHAR(500),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_egreso_id BIGINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_umbral DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_requiere_aprobacion BOOLEAN DEFAULT FALSE;
    DECLARE v_estado VARCHAR(30) DEFAULT 'aprobado';

    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF p_metodo_pago NOT IN ('efectivo', 'transferencia', 'yape', 'plin', 'otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metodo de pago no valido';
    END IF;

    IF p_comprobante_tipo NOT IN ('boleta', 'factura', 'recibo', 'ticket', 'sin_comprobante', 'otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de comprobante no valido';
    END IF;

    SELECT CAST(valor AS DECIMAL(10,2))
    INTO v_umbral
    FROM configuracion_egresos
    WHERE clave = 'umbral_aprobacion'
    LIMIT 1;

    SELECT requiere_aprobacion
    INTO v_requiere_aprobacion
    FROM categorias_egreso
    WHERE id = p_categoria_id
      AND activa = TRUE
    LIMIT 1;

    IF v_requiere_aprobacion IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria de egreso no encontrada o inactiva';
    END IF;

    SET v_requiere_aprobacion = v_requiere_aprobacion OR p_monto >= COALESCE(v_umbral, 0);
    SET v_estado = IF(v_requiere_aprobacion, 'pendiente_aprobacion', 'aprobado');

    CALL sp_egreso_generar_serie(YEAR(p_fecha_egreso), p_numero_serie);

    INSERT INTO egresos (
        numero_serie, categoria_id, proveedor_id, concepto, descripcion,
        monto, metodo_pago, fecha_egreso, comprobante_tipo, comprobante_numero,
        comprobante_archivo, comprobante_nombre, estado, requiere_aprobacion,
        aprobado_por, fecha_aprobacion, observaciones, created_by
    ) VALUES (
        p_numero_serie, p_categoria_id, p_proveedor_id, p_concepto, p_descripcion,
        p_monto, p_metodo_pago, p_fecha_egreso, p_comprobante_tipo, p_comprobante_numero,
        p_comprobante_archivo, p_comprobante_nombre, v_estado, v_requiere_aprobacion,
        IF(v_estado = 'aprobado', p_created_by, NULL),
        IF(v_estado = 'aprobado', CURRENT_TIMESTAMP, NULL),
        p_observaciones, p_created_by
    );

    SET p_egreso_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_egreso_aprobar $$
CREATE PROCEDURE sp_egreso_aprobar(
    IN p_egreso_id BIGINT UNSIGNED,
    IN p_aprobado_por BIGINT UNSIGNED
)
BEGIN
    UPDATE egresos
    SET estado = 'aprobado',
        aprobado_por = p_aprobado_por,
        fecha_aprobacion = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_egreso_id
      AND estado = 'pendiente_aprobacion';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egreso pendiente no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_egreso_rechazar $$
CREATE PROCEDURE sp_egreso_rechazar(
    IN p_egreso_id BIGINT UNSIGNED,
    IN p_rechazado_por BIGINT UNSIGNED,
    IN p_motivo_rechazo VARCHAR(500)
)
BEGIN
    UPDATE egresos
    SET estado = 'rechazado',
        rechazado_por = p_rechazado_por,
        fecha_rechazo = CURRENT_TIMESTAMP,
        motivo_rechazo = p_motivo_rechazo,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_egreso_id
      AND estado = 'pendiente_aprobacion';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egreso pendiente no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_egreso_anular $$
CREATE PROCEDURE sp_egreso_anular(
    IN p_egreso_id BIGINT UNSIGNED,
    IN p_motivo_anulacion VARCHAR(500),
    IN p_anulado_por BIGINT UNSIGNED,
    IN p_devolver_dinero BOOLEAN
)
BEGIN
    UPDATE egresos
    SET estado = 'anulado',
        motivo_anulacion = p_motivo_anulacion,
        anulado_por = p_anulado_por,
        fecha_anulacion = CURRENT_TIMESTAMP,
        devolver_dinero = p_devolver_dinero,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_egreso_id
      AND estado IN ('aprobado', 'pendiente_aprobacion');

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Egreso activo no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_egresos_listar $$
CREATE PROCEDURE sp_egresos_listar(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED,
    IN p_estado VARCHAR(30)
)
BEGIN
    SELECT
        e.numero_serie,
        e.fecha_egreso AS fecha,
        e.concepto,
        c.nombre AS categoria,
        COALESCE(p.nombre, 'Sin proveedor') AS proveedor,
        e.monto,
        e.estado,
        e.requiere_aprobacion
    FROM egresos e
    INNER JOIN categorias_egreso c ON e.categoria_id = c.id
    LEFT JOIN proveedores p ON e.proveedor_id = p.id
    WHERE YEAR(e.fecha_egreso) = p_anio
      AND MONTH(e.fecha_egreso) = p_mes
      AND (p_estado IS NULL OR e.estado = p_estado)
    ORDER BY e.fecha_egreso DESC, e.numero_serie DESC;
END $$

DROP PROCEDURE IF EXISTS sp_egresos_kpis $$
CREATE PROCEDURE sp_egresos_kpis(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        COUNT(*) AS num_egresos,
        COALESCE(SUM(monto), 0) AS total_egresos,
        ROUND(COALESCE(AVG(monto), 0), 2) AS gasto_promedio,
        SUM(CASE WHEN estado = 'pendiente_aprobacion' THEN 1 ELSE 0 END) AS pendientes_aprobacion
    FROM egresos
    WHERE YEAR(fecha_egreso) = p_anio
      AND MONTH(fecha_egreso) = p_mes
      AND estado IN ('aprobado', 'pendiente_aprobacion');
END $$

DROP PROCEDURE IF EXISTS sp_egresos_distribucion_categoria $$
CREATE PROCEDURE sp_egresos_distribucion_categoria(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        c.nombre AS categoria,
        COUNT(e.id) AS cantidad,
        COALESCE(SUM(e.monto), 0) AS total,
        ROUND(
            COALESCE(SUM(e.monto), 0) * 100.0 /
            NULLIF((
                SELECT SUM(monto)
                FROM egresos
                WHERE YEAR(fecha_egreso) = p_anio
                  AND MONTH(fecha_egreso) = p_mes
                  AND estado = 'aprobado'
            ), 0),
            1
        ) AS porcentaje
    FROM categorias_egreso c
    LEFT JOIN egresos e ON e.categoria_id = c.id
        AND YEAR(e.fecha_egreso) = p_anio
        AND MONTH(e.fecha_egreso) = p_mes
        AND e.estado = 'aprobado'
    GROUP BY c.id, c.nombre
    ORDER BY total DESC;
END $$

DROP PROCEDURE IF EXISTS sp_balance_mes $$
CREATE PROCEDURE sp_balance_mes(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    SELECT
        (
            SELECT COALESCE(SUM(monto_recibido), 0)
            FROM cobros
            WHERE YEAR(fecha_cobro) = p_anio
              AND MONTH(fecha_cobro) = p_mes
              AND estado = 'pagado'
        ) +
        (
            SELECT COALESCE(SUM(monto), 0)
            FROM ingresos
            WHERE YEAR(fecha_ingreso) = p_anio
              AND MONTH(fecha_ingreso) = p_mes
              AND estado = 'activo'
        ) AS total_ingresos,
        (
            SELECT COALESCE(SUM(monto), 0)
            FROM egresos
            WHERE YEAR(fecha_egreso) = p_anio
              AND MONTH(fecha_egreso) = p_mes
              AND estado = 'aprobado'
        ) AS total_egresos;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_egresos_kpis(2026, 5);
-- CALL sp_egresos_distribucion_categoria(2026, 5);
-- CALL sp_egresos_listar(2026, 5, NULL);
-- CALL sp_balance_mes(2026, 5);
