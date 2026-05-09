-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 8: Eventos y Asistencias
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 22: tipos_evento
-- Catalogo de tipos de evento.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tipos_evento (
    id                          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre                      VARCHAR(50) NOT NULL UNIQUE,
    descripcion                 VARCHAR(255) NULL,
    icono                       VARCHAR(50) NULL,
    color_hex                   VARCHAR(7) NULL DEFAULT '#0891B2',
    es_obligatorio_default      BOOLEAN NOT NULL DEFAULT TRUE,
    genera_multa_default        BOOLEAN NOT NULL DEFAULT TRUE,
    multa_id_default            INT UNSIGNED NULL,
    activa                      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_tipos_evento_multa FOREIGN KEY (multa_id_default)
        REFERENCES multas(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_tipos_evento_activa (activa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catalogo de tipos de evento';

-- ------------------------------------------------------------
-- TABLA 23: eventos
-- Eventos programados: asambleas, faenas, capacitaciones.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS eventos (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo                      VARCHAR(15) NOT NULL UNIQUE
                                COMMENT 'Auto-generado: EVT-2026-0001',
    tipo_evento_id              INT UNSIGNED NOT NULL,

    titulo                      VARCHAR(150) NOT NULL,
    descripcion                 TEXT NULL,

    fecha_evento                DATE NOT NULL,
    hora_inicio                 TIME NOT NULL,
    duracion_minutos            INT UNSIGNED NOT NULL DEFAULT 120,
    lugar                       VARCHAR(255) NOT NULL,

    es_obligatorio              BOOLEAN NOT NULL DEFAULT TRUE,
    multa_id                    INT UNSIGNED NULL,

    convocatoria_tipo           ENUM('todos','por_categoria','manual') NOT NULL DEFAULT 'todos',
    categorias_convocadas_json  JSON NULL,
    total_convocados            INT UNSIGNED NOT NULL DEFAULT 0,

    estado                      ENUM('programado','lista_pendiente','realizado','cancelado')
                                NOT NULL DEFAULT 'programado',

    notificar_email             BOOLEAN NOT NULL DEFAULT FALSE,
    notificar_sms               BOOLEAN NOT NULL DEFAULT FALSE,
    convocatoria_pdf_path       VARCHAR(500) NULL,

    confirmada_por              BIGINT UNSIGNED NULL,
    fecha_confirmacion          TIMESTAMP NULL,
    multas_aplicadas_count      INT UNSIGNED NOT NULL DEFAULT 0,
    monto_multas_aplicadas      DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    motivo_cancelacion          VARCHAR(500) NULL,
    cancelado_por               BIGINT UNSIGNED NULL,
    fecha_cancelacion           TIMESTAMP NULL,

    created_by                  BIGINT UNSIGNED NOT NULL,
    updated_by                  BIGINT UNSIGNED NULL,
    deleted_by                  BIGINT UNSIGNED NULL,
    motivo_eliminacion          VARCHAR(500) NULL,
    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at                  TIMESTAMP NULL,

    CONSTRAINT fk_eventos_tipo FOREIGN KEY (tipo_evento_id)
        REFERENCES tipos_evento(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_multa FOREIGN KEY (multa_id)
        REFERENCES multas(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_confirmador FOREIGN KEY (confirmada_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_cancelador FOREIGN KEY (cancelado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_updater FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_eventos_deleter FOREIGN KEY (deleted_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_eventos_codigo    (codigo),
    INDEX idx_eventos_tipo      (tipo_evento_id),
    INDEX idx_eventos_fecha     (fecha_evento),
    INDEX idx_eventos_estado    (estado),
    INDEX idx_eventos_deleted   (deleted_at),
    INDEX idx_eventos_compuesto (estado, fecha_evento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Eventos de la junta';

-- ------------------------------------------------------------
-- TABLA 24: asistencias
-- Lista de asistencia por vecino y evento.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS asistencias (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    evento_id                   BIGINT UNSIGNED NOT NULL,
    vecino_id                   BIGINT UNSIGNED NOT NULL,

    estado                      ENUM('no_marcado','presente','tarde','justificado','ausente')
                                NOT NULL DEFAULT 'no_marcado',

    hora_llegada                TIME NULL,
    motivo_justificacion        VARCHAR(1000) NULL,
    documento_justificacion     VARCHAR(500) NULL,
    observaciones               VARCHAR(500) NULL,

    justificacion_aprobada      BOOLEAN NULL,
    aprobada_por                BIGINT UNSIGNED NULL,
    fecha_aprobacion            TIMESTAMP NULL,
    motivo_rechazo_just         VARCHAR(500) NULL,

    multa_aplicada_id           BIGINT UNSIGNED NULL,

    registrada_por              BIGINT UNSIGNED NULL,
    fecha_registro              TIMESTAMP NULL,

    motivo_ultima_edicion       VARCHAR(500) NULL,
    editado_por                 BIGINT UNSIGNED NULL,
    fecha_ultima_edicion        TIMESTAMP NULL,

    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_asistencias_evento FOREIGN KEY (evento_id)
        REFERENCES eventos(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_asistencias_vecino FOREIGN KEY (vecino_id)
        REFERENCES vecinos(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_asistencias_multa_apl FOREIGN KEY (multa_aplicada_id)
        REFERENCES multas_aplicadas(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_asistencias_registrador FOREIGN KEY (registrada_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_asistencias_aprobador FOREIGN KEY (aprobada_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_asistencias_editor FOREIGN KEY (editado_por)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    UNIQUE KEY uk_evento_vecino (evento_id, vecino_id),

    INDEX idx_asistencias_evento    (evento_id),
    INDEX idx_asistencias_vecino    (vecino_id),
    INDEX idx_asistencias_estado    (estado),
    INDEX idx_asistencias_compuesto (vecino_id, estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Lista de asistencia por evento';

-- ------------------------------------------------------------
-- FK pendiente en multas_aplicadas.evento_id
-- Se agrega solo si no existe, para permitir reejecucion.
-- ------------------------------------------------------------
SET @fk_multas_apl_evento_exists = (
    SELECT COUNT(*)
    FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
      AND TABLE_NAME = 'multas_aplicadas'
      AND CONSTRAINT_NAME = 'fk_multas_apl_evento'
);

SET @sql_add_fk_multas_apl_evento = IF(
    @fk_multas_apl_evento_exists = 0,
    'ALTER TABLE multas_aplicadas ADD CONSTRAINT fk_multas_apl_evento FOREIGN KEY (evento_id) REFERENCES eventos(id) ON DELETE SET NULL ON UPDATE CASCADE',
    'SELECT 1'
);

PREPARE stmt_add_fk_multas_apl_evento FROM @sql_add_fk_multas_apl_evento;
EXECUTE stmt_add_fk_multas_apl_evento;
DEALLOCATE PREPARE stmt_add_fk_multas_apl_evento;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);
SET @operador_id = (SELECT id FROM users WHERE username = 'joacim_huanca' LIMIT 1);
SET @m_faena = (SELECT id FROM multas WHERE codigo = 'M-04' LIMIT 1);

INSERT INTO tipos_evento
    (nombre, descripcion, icono, color_hex, es_obligatorio_default,
     genera_multa_default, multa_id_default, activa)
VALUES
('Asamblea Ordinaria', 'Reunion mensual ordinaria de la junta', 'Users', '#0891B2', TRUE, TRUE, @m_faena, TRUE),
('Asamblea Extraordinaria', 'Reunion convocada por temas especiales', 'AlertCircle', '#F59E0B', TRUE, TRUE, @m_faena, TRUE),
('Faena Comunal', 'Trabajo comunitario obligatorio', 'Wrench', '#10B981', TRUE, TRUE, @m_faena, TRUE),
('Capacitacion', 'Capacitaciones y talleres', 'GraduationCap', '#8B5CF6', FALSE, FALSE, NULL, TRUE),
('Otro', 'Otros tipos de evento', 'Calendar', '#94A3B8', FALSE, FALSE, NULL, TRUE)
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    icono = VALUES(icono),
    color_hex = VALUES(color_hex),
    es_obligatorio_default = VALUES(es_obligatorio_default),
    genera_multa_default = VALUES(genera_multa_default),
    multa_id_default = VALUES(multa_id_default),
    activa = VALUES(activa),
    updated_at = CURRENT_TIMESTAMP;

SET @tipo_asamblea_ord = (SELECT id FROM tipos_evento WHERE nombre = 'Asamblea Ordinaria' LIMIT 1);
SET @tipo_asamblea_ext = (SELECT id FROM tipos_evento WHERE nombre = 'Asamblea Extraordinaria' LIMIT 1);
SET @tipo_faena = (SELECT id FROM tipos_evento WHERE nombre = 'Faena Comunal' LIMIT 1);
SET @tipo_capacitacion = (SELECT id FROM tipos_evento WHERE nombre = 'Capacitacion' LIMIT 1);

INSERT INTO eventos
    (codigo, tipo_evento_id, titulo, descripcion,
     fecha_evento, hora_inicio, duracion_minutos, lugar,
     es_obligatorio, multa_id, convocatoria_tipo, total_convocados,
     estado, created_by)
VALUES
('EVT-2026-0010', @tipo_faena, 'Limpieza de reservorio', 'Faena de limpieza programada del reservorio sector A', '2026-05-15', '06:00:00', 240, 'Reservorio sector A', TRUE, @m_faena, 'todos', 124, 'programado', @admin_jass_id),
('EVT-2026-0009', @tipo_capacitacion, 'Uso eficiente del agua', 'Capacitacion abierta sobre buenas practicas', '2026-05-12', '19:00:00', 120, 'Casa Comunal de Quilcata', FALSE, NULL, 'todos', 124, 'programado', @admin_jass_id),
('EVT-2026-0008', @tipo_asamblea_ord, 'Asamblea Ordinaria de Mayo', 'Asamblea mensual ordinaria', '2026-05-06', '19:30:00', 180, 'Casa Comunal de Quilcata', TRUE, @m_faena, 'todos', 124, 'lista_pendiente', @admin_jass_id),
('EVT-2026-0007', @tipo_faena, 'Reparacion tuberia sector C', 'Faena de reparacion urgente', '2026-04-28', '06:00:00', 300, 'Tuberia sector C', TRUE, @m_faena, 'todos', 124, 'realizado', @admin_jass_id),
('EVT-2026-0006', @tipo_asamblea_ord, 'Asamblea Ordinaria de Abril', 'Asamblea mensual ordinaria', '2026-04-06', '19:30:00', 180, 'Casa Comunal de Quilcata', TRUE, @m_faena, 'todos', 124, 'realizado', @admin_jass_id),
('EVT-2026-0005', @tipo_faena, 'Limpieza de canales', 'Faena de limpieza de canales principales', '2026-03-22', '06:00:00', 240, 'Canal principal', TRUE, @m_faena, 'todos', 124, 'realizado', @admin_jass_id),
('EVT-2026-0004', @tipo_asamblea_ext, 'Aprobacion de tarifas 2026', 'Asamblea extraordinaria para aprobar nuevas tarifas', '2026-03-15', '19:00:00', 180, 'Casa Comunal de Quilcata', TRUE, @m_faena, 'todos', 124, 'realizado', @admin_jass_id),
('EVT-2026-0003', @tipo_faena, 'Faena cancelada por lluvia', 'Faena programada para reservorio', '2026-02-28', '06:00:00', 240, 'Reservorio', TRUE, @m_faena, 'todos', 124, 'cancelado', @admin_jass_id)
ON DUPLICATE KEY UPDATE
    tipo_evento_id = VALUES(tipo_evento_id),
    titulo = VALUES(titulo),
    descripcion = VALUES(descripcion),
    fecha_evento = VALUES(fecha_evento),
    hora_inicio = VALUES(hora_inicio),
    duracion_minutos = VALUES(duracion_minutos),
    lugar = VALUES(lugar),
    es_obligatorio = VALUES(es_obligatorio),
    multa_id = VALUES(multa_id),
    convocatoria_tipo = VALUES(convocatoria_tipo),
    total_convocados = VALUES(total_convocados),
    estado = VALUES(estado),
    updated_by = @admin_jass_id,
    updated_at = CURRENT_TIMESTAMP,
    deleted_at = NULL;

UPDATE eventos SET
    confirmada_por = @operador_id,
    fecha_confirmacion = '2026-04-28 12:00:00',
    multas_aplicadas_count = 28,
    monto_multas_aplicadas = 280.00
WHERE codigo = 'EVT-2026-0007';

UPDATE eventos SET
    confirmada_por = @operador_id,
    fecha_confirmacion = '2026-04-06 21:30:00',
    multas_aplicadas_count = 17,
    monto_multas_aplicadas = 170.00
WHERE codigo = 'EVT-2026-0006';

UPDATE eventos SET
    confirmada_por = @operador_id,
    fecha_confirmacion = '2026-03-22 11:00:00',
    multas_aplicadas_count = 24,
    monto_multas_aplicadas = 240.00
WHERE codigo = 'EVT-2026-0005';

UPDATE eventos SET
    confirmada_por = @admin_jass_id,
    fecha_confirmacion = '2026-03-15 21:30:00',
    multas_aplicadas_count = 6,
    monto_multas_aplicadas = 60.00
WHERE codigo = 'EVT-2026-0004';

UPDATE eventos SET
    motivo_cancelacion = 'Cancelada por lluvia intensa - reagendada',
    cancelado_por = @admin_jass_id,
    fecha_cancelacion = '2026-02-28 05:30:00'
WHERE codigo = 'EVT-2026-0003';

SET @evento_abril = (SELECT id FROM eventos WHERE codigo = 'EVT-2026-0006' LIMIT 1);
SET @evento_mayo = (SELECT id FROM eventos WHERE codigo = 'EVT-2026-0008' LIMIT 1);

-- Lista de ejemplo para Asamblea Abril. Se incluyen vecinos no eliminados para que U-0006 y U-0007 puedan figurar ausentes.
INSERT INTO asistencias
    (evento_id, vecino_id, estado, hora_llegada, motivo_justificacion,
     registrada_por, fecha_registro)
SELECT
    @evento_abril,
    v.id,
    CASE
        WHEN v.codigo IN ('U-0001','U-0003','U-0005','U-0008') THEN 'presente'
        WHEN v.codigo = 'U-0002' THEN 'tarde'
        WHEN v.codigo = 'U-0004' THEN 'justificado'
        WHEN v.codigo IN ('U-0006','U-0007') THEN 'ausente'
        ELSE 'presente'
    END AS estado,
    CASE WHEN v.codigo = 'U-0002' THEN '19:50:00' ELSE NULL END,
    CASE WHEN v.codigo = 'U-0004'
         THEN 'Viaje medico a Cusco con constancia medica'
         ELSE NULL END,
    @operador_id,
    '2026-04-06 21:25:00'
FROM vecinos v
WHERE v.deleted_at IS NULL
ON DUPLICATE KEY UPDATE
    estado = VALUES(estado),
    hora_llegada = VALUES(hora_llegada),
    motivo_justificacion = VALUES(motivo_justificacion),
    registrada_por = VALUES(registrada_por),
    fecha_registro = VALUES(fecha_registro),
    updated_at = CURRENT_TIMESTAMP;

-- Lista pendiente de Mayo para la pantalla "Pasar lista".
INSERT INTO asistencias
    (evento_id, vecino_id, estado, registrada_por, fecha_registro)
SELECT
    @evento_mayo,
    v.id,
    'no_marcado',
    NULL,
    NULL
FROM vecinos v
WHERE v.deleted_at IS NULL
ON DUPLICATE KEY UPDATE
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO multas_aplicadas
    (vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
     aplicada_por, motivo_aplicacion, evento_id)
SELECT
    a.vecino_id,
    @m_faena,
    10.00,
    'pendiente',
    '2026-04-06',
    @operador_id,
    CONCAT('Inasistencia a Asamblea Ordinaria de Abril (', (SELECT codigo FROM eventos WHERE id = a.evento_id), ')'),
    a.evento_id
FROM asistencias a
WHERE a.evento_id = @evento_abril
  AND a.estado = 'ausente'
  AND NOT EXISTS (
      SELECT 1
      FROM multas_aplicadas ma
      WHERE ma.vecino_id = a.vecino_id
        AND ma.evento_id = a.evento_id
        AND ma.multa_id = @m_faena
  );

UPDATE asistencias a
INNER JOIN multas_aplicadas ma
    ON ma.vecino_id = a.vecino_id
    AND ma.evento_id = a.evento_id
    AND ma.multa_id = @m_faena
SET a.multa_aplicada_id = ma.id
WHERE a.evento_id = @evento_abril
  AND a.estado = 'ausente';

UPDATE asistencias
SET justificacion_aprobada = TRUE,
    aprobada_por = @admin_jass_id,
    fecha_aprobacion = '2026-04-07 09:00:00'
WHERE evento_id = @evento_abril
  AND vecino_id = (SELECT id FROM vecinos WHERE codigo = 'U-0004' LIMIT 1);

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_evento_generar_codigo $$
CREATE PROCEDURE sp_evento_generar_codigo(
    IN p_anio SMALLINT UNSIGNED,
    OUT p_codigo VARCHAR(15)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(codigo, 10) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM eventos
    WHERE codigo LIKE CONCAT('EVT-', p_anio, '-%');

    SET p_codigo = CONCAT('EVT-', p_anio, '-', LPAD(v_numero, 4, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_evento_crear $$
CREATE PROCEDURE sp_evento_crear(
    IN p_tipo_evento_id INT UNSIGNED,
    IN p_titulo VARCHAR(150),
    IN p_descripcion TEXT,
    IN p_fecha_evento DATE,
    IN p_hora_inicio TIME,
    IN p_duracion_minutos INT UNSIGNED,
    IN p_lugar VARCHAR(255),
    IN p_convocatoria_tipo VARCHAR(20),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_evento_id BIGINT UNSIGNED,
    OUT p_codigo VARCHAR(15)
)
BEGIN
    DECLARE v_es_obligatorio BOOLEAN DEFAULT TRUE;
    DECLARE v_multa_id INT UNSIGNED DEFAULT NULL;

    IF p_convocatoria_tipo NOT IN ('todos', 'por_categoria', 'manual') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de convocatoria no valido';
    END IF;

    SELECT es_obligatorio_default, multa_id_default
    INTO v_es_obligatorio, v_multa_id
    FROM tipos_evento
    WHERE id = p_tipo_evento_id
      AND activa = TRUE
    LIMIT 1;

    IF v_es_obligatorio IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de evento no encontrado o inactivo';
    END IF;

    CALL sp_evento_generar_codigo(YEAR(p_fecha_evento), p_codigo);

    INSERT INTO eventos (
        codigo, tipo_evento_id, titulo, descripcion, fecha_evento, hora_inicio,
        duracion_minutos, lugar, es_obligatorio, multa_id, convocatoria_tipo,
        total_convocados, estado, created_by
    ) VALUES (
        p_codigo, p_tipo_evento_id, p_titulo, p_descripcion, p_fecha_evento, p_hora_inicio,
        COALESCE(p_duracion_minutos, 120), p_lugar, v_es_obligatorio, v_multa_id, p_convocatoria_tipo,
        0, 'programado', p_created_by
    );

    SET p_evento_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_evento_generar_lista $$
CREATE PROCEDURE sp_evento_generar_lista(
    IN p_evento_id BIGINT UNSIGNED
)
BEGIN
    INSERT INTO asistencias (evento_id, vecino_id, estado)
    SELECT p_evento_id, v.id, 'no_marcado'
    FROM vecinos v
    WHERE v.deleted_at IS NULL
    ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

    UPDATE eventos
    SET total_convocados = (
            SELECT COUNT(*)
            FROM asistencias
            WHERE evento_id = p_evento_id
        ),
        estado = IF(estado = 'programado', 'lista_pendiente', estado),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_evento_id;
END $$

DROP PROCEDURE IF EXISTS sp_asistencia_marcar $$
CREATE PROCEDURE sp_asistencia_marcar(
    IN p_asistencia_id BIGINT UNSIGNED,
    IN p_estado VARCHAR(20),
    IN p_hora_llegada TIME,
    IN p_motivo_justificacion VARCHAR(1000),
    IN p_documento_justificacion VARCHAR(500),
    IN p_observaciones VARCHAR(500),
    IN p_registrada_por BIGINT UNSIGNED
)
BEGIN
    IF p_estado NOT IN ('no_marcado', 'presente', 'tarde', 'justificado', 'ausente') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de asistencia no valido';
    END IF;

    UPDATE asistencias
    SET estado = p_estado,
        hora_llegada = IF(p_estado = 'tarde', p_hora_llegada, NULL),
        motivo_justificacion = IF(p_estado = 'justificado', p_motivo_justificacion, NULL),
        documento_justificacion = IF(p_estado = 'justificado', p_documento_justificacion, NULL),
        observaciones = p_observaciones,
        registrada_por = p_registrada_por,
        fecha_registro = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_asistencia_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Asistencia no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_evento_confirmar_lista $$
CREATE PROCEDURE sp_evento_confirmar_lista(
    IN p_evento_id BIGINT UNSIGNED,
    IN p_confirmada_por BIGINT UNSIGNED
)
BEGIN
    DECLARE v_multa_id INT UNSIGNED DEFAULT NULL;

    SELECT multa_id INTO v_multa_id
    FROM eventos
    WHERE id = p_evento_id
      AND es_obligatorio = TRUE
    LIMIT 1;

    IF v_multa_id IS NOT NULL THEN
        INSERT INTO multas_aplicadas (
            vecino_id, multa_id, monto_aplicado, estado, fecha_aplicacion,
            aplicada_por, motivo_aplicacion, evento_id
        )
        SELECT
            a.vecino_id,
            v_multa_id,
            m.monto,
            'pendiente',
            e.fecha_evento,
            p_confirmada_por,
            CONCAT('Inasistencia a ', e.titulo, ' (', e.codigo, ')'),
            e.id
        FROM asistencias a
        INNER JOIN eventos e ON e.id = a.evento_id
        INNER JOIN multas m ON m.id = v_multa_id
        WHERE a.evento_id = p_evento_id
          AND a.estado = 'ausente'
          AND NOT EXISTS (
              SELECT 1
              FROM multas_aplicadas ma
              WHERE ma.vecino_id = a.vecino_id
                AND ma.evento_id = a.evento_id
                AND ma.multa_id = v_multa_id
          );

        UPDATE asistencias a
        INNER JOIN multas_aplicadas ma
            ON ma.vecino_id = a.vecino_id
            AND ma.evento_id = a.evento_id
            AND ma.multa_id = v_multa_id
        SET a.multa_aplicada_id = ma.id
        WHERE a.evento_id = p_evento_id
          AND a.estado = 'ausente';
    END IF;

    UPDATE eventos
    SET estado = 'realizado',
        confirmada_por = p_confirmada_por,
        fecha_confirmacion = CURRENT_TIMESTAMP,
        multas_aplicadas_count = (
            SELECT COUNT(*)
            FROM multas_aplicadas
            WHERE evento_id = p_evento_id
        ),
        monto_multas_aplicadas = (
            SELECT COALESCE(SUM(monto_aplicado), 0)
            FROM multas_aplicadas
            WHERE evento_id = p_evento_id
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_evento_id;
END $$

DROP PROCEDURE IF EXISTS sp_eventos_proximos $$
CREATE PROCEDURE sp_eventos_proximos()
BEGIN
    SELECT
        e.codigo,
        te.nombre AS tipo,
        e.titulo,
        DATE_FORMAT(e.fecha_evento, '%d/%m/%Y') AS fecha,
        TIME_FORMAT(e.hora_inicio, '%H:%i') AS hora,
        e.lugar,
        e.total_convocados,
        e.estado
    FROM eventos e
    INNER JOIN tipos_evento te ON e.tipo_evento_id = te.id
    WHERE e.estado IN ('programado', 'lista_pendiente')
      AND e.deleted_at IS NULL
    ORDER BY e.fecha_evento ASC;
END $$

DROP PROCEDURE IF EXISTS sp_eventos_pasados_asistencia $$
CREATE PROCEDURE sp_eventos_pasados_asistencia()
BEGIN
    SELECT
        e.codigo,
        e.titulo,
        DATE_FORMAT(e.fecha_evento, '%d/%m/%Y') AS fecha,
        e.total_convocados,
        SUM(CASE WHEN a.estado IN ('presente', 'tarde') THEN 1 ELSE 0 END) AS presentes,
        SUM(CASE WHEN a.estado = 'justificado' THEN 1 ELSE 0 END) AS justificados,
        SUM(CASE WHEN a.estado = 'ausente' THEN 1 ELSE 0 END) AS ausentes,
        ROUND(
            SUM(CASE WHEN a.estado IN ('presente', 'tarde') THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(e.total_convocados, 0),
            1
        ) AS porcentaje_asistencia
    FROM eventos e
    LEFT JOIN asistencias a ON a.evento_id = e.id
    WHERE e.estado = 'realizado'
    GROUP BY e.id, e.codigo, e.titulo, e.fecha_evento, e.total_convocados
    ORDER BY e.fecha_evento DESC;
END $$

DROP PROCEDURE IF EXISTS sp_asistencia_por_vecino $$
CREATE PROCEDURE sp_asistencia_por_vecino()
BEGIN
    SELECT
        v.codigo,
        CONCAT(v.nombres, ' ', v.apellidos) AS vecino,
        COUNT(a.id) AS eventos_convocados,
        SUM(CASE WHEN a.estado = 'presente' THEN 1 ELSE 0 END) AS asistio,
        SUM(CASE WHEN a.estado = 'tarde' THEN 1 ELSE 0 END) AS tarde,
        SUM(CASE WHEN a.estado = 'justificado' THEN 1 ELSE 0 END) AS justificado,
        SUM(CASE WHEN a.estado = 'ausente' THEN 1 ELSE 0 END) AS falto,
        ROUND(
            SUM(CASE WHEN a.estado IN ('presente', 'tarde') THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(COUNT(a.id), 0),
            1
        ) AS porcentaje_asistencia,
        SUM(CASE WHEN a.estado = 'ausente' AND ma.estado = 'pendiente'
                 THEN ma.monto_aplicado ELSE 0 END) AS deuda_multas_inasistencia
    FROM vecinos v
    LEFT JOIN asistencias a ON a.vecino_id = v.id
    LEFT JOIN multas_aplicadas ma ON ma.id = a.multa_aplicada_id
    WHERE v.deleted_at IS NULL
      AND v.estado = 'activo'
    GROUP BY v.id, v.codigo, v.nombres, v.apellidos
    ORDER BY porcentaje_asistencia DESC;
END $$

DROP PROCEDURE IF EXISTS sp_asistencia_kpis $$
CREATE PROCEDURE sp_asistencia_kpis()
BEGIN
    SELECT
        (SELECT COUNT(*) FROM eventos WHERE estado = 'lista_pendiente' AND deleted_at IS NULL) AS pendientes_lista,
        (SELECT COUNT(*) FROM eventos WHERE estado = 'programado' AND deleted_at IS NULL) AS proximos,
        (SELECT COUNT(*) FROM eventos WHERE estado = 'realizado'
            AND YEAR(fecha_evento) = YEAR(CURRENT_DATE)
            AND MONTH(fecha_evento) = MONTH(CURRENT_DATE)) AS listas_pasadas_mes,
        (SELECT COUNT(*) FROM multas_aplicadas WHERE evento_id IS NOT NULL AND estado = 'pendiente') AS multas_inasistencia_activas;
END $$

DROP PROCEDURE IF EXISTS sp_asistencia_detalle_evento $$
CREATE PROCEDURE sp_asistencia_detalle_evento(
    IN p_codigo_evento VARCHAR(15)
)
BEGIN
    SELECT
        a.id AS asistencia_id,
        v.codigo,
        CONCAT(v.nombres, ' ', v.apellidos) AS vecino,
        a.estado,
        a.hora_llegada,
        a.motivo_justificacion,
        CASE WHEN a.multa_aplicada_id IS NOT NULL THEN 'Si' ELSE 'No' END AS multa_aplicada
    FROM asistencias a
    INNER JOIN vecinos v ON a.vecino_id = v.id
    WHERE a.evento_id = (SELECT id FROM eventos WHERE codigo = p_codigo_evento LIMIT 1)
    ORDER BY v.apellidos, v.nombres;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_eventos_proximos();
-- CALL sp_eventos_pasados_asistencia();
-- CALL sp_asistencia_por_vecino();
-- CALL sp_asistencia_kpis();
-- CALL sp_asistencia_detalle_evento('EVT-2026-0008');

