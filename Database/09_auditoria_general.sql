-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 9: Auditoria General
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 25: audit_logs
-- Registro centralizado de cambios del sistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    tabla                   VARCHAR(50) NOT NULL
                            COMMENT 'Nombre de la tabla modificada',
    registro_id             BIGINT UNSIGNED NOT NULL
                            COMMENT 'PK del registro modificado',
    operacion               ENUM('INSERT','UPDATE','DELETE') NOT NULL,

    usuario_id              BIGINT UNSIGNED NULL
                            COMMENT 'NULL si es sistema',
    usuario_nombre          VARCHAR(100) NULL,
    ip_address              VARCHAR(45) NULL,
    user_agent              TEXT NULL,

    datos_anteriores_json   JSON NULL,
    datos_nuevos_json       JSON NULL,

    razon_cambio            VARCHAR(1000) NULL,
    campos_modificados      JSON NULL,

    timestamp               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_audit_tabla     (tabla),
    INDEX idx_audit_registro  (tabla, registro_id),
    INDEX idx_audit_usuario   (usuario_id),
    INDEX idx_audit_operacion (operacion),
    INDEX idx_audit_timestamp (timestamp),
    INDEX idx_audit_compuesto (tabla, timestamp, operacion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Auditoria centralizada de cambios';

-- ============================================================
-- TRIGGERS PARA AUDITORIA AUTOMATICA
-- ============================================================

DROP TRIGGER IF EXISTS users_audit_update;
DROP TRIGGER IF EXISTS cobros_audit_update;
DROP TRIGGER IF EXISTS egresos_audit_update;
DROP TRIGGER IF EXISTS multas_aplicadas_audit_update;
DROP TRIGGER IF EXISTS reportes_mensuales_audit_update;
DROP TRIGGER IF EXISTS asistencias_audit_update;
DROP TRIGGER IF EXISTS tarifas_audit_update;

DELIMITER $$

CREATE TRIGGER users_audit_update
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'users',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.created_by, NEW.id),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users WHERE id = COALESCE(NEW.created_by, NEW.id)),
        JSON_OBJECT(
            'username', OLD.username,
            'rol_id', OLD.rol_id,
            'estado', OLD.estado,
            'intentos_fallidos', OLD.intentos_fallidos,
            'ultimo_login', OLD.ultimo_login,
            'requiere_cambio_password', OLD.requiere_cambio_password
        ),
        JSON_OBJECT(
            'username', NEW.username,
            'rol_id', NEW.rol_id,
            'estado', NEW.estado,
            'intentos_fallidos', NEW.intentos_fallidos,
            'ultimo_login', NEW.ultimo_login,
            'requiere_cambio_password', NEW.requiere_cambio_password
        ),
        CASE
            WHEN OLD.estado <> NEW.estado THEN CONCAT('Cambio de estado: ', OLD.estado, ' -> ', NEW.estado)
            WHEN OLD.rol_id <> NEW.rol_id THEN 'Cambio de rol'
            ELSE 'Actualizacion de usuario'
        END,
        JSON_ARRAY(
            IF(OLD.username <> NEW.username, 'username', NULL),
            IF(OLD.rol_id <> NEW.rol_id, 'rol_id', NULL),
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(OLD.intentos_fallidos <> NEW.intentos_fallidos, 'intentos_fallidos', NULL),
            IF(NOT (OLD.ultimo_login <=> NEW.ultimo_login), 'ultimo_login', NULL),
            IF(OLD.requiere_cambio_password <> NEW.requiere_cambio_password, 'requiere_cambio_password', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER cobros_audit_update
AFTER UPDATE ON cobros
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'cobros',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.anulado_por, NEW.editado_por, NEW.operador_id),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.anulado_por, NEW.editado_por, NEW.operador_id)),
        JSON_OBJECT(
            'numero_serie', OLD.numero_serie,
            'monto_total', OLD.monto_total,
            'monto_recibido', OLD.monto_recibido,
            'estado', OLD.estado,
            'metodo_pago', OLD.metodo_pago
        ),
        JSON_OBJECT(
            'numero_serie', NEW.numero_serie,
            'monto_total', NEW.monto_total,
            'monto_recibido', NEW.monto_recibido,
            'estado', NEW.estado,
            'metodo_pago', NEW.metodo_pago
        ),
        COALESCE(NEW.motivo_anulacion, NEW.motivo_ultima_edicion, 'Actualizacion de cobro'),
        JSON_ARRAY(
            IF(OLD.monto_total <> NEW.monto_total, 'monto_total', NULL),
            IF(OLD.monto_recibido <> NEW.monto_recibido, 'monto_recibido', NULL),
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(OLD.metodo_pago <> NEW.metodo_pago, 'metodo_pago', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER egresos_audit_update
AFTER UPDATE ON egresos
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'egresos',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.aprobado_por, NEW.rechazado_por, NEW.anulado_por, NEW.editado_por, NEW.created_by),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.aprobado_por, NEW.rechazado_por, NEW.anulado_por, NEW.editado_por, NEW.created_by)),
        JSON_OBJECT(
            'numero_serie', OLD.numero_serie,
            'monto', OLD.monto,
            'estado', OLD.estado,
            'concepto', OLD.concepto
        ),
        JSON_OBJECT(
            'numero_serie', NEW.numero_serie,
            'monto', NEW.monto,
            'estado', NEW.estado,
            'concepto', NEW.concepto
        ),
        COALESCE(NEW.motivo_rechazo, NEW.motivo_anulacion, NEW.motivo_ultima_edicion, 'Actualizacion de egreso'),
        JSON_ARRAY(
            IF(OLD.monto <> NEW.monto, 'monto', NULL),
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(OLD.concepto <> NEW.concepto, 'concepto', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER multas_aplicadas_audit_update
AFTER UPDATE ON multas_aplicadas
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'multas_aplicadas',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.anulada_por, NEW.aplicada_por),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.anulada_por, NEW.aplicada_por)),
        JSON_OBJECT(
            'vecino_id', OLD.vecino_id,
            'estado', OLD.estado,
            'monto_aplicado', OLD.monto_aplicado,
            'cobro_id', OLD.cobro_id
        ),
        JSON_OBJECT(
            'vecino_id', NEW.vecino_id,
            'estado', NEW.estado,
            'monto_aplicado', NEW.monto_aplicado,
            'cobro_id', NEW.cobro_id
        ),
        COALESCE(NEW.motivo_anulacion, NEW.motivo_justificacion, 'Actualizacion de multa aplicada'),
        JSON_ARRAY(
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(OLD.monto_aplicado <> NEW.monto_aplicado, 'monto_aplicado', NULL),
            IF(NOT (OLD.cobro_id <=> NEW.cobro_id), 'cobro_id', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER reportes_mensuales_audit_update
AFTER UPDATE ON reportes_mensuales
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'reportes_mensuales',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.aprobado_por, NEW.rechazado_por),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.aprobado_por, NEW.rechazado_por)),
        JSON_OBJECT(
            'periodo', CONCAT(OLD.periodo_anio, '-', LPAD(OLD.periodo_mes, 2, '0')),
            'estado', OLD.estado,
            'balance_neto', OLD.balance_neto,
            'version', OLD.version
        ),
        JSON_OBJECT(
            'periodo', CONCAT(NEW.periodo_anio, '-', LPAD(NEW.periodo_mes, 2, '0')),
            'estado', NEW.estado,
            'balance_neto', NEW.balance_neto,
            'version', NEW.version
        ),
        COALESCE(NEW.observaciones_admin, NEW.motivo_rechazo, 'Actualizacion de reporte mensual'),
        JSON_ARRAY(
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(OLD.balance_neto <> NEW.balance_neto, 'balance_neto', NULL),
            IF(OLD.version <> NEW.version, 'version', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER asistencias_audit_update
AFTER UPDATE ON asistencias
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'asistencias',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.editado_por, NEW.registrada_por, NEW.aprobada_por),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.editado_por, NEW.registrada_por, NEW.aprobada_por)),
        JSON_OBJECT(
            'vecino_id', OLD.vecino_id,
            'estado', OLD.estado,
            'motivo_justificacion', OLD.motivo_justificacion,
            'multa_aplicada_id', OLD.multa_aplicada_id
        ),
        JSON_OBJECT(
            'vecino_id', NEW.vecino_id,
            'estado', NEW.estado,
            'motivo_justificacion', NEW.motivo_justificacion,
            'multa_aplicada_id', NEW.multa_aplicada_id
        ),
        COALESCE(NEW.motivo_ultima_edicion, NEW.motivo_rechazo_just, 'Actualizacion de asistencia'),
        JSON_ARRAY(
            IF(OLD.estado <> NEW.estado, 'estado', NULL),
            IF(NOT (OLD.motivo_justificacion <=> NEW.motivo_justificacion), 'motivo_justificacion', NULL),
            IF(NOT (OLD.multa_aplicada_id <=> NEW.multa_aplicada_id), 'multa_aplicada_id', NULL)
        ),
        NOW()
    );
