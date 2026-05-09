-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 2: Padron de Vecinos
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 6: categorias_servicio
-- Categorias de vecinos segun uso del servicio de agua.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categorias_servicio (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL UNIQUE,
    descripcion     VARCHAR(255) NULL,
    icono           VARCHAR(50) NULL
                    COMMENT 'Nombre del icono lucide para UI',
    color_hex       VARCHAR(7) NULL DEFAULT '#0891B2'
                    COMMENT 'Color para badges en la UI',
    activa          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_categorias_activa (activa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorias de servicio';

-- ------------------------------------------------------------
-- TABLA 7: vecinos
-- Padron de usuarios del servicio de agua potable.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vecinos (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(10) NOT NULL UNIQUE
                    COMMENT 'Auto-generado: U-0001, U-0002',

    documento_tipo  ENUM('DNI','RUC','CE') NOT NULL DEFAULT 'DNI',
    documento_num   VARCHAR(11) NOT NULL UNIQUE
                    COMMENT 'DNI 8, RUC 11, CE variable',
    nombres         VARCHAR(100) NOT NULL,
    apellidos       VARCHAR(100) NOT NULL,

    direccion       VARCHAR(255) NOT NULL,
    telefono        VARCHAR(20) NULL,
    email           VARCHAR(150) NULL,

    categoria_id    INT UNSIGNED NOT NULL,
    estado          ENUM('activo','suspendido','cortado','baja')
                    NOT NULL DEFAULT 'activo',
    tiene_medidor   BOOLEAN NOT NULL DEFAULT FALSE,
    numero_medidor  VARCHAR(30) NULL UNIQUE,
    fecha_registro  DATE NOT NULL DEFAULT (CURRENT_DATE),
    fecha_corte     DATE NULL
                    COMMENT 'Fecha de corte si estado=cortado',
    motivo_estado   VARCHAR(500) NULL
                    COMMENT 'Razon de suspension, corte o baja',

    created_by      BIGINT UNSIGNED NULL,
    updated_by      BIGINT UNSIGNED NULL,
    deleted_by      BIGINT UNSIGNED NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      TIMESTAMP NULL
                    COMMENT 'Soft delete',

    CONSTRAINT fk_vecinos_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias_servicio(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_vecinos_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_vecinos_updater FOREIGN KEY (updated_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_vecinos_deleter FOREIGN KEY (deleted_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_vecinos_codigo    (codigo),
    INDEX idx_vecinos_documento (documento_num),
    INDEX idx_vecinos_nombres   (nombres, apellidos),
    INDEX idx_vecinos_categoria (categoria_id),
    INDEX idx_vecinos_estado    (estado),
    INDEX idx_vecinos_deleted   (deleted_at),
    INDEX idx_vecinos_search    (codigo, documento_num, apellidos)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Padron de vecinos del servicio de agua';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

INSERT INTO categorias_servicio (nombre, descripcion, icono, color_hex, activa) VALUES
('Domestica', 'Uso residencial estandar', 'Home', '#0891B2', TRUE),
('Comercial', 'Establecimientos comerciales y negocios', 'Store', '#10B981', TRUE),
('Institucional', 'Instituciones educativas, postas de salud y otros', 'Building2', '#F59E0B', TRUE)
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    icono = VALUES(icono),
    color_hex = VALUES(color_hex),
    activa = VALUES(activa),
    updated_at = CURRENT_TIMESTAMP;

SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);
SET @cat_domestica = (SELECT id FROM categorias_servicio WHERE nombre = 'Domestica' LIMIT 1);
SET @cat_comercial = (SELECT id FROM categorias_servicio WHERE nombre = 'Comercial' LIMIT 1);
SET @cat_institucional = (SELECT id FROM categorias_servicio WHERE nombre = 'Institucional' LIMIT 1);

INSERT INTO vecinos
    (codigo, documento_tipo, documento_num, nombres, apellidos,
     direccion, telefono, email, categoria_id, estado, tiene_medidor,
     numero_medidor, created_by)
VALUES
('U-0001','DNI','45123456','Juan','Perez Quispe','Jr. Los Andes 145','999111222',NULL,@cat_domestica,'activo',TRUE,'MED-0001',@admin_jass_id),
('U-0002','DNI','45234567','Maria','Quispe Mamani','Av. Principal 220','999222333',NULL,@cat_domestica,'activo',TRUE,'MED-0002',@admin_jass_id),
('U-0003','DNI','45345678','Pedro','Huaman Ccori','Jr. Sara-Sara 88','999333444',NULL,@cat_domestica,'activo',FALSE,NULL,@admin_jass_id),
('U-0004','DNI','45456789','Lucia','Condori Mamani','Calle Bolivar 56','999444555',NULL,@cat_comercial,'activo',TRUE,'MED-0004',@admin_jass_id),
('U-0005','DNI','45567890','Jose','Carrion Aroni','Av. Los Incas 312','999555666','jose.carrion@gmail.com',@cat_domestica,'activo',TRUE,'MED-0005',@admin_jass_id),
('U-0006','DNI','45678901','Rosa','Mamani Huillca','Jr. Cusco 89','999666777',NULL,@cat_domestica,'suspendido',FALSE,NULL,@admin_jass_id),
('U-0007','DNI','45789012','Ana','Flores Chuquihuaccha','Calle Lima 12','999777888',NULL,@cat_domestica,'cortado',FALSE,NULL,@admin_jass_id),
('U-0008','RUC','20100100100','I.E. Sara-Sara','I.E. Sara-Sara','Av. Educacion s/n','999888999','ie.sarasara@gmail.com',@cat_institucional,'activo',TRUE,'MED-0008',@admin_jass_id)
ON DUPLICATE KEY UPDATE
    documento_tipo = VALUES(documento_tipo),
    nombres = VALUES(nombres),
    apellidos = VALUES(apellidos),
    direccion = VALUES(direccion),
    telefono = VALUES(telefono),
    email = VALUES(email),
    categoria_id = VALUES(categoria_id),
    estado = VALUES(estado),
    tiene_medidor = VALUES(tiene_medidor),
    numero_medidor = VALUES(numero_medidor),
    updated_by = @admin_jass_id,
    updated_at = CURRENT_TIMESTAMP;

UPDATE vecinos
SET fecha_corte = '2026-04-15',
    motivo_estado = 'Corte por morosidad - 6 meses sin pago',
    updated_by = @admin_jass_id
WHERE codigo = 'U-0007';

UPDATE vecinos
SET motivo_estado = 'Suspendido temporalmente - vivienda desocupada por viaje',
    updated_by = @admin_jass_id
WHERE codigo = 'U-0006';

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_categoria_servicio_crear $$
CREATE PROCEDURE sp_categoria_servicio_crear(
    IN p_nombre VARCHAR(50),
    IN p_descripcion VARCHAR(255),
    IN p_icono VARCHAR(50),
    IN p_color_hex VARCHAR(7),
    OUT p_categoria_id INT UNSIGNED
)
BEGIN
    IF EXISTS (SELECT 1 FROM categorias_servicio WHERE nombre = p_nombre) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria de servicio ya existe';
    END IF;

    INSERT INTO categorias_servicio (nombre, descripcion, icono, color_hex, activa)
    VALUES (p_nombre, p_descripcion, p_icono, COALESCE(p_color_hex, '#0891B2'), TRUE);

    SET p_categoria_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_categoria_servicio_cambiar_estado $$
CREATE PROCEDURE sp_categoria_servicio_cambiar_estado(
    IN p_categoria_id INT UNSIGNED,
    IN p_activa BOOLEAN
)
BEGIN
    UPDATE categorias_servicio
    SET activa = p_activa,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_categoria_id;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Categoria de servicio no encontrada';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_vecino_generar_codigo $$
CREATE PROCEDURE sp_vecino_generar_codigo(
    OUT p_codigo VARCHAR(10)
)
BEGIN
    DECLARE v_numero INT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(CAST(SUBSTRING(codigo, 3) AS UNSIGNED)), 0) + 1
    INTO v_numero
    FROM vecinos
    WHERE codigo REGEXP '^U-[0-9]+$';

    SET p_codigo = CONCAT('U-', LPAD(v_numero, 4, '0'));
END $$

DROP PROCEDURE IF EXISTS sp_vecino_crear $$
CREATE PROCEDURE sp_vecino_crear(
    IN p_documento_tipo VARCHAR(3),
    IN p_documento_num VARCHAR(11),
    IN p_nombres VARCHAR(100),
    IN p_apellidos VARCHAR(100),
    IN p_direccion VARCHAR(255),
    IN p_telefono VARCHAR(20),
    IN p_email VARCHAR(150),
    IN p_categoria_id INT UNSIGNED,
    IN p_tiene_medidor BOOLEAN,
    IN p_numero_medidor VARCHAR(30),
    IN p_created_by BIGINT UNSIGNED,
    OUT p_vecino_id BIGINT UNSIGNED,
    OUT p_codigo VARCHAR(10)
)
BEGIN
    IF p_documento_tipo NOT IN ('DNI', 'RUC', 'CE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de documento no valido';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM categorias_servicio WHERE id = p_categoria_id AND activa = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria no existe o esta inactiva';
    END IF;

    IF EXISTS (SELECT 1 FROM vecinos WHERE documento_num = p_documento_num AND deleted_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El documento ya esta registrado';
    END IF;

    IF p_numero_medidor IS NOT NULL
       AND EXISTS (SELECT 1 FROM vecinos WHERE numero_medidor = p_numero_medidor AND deleted_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El numero de medidor ya esta registrado';
    END IF;

    CALL sp_vecino_generar_codigo(p_codigo);

    INSERT INTO vecinos (
        codigo, documento_tipo, documento_num, nombres, apellidos,
        direccion, telefono, email, categoria_id, estado, tiene_medidor,
        numero_medidor, created_by
    ) VALUES (
        p_codigo, p_documento_tipo, p_documento_num, p_nombres, p_apellidos,
        p_direccion, p_telefono, p_email, p_categoria_id, 'activo', p_tiene_medidor,
        p_numero_medidor, p_created_by
    );

    SET p_vecino_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_vecino_actualizar $$
CREATE PROCEDURE sp_vecino_actualizar(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_documento_tipo VARCHAR(3),
    IN p_documento_num VARCHAR(11),
    IN p_nombres VARCHAR(100),
    IN p_apellidos VARCHAR(100),
    IN p_direccion VARCHAR(255),
    IN p_telefono VARCHAR(20),
    IN p_email VARCHAR(150),
    IN p_categoria_id INT UNSIGNED,
    IN p_tiene_medidor BOOLEAN,
    IN p_numero_medidor VARCHAR(30),
    IN p_updated_by BIGINT UNSIGNED
)
BEGIN
    IF p_documento_tipo NOT IN ('DNI', 'RUC', 'CE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tipo de documento no valido';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM categorias_servicio WHERE id = p_categoria_id AND activa = TRUE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La categoria no existe o esta inactiva';
    END IF;

    IF EXISTS (
        SELECT 1 FROM vecinos
        WHERE documento_num = p_documento_num
          AND id <> p_vecino_id
          AND deleted_at IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El documento ya esta registrado';
    END IF;

    IF p_numero_medidor IS NOT NULL
       AND EXISTS (
        SELECT 1 FROM vecinos
        WHERE numero_medidor = p_numero_medidor
          AND id <> p_vecino_id
          AND deleted_at IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El numero de medidor ya esta registrado';
    END IF;

    UPDATE vecinos
    SET documento_tipo = p_documento_tipo,
        documento_num = p_documento_num,
        nombres = p_nombres,
        apellidos = p_apellidos,
        direccion = p_direccion,
        telefono = p_telefono,
        email = p_email,
        categoria_id = p_categoria_id,
        tiene_medidor = p_tiene_medidor,
        numero_medidor = p_numero_medidor,
        updated_by = p_updated_by,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_vecino_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vecino no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_vecino_cambiar_estado $$
CREATE PROCEDURE sp_vecino_cambiar_estado(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_estado VARCHAR(20),
    IN p_motivo_estado VARCHAR(500),
    IN p_updated_by BIGINT UNSIGNED
)
BEGIN
    IF p_estado NOT IN ('activo', 'suspendido', 'cortado', 'baja') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de vecino no valido';
    END IF;

    UPDATE vecinos
    SET estado = p_estado,
        fecha_corte = IF(p_estado = 'cortado', CURRENT_DATE, NULL),
        motivo_estado = p_motivo_estado,
        updated_by = p_updated_by,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_vecino_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vecino no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_vecino_eliminar $$
CREATE PROCEDURE sp_vecino_eliminar(
    IN p_vecino_id BIGINT UNSIGNED,
    IN p_motivo_estado VARCHAR(500),
    IN p_deleted_by BIGINT UNSIGNED
)
BEGIN
    UPDATE vecinos
    SET estado = 'baja',
        motivo_estado = p_motivo_estado,
        deleted_by = p_deleted_by,
        deleted_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_vecino_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vecino no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_vecino_obtener $$
CREATE PROCEDURE sp_vecino_obtener(
    IN p_vecino_id BIGINT UNSIGNED
)
BEGIN
    SELECT
        v.*,
        c.nombre AS categoria,
        c.icono AS categoria_icono,
        c.color_hex AS categoria_color
    FROM vecinos v
    INNER JOIN categorias_servicio c ON v.categoria_id = c.id
    WHERE v.id = p_vecino_id
      AND v.deleted_at IS NULL
    LIMIT 1;
END $$

DROP PROCEDURE IF EXISTS sp_vecinos_buscar $$
CREATE PROCEDURE sp_vecinos_buscar(
    IN p_busqueda VARCHAR(150),
    IN p_estado VARCHAR(20),
    IN p_categoria_id INT UNSIGNED
)
BEGIN
    SELECT
        v.id,
        v.codigo,
        CONCAT(v.documento_tipo, ' ', v.documento_num) AS documento,
        CONCAT(v.nombres, ' ', v.apellidos) AS nombre_completo,
        v.direccion,
        v.telefono,
        v.email,
        c.nombre AS categoria,
        v.estado,
        v.tiene_medidor,
        v.numero_medidor
    FROM vecinos v
    INNER JOIN categorias_servicio c ON v.categoria_id = c.id
    WHERE v.deleted_at IS NULL
      AND (p_estado IS NULL OR v.estado = p_estado)
      AND (p_categoria_id IS NULL OR v.categoria_id = p_categoria_id)
      AND (
          p_busqueda IS NULL
          OR v.codigo LIKE CONCAT('%', p_busqueda, '%')
          OR v.documento_num LIKE CONCAT('%', p_busqueda, '%')
          OR v.nombres LIKE CONCAT('%', p_busqueda, '%')
          OR v.apellidos LIKE CONCAT('%', p_busqueda, '%')
          OR v.direccion LIKE CONCAT('%', p_busqueda, '%')
      )
    ORDER BY v.codigo;
END $$

DROP PROCEDURE IF EXISTS sp_padron_estadisticas_categoria $$
CREATE PROCEDURE sp_padron_estadisticas_categoria()
BEGIN
    SELECT
        c.nombre AS categoria,
        COUNT(v.id) AS total,
        SUM(CASE WHEN v.estado = 'activo' THEN 1 ELSE 0 END) AS activos,
        SUM(CASE WHEN v.estado = 'suspendido' THEN 1 ELSE 0 END) AS suspendidos,
        SUM(CASE WHEN v.estado = 'cortado' THEN 1 ELSE 0 END) AS cortados
    FROM categorias_servicio c
    LEFT JOIN vecinos v ON v.categoria_id = c.id AND v.deleted_at IS NULL
    GROUP BY c.id, c.nombre
    ORDER BY c.id;
END $$

DROP PROCEDURE IF EXISTS sp_padron_kpis $$
CREATE PROCEDURE sp_padron_kpis()
BEGIN
    SELECT
        COUNT(*) AS total_vecinos,
        SUM(CASE WHEN estado = 'activo' THEN 1 ELSE 0 END) AS al_dia,
        SUM(CASE WHEN estado = 'suspendido' THEN 1 ELSE 0 END) AS suspendidos,
        SUM(CASE WHEN estado = 'cortado' THEN 1 ELSE 0 END) AS cortados
    FROM vecinos
    WHERE deleted_at IS NULL;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- SELECT
--     v.codigo,
--     CONCAT(v.documento_tipo, ' ', v.documento_num) AS documento,
--     CONCAT(v.nombres, ' ', v.apellidos) AS nombre_completo,
--     v.direccion,
--     c.nombre AS categoria,
--     v.estado,
--     CASE WHEN v.tiene_medidor THEN CONCAT('Si (', v.numero_medidor, ')')
--          ELSE 'No' END AS medidor
-- FROM vecinos v
-- INNER JOIN categorias_servicio c ON v.categoria_id = c.id
-- WHERE v.deleted_at IS NULL
-- ORDER BY v.codigo;

-- CALL sp_vecinos_buscar(NULL, NULL, NULL);
-- CALL sp_padron_estadisticas_categoria();
-- CALL sp_padron_kpis();

