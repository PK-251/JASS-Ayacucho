DELIMITER $$
DROP PROCEDURE IF EXISTS sp_calcular_deuda_vecino$$
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
END$$
DELIMITER ;