END$$

CREATE TRIGGER tarifas_audit_update
AFTER UPDATE ON tarifas
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, campos_modificados, timestamp)
    VALUES (
        'tarifas',
        NEW.id,
        'UPDATE',
        COALESCE(NEW.updated_by, NEW.created_by),
        (SELECT CONCAT(nombres, ' ', apellidos) FROM users
         WHERE id = COALESCE(NEW.updated_by, NEW.created_by)),
        JSON_OBJECT(
            'categoria_id', OLD.categoria_id,
            'monto', OLD.monto,
            'activa', OLD.activa,
            'fecha_vigencia_fin', OLD.fecha_vigencia_fin
        ),
        JSON_OBJECT(
            'categoria_id', NEW.categoria_id,
            'monto', NEW.monto,
            'activa', NEW.activa,
            'fecha_vigencia_fin', NEW.fecha_vigencia_fin
        ),
        COALESCE(NEW.motivo_cambio, 'Actualizacion de tarifa'),
        JSON_ARRAY(
            IF(OLD.monto <> NEW.monto, 'monto', NULL),
            IF(OLD.activa <> NEW.activa, 'activa', NULL),
            IF(NOT (OLD.fecha_vigencia_fin <=> NEW.fecha_vigencia_fin), 'fecha_vigencia_fin', NULL)
        ),
        NOW()
    );
