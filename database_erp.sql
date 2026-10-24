-- =====================================================================================
-- QUANTUMERP PRO v4.0 - SISTEMA ERP, POS FEL, KARDEX FORENSE Y AUDITORÍA TRANSACCIONAL
-- Motor: MySQL 8.0+ / MariaDB
-- =====================================================================================

DROP DATABASE IF EXISTS quantum_erp_db;
CREATE DATABASE quantum_erp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quantum_erp_db;

-- 1. TABLA DE PRODUCTOS (CATÁLOGO, STOCK Y PROVEEDOR B2B)
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(30) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    categoria VARCHAR(60) NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock_actual INT NOT NULL DEFAULT 0,
    stock_minimo INT NOT NULL DEFAULT 5,
    proveedor_nombre VARCHAR(100) DEFAULT 'Distribuidora Mayorista GT',
    proveedor_tel VARCHAR(20) DEFAULT '50255551234',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. TABLA DE MOVIMIENTOS (ENTRADAS Y SALIDAS OPERATIVAS)
CREATE TABLE movimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    tipo_movimiento ENUM('ENTRADA', 'SALIDA') NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    referencia VARCHAR(120) NOT NULL,
    usuario_responsable VARCHAR(80) NOT NULL DEFAULT 'admin_sistema',
    fecha_movimiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
);

-- 3. TABLA DE KARDEX DE AUDITORÍA FORENSE (LLENADA 100% POR EL TRIGGER)
CREATE TABLE kardex_auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    sku VARCHAR(30) NOT NULL,
    tipo_operacion ENUM('ENTRADA', 'SALIDA') NOT NULL,
    cantidad INT NOT NULL,
    saldo_anterior INT NOT NULL,
    saldo_nuevo INT NOT NULL,
    costo_unitario DECIMAL(10,2) NOT NULL,
    valor_total_movimiento DECIMAL(12,2) NOT NULL,
    referencia_documento VARCHAR(120) NOT NULL,
    usuario_auditoria VARCHAR(80) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
);

-- 4. NUEVA TABLA: FACTURACIÓN ELECTRÓNICA FEL (POS COMERCIAL)
CREATE TABLE facturas_fel (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_dte VARCHAR(60) NOT NULL UNIQUE,
    nit_cliente VARCHAR(25) NOT NULL DEFAULT 'CF',
    nombre_cliente VARCHAR(120) NOT NULL DEFAULT 'Consumidor Final',
    metodo_pago ENUM('EFECTIVO', 'TARJETA_POS', 'TRANSFERENCIA') NOT NULL DEFAULT 'EFECTIVO',
    subtotal_sin_iva DECIMAL(10,2) NOT NULL,
    iva_12 DECIMAL(10,2) NOT NULL,
    total_facturado DECIMAL(10,2) NOT NULL,
    cajero VARCHAR(80) NOT NULL DEFAULT 'Derek Ramos',
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================================
-- 5. TRIGGER TRANSACCIONAL: ANTI-STOCK NEGATIVO + AUDITORÍA KARDEX AUTOMÁTICA
-- =====================================================================================
DELIMITER $$

CREATE TRIGGER trg_procesar_movimiento_kardex
BEFORE INSERT ON movimientos
FOR EACH ROW
BEGIN
    DECLARE v_stock_actual INT;
    DECLARE v_nuevo_stock INT;
    DECLARE v_sku VARCHAR(30);
    DECLARE v_costo DECIMAL(10,2);

    -- Bloqueo de fila para evitar condiciones de carrera (FOR UPDATE)
    SELECT stock_actual, sku, costo_unitario
    INTO v_stock_actual, v_sku, v_costo
    FROM productos
    WHERE id = NEW.producto_id
    FOR UPDATE;

    IF NEW.tipo_movimiento = 'ENTRADA' THEN
        SET v_nuevo_stock = v_stock_actual + NEW.cantidad;
    ELSEIF NEW.tipo_movimiento = 'SALIDA' THEN
        -- Protección estricta contra stock negativo a nivel de motor SQL
        IF v_stock_actual < NEW.cantidad THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR TRANSACCIONAL SQL: Stock insuficiente para procesar la salida o venta.';
        END IF;
        SET v_nuevo_stock = v_stock_actual - NEW.cantidad;
    END IF;

    -- Actualizar el stock en el catálogo principal
    UPDATE productos
    SET stock_actual = v_nuevo_stock
    WHERE id = NEW.producto_id;

    -- Insertar rastro inmutable en el Kardex Forense
    INSERT INTO kardex_auditoria (
        producto_id, sku, tipo_operacion, cantidad,
        saldo_anterior, saldo_nuevo, costo_unitario,
        valor_total_movimiento, referencia_documento, usuario_auditoria
    ) VALUES (
        NEW.producto_id, v_sku, NEW.tipo_movimiento, NEW.cantidad,
        v_stock_actual, v_nuevo_stock, v_costo,
        (NEW.cantidad * v_costo), NEW.referencia, NEW.usuario_responsable
    );
END$$

DELIMITER ;

-- =====================================================================================
-- 6. DATOS SEMILLA EMPRESARIALES (GUATEMALA)
-- =====================================================================================
INSERT INTO productos (sku, nombre, categoria, costo_unitario, precio_venta, stock_actual, stock_minimo, proveedor_nombre, proveedor_tel) VALUES
('HW-SSD-001', 'SSD NVMe Kingston 1TB PCIe 4.0', 'Almacenamiento', 420.00, 595.00, 0, 5, 'Intcomex Guatemala', '50223286000'),
('HW-RAM-002', 'Memoria RAM Corsair Vengeance 16GB DDR4', 'Memorias', 280.00, 410.00, 0, 6, 'Intcomex Guatemala', '50223286000'),
('NET-RTR-003', 'Router Mesh TP-Link Deco X20 AX1800', 'Redes', 650.00, 890.00, 0, 4, 'Redes y Enlaces GT', '50224109900'),
('MON-SAM-004', 'Monitor Samsung 24" IPS 100Hz FHD', 'Monitores', 850.00, 1190.00, 0, 3, 'Distelsa Mayorista', '50224278000'),
('PER-LOG-005', 'Mouse Inalámbrico Logitech MX Master 3S', 'Periféricos', 520.00, 750.00, 0, 5, ' Tecnifácil Corporativo', '50222114400');

-- Ingresos iniciales vía tabla movimientos (dispara el trigger automáticamente)
INSERT INTO movimientos (producto_id, tipo_movimiento, cantidad, referencia, usuario_responsable) VALUES
(1, 'ENTRADA', 15, 'FAC-COMPRA-00102 | Inventario Inicial', 'Derek Ramos'),
(2, 'ENTRADA', 4,  'FAC-COMPRA-00102 | Inventario Inicial (Stock Bajo)', 'Derek Ramos'),
(3, 'ENTRADA', 8,  'FAC-COMPRA-00105 | Lote Redes', 'Derek Ramos'),
(4, 'ENTRADA', 6,  'FAC-COMPRA-00109 | Lote Monitores', 'Derek Ramos'),
(5, 'ENTRADA', 12, 'FAC-COMPRA-00112 | Lote Periféricos', 'Derek Ramos');