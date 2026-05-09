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