END$$

DELIMITER ;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);
SET @operador_id = (SELECT id FROM users WHERE username = 'joacim_huanca' LIMIT 1);
SET @cobro_anulado_id = (SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0150' LIMIT 1);
SET @egreso_pendiente_id = (SELECT id FROM egresos WHERE numero_serie = 'EGR-2026-0013' LIMIT 1);
SET @asistencia_maria_id = (
    SELECT a.id
    FROM asistencias a
    INNER JOIN eventos e ON e.id = a.evento_id
    INNER JOIN vecinos v ON v.id = a.vecino_id
    WHERE e.codigo = 'EVT-2026-0006'
      AND v.codigo = 'U-0002'
    LIMIT 1
);
SET @reporte_dic_id = (
    SELECT id
    FROM reportes_mensuales
    WHERE periodo_anio = 2025
      AND periodo_mes = 12
    LIMIT 1
);

INSERT INTO audit_logs
    (tabla, registro_id, operacion, usuario_id, usuario_nombre,
     datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
SELECT
    'users', @operador_id, 'UPDATE', @admin_jass_id, 'Administrador JASS QUILCATA',
    JSON_OBJECT('estado', 'activo', 'intentos_fallidos', 0),
    JSON_OBJECT('estado', 'bloqueado', 'intentos_fallidos', 3),
    'Bloqueo tras 3 intentos fallidos de login',
    '2026-05-06 14:30:00'
WHERE NOT EXISTS (
    SELECT 1 FROM audit_logs
    WHERE tabla = 'users'
      AND registro_id = @operador_id
      AND razon_cambio = 'Bloqueo tras 3 intentos fallidos de login'
);

INSERT INTO audit_logs
    (tabla, registro_id, operacion, usuario_id, usuario_nombre,
     datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
SELECT
    'cobros', @cobro_anulado_id, 'UPDATE', @admin_jass_id, 'Administrador JASS QUILCATA',
    JSON_OBJECT('numero_serie', 'QLC-2026-0150', 'estado', 'pagado', 'monto_total', 4.00),
    JSON_OBJECT('numero_serie', 'QLC-2026-0150', 'estado', 'anulado', 'monto_total', 4.00),
    'Pago duplicado: Juan Perez ya habia pagado por transferencia',
    '2026-05-05 18:00:00'
WHERE @cobro_anulado_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM audit_logs
    WHERE tabla = 'cobros'
      AND registro_id = @cobro_anulado_id
      AND razon_cambio LIKE 'Pago duplicado:%'
);

INSERT INTO audit_logs
    (tabla, registro_id, operacion, usuario_id, usuario_nombre,
     datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
SELECT
    'egresos', @egreso_pendiente_id, 'UPDATE', @admin_jass_id, 'Administrador JASS QUILCATA',
    JSON_OBJECT('numero_serie', 'EGR-2026-0013', 'estado', 'pendiente_aprobacion', 'monto', 250.00),
    JSON_OBJECT('numero_serie', 'EGR-2026-0013', 'estado', 'aprobado', 'monto', 250.00),
    'Aprobado: Reparacion urgente de motobomba',
    '2026-05-06 10:30:00'
WHERE @egreso_pendiente_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM audit_logs
    WHERE tabla = 'egresos'
      AND registro_id = @egreso_pendiente_id
      AND razon_cambio = 'Aprobado: Reparacion urgente de motobomba'
);

INSERT INTO audit_logs
    (tabla, registro_id, operacion, usuario_id, usuario_nombre,
     datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
SELECT
    'asistencias', @asistencia_maria_id, 'UPDATE', @operador_id, 'Joacim Huanca Asto',
    JSON_OBJECT('estado', 'no_marcado'),
    JSON_OBJECT('estado', 'presente'),
    'Pasar lista automatica',
    '2026-04-06 21:25:00'
WHERE @asistencia_maria_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM audit_logs
    WHERE tabla = 'asistencias'
      AND registro_id = @asistencia_maria_id
      AND razon_cambio = 'Pasar lista automatica'
);

INSERT INTO audit_logs
    (tabla, registro_id, operacion, usuario_id, usuario_nombre,
     datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
SELECT
    'reportes_mensuales', @reporte_dic_id, 'UPDATE', @admin_jass_id, 'Administrador JASS QUILCATA',
    JSON_OBJECT('estado', 'en_proceso'),
    JSON_OBJECT('estado', 'rechazado'),
    'Inconsistencia en egresos: faltan dos boletas de combustible no registradas. Revisar y regenerar.',
    '2026-01-04 10:00:00'
WHERE @reporte_dic_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM audit_logs
    WHERE tabla = 'reportes_mensuales'
      AND registro_id = @reporte_dic_id
      AND razon_cambio LIKE 'Inconsistencia en egresos:%'
);

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS DE CONSULTA
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_audit_historial_registro $$
CREATE PROCEDURE sp_audit_historial_registro(
    IN p_tabla VARCHAR(50),
    IN p_registro_id BIGINT UNSIGNED
)
BEGIN
    SELECT
        a.operacion,
        a.usuario_nombre AS quien,
        a.razon_cambio AS por_que,
        DATE_FORMAT(a.timestamp, '%d/%m/%Y %H:%i:%s') AS cuando,
        JSON_PRETTY(a.datos_anteriores_json) AS antes,
        JSON_PRETTY(a.datos_nuevos_json) AS despues
    FROM audit_logs a
    WHERE a.tabla = p_tabla
      AND a.registro_id = p_registro_id
    ORDER BY a.timestamp ASC;
END $$

DROP PROCEDURE IF EXISTS sp_audit_reportes_decisiones $$
CREATE PROCEDURE sp_audit_reportes_decisiones()
BEGIN
    SELECT
        CONCAT(r.periodo_anio, '-', LPAD(r.periodo_mes, 2, '0')) AS periodo,
        r.estado,
        a.usuario_nombre AS quien_decidio,
        a.razon_cambio AS motivo,
        DATE_FORMAT(a.timestamp, '%d/%m/%Y %H:%i') AS cuando
    FROM reportes_mensuales r
    LEFT JOIN audit_logs a ON a.tabla = 'reportes_mensuales'
        AND a.registro_id = r.id
        AND a.operacion = 'UPDATE'
    WHERE r.estado IN ('aprobado', 'rechazado')
    ORDER BY r.periodo_anio DESC, r.periodo_mes DESC;
END $$

DROP PROCEDURE IF EXISTS sp_audit_actividad_usuario $$
CREATE PROCEDURE sp_audit_actividad_usuario(
    IN p_usuario_id BIGINT UNSIGNED,
    IN p_limite INT UNSIGNED
)
BEGIN
    SELECT
        a.tabla,
        a.operacion,
        a.registro_id,
        a.razon_cambio,
        DATE_FORMAT(a.timestamp, '%d/%m/%Y %H:%i:%s') AS timestamp
    FROM audit_logs a
    WHERE a.usuario_id = p_usuario_id
    ORDER BY a.timestamp DESC
    LIMIT p_limite;
END $$

DROP PROCEDURE IF EXISTS sp_audit_cambios_recientes $$
CREATE PROCEDURE sp_audit_cambios_recientes()
BEGIN
    SELECT
        DATE_FORMAT(a.timestamp, '%d/%m/%Y') AS fecha,
        a.tabla,
        a.operacion,
        a.usuario_nombre,
        COUNT(*) AS cantidad_cambios
    FROM audit_logs a
    WHERE a.timestamp >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
    GROUP BY DATE(a.timestamp), a.tabla, a.operacion, a.usuario_nombre
    ORDER BY MAX(a.timestamp) DESC;
END $$

DROP PROCEDURE IF EXISTS sp_audit_buscar_razon $$
CREATE PROCEDURE sp_audit_buscar_razon(
    IN p_texto VARCHAR(150)
)
BEGIN
    SELECT
        a.tabla,
        a.registro_id,
        a.operacion,
        a.usuario_nombre,
        a.razon_cambio,
        DATE_FORMAT(a.timestamp, '%d/%m/%Y %H:%i') AS cuando
    FROM audit_logs a
    WHERE a.razon_cambio LIKE CONCAT('%', p_texto, '%')
    ORDER BY a.timestamp DESC;
END $$

DROP PROCEDURE IF EXISTS sp_audit_egresos_hoy $$
CREATE PROCEDURE sp_audit_egresos_hoy()
BEGIN
    SELECT
        DATE_FORMAT(a.timestamp, '%H:%i') AS hora,
        a.operacion,
        a.usuario_nombre,
        a.razon_cambio,
        JSON_EXTRACT(a.datos_nuevos_json, '$.numero_serie') AS egreso,
        JSON_EXTRACT(a.datos_nuevos_json, '$.monto') AS monto
    FROM audit_logs a
    WHERE a.tabla = 'egresos'
      AND a.operacion = 'UPDATE'
      AND DATE(a.timestamp) = CURRENT_DATE
    ORDER BY a.timestamp DESC;
END $$

DROP PROCEDURE IF EXISTS sp_audit_cambios_criticos $$
CREATE PROCEDURE sp_audit_cambios_criticos()
BEGIN
    SELECT
        a.usuario_nombre,
        COUNT(*) AS cambios_criticos,
        GROUP_CONCAT(DISTINCT a.tabla) AS tablas_modificadas
    FROM audit_logs a
    WHERE (
        a.razon_cambio LIKE '%anular%'
        OR a.razon_cambio LIKE '%error%'
        OR a.tabla IN ('cobros', 'egresos')
    )
      AND a.timestamp >= DATE_SUB(NOW(), INTERVAL 30 DAY)
    GROUP BY a.usuario_id, a.usuario_nombre
    HAVING cambios_criticos > 5
    ORDER BY cambios_criticos DESC;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- CALL sp_audit_historial_registro('cobros', (SELECT id FROM cobros WHERE numero_serie = 'QLC-2026-0150'));
-- CALL sp_audit_reportes_decisiones();
-- CALL sp_audit_actividad_usuario(1, 50);
-- CALL sp_audit_cambios_recientes();
-- CALL sp_audit_buscar_razon('duplicado');
-- CALL sp_audit_egresos_hoy();
-- CALL sp_audit_cambios_criticos();

