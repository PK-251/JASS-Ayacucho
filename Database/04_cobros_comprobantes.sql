-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 4: Cobros, Comprobantes y Multas Aplicadas
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 10: jornadas_cobro
-- Sesiones de cobranza del operador.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS jornadas_cobro (
    id                           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    operador_id                  BIGINT UNSIGNED NOT NULL,
    fecha_inicio                 TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_cierre                 TIMESTAMP NULL,
    estado                       ENUM('activa','cerrada') NOT NULL DEFAULT 'activa',

    total_vecinos_atendidos      INT UNSIGNED NOT NULL DEFAULT 0,
    total_recaudado              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_pendientes_registrados INT UNSIGNED NOT NULL DEFAULT 0,

    observaciones                VARCHAR(500) NULL,
    created_at                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_jornadas_operador FOREIGN KEY (operador_id)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    INDEX idx_jornadas_operador (operador_id),
    INDEX idx_jornadas_estado   (estado),
    INDEX idx_jornadas_fechas   (fecha_inicio, fecha_cierre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Jornadas de cobro del operador';

-- ------------------------------------------------------------
-- TABLA 11: cobros
-- Tabla principal transaccional del sistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cobros (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_serie            VARCHAR(20) NOT NULL UNIQUE
                            COMMENT 'Auto-generado: QLC-2026-0001',

    vecino_id               BIGINT UNSIGNED NOT NULL,
    operador_id             BIGINT UNSIGNED NOT NULL,
    jornada_id              BIGINT UNSIGNED NULL,

    periodo_anio            SMALLINT UNSIGNED NOT NULL,
    periodo_mes             TINYINT UNSIGNED NOT NULL,

    monto_cuota             DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    monto_deuda_anterior    DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    monto_multas            DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    monto_total             DECIMAL(8,2) NOT NULL,
    monto_recibido          DECIMAL(8,2) NOT NULL,

    metodo_pago             ENUM('efectivo','transferencia','yape','plin','otro')
                            NOT NULL DEFAULT 'efectivo',
    estado                  ENUM('pagado','anulado') NOT NULL DEFAULT 'pagado',

    fecha_cobro             DATE NOT NULL,
    hora_cobro              TIME NOT NULL,

    observaciones           VARCHAR(500) NULL,

    motivo_ultima_edicion   VARCHAR(500) NULL,
    editado_por             BIGINT UNSIGNED NULL,
    fecha_ultima_edicion    TIMESTAMP NULL,

    motivo_anulacion        VARCHAR(500) NULL,
    anulado_por             BIGINT UNSIGNED NULL,
    fecha_anulacion         TIMESTAMP NULL,
    devolver_dinero         BOOLEAN NULL,

    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_cobros_vecino FOREIGN KEY (vecino_id)
        REFERENCES vecinos(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cobros_operador FOREIGN KEY (operador_id)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cobros_jornada FOREIGN KEY (jornada_id)
        REFERENCES jornadas_cobro(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_cobros_editor FOREIGN KEY (editado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_cobros_anulador FOREIGN KEY (anulado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_periodo_mes CHECK (periodo_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_montos_positivos CHECK (monto_total >= 0 AND monto_recibido >= 0),
    CONSTRAINT chk_total_correcto CHECK (monto_total = monto_cuota + monto_deuda_anterior + monto_multas),

    INDEX idx_cobros_serie     (numero_serie),
    INDEX idx_cobros_vecino    (vecino_id),
    INDEX idx_cobros_operador  (operador_id),
    INDEX idx_cobros_jornada   (jornada_id),
    INDEX idx_cobros_periodo   (periodo_anio, periodo_mes),
    INDEX idx_cobros_fecha     (fecha_cobro),
    INDEX idx_cobros_estado    (estado),
    INDEX idx_cobros_compuesto (vecino_id, periodo_anio, periodo_mes, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro de pagos cobrados';

-- ------------------------------------------------------------
-- TABLA 12: comprobantes_pdf
-- Comprobantes PDF generados, relacion 1:1 con cobros.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comprobantes_pdf (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cobro_id            BIGINT UNSIGNED NOT NULL UNIQUE,
    numero_serie        VARCHAR(20) NOT NULL,

    ruta_archivo        VARCHAR(500) NOT NULL,
    nombre_archivo      VARCHAR(100) NOT NULL,
    tamano_bytes        INT UNSIGNED NULL,
    codigo_qr_url       VARCHAR(255) NULL,

    modalidad_entrega   ENUM('pendiente','impresion','qr','email','multiple')
                        NOT NULL DEFAULT 'pendiente',
    fecha_generacion    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega       TIMESTAMP NULL,

    enviado_email       BOOLEAN NOT NULL DEFAULT FALSE,
    email_destinatario  VARCHAR(150) NULL,
    fecha_envio_email   TIMESTAMP NULL,

    impreso             BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_impresion     TIMESTAMP NULL,

    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_comprobantes_cobro FOREIGN KEY (cobro_id)
        REFERENCES cobros(id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    INDEX idx_comprobantes_serie     (numero_serie),
    INDEX idx_comprobantes_modalidad (modalidad_entrega)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Comprobantes PDF generados';

-- ------------------------------------------------------------
-- TABLA 13: multas_aplicadas
-- Multas concretas aplicadas a vecinos especificos.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS multas_aplicadas (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vecino_id               BIGINT UNSIGNED NOT NULL,
    multa_id                INT UNSIGNED NOT NULL,

    monto_aplicado          DECIMAL(8,2) NOT NULL,
    estado                  ENUM('pendiente','cobrada','anulada','justificada')
                            NOT NULL DEFAULT 'pendiente',

    fecha_aplicacion        DATE NOT NULL,
    fecha_cobro             DATE NULL,
    fecha_anulacion         TIMESTAMP NULL,

    aplicada_por            BIGINT UNSIGNED NOT NULL,
    motivo_aplicacion       VARCHAR(500) NULL,

    cobro_id                BIGINT UNSIGNED NULL,
    evento_id               BIGINT UNSIGNED NULL
                            COMMENT 'FK se agregara en Parte 8',

    motivo_justificacion    VARCHAR(500) NULL,
    documento_justificacion VARCHAR(255) NULL,
    motivo_anulacion        VARCHAR(500) NULL,
    anulada_por             BIGINT UNSIGNED NULL,

    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_multas_apl_vecino FOREIGN KEY (vecino_id)
        REFERENCES vecinos(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_multas_apl_multa FOREIGN KEY (multa_id)
        REFERENCES multas(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_multas_apl_cobro FOREIGN KEY (cobro_id)
        REFERENCES cobros(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_multas_apl_aplicada FOREIGN KEY (aplicada_por)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_multas_apl_anulada FOREIGN KEY (anulada_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_monto_aplicado_positivo CHECK (monto_aplicado > 0),

    INDEX idx_multas_apl_vecino    (vecino_id),
    INDEX idx_multas_apl_multa     (multa_id),
    INDEX idx_multas_apl_estado    (estado),
    INDEX idx_multas_apl_cobro     (cobro_id),
    INDEX idx_multas_apl_evento    (evento_id),
    INDEX idx_multas_apl_compuesto (vecino_id, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Multas aplicadas a vecinos especificos';

-- ------------------------------------------------------------
-- TABLA 14: pagos_pendientes
-- Vecinos no atendidos en jornada.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_pendientes (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vecino_id           BIGINT UNSIGNED NOT NULL,

    periodo_anio        SMALLINT UNSIGNED NOT NULL,
    periodo_mes         TINYINT UNSIGNED NOT NULL,
    monto_pendiente     DECIMAL(8,2) NOT NULL,

    estado              ENUM('pendiente','cobrado','condonado')
                        NOT NULL DEFAULT 'pendiente',

    fecha_intento       DATE NOT NULL,
    fecha_cobro         DATE NULL,
    motivo              VARCHAR(500) NULL,

    jornada_id          BIGINT UNSIGNED NULL,
    registrado_por      BIGINT UNSIGNED NOT NULL,
    cobro_id            BIGINT UNSIGNED NULL,

    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_pendientes_vecino FOREIGN KEY (vecino_id)
        REFERENCES vecinos(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pendientes_jornada FOREIGN KEY (jornada_id)
        REFERENCES jornadas_cobro(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_pendientes_registrado FOREIGN KEY (registrado_por)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pendientes_cobro FOREIGN KEY (cobro_id)
        REFERENCES cobros(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    CONSTRAINT chk_pendiente_periodo CHECK (periodo_mes BETWEEN 1 AND 12),
    CONSTRAINT chk_pendiente_monto CHECK (monto_pendiente > 0),

    INDEX idx_pendientes_vecino    (vecino_id),
    INDEX idx_pendientes_estado    (estado),
    INDEX idx_pendientes_periodo   (periodo_anio, periodo_mes),
    INDEX idx_pendientes_compuesto (vecino_id, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Pagos pendientes por vecinos no atendidos';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);
SET @operador_id = (SELECT id FROM users WHERE username = 'joacim_huanca' LIMIT 1);

SET @v_juan = (SELECT id FROM vecinos WHERE codigo = 'U-0001' LIMIT 1);
SET @v_maria = (SELECT id FROM vecinos WHERE codigo = 'U-0002' LIMIT 1);
SET @v_pedro = (SELECT id FROM vecinos WHERE codigo = 'U-0003' LIMIT 1);
SET @v_lucia = (SELECT id FROM vecinos WHERE codigo = 'U-0004' LIMIT 1);
SET @v_jose = (SELECT id FROM vecinos WHERE codigo = 'U-0005' LIMIT 1);
SET @v_rosa = (SELECT id FROM vecinos WHERE codigo = 'U-0006' LIMIT 1);

SET @m_mora = (SELECT id FROM multas WHERE codigo = 'M-01' LIMIT 1);
SET @m_faena = (SELECT id FROM multas WHERE codigo = 'M-04' LIMIT 1);

INSERT INTO jornadas_cobro
    (operador_id, fecha_inicio, fecha_cierre, estado,
     total_vecinos_atendidos, total_recaudado, total_pendientes_registrados)
SELECT @operador_id, '2026-05-05 14:00:00', '2026-05-05 17:30:00', 'cerrada', 4, 36.00, 1
WHERE NOT EXISTS (
    SELECT 1 FROM jornadas_cobro
    WHERE operador_id = @operador_id AND fecha_inicio = '2026-05-05 14:00:00'
);

INSERT INTO jornadas_cobro
    (operador_id, fecha_inicio, fecha_cierre, estado,
     total_vecinos_atendidos, total_recaudado, total_pendientes_registrados)
SELECT @operador_id, '2026-05-06 08:30:00', NULL, 'activa', 3, 20.00, 1
WHERE NOT EXISTS (
    SELECT 1 FROM jornadas_cobro
    WHERE operador_id = @operador_id AND fecha_inicio = '2026-05-06 08:30:00'
);

SET @jornada_ayer = (
    SELECT id FROM jornadas_cobro
    WHERE operador_id = @operador_id AND fecha_inicio = '2026-05-05 14:00:00'
    LIMIT 1
);
SET @jornada_hoy = (
    SELECT id FROM jornadas_cobro
    WHERE operador_id = @operador_id AND fecha_inicio = '2026-05-06 08:30:00'
    LIMIT 1
);

INSERT INTO multas_aplicadas
    (vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
     aplicada_por, motivo_aplicacion)
SELECT @v_maria, @m_mora, 4.00, 'pendiente', '2026-05-01', @admin_jass_id, 'Mora automatica por no pago en abril'
WHERE NOT EXISTS (
    SELECT 1 FROM multas_aplicadas
    WHERE vecino_id = @v_maria AND multa_id = @m_mora AND fecha_aplicacion = '2026-05-01'
);

INSERT INTO multas_aplicadas
    (vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
     aplicada_por, motivo_aplicacion)
SELECT @v_rosa, @m_faena, 10.00, 'pendiente', '2026-04-28', @admin_jass_id, 'Inasistencia a faena del 28/04/2026'
WHERE NOT EXISTS (
    SELECT 1 FROM multas_aplicadas
    WHERE vecino_id = @v_rosa AND multa_id = @m_faena AND fecha_aplicacion = '2026-04-28'
);

INSERT INTO multas_aplicadas
    (vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
     aplicada_por, motivo_aplicacion)
SELECT @v_rosa, @m_faena, 10.00, 'pendiente', '2026-03-22', @admin_jass_id, 'Inasistencia a faena del 22/03/2026'
WHERE NOT EXISTS (
    SELECT 1 FROM multas_aplicadas
    WHERE vecino_id = @v_rosa AND multa_id = @m_faena AND fecha_aplicacion = '2026-03-22'
);

INSERT INTO multas_aplicadas
    (vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
     aplicada_por, motivo_aplicacion)
SELECT @v_rosa, @m_mora, 4.00, 'pendiente', '2026-05-01', @admin_jass_id, 'Mora automatica por no pago en abril'
WHERE NOT EXISTS (
    SELECT 1 FROM multas_aplicadas
    WHERE vecino_id = @v_rosa AND multa_id = @m_mora AND fecha_aplicacion = '2026-05-01'
);

INSERT INTO cobros
    (numero_serie, vecino_id, operador_id, jornada_id,
     periodo_anio, periodo_mes,
     monto_cuota, monto_deuda_anterior, monto_multas, monto_total, monto_recibido,
     metodo_pago, estado, fecha_cobro, hora_cobro)
VALUES
('QLC-2026-0153', @v_rosa, @operador_id, @jornada_ayer, 2026, 5, 4.00, 0.00, 24.00, 28.00, 28.00, 'efectivo', 'pagado', '2026-05-05', '16:42:00'),
('QLC-2026-0152', @v_lucia, @operador_id, @jornada_ayer, 2026, 5, 8.00, 0.00, 0.00, 8.00, 8.00, 'efectivo', 'pagado', '2026-05-05', '15:20:00'),
('QLC-2026-0151', @v_pedro, @operador_id, @jornada_ayer, 2026, 5, 4.00, 0.00, 0.00, 4.00, 4.00, 'efectivo', 'pagado', '2026-05-05', '14:55:00'),
('QLC-2026-0150', @v_juan, @operador_id, @jornada_ayer, 2026, 5, 4.00, 0.00, 0.00, 4.00, 4.00, 'efectivo', 'anulado', '2026-05-05', '14:30:00'),
('QLC-2026-0156', @v_maria, @operador_id, @jornada_hoy, 2026, 5, 4.00, 4.00, 4.00, 12.00, 12.00, 'efectivo', 'pagado', '2026-05-06', '10:34:00'),
('QLC-2026-0155', @v_juan, @operador_id, @jornada_hoy, 2026, 5, 4.00, 0.00, 0.00, 4.00, 4.00, 'efectivo', 'pagado', '2026-05-06', '10:28:00'),
('QLC-2026-0154', @v_jose, @operador_id, @jornada_hoy, 2026, 5, 4.00, 0.00, 0.00, 4.00, 4.00, 'yape', 'pagado', '2026-05-06', '10:15:00')
ON DUPLICATE KEY UPDATE
    vecino_id = VALUES(vecino_id),
    operador_id = VALUES(operador_id),
    jornada_id = VALUES(jornada_id),
    periodo_anio = VALUES(periodo_anio),
    periodo_mes = VALUES(periodo_mes),
    monto_cuota = VALUES(monto_cuota),
    monto_deuda_anterior = VALUES(monto_deuda_anterior),
    monto_multas = VALUES(monto_multas),
    monto_total = VALUES(monto_total),
    monto_recibido = VALUES(monto_recibido),
    metodo_pago = VALUES(metodo_pago),
    estado = VALUES(estado),
    fecha_cobro = VALUES(fecha_cobro),
    hora_cobro = VALUES(hora_cobro),
    updated_at = CURRENT_TIMESTAMP;

UPDATE cobros
SET motivo_anulacion = 'Pago duplicado: Juan Perez ya habia pagado por transferencia',
    anulado_por = @admin_jass_id,
    fecha_anulacion = '2026-05-05 18:00:00',
    devolver_dinero = TRUE
WHERE numero_serie = 'QLC-2026-0150';

INSERT INTO comprobantes_pdf
    (cobro_id, numero_serie, ruta_archivo, nombre_archivo, codigo_qr_url,
     modalidad_entrega, impreso, fecha_impresion)
VALUES
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0156'), 'QLC-2026-0156', '/storage/comprobantes/2026/05/QLC-2026-0156.pdf', 'QLC-2026-0156.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0156', 'impresion', TRUE, '2026-05-06 10:35:00'),
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0155'), 'QLC-2026-0155', '/storage/comprobantes/2026/05/QLC-2026-0155.pdf', 'QLC-2026-0155.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0155', 'impresion', TRUE, '2026-05-06 10:29:00'),
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0154'), 'QLC-2026-0154', '/storage/comprobantes/2026/05/QLC-2026-0154.pdf', 'QLC-2026-0154.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0154', 'qr', FALSE, NULL),
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0153'), 'QLC-2026-0153', '/storage/comprobantes/2026/05/QLC-2026-0153.pdf', 'QLC-2026-0153.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0153', 'impresion', TRUE, '2026-05-05 16:43:00'),
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0152'), 'QLC-2026-0152', '/storage/comprobantes/2026/05/QLC-2026-0152.pdf', 'QLC-2026-0152.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0152', 'impresion', TRUE, '2026-05-05 15:21:00'),
((SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0151'), 'QLC-2026-0151', '/storage/comprobantes/2026/05/QLC-2026-0151.pdf', 'QLC-2026-0151.pdf', 'https://jass-quilcata.pe/v/QLC-2026-0151', 'impresion', TRUE, '2026-05-05 14:56:00')
ON DUPLICATE KEY UPDATE
    numero_serie = VALUES(numero_serie),
    ruta_archivo = VALUES(ruta_archivo),
    nombre_archivo = VALUES(nombre_archivo),
    codigo_qr_url = VALUES(codigo_qr_url),
    modalidad_entrega = VALUES(modalidad_entrega),
    impreso = VALUES(impreso),
    fecha_impresion = VALUES(fecha_impresion),
    updated_at = CURRENT_TIMESTAMP;

UPDATE multas_aplicadas
SET estado = 'cobrada',
    fecha_cobro = '2026-05-06',
    cobro_id = (SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0156')
WHERE vecino_id = @v_maria
  AND multa_id = @m_mora
  AND fecha_aplicacion = '2026-05-01';

UPDATE multas_aplicadas
SET estado = 'cobrada',
    fecha_cobro = '2026-05-05',
    cobro_id = (SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0153')
WHERE vecino_id = @v_rosa
  AND estado = 'pendiente';

INSERT INTO pagos_pendientes
    (vecino_id, periodo_anio, periodo_mes, monto_pendiente, estado,
     fecha_intento, motivo, jornada_id, registrado_por)
SELECT @v_pedro, 2026, 5, 4.00, 'pendiente', '2026-05-06', 'No estaba en casa - reagendado para proxima jornada', @jornada_hoy, @operador_id
WHERE NOT EXISTS (
    SELECT 1 FROM pagos_pendientes
    WHERE vecino_id = @v_pedro AND periodo_anio = 2026 AND periodo_mes = 5 AND estado = 'pendiente'
);

INSERT INTO pagos_pendientes
    (vecino_id, periodo_anio, periodo_mes, monto_pendiente, estado,
     fecha_intento, motivo, jornada_id, registrado_por)
SELECT @v_lucia, 2026, 4, 8.00, 'pendiente', '2026-04-15', 'Vivienda cerrada - sin contacto', @jornada_ayer, @operador_id
WHERE NOT EXISTS (
    SELECT 1 FROM pagos_pendientes
    WHERE vecino_id = @v_lucia AND periodo_anio = 2026 AND periodo_mes = 4 AND estado = 'pendiente'
);

UPDATE jornadas_cobro
SET total_recaudado = (
        SELECT COALESCE(SUM(monto_recibido), 0)
        FROM cobros
        WHERE jornada_id = @jornada_ayer AND estado = 'pagado'
    ),
    total_vecinos_atendidos = (
        SELECT COUNT(*)
        FROM cobros
        WHERE jornada_id = @jornada_ayer AND estado = 'pagado'
    ),
    total_pendientes_registrados = (
        SELECT COUNT(*)
        FROM pagos_pendientes
        WHERE jornada_id = @jornada_ayer
    )
WHERE id = @jornada_ayer;

UPDATE jornadas_cobro
SET total_recaudado = (
        SELECT COALESCE(SUM(monto_recibido), 0)
        FROM cobros
        WHERE jornada_id = @jornada_hoy AND estado = 'pagado'
    ),
    total_vecinos_atendidos = (
        SELECT COUNT(*)
        FROM cobros
        WHERE jornada_id = @jornada_hoy AND estado = 'pagado'
    ),
    total_pendientes_registrados = (
        SELECT COUNT(*)
        FROM pagos_pendientes
        WHERE jornada_id = @jornada_hoy
    )
WHERE id = @jornada_hoy;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_jornada_iniciar $$
CREATE PROCEDURE sp_jornada_iniciar(
    IN p_operador_id BIGINT UNSIGNED,
    IN p_observaciones VARCHAR(500),
    OUT p_jornada_id BIGINT UNSIGNED
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM jornadas_cobro
        WHERE operador_id = p_operador_id AND estado = 'activa'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El operador ya tiene una jornada activa';
    END IF;

    INSERT INTO jornadas_cobro (operador_id, observaciones)
    VALUES (p_operador_id, p_observaciones);

    SET p_jornada_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_jornada_cerrar $$
CREATE PROCEDURE sp_jornada_cerrar(
    IN p_jornada_id BIGINT UNSIGNED,
    IN p_observaciones VARCHAR(500)
)
BEGIN
    UPDATE jornadas_cobro
    SET estado = 'cerrada',
        fecha_cierre = CURRENT_TIMESTAMP,
        total_recaudado = (
            SELECT COALESCE(SUM(monto_recibido), 0)
            FROM cobros
            WHERE jornada_id = p_jornada_id AND estado = 'pagado'
        ),
        total_vecinos_atendidos = (
            SELECT COUNT(*)
            FROM cobros
            WHERE jornada_id = p_jornada_id AND estado = 'pagado'
        ),
        total_pendientes_registrados = (
            SELECT COUNT(*)
            FROM pagos_pendientes
            WHERE jornada_id = p_jornada_id
        ),
        observaciones = p_observaciones,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_jornada_id
      AND estado = 'activa';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Jornada activa no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_cobro_generar_serie $$
CREATE PROCEDURE sp_cobro_generar_serie(
    IN p_anio SMALLINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM cobros
    WHERE numero_serie LIKE CONCAT('QLC-', p_anio, '-%');

    SET p_numero_serie = CONCAT('QLC-', p_anio, '-', LPAD(v_numero, 4, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_cobro_registrar $$
CREATE PROCEDURE sp_cobro_registrar(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_operador_id BIGINT UNSIGNED,
    IN p_jornada_id BIGINT UNSIGNED,
    IN p_periodo_anio SMALLINT UNSIGNED,
    IN p_periodo_mes TINYINT UNSIGNED,
    IN p_monto_cuota DECIMAL(8,2),
    IN p_monto_deuda_anterior DECIMAL(8,2),
    IN p_monto_multas DECIMAL(8,2),
    IN p_monto_recibido DECIMAL(8,2),
    IN p_metodo_pago VARCHAR(20),
    IN p_observaciones VARCHAR(500),
    OUT p_cobro_id BIGINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_total DECIMAL(8,2) DEFAULT 0.00;

    IF p_periodo_mes NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mes de periodo no valido';
    END IF;

    IF p_metodo_pago NOT IN ('efectivo', 'transferencia', 'yape', 'plin', 'otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metodo de pago no valido';
    END IF;

    SET v_total = p_monto_cuota + p_monto_deuda_anterior + p_monto_multas;
    CALL sp_cobro_generar_serie(p_periodo_anio, p_numero_serie);

    INSERT INTO cobros (
        numero_serie, vecino_id, operador_id, jornada_id,
        periodo_anio, periodo_mes,
        monto_cuota, monto_deuda_anterior, monto_multas, monto_total, monto_recibido,
        metodo_pago, estado, fecha_cobro, hora_cobro, observaciones
    ) VALUES (
        p_numero_serie, p_vecino_id, p_operador_id, p_jornada_id,
        p_periodo_anio, p_periodo_mes,
        p_monto_cuota, p_monto_deuda_anterior, p_monto_multas, v_total, p_monto_recibido,
        p_metodo_pago, 'pagado', CURRENT_DATE, CURRENT_TIME, p_observaciones
    );

    SET p_cobro_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_cobro_anular $$
CREATE PROCEDURE sp_cobro_anular(
    IN p_cobro_id BIGINT UNSIGNED,
    IN p_motivo_anulacion VARCHAR(500),
    IN p_anulado_por BIGINT UNSIGNED,
    IN p_devolver_dinero BOOLEAN
)
BEGIN
    UPDATE cobros
    SET estado = 'anulado',
        motivo_anulacion = p_motivo_anulacion,
        anulado_por = p_anulado_por,
        fecha_anulacion = CURRENT_TIMESTAMP,
        devolver_dinero = p_devolver_dinero,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_cobro_id
      AND estado = 'pagado';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cobro pagado no encontrado';
    END IF;

    UPDATE multas_aplicadas
    SET estado = 'pendiente',
        fecha_cobro = NULL,
        cobro_id = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE cobro_id = p_cobro_id;

    UPDATE pagos_pendientes
    SET estado = 'pendiente',
        fecha_cobro = NULL,
        cobro_id = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE cobro_id = p_cobro_id;
END $$

DROP PROCEDURE IF EXISTS sp_comprobante_pdf_registrar $$
CREATE PROCEDURE sp_comprobante_pdf_registrar(
    IN p_cobro_id BIGINT UNSIGNED,
    IN p_ruta_archivo VARCHAR(500),
    IN p_nombre_archivo VARCHAR(100),
    IN p_tamano_bytes INT UNSIGNED,
    IN p_codigo_qr_url VARCHAR(255),
    IN p_modalidad_entrega VARCHAR(20),
    OUT p_comprobante_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_numero_serie VARCHAR(20);

    IF p_modalidad_entrega NOT IN ('pendiente', 'impresion', 'qr', 'email', 'multiple') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modalidad de entrega no valida';
    END IF;

    SELECT numero_serie INTO v_numero_serie
    FROM cobros
    WHERE id = p_cobro_id
    LIMIT 1;

    IF v_numero_serie IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cobro no encontrado';
    END IF;

    INSERT INTO comprobantes_pdf (
        cobro_id, numero_serie, ruta_archivo, nombre_archivo,
        tamano_bytes, codigo_qr_url, modalidad_entrega
    ) VALUES (
        p_cobro_id, v_numero_serie, p_ruta_archivo, p_nombre_archivo,
        p_tamano_bytes, p_codigo_qr_url, p_modalidad_entrega
    )
    ON DUPLICATE KEY UPDATE
        ruta_archivo = VALUES(ruta_archivo),
        nombre_archivo = VALUES(nombre_archivo),
        tamano_bytes = VALUES(tamano_bytes),
        codigo_qr_url = VALUES(codigo_qr_url),
        modalidad_entrega = VALUES(modalidad_entrega),
        updated_at = CURRENT_TIMESTAMP;

    SET p_comprobante_id = (
        SELECT id FROM comprobantes_pdf WHERE cobro_id = p_cobro_id LIMIT 1
    );
END $$

DROP PROCEDURE IF EXISTS sp_multa_aplicada_crear $$
CREATE PROCEDURE sp_multa_aplicada_crear(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_multa_id INT UNSIGNED,
    IN p_fecha_aplicacion DATE,
    IN p_aplicada_por BIGINT UNSIGNED,
    IN p_motivo_aplicacion VARCHAR(500),
    OUT p_multa_aplicada_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_monto DECIMAL(8,2);

    SELECT monto INTO v_monto
    FROM multas
    WHERE id = p_multa_id
      AND activa = TRUE
      AND deleted_at IS NULL
    LIMIT 1;

    IF v_monto IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Multa no encontrada o inactiva';
    END IF;

    INSERT INTO multas_aplicadas (
        vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
        aplicada_por, motivo_aplicacion
    ) VALUES (
        p_vecino_id, p_multa_id, v_monto, 'pendiente', p_fecha_aplicacion,
        p_aplicada_por, p_motivo_aplicacion
    );

    SET p_multa_aplicada_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_multa_aplicada_justificar $$
CREATE PROCEDURE sp_multa_aplicada_justificar(
    IN p_multa_aplicada_id BIGINT UNSIGNED,
    IN p_motivo_justificacion VARCHAR(500),
    IN p_documento_justificacion VARCHAR(255)
)
BEGIN
    UPDATE multas_aplicadas
    SET estado = 'justificada',
        motivo_justificacion = p_motivo_justificacion,
        documento_justificacion = p_documento_justificacion,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_multa_aplicada_id
      AND estado = 'pendiente';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Multa pendiente no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_pago_pendiente_registrar $$
CREATE PROCEDURE sp_pago_pendiente_registrar(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_periodo_anio SMALLINT UNSIGNED,
    IN p_periodo_mes TINYINT UNSIGNED,
    IN p_monto_pendiente DECIMAL(8,2),
    IN p_fecha_intento DATE,
    IN p_motivo VARCHAR(500),
    IN p_jornada_id BIGINT UNSIGNED,
    IN p_registrado_por BIGINT UNSIGNED,
    OUT p_pendiente_id BIGINT UNSIGNED
)
BEGIN
    IF p_periodo_mes NOT BETWEEN 1 AND 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mes de periodo no valido';
    END IF;

    IF p_monto_pendiente <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Monto pendiente no valido';
    END IF;

    INSERT INTO pagos_pendientes (
        vecino_id, periodo_anio, periodo_mes, monto_pendiente, estado,
        fecha_intento, motivo, jornada_id, registrado_por
    ) VALUES (
        p_vecino_id, p_periodo_anio, p_periodo_mes, p_monto_pendiente, 'pendiente',
        p_fecha_intento, p_motivo, p_jornada_id, p_registrado_por
    );

    SET p_pendiente_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_pagos_pendientes_marcar_cobrados $$
CREATE PROCEDURE sp_pagos_pendientes_marcar_cobrados(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_cobro_id BIGINT UNSIGNED
)
BEGIN
    UPDATE pagos_pendientes
    SET estado = 'cobrado',
        fecha_cobro = CURRENT_DATE,
        cobro_id = p_cobro_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE vecino_id = p_vecino_id
      AND estado = 'pendiente';
END $$

DROP PROCEDURE IF EXISTS sp_cobros_por_fecha $$
CREATE PROCEDURE sp_cobros_por_fecha(
    IN p_fecha DATE
)
BEGIN
    SELECT
        c.numero_serie,
        CONCAT(v.nombres, ' ', v.apellidos) AS vecino,
        c.monto_total,
        c.metodo_pago,
        c.estado,
        c.hora_cobro,
        CONCAT(u.nombres, ' ', u.apellidos) AS operador
    FROM cobros c
    INNER JOIN vecinos v ON c.vecino_id = v.id
    INNER JOIN users u ON c.operador_id = u.id
    WHERE c.fecha_cobro = COALESCE(p_fecha, CURRENT_DATE)
    ORDER BY c.hora_cobro DESC;
END $$

DROP PROCEDURE IF EXISTS sp_deuda_vecinos $$
CREATE PROCEDURE sp_deuda_vecinos()
BEGIN
    SELECT
        v.codigo,
        CONCAT(v.nombres, ' ', v.apellidos) AS vecino,
        COALESCE(pp.deuda_cuotas, 0) AS deuda_cuotas,
        COALESCE(ma.deuda_multas, 0) AS deuda_multas,
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
      AND v.estado = 'activo'
      AND (COALESCE(pp.deuda_cuotas, 0) + COALESCE(ma.deuda_multas, 0)) > 0
    ORDER BY deuda_total DESC;
END $$

DROP PROCEDURE IF EXISTS sp_jornada_activa_resumen $$
CREATE PROCEDURE sp_jornada_activa_resumen()
BEGIN
    SELECT
        j.id,
        CONCAT(u.nombres, ' ', u.apellidos) AS operador,
        j.fecha_inicio,
        TIMEDIFF(NOW(), j.fecha_inicio) AS duracion,
        j.total_vecinos_atendidos,
        j.total_recaudado,
        j.total_pendientes_registrados
    FROM jornadas_cobro j
    INNER JOIN users u ON j.operador_id = u.id
    WHERE j.estado = 'activa';
END $$

DROP PROCEDURE IF EXISTS sp_cobros_kpis $$
CREATE PROCEDURE sp_cobros_kpis(
    IN p_fecha DATE
)
BEGIN
    SELECT
        COUNT(*) AS total_cobros,
        SUM(CASE WHEN estado = 'pagado' THEN 1 ELSE 0 END) AS pagados,
        SUM(CASE WHEN estado = 'anulado' THEN 1 ELSE 0 END) AS anulados,
        COALESCE(SUM(CASE WHEN estado = 'pagado' THEN monto_recibido ELSE 0 END), 0) AS total_recaudado
    FROM cobros
    WHERE fecha_cobro = COALESCE(p_fecha, CURRENT_DATE);
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- Nota: los datos de ejemplo corresponden al 2026-05-06.
-- ============================================================

-- CALL sp_cobros_por_fecha('2026-05-06');
-- CALL sp_deuda_vecinos();
-- CALL sp_jornada_activa_resumen();
-- CALL sp_cobros_kpis('2026-05-06');

