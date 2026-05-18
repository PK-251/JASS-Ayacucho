-- Stored procedures and non-negative guards for JASS Quilcata
-- MariaDB / MySQL compatible. Re-runnable.

DROP PROCEDURE IF EXISTS sp_audit_log;
CREATE PROCEDURE sp_audit_log(
    IN p_tabla VARCHAR(50),
    IN p_registro_id BIGINT UNSIGNED,
    IN p_operacion VARCHAR(10),
    IN p_usuario_id BIGINT UNSIGNED,
    IN p_razon_cambio VARCHAR(1000),
    IN p_datos_anteriores_json LONGTEXT,
    IN p_datos_nuevos_json LONGTEXT
)
BEGIN
    INSERT INTO audit_logs
        (tabla, registro_id, operacion, usuario_id, usuario_nombre,
         datos_anteriores_json, datos_nuevos_json, razon_cambio, timestamp)
    VALUES
        (p_tabla, p_registro_id, p_operacion, p_usuario_id,
         (SELECT CONCAT(nombres, ' ', apellidos) FROM users WHERE id = p_usuario_id),
         p_datos_anteriores_json, p_datos_nuevos_json, p_razon_cambio, NOW());
END;

DROP PROCEDURE IF EXISTS sp_calcular_deuda_vecino;
CREATE PROCEDURE sp_calcular_deuda_vecino(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED
)
BEGIN
    DECLARE v_categoria_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_periodo DATE;
    DECLARE v_cuota DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_deuda_cuotas DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_deuda_multas DECIMAL(8,2) DEFAULT 0.00;

    IF p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodo invalido: el mes debe estar entre 1 y 12.';
    END IF;

    SET v_periodo = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');

    SELECT categoria_id INTO v_categoria_id
    FROM vecinos
    WHERE id = p_vecino_id AND deleted_at IS NULL
    LIMIT 1;

    IF v_categoria_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado o dado de baja.';
    END IF;

    SELECT COALESCE((
        SELECT monto
        FROM tarifas
        WHERE categoria_id = v_categoria_id
          AND fecha_vigencia_inicio <= LAST_DAY(v_periodo)
          AND (fecha_vigencia_fin IS NULL OR fecha_vigencia_fin >= v_periodo)
        ORDER BY activa DESC, fecha_vigencia_inicio DESC
        LIMIT 1
    ), 0.00) INTO v_cuota;

    SELECT COALESCE(SUM(monto_pendiente), 0.00) INTO v_deuda_cuotas
    FROM pagos_pendientes
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    SELECT COALESCE(SUM(monto_aplicado), 0.00) INTO v_deuda_multas
    FROM multas_aplicadas
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    SELECT
        v_cuota AS cuota,
        v_deuda_cuotas AS deuda_cuotas,
        v_deuda_multas AS deuda_multas,
        (v_cuota + v_deuda_cuotas + v_deuda_multas) AS total;
END;

