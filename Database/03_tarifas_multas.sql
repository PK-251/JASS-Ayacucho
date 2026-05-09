-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 3: Tarifas y Multas
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 8: tarifas
-- Historial completo de tarifas por categoria.
-- Una tarifa vigente por categoria: activa = TRUE y fecha_vigencia_fin = NULL.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tarifas (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    categoria_id            INT UNSIGNED NOT NULL,
    monto                   DECIMAL(8,2) NOT NULL
                            COMMENT 'Cuota mensual en soles',
    fecha_vigencia_inicio   DATE NOT NULL,
    fecha_vigencia_fin      DATE NULL
                            COMMENT 'NULL = tarifa vigente',
    activa                  BOOLEAN NOT NULL DEFAULT TRUE
                            COMMENT 'Solo una activa por categoria',
    descripcion             VARCHAR(500) NULL,
    motivo_cambio           VARCHAR(500) NULL,

    created_by              BIGINT UNSIGNED NULL,
    updated_by              BIGINT UNSIGNED NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_tarifas_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias_servicio(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_tarifas_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_tarifas_updater FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_monto_positivo CHECK (monto > 0),
    CONSTRAINT chk_fechas_validas CHECK (
        fecha_vigencia_fin IS NULL OR fecha_vigencia_fin >= fecha_vigencia_inicio
    ),

    INDEX idx_tarifas_categoria (categoria_id),
    INDEX idx_tarifas_activa    (categoria_id, activa),
    INDEX idx_tarifas_vigencia  (fecha_vigencia_inicio, fecha_vigencia_fin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tarifas mensuales por categoria con historial';

-- ------------------------------------------------------------
-- TABLA 9: multas
-- Catalogo de tipos de multa configurables.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS multas (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo                  VARCHAR(10) NOT NULL UNIQUE
                            COMMENT 'Auto-generado: M-01, M-02',
    nombre                  VARCHAR(100) NOT NULL,
    descripcion             VARCHAR(500) NULL,
    monto                   DECIMAL(8,2) NOT NULL
                            COMMENT 'Importe de la multa en soles',

    tipo_aplicacion         ENUM('automatica_mensual','manual','semi_automatica')
                            NOT NULL DEFAULT 'manual',
    condicion_aplicacion    VARCHAR(500) NULL,
    activa                  BOOLEAN NOT NULL DEFAULT TRUE,

    created_by              BIGINT UNSIGNED NULL,
    updated_by              BIGINT UNSIGNED NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                            ON UPDATE CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMP NULL
                            COMMENT 'Soft delete',

    CONSTRAINT fk_multas_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_multas_updater FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_multa_monto_positivo CHECK (monto > 0),

    INDEX idx_multas_codigo (codigo),
    INDEX idx_multas_activa (activa),
    INDEX idx_multas_tipo   (tipo_aplicacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catalogo de tipos de multa';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);
SET @cat_domestica = (SELECT id FROM categorias_servicio WHERE nombre = 'Domestica' LIMIT 1);
SET @cat_comercial = (SELECT id FROM categorias_servicio WHERE nombre = 'Comercial' LIMIT 1);
SET @cat_institucional = (SELECT id FROM categorias_servicio WHERE nombre = 'Institucional' LIMIT 1);

INSERT INTO tarifas
    (categoria_id, monto, fecha_vigencia_inicio, fecha_vigencia_fin,
     activa, motivo_cambio, created_by)
VALUES
(@cat_domestica, 3.00, '2024-01-01', '2024-12-31', FALSE, 'Tarifa inicial registrada en sistema', @admin_jass_id),
(@cat_domestica, 3.50, '2025-01-01', '2025-12-31', FALSE, 'Reajuste por inflacion 2025', @admin_jass_id),
(@cat_domestica, 4.00, '2026-01-01', NULL, TRUE, 'Reajuste anual aprobado en asamblea del 28/12/2025', @admin_jass_id),
(@cat_comercial, 6.00, '2024-01-01', '2024-12-31', FALSE, 'Tarifa inicial 2024', @admin_jass_id),
(@cat_comercial, 8.00, '2025-01-01', NULL, TRUE, 'Aumento por mayor consumo en establecimientos comerciales', @admin_jass_id),
(@cat_institucional, 2.00, '2024-01-01', NULL, TRUE, 'Tarifa preferencial para instituciones educativas y de salud', @admin_jass_id);

INSERT INTO multas
    (codigo, nombre, descripcion, monto, tipo_aplicacion,
     condicion_aplicacion, activa, created_by)
VALUES
('M-01', 'Mora por pago tardio', 'Aplicada cuando el vecino paga despues del dia 15 del mes', 4.00, 'automatica_mensual', 'Si fecha_pago > dia 15 del mes correspondiente', TRUE, @admin_jass_id),
('M-02', 'Conexion clandestina', 'Detectada conexion no autorizada al sistema de agua', 50.00, 'manual', 'Aplicada por el operador tras inspeccion', TRUE, @admin_jass_id),
('M-03', 'Dano a infraestructura', 'Dano al medidor, tuberia principal u otra infraestructura', 30.00, 'manual', 'Aplicada tras evaluacion del dano', TRUE, @admin_jass_id),
('M-04', 'Inasistencia a faena', 'Falta a faena comunal obligatoria', 10.00, 'manual', 'Aplicada al confirmar lista de asistencia', TRUE, @admin_jass_id),
('M-05', 'Multa por reconexion', 'Costo de reconexion tras corte por morosidad', 15.00, 'semi_automatica', 'Sugerida por el sistema al solicitar reconexion', TRUE, @admin_jass_id),
('M-06', 'Multa antigua sin uso', 'Multa descontinuada en 2024', 5.00, 'manual', 'Ya no se aplica', FALSE, @admin_jass_id)
ON DUPLICATE KEY UPDATE
    nombre = VALUES(nombre),
    descripcion = VALUES(descripcion),
    monto = VALUES(monto),
    tipo_aplicacion = VALUES(tipo_aplicacion),
    condicion_aplicacion = VALUES(condicion_aplicacion),
    activa = VALUES(activa),
    updated_by = @admin_jass_id,
    updated_at = CURRENT_TIMESTAMP,
    deleted_at = NULL;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_tarifa_obtener_vigente $$
CREATE PROCEDURE sp_tarifa_obtener_vigente(
    IN p_categoria_id INT UNSIGNED,
    IN p_fecha DATE
)
BEGIN
    SELECT
        t.id,
        t.categoria_id,
        c.nombre AS categoria,
        t.monto,
        t.fecha_vigencia_inicio,
        t.fecha_vigencia_fin,
        t.activa,
        t.motivo_cambio
    FROM tarifas t
    INNER JOIN categorias_servicio c ON t.categoria_id = c.id
    WHERE t.categoria_id = p_categoria_id
      AND t.fecha_vigencia_inicio <= COALESCE(p_fecha, CURRENT_DATE)
      AND (t.fecha_vigencia_fin IS NULL OR t.fecha_vigencia_fin >= COALESCE(p_fecha, CURRENT_DATE))
    ORDER BY t.fecha_vigencia_inicio DESC
    LIMIT 1;
END $$

DROP PROCEDURE IF EXISTS sp_tarifas_vigentes_listar $$
CREATE PROCEDURE sp_tarifas_vigentes_listar()
BEGIN
    SELECT
        c.nombre AS categoria,
        t.monto AS tarifa_actual,
        t.fecha_vigencia_inicio AS desde,
        t.motivo_cambio
    FROM tarifas t
    INNER JOIN categorias_servicio c ON t.categoria_id = c.id
    WHERE t.activa = TRUE
      AND t.fecha_vigencia_fin IS NULL
    ORDER BY c.nombre;
END $$

DROP PROCEDURE IF EXISTS sp_tarifa_cambiar $$
CREATE PROCEDURE sp_tarifa_cambiar(
    IN p_categoria_id INT UNSIGNED,
    IN p_monto DECIMAL(8,2),
    IN p_fecha_vigencia_inicio DATE,
    IN p_motivo_cambio VARCHAR(500),
    IN p_user_id BIGINT UNSIGNED,
    OUT p_tarifa_id INT UNSIGNED
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM categorias_servicio WHERE id = p_categoria_id AND activa = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria no encontrada o inactiva';
    END IF;

    UPDATE tarifas
    SET activa = FALSE,
        fecha_vigencia_fin = DATE_SUB(p_fecha_vigencia_inicio, INTERVAL 1 DAY),
        updated_by = p_user_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE categoria_id = p_categoria_id
      AND activa = TRUE
      AND fecha_vigencia_fin IS NULL;

    INSERT INTO tarifas (
        categoria_id, monto, fecha_vigencia_inicio, fecha_vigencia_fin,
        activa, motivo_cambio, created_by
    ) VALUES (
        p_categoria_id, p_monto, p_fecha_vigencia_inicio, NULL,
        TRUE, p_motivo_cambio, p_user_id
    );

    SET p_tarifa_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_tarifas_historial $$
CREATE PROCEDURE sp_tarifas_historial()
BEGIN
    SELECT
        t.fecha_vigencia_inicio AS fecha_cambio,
        c.nombre AS categoria,
        LAG(t.monto) OVER (
            PARTITION BY t.categoria_id
            ORDER BY t.fecha_vigencia_inicio
        ) AS valor_anterior,
        t.monto AS valor_nuevo,
        CONCAT(u.nombres, ' ', u.apellidos) AS modificado_por,
        t.motivo_cambio,
        t.activa
    FROM tarifas t
    INNER JOIN categorias_servicio c ON t.categoria_id = c.id
    LEFT JOIN users u ON t.created_by = u.id
    ORDER BY t.fecha_vigencia_inicio DESC, c.nombre;
END $$

DROP PROCEDURE IF EXISTS sp_multa_generar_codigo $$
CREATE PROCEDURE sp_multa_generar_codigo(
    OUT p_codigo VARCHAR(10)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(codigo, 3) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM multas
    WHERE codigo REGEXP '^M-[0-9]+$';

    SET p_codigo = CONCAT('M-', LPAD(v_numero, 2, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_multa_crear $$
CREATE PROCEDURE sp_multa_crear(
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(500),
    IN p_monto DECIMAL(8,2),
    IN p_tipo_aplicacion VARCHAR(30),
    IN p_condicion_aplicacion VARCHAR(500),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_multa_id INT UNSIGNED,
    OUT p_codigo VARCHAR(10)
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF p_tipo_aplicacion NOT IN ('automatica_mensual', 'manual', 'semi_automatica') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de aplicacion no valido';
    END IF;

    CALL sp_multa_generar_codigo(p_codigo);

    INSERT INTO multas (
        codigo, nombre, descripcion, monto, tipo_aplicacion,
        condicion_aplicacion, activa, created_by
    ) VALUES (
        p_codigo, p_nombre, p_descripcion, p_monto, p_tipo_aplicacion,
        p_condicion_aplicacion, TRUE, p_created_by
    );

    SET p_multa_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_multa_actualizar $$
CREATE PROCEDURE sp_multa_actualizar(
    IN p_multa_id INT UNSIGNED,
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(500),
    IN p_monto DECIMAL(8,2),
    IN p_tipo_aplicacion VARCHAR(30),
    IN p_condicion_aplicacion VARCHAR(500),
    IN p_activa BOOLEAN,
    IN p_updated_by BIGINT UNSIGNED
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto debe ser mayor que cero';
    END IF;

    IF p_tipo_aplicacion NOT IN ('automatica_mensual', 'manual', 'semi_automatica') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de aplicacion no valido';
    END IF;

    UPDATE multas
    SET nombre = p_nombre,
        descripcion = p_descripcion,
        monto = p_monto,
        tipo_aplicacion = p_tipo_aplicacion,
        condicion_aplicacion = p_condicion_aplicacion,
        activa = p_activa,
        updated_by = p_updated_by,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_multa_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Multa no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_multa_eliminar $$
CREATE PROCEDURE sp_multa_eliminar(
    IN p_multa_id INT UNSIGNED,
    IN p_deleted_by BIGINT UNSIGNED
)
BEGIN
    UPDATE multas
    SET activa = FALSE,
        deleted_at = CURRENT_TIMESTAMP,
        updated_by = p_deleted_by,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_multa_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Multa no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_multas_listar $$
CREATE PROCEDURE sp_multas_listar(
    IN p_solo_activas BOOLEAN
)
BEGIN
    SELECT
        codigo,
        nombre,
        descripcion,
        monto,
        tipo_aplicacion,
        condicion_aplicacion,
        activa
    FROM multas
    WHERE deleted_at IS NULL
      AND (p_solo_activas IS NULL OR p_solo_activas = FALSE OR activa = TRUE)
    ORDER BY codigo;
END $$

DROP PROCEDURE IF EXISTS sp_tarifas_multas_kpis $$
CREATE PROCEDURE sp_tarifas_multas_kpis()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM tarifas WHERE activa = TRUE AND fecha_vigencia_fin IS NULL) AS tarifas_vigentes,
        (SELECT COUNT(*) FROM multas WHERE activa = TRUE AND deleted_at IS NULL) AS multas_activas,
        (SELECT COUNT(*) FROM multas WHERE activa = FALSE AND deleted_at IS NULL) AS multas_inactivas;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_tarifas_vigentes_listar();
-- CALL sp_tarifas_historial();
-- CALL sp_multas_listar(NULL);
-- CALL sp_tarifas_multas_kpis();

