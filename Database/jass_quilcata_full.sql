-- ============================================================
-- BASE DE DATOS COMPLETA: jass_quilcata
-- Proyecto Agua - JASS Quilcata
-- Incluye Partes 1 a 9
-- Generado: 2026-05-08
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
--
-- USO:
--   mysql -u root < jass_quilcata_full.sql
--
-- ADVERTENCIA:
--   Este archivo borra y recrea la base jass_quilcata desde cero.
-- ============================================================

DROP DATABASE IF EXISTS jass_quilcata;


-- ============================================================
-- INICIO 01_auth_usuarios.sql
-- ============================================================

-- ============================================================
-- BASE DE DATOS: jass_quilcata
-- PARTE 1: Autenticacion y Usuarios del Sistema
-- Motor: MariaDB / MySQL InnoDB
-- Charset: utf8mb4
-- ============================================================

CREATE DATABASE IF NOT EXISTS jass_quilcata
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE jass_quilcata;

-- ------------------------------------------------------------
-- TABLA 1: roles
-- Define los roles disponibles en el sistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(50)  NOT NULL UNIQUE
                    COMMENT 'Administrador | Operador',
    descripcion     VARCHAR(255) NULL,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Roles del sistema';

-- ------------------------------------------------------------
-- TABLA 2: users
-- Usuarios del sistema: administradores y operadores.
-- No confundir con vecinos, que son usuarios del servicio de agua.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id                          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username                    VARCHAR(50)  NOT NULL UNIQUE
                                COMMENT 'Login del usuario, ej: admin_jass',
    nombres                     VARCHAR(100) NOT NULL,
    apellidos                   VARCHAR(100) NOT NULL,
    email                       VARCHAR(150) NULL UNIQUE,
    password                    VARCHAR(255) NOT NULL
                                COMMENT 'Hash bcrypt',
    rol_id                      INT UNSIGNED NOT NULL,

    estado                      ENUM('activo','inactivo','bloqueado')
                                NOT NULL DEFAULT 'activo',
    intentos_fallidos           TINYINT UNSIGNED NOT NULL DEFAULT 0
                                COMMENT 'Bloqueo tras 3 fallos',
    bloqueado_hasta             TIMESTAMP NULL,
    requiere_cambio_password    BOOLEAN NOT NULL DEFAULT FALSE,
    ultimo_login                TIMESTAMP NULL,

    created_by                  BIGINT UNSIGNED NULL
                                COMMENT 'Admin que creo el usuario',
    created_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
    deleted_at                  TIMESTAMP NULL
                                COMMENT 'Soft delete',

    CONSTRAINT fk_users_rol FOREIGN KEY (rol_id)
        REFERENCES roles(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_users_creator FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_users_username (username),
    INDEX idx_users_email    (email),
    INDEX idx_users_rol      (rol_id),
    INDEX idx_users_estado   (estado),
    INDEX idx_users_deleted  (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Usuarios del sistema';

-- ------------------------------------------------------------
-- TABLA 3: login_logs
-- Auditoria de intentos de login.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS login_logs (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             BIGINT UNSIGNED NULL,
    username_intentado  VARCHAR(50)  NOT NULL,
    ip_address          VARCHAR(45)  NOT NULL
                        COMMENT 'IPv4 o IPv6',
    user_agent          TEXT NULL,
    resultado           ENUM('exitoso','fallido_credenciales',
                             'fallido_bloqueado','sesion_expirada')
                        NOT NULL,
    motivo_fallo        VARCHAR(255) NULL,
    fecha_intento       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_login_user FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL ON UPDATE CASCADE,

    INDEX idx_login_user      (user_id),
    INDEX idx_login_ip        (ip_address),
    INDEX idx_login_resultado (resultado),
    INDEX idx_login_fecha     (fecha_intento),
    INDEX idx_login_username  (username_intentado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Auditoria de intentos de login';

-- ------------------------------------------------------------
-- TABLA 4: password_reset_tokens
-- Estructura compatible con Laravel.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS password_reset_tokens (
    email           VARCHAR(150) PRIMARY KEY,
    token           VARCHAR(255) NOT NULL,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tokens para reset de contrasena';

-- ------------------------------------------------------------
-- TABLA 5: personal_access_tokens
-- Estructura compatible con Laravel Sanctum.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS personal_access_tokens (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tokenable_type  VARCHAR(255) NOT NULL,
    tokenable_id    BIGINT UNSIGNED NOT NULL,
    name            VARCHAR(255) NOT NULL,
    token           VARCHAR(64)  NOT NULL UNIQUE,
    abilities       TEXT NULL,
    last_used_at    TIMESTAMP NULL,
    expires_at      TIMESTAMP NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tokens_tokenable (tokenable_type, tokenable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Tokens REST API Laravel Sanctum';

-- ============================================================
-- DATOS INICIALES
-- ============================================================

INSERT INTO roles (nombre, descripcion) VALUES
('Administrador', 'Acceso completo al sistema. Gestiona padron, tarifas, multas, reportes, ingresos y egresos.'),
('Operador', 'Acceso a cobros y asistencia. Registra pagos, emite comprobantes PDF y registra faenas.')
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    updated_at = CURRENT_TIMESTAMP;

-- Usuario: admin_jass
-- Contrasena inicial: admin123
INSERT INTO users
    (username, nombres, apellidos, email, password, rol_id, estado, requiere_cambio_password)
VALUES (
    'admin_jass',
    'Administrador',
    'JASS QUILCATA',
    'admin@jass-quilcata.pe',
    '$2y$10$t.QcJ1OsORtLqjmkXGk2SeXMyx4.oRy1wqnrK/ptSTzh9zi2zWFIm',
    (SELECT id FROM roles WHERE nombre = 'Administrador'),
    'activo',
    TRUE
)
ON DUPLICATE KEY UPDATE
    nombres = VALUES(nombres),
    apellidos = VALUES(apellidos),
    rol_id = VALUES(rol_id),
    estado = VALUES(estado),
    requiere_cambio_password = VALUES(requiere_cambio_password),
    updated_at = CURRENT_TIMESTAMP;

-- Usuario: joacim_huanca
-- Contrasena inicial: operador123
SET @admin_jass_id = (SELECT id FROM users WHERE username = 'admin_jass' LIMIT 1);

INSERT INTO users
    (username, nombres, apellidos, email, password, rol_id, estado,
     requiere_cambio_password, created_by)
VALUES (
    'joacim_huanca',
    'Joacim',
    'Huanca Asto',
    'joacim@jass-quilcata.pe',
    '$2y$10$QJbW.0k.30h2dlnmVZaiCuT7Lh8ZCaV1DhiaLATCAAoa/PiCwYRlu',
    (SELECT id FROM roles WHERE nombre = 'Operador'),
    'activo',
    TRUE,
    @admin_jass_id
)
ON DUPLICATE KEY UPDATE
    nombres = VALUES(nombres),
    apellidos = VALUES(apellidos),
    rol_id = VALUES(rol_id),
    estado = VALUES(estado),
    requiere_cambio_password = VALUES(requiere_cambio_password),
    created_by = VALUES(created_by),
    updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_usuario_crear $$
CREATE PROCEDURE sp_usuario_crear(
    IN  p_username VARCHAR(50),
    IN  p_nombres VARCHAR(100),
    IN  p_apellidos VARCHAR(100),
    IN  p_email VARCHAR(150),
    IN  p_password_hash VARCHAR(255),
    IN  p_rol_id INT UNSIGNED,
    IN  p_created_by BIGINT UNSIGNED,
    OUT p_user_id BIGINT UNSIGNED
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id = p_rol_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El rol indicado no existe';
    END IF;

    IF EXISTS (SELECT 1 FROM users WHERE username = p_username AND deleted_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El username ya existe';
    END IF;

    IF p_email IS NOT NULL AND EXISTS (SELECT 1 FROM users WHERE email = p_email AND deleted_at IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El email ya existe';
    END IF;

    INSERT INTO users (
        username, nombres, apellidos, email, password, rol_id,
        estado, requiere_cambio_password, created_by
    ) VALUES (
        p_username, p_nombres, p_apellidos, p_email, p_password_hash, p_rol_id,
        'activo', TRUE, p_created_by
    );

    SET p_user_id = LAST_INSERT_ID();
END $$

DROP PROCEDURE IF EXISTS sp_usuario_cambiar_estado $$
CREATE PROCEDURE sp_usuario_cambiar_estado(
    IN p_user_id BIGINT UNSIGNED,
    IN p_estado VARCHAR(20)
)
BEGIN
    IF p_estado NOT IN ('activo', 'inactivo', 'bloqueado') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estado de usuario no valido';
    END IF;

    UPDATE users
    SET estado = p_estado,
        bloqueado_hasta = IF(p_estado = 'bloqueado', DATE_ADD(NOW(), INTERVAL 15 MINUTE), NULL),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_user_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_usuario_desbloquear $$
CREATE PROCEDURE sp_usuario_desbloquear(
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    UPDATE users
    SET estado = 'activo',
        intentos_fallidos = 0,
        bloqueado_hasta = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_user_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_usuario_cambiar_password $$
CREATE PROCEDURE sp_usuario_cambiar_password(
    IN p_user_id BIGINT UNSIGNED,
    IN p_password_hash VARCHAR(255),
    IN p_requiere_cambio_password BOOLEAN
)
BEGIN
    UPDATE users
    SET password = p_password_hash,
        requiere_cambio_password = p_requiere_cambio_password,
        intentos_fallidos = 0,
        bloqueado_hasta = NULL,
        estado = 'activo',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_user_id
      AND deleted_at IS NULL;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no encontrado';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_login_registrar $$
CREATE PROCEDURE sp_login_registrar(
    IN p_username VARCHAR(50),
    IN p_ip_address VARCHAR(45),
    IN p_user_agent TEXT,
    IN p_resultado VARCHAR(30),
    IN p_motivo_fallo VARCHAR(255)
)
BEGIN
    DECLARE v_user_id BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_intentos TINYINT UNSIGNED DEFAULT 0;

    IF p_resultado NOT IN ('exitoso', 'fallido_credenciales', 'fallido_bloqueado', 'sesion_expirada') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resultado de login no valido';
    END IF;

    SELECT id, intentos_fallidos
    INTO v_user_id, v_intentos
    FROM users
    WHERE username = p_username
      AND deleted_at IS NULL
    LIMIT 1;

    INSERT INTO login_logs (
        user_id, username_intentado, ip_address, user_agent, resultado, motivo_fallo
    ) VALUES (
        v_user_id, p_username, p_ip_address, p_user_agent, p_resultado, p_motivo_fallo
    );

    IF v_user_id IS NOT NULL AND p_resultado = 'exitoso' THEN
        UPDATE users
        SET intentos_fallidos = 0,
            bloqueado_hasta = NULL,
            estado = 'activo',
            ultimo_login = CURRENT_TIMESTAMP,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_user_id;
    END IF;

    IF v_user_id IS NOT NULL AND p_resultado = 'fallido_credenciales' THEN
        UPDATE users
        SET intentos_fallidos = LEAST(intentos_fallidos + 1, 3),
            estado = IF(intentos_fallidos + 1 >= 3, 'bloqueado', estado),
            bloqueado_hasta = IF(intentos_fallidos + 1 >= 3, DATE_ADD(NOW(), INTERVAL 15 MINUTE), bloqueado_hasta),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_user_id;
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_usuarios_listar_con_roles $$
CREATE PROCEDURE sp_usuarios_listar_con_roles()
BEGIN
    SELECT
        u.id,
        u.username,
        CONCAT(u.nombres, ' ', u.apellidos) AS nombre_completo,
        u.email,
        r.nombre AS rol,
        u.estado,
        u.intentos_fallidos,
        u.bloqueado_hasta,
        u.ultimo_login
    FROM users u
    INNER JOIN roles r ON u.rol_id = r.id
    WHERE u.deleted_at IS NULL
    ORDER BY u.id;
END $$

DROP PROCEDURE IF EXISTS sp_usuario_obtener_login $$
CREATE PROCEDURE sp_usuario_obtener_login(
    IN p_username VARCHAR(50)
)
BEGIN
    SELECT
        u.id,
        u.username,
        u.nombres,
        u.apellidos,
        u.email,
        u.password,
        u.estado,
        u.intentos_fallidos,
        u.bloqueado_hasta,
        u.requiere_cambio_password,
        r.nombre AS rol
    FROM users u
    INNER JOIN roles r ON u.rol_id = r.id
    WHERE u.username = p_username
      AND u.deleted_at IS NULL
    LIMIT 1;
END $$

DELIMITER ;

-- ============================================================
-- CONSULTAS DE VERIFICACION
-- Ejecutar manualmente despues de cargar el script.
-- ============================================================

-- SHOW TABLES;

-- SELECT * FROM roles;

-- SELECT
--     u.id,
--     u.username,
--     CONCAT(u.nombres, ' ', u.apellidos) AS nombre_completo,
--     r.nombre AS rol,
--     u.estado
-- FROM users u
-- INNER JOIN roles r ON u.rol_id = r.id;

-- SELECT
--     TABLE_NAME,
--     COLUMN_NAME,
--     CONSTRAINT_NAME,
--     REFERENCED_TABLE_NAME,
--     REFERENCED_COLUMN_NAME
-- FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
-- WHERE TABLE_SCHEMA = 'jass_quilcata'
--   AND REFERENCED_TABLE_NAME IS NOT NULL;

-- CALL sp_usuarios_listar_con_roles();


-- ============================================================
-- FIN 01_auth_usuarios.sql
-- ============================================================


-- ============================================================
-- INICIO 02_padron_vecinos.sql
-- ============================================================

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



-- ============================================================
-- FIN 02_padron_vecinos.sql
-- ============================================================


-- ============================================================
-- INICIO 03_tarifas_multas.sql
-- ============================================================

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



-- ============================================================
-- FIN 03_tarifas_multas.sql
-- ============================================================


-- ============================================================
-- INICIO 04_cobros_comprobantes.sql
-- ============================================================

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

DROP PROCEDURE IF EXISTS sp_registrar_cobro $$
CREATE PROCEDURE sp_registrar_cobro(
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



-- ============================================================
-- FIN 04_cobros_comprobantes.sql
-- ============================================================


-- ============================================================
-- INICIO 05_ingresos.sql
-- ============================================================

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
    c.fecha_cobro AS fecha_ingreso,
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



-- ============================================================
-- FIN 05_ingresos.sql
-- ============================================================


-- ============================================================
-- INICIO 06_egresos.sql
-- ============================================================

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


-- ============================================================
-- FIN 06_egresos.sql
-- ============================================================


-- ============================================================
-- INICIO 07_reportes_mensuales.sql
-- ============================================================

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


-- ============================================================
-- FIN 07_reportes_mensuales.sql
-- ============================================================


-- ============================================================
-- INICIO 08_eventos_asistencias.sql
-- ============================================================

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



-- ============================================================
-- FIN 08_eventos_asistencias.sql
-- ============================================================


-- ============================================================
-- INICIO 09_auditoria_general.sql
-- ============================================================

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



-- ============================================================
-- FIN 09_auditoria_general.sql
-- ============================================================