DROP PROCEDURE IF EXISTS sp_registrar_cobro;
CREATE PROCEDURE sp_registrar_cobro(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_operador_id BIGINT UNSIGNED,
    IN p_jornada_id BIGINT UNSIGNED,
    IN p_periodo_anio SMALLINT UNSIGNED,
    IN p_periodo_mes TINYINT UNSIGNED,
    IN p_monto_recibido DECIMAL(8,2),
    IN p_metodo_pago VARCHAR(20),
    IN p_observaciones VARCHAR(500),
    OUT p_cobro_id BIGINT UNSIGNED,
    OUT p_numero_serie VARCHAR(20)
)
BEGIN
    DECLARE v_categoria_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_periodo DATE;
    DECLARE v_cuota DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_deuda_cuotas DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_deuda_multas DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_total DECIMAL(8,2) DEFAULT 0.00;
    DECLARE v_next INT DEFAULT 1;
    DECLARE v_fecha DATE;
    DECLARE v_hora TIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_monto_recibido < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se permiten montos negativos.';
    END IF;

    IF p_periodo_mes < 1 OR p_periodo_mes > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodo invalido: el mes debe estar entre 1 y 12.';
    END IF;

    IF p_metodo_pago NOT IN ('efectivo','transferencia','yape','plin','otro') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metodo de pago invalido.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM cobros
        WHERE vecino_id = p_vecino_id
          AND periodo_anio = p_periodo_anio
          AND periodo_mes = p_periodo_mes
          AND estado = 'pagado'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este usuario ya tiene un cobro pagado para ese periodo.';
    END IF;

    SELECT categoria_id INTO v_categoria_id
    FROM vecinos
    WHERE id = p_vecino_id AND deleted_at IS NULL
    LIMIT 1;

    IF v_categoria_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado o dado de baja.';
    END IF;

    SET v_periodo = STR_TO_DATE(CONCAT(p_periodo_anio, '-', LPAD(p_periodo_mes, 2, '0'), '-01'), '%Y-%m-%d');

    SELECT COALESCE((
        SELECT monto
        FROM tarifas
        WHERE categoria_id = v_categoria_id
          AND fecha_vigencia_inicio <= LAST_DAY(v_periodo)
          AND (fecha_vigencia_fin IS NULL OR fecha_vigencia_fin >= v_periodo)
        ORDER BY activa DESC, fecha_vigencia_inicio DESC
        LIMIT 1
    ), 0.00) INTO v_cuota;

    SELECT COALESCE(SUM(monto_pendiente), 0.00) INTO v_deuda_cuotas
    FROM pagos_pendientes
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    SELECT COALESCE(SUM(monto_aplicado), 0.00) INTO v_deuda_multas
    FROM multas_aplicadas
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    SET v_total = ROUND(v_cuota + v_deuda_cuotas + v_deuda_multas, 2);

    IF ROUND(p_monto_recibido, 2) <> v_total THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El monto recibido debe coincidir con el total a cobrar.';
    END IF;

    SELECT COALESCE(MAX(CAST(SUBSTRING(numero_serie, 10) AS UNSIGNED)), 0) + 1 INTO v_next
    FROM cobros
    WHERE numero_serie LIKE CONCAT('QLC-', p_periodo_anio, '-%');

    SET p_numero_serie = CONCAT('QLC-', p_periodo_anio, '-', LPAD(v_next, 4, '0'));
    SET v_fecha = CURRENT_DATE();
    SET v_hora = CURRENT_TIME();

    START TRANSACTION;

    INSERT INTO cobros
        (numero_serie, vecino_id, operador_id, jornada_id, periodo_anio, periodo_mes,
         monto_cuota, monto_deuda_anterior, monto_multas, monto_total, monto_recibido,
         metodo_pago, estado, fecha_cobro, hora_cobro, observaciones, created_at, updated_at)
    VALUES
        (p_numero_serie, p_vecino_id, p_operador_id, p_jornada_id, p_periodo_anio, p_periodo_mes,
         v_cuota, v_deuda_cuotas, v_deuda_multas, v_total, ROUND(p_monto_recibido, 2),
         p_metodo_pago, 'pagado', v_fecha, v_hora, p_observaciones, NOW(), NOW());

    SET p_cobro_id = LAST_INSERT_ID();

    UPDATE pagos_pendientes
    SET estado = 'cobrado', fecha_cobro = v_fecha, cobro_id = p_cobro_id, updated_at = NOW()
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    UPDATE multas_aplicadas
    SET estado = 'cobrada', fecha_cobro = v_fecha, cobro_id = p_cobro_id, updated_at = NOW()
    WHERE vecino_id = p_vecino_id AND estado = 'pendiente';

    INSERT INTO comprobantes_pdf
        (cobro_id, numero_serie, ruta_archivo, nombre_archivo, codigo_qr_url, modalidad_entrega, created_at, updated_at)
    VALUES
        (p_cobro_id, p_numero_serie,
         CONCAT('/storage/comprobantes/', YEAR(v_fecha), '/', LPAD(MONTH(v_fecha), 2, '0'), '/', p_numero_serie, '.pdf'),
         CONCAT(p_numero_serie, '.pdf'),
         CONCAT('/cobros/', p_cobro_id),
         'pendiente', NOW(), NOW());

    IF p_jornada_id IS NOT NULL THEN
        UPDATE jornadas_cobro j
        SET total_vecinos_atendidos = (SELECT COUNT(*) FROM cobros WHERE jornada_id = p_jornada_id AND estado = 'pagado'),
            total_recaudado = (SELECT COALESCE(SUM(monto_recibido),0) FROM cobros WHERE jornada_id = p_jornada_id AND estado = 'pagado'),
            total_pendientes_registrados = (SELECT COUNT(*) FROM pagos_pendientes WHERE jornada_id = p_jornada_id AND estado = 'pendiente'),
            updated_at = NOW()
        WHERE j.id = p_jornada_id;
    END IF;

    CALL sp_audit_log(
        'cobros', p_cobro_id, 'INSERT', p_operador_id, 'Cobro registrado por procedimiento almacenado',
        NULL,
        JSON_OBJECT('numero_serie', p_numero_serie, 'vecino_id', p_vecino_id, 'monto_total', v_total, 'metodo_pago', p_metodo_pago)
    );

    COMMIT;
END;

DROP PROCEDURE IF EXISTS sp_generar_reporte_mensual;
CREATE PROCEDURE sp_generar_reporte_mensual(
    IN p_anio SMALLINT UNSIGNED,
    IN p_mes TINYINT UNSIGNED,
    IN p_es_parcial BOOLEAN,
    IN p_usuario_id BIGINT UNSIGNED,
    OUT p_reporte_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_inicio DATE;
    DECLARE v_fin DATE;
    DECLARE v_total_cobros DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_manual DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_ingresos DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_egresos DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_num_cobros INT UNSIGNED DEFAULT 0;
    DECLARE v_num_manual INT UNSIGNED DEFAULT 0;
    DECLARE v_num_egresos INT UNSIGNED DEFAULT 0;
    DECLARE v_total_cuotas DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_multas DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_deuda DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_vecinos_total INT UNSIGNED DEFAULT 0;
    DECLARE v_morosos INT UNSIGNED DEFAULT 0;

    IF p_mes < 1 OR p_mes > 12 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodo invalido: el mes debe estar entre 1 y 12.';
    END IF;

    SET v_inicio = STR_TO_DATE(CONCAT(p_anio, '-', LPAD(p_mes, 2, '0'), '-01'), '%Y-%m-%d');
    SET v_fin = LAST_DAY(v_inicio);

    SELECT COALESCE(SUM(monto_recibido),0), COUNT(*), COALESCE(SUM(monto_cuota + monto_deuda_anterior),0), COALESCE(SUM(monto_multas),0)
    INTO v_total_cobros, v_num_cobros, v_total_cuotas, v_total_multas
    FROM cobros
    WHERE YEAR(fecha_cobro)=p_anio AND MONTH(fecha_cobro)=p_mes AND estado='pagado';

    SELECT COALESCE(SUM(monto),0), COUNT(*)
    INTO v_total_manual, v_num_manual
    FROM ingresos
    WHERE YEAR(fecha_ingreso)=p_anio AND MONTH(fecha_ingreso)=p_mes AND estado='activo';

    SELECT COALESCE(SUM(monto),0), COUNT(*)
    INTO v_total_egresos, v_num_egresos
    FROM egresos
    WHERE YEAR(fecha_egreso)=p_anio AND MONTH(fecha_egreso)=p_mes AND estado='aprobado';

    SET v_total_ingresos = v_total_cobros + v_total_manual;

    SELECT COUNT(*) INTO v_vecinos_total FROM vecinos WHERE deleted_at IS NULL;

    SELECT COALESCE(SUM(monto_pendiente),0) + COALESCE((SELECT SUM(monto_aplicado) FROM multas_aplicadas WHERE estado='pendiente'),0)
    INTO v_deuda
    FROM pagos_pendientes
    WHERE estado='pendiente';

    SELECT COUNT(*) INTO v_morosos
    FROM vecinos v
    WHERE v.deleted_at IS NULL
      AND (
        EXISTS (SELECT 1 FROM pagos_pendientes pp WHERE pp.vecino_id=v.id AND pp.estado='pendiente')
        OR EXISTS (SELECT 1 FROM multas_aplicadas ma WHERE ma.vecino_id=v.id AND ma.estado='pendiente')
      );

    INSERT INTO reportes_mensuales
        (periodo_anio, periodo_mes, fecha_inicio_periodo, fecha_fin_periodo, estado,
         total_ingresos, num_cobros, num_ingresos_manuales,
         total_cuotas, total_multas_cobradas, total_cuotas_extraordinarias,
         total_donaciones, total_otros_ingresos,
         total_egresos, num_egresos,
         total_materiales, total_personal, total_mantenimiento, total_combustible, total_servicios, total_otros_egresos,
         balance_neto, num_vecinos_total, num_vecinos_al_dia, num_vecinos_morosos,
         deuda_acumulada, porcentaje_morosidad,
         desglose_ingresos_json, desglose_egresos_json, fecha_generacion,
         generado_por_sistema, es_reporte_parcial, version, created_at, updated_at)
    VALUES
        (p_anio, p_mes, v_inicio, v_fin, IF(p_es_parcial, 'en_proceso', 'pendiente_aprobacion'),
         v_total_ingresos, v_num_cobros, v_num_manual,
         v_total_cuotas, v_total_multas, 0.00,
         0.00, v_total_manual,
         v_total_egresos, v_num_egresos,
         0.00, 0.00, 0.00, 0.00, 0.00, v_total_egresos,
         v_total_ingresos - v_total_egresos, v_vecinos_total, GREATEST(v_vecinos_total - v_morosos, 0), v_morosos,
         COALESCE(v_deuda,0), IF(v_vecinos_total > 0, ROUND(v_morosos * 100 / v_vecinos_total, 2), 0.00),
         JSON_OBJECT('cobros', v_total_cobros, 'manuales', v_total_manual, 'multas', v_total_multas),
         JSON_OBJECT('egresos_aprobados', v_total_egresos), NOW(),
         TRUE, p_es_parcial, 1, NOW(), NOW())
    ON DUPLICATE KEY UPDATE
         id = LAST_INSERT_ID(id),
         estado = VALUES(estado),
         total_ingresos = VALUES(total_ingresos),
         num_cobros = VALUES(num_cobros),
         num_ingresos_manuales = VALUES(num_ingresos_manuales),
         total_cuotas = VALUES(total_cuotas),
         total_multas_cobradas = VALUES(total_multas_cobradas),
         total_otros_ingresos = VALUES(total_otros_ingresos),
         total_egresos = VALUES(total_egresos),
         num_egresos = VALUES(num_egresos),
         total_otros_egresos = VALUES(total_otros_egresos),
         balance_neto = VALUES(balance_neto),
         num_vecinos_total = VALUES(num_vecinos_total),
         num_vecinos_al_dia = VALUES(num_vecinos_al_dia),
         num_vecinos_morosos = VALUES(num_vecinos_morosos),
         deuda_acumulada = VALUES(deuda_acumulada),
         porcentaje_morosidad = VALUES(porcentaje_morosidad),
         desglose_ingresos_json = VALUES(desglose_ingresos_json),
         desglose_egresos_json = VALUES(desglose_egresos_json),
         fecha_generacion = NOW(),
         updated_at = NOW();

    SET p_reporte_id = LAST_INSERT_ID();

    CALL sp_audit_log('reportes_mensuales', p_reporte_id, 'INSERT', p_usuario_id, 'Reporte generado por procedimiento almacenado', NULL, JSON_OBJECT('periodo', CONCAT(p_anio, '-', LPAD(p_mes, 2, '0')), 'parcial', p_es_parcial));
END;

DROP PROCEDURE IF EXISTS sp_add_check_constraint;
CREATE PROCEDURE sp_add_check_constraint(
    IN p_table_name VARCHAR(64),
    IN p_constraint_name VARCHAR(64),
    IN p_check_expression TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND TABLE_NAME = p_table_name
          AND CONSTRAINT_NAME = p_constraint_name
    ) THEN
        SET @sql = CONCAT('ALTER TABLE ', p_table_name, ' ADD CONSTRAINT ', p_constraint_name, ' CHECK (', p_check_expression, ')');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END;

CALL sp_add_check_constraint('cobros', 'chk_cobros_montos_no_negativos', 'monto_cuota >= 0 AND monto_deuda_anterior >= 0 AND monto_multas >= 0 AND monto_total >= 0 AND monto_recibido >= 0 AND monto_total = monto_cuota + monto_deuda_anterior + monto_multas');
CALL sp_add_check_constraint('ingresos', 'chk_ingresos_monto_positivo', 'monto > 0');
CALL sp_add_check_constraint('egresos', 'chk_egresos_monto_positivo', 'monto > 0');
CALL sp_add_check_constraint('tarifas', 'chk_tarifas_monto_positivo', 'monto > 0');
CALL sp_add_check_constraint('multas', 'chk_multas_monto_positivo', 'monto > 0');
CALL sp_add_check_constraint('multas_aplicadas', 'chk_multas_aplicadas_monto_positivo', 'monto_aplicado > 0');
CALL sp_add_check_constraint('pagos_pendientes', 'chk_pagos_pendientes_monto_positivo', 'monto_pendiente > 0');
CALL sp_add_check_constraint('jornadas_cobro', 'chk_jornadas_recaudado_no_negativo', 'total_recaudado >= 0');
CALL sp_add_check_constraint('reportes_mensuales', 'chk_reportes_totales_no_negativos', 'total_ingresos >= 0 AND total_egresos >= 0 AND total_cuotas >= 0 AND total_multas_cobradas >= 0 AND total_cuotas_extraordinarias >= 0 AND total_donaciones >= 0 AND total_otros_ingresos >= 0 AND total_materiales >= 0 AND total_personal >= 0 AND total_mantenimiento >= 0 AND total_combustible >= 0 AND total_servicios >= 0 AND total_otros_egresos >= 0 AND deuda_acumulada >= 0 AND porcentaje_morosidad >= 0');
