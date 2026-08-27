


-- =============================================================================
-- TRABAJO PRÁCTICO N.º 1 - FOOD STORE
-- Archivo: schema.sql
-- Motor: PostgreSQL
-- Autor: Facundo Cabrera
-- =============================================================================

-- 1. Limpieza preventiva de tablas y tipos (ejecución idempotente)
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS cliente;
DROP TYPE IF EXISTS forma_pago_enum;

-- 2. Creación de tipos enumerados
CREATE TYPE forma_pago_enum AS ENUM ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA');

-- 3. Tabla: CATEGORIA
CREATE TABLE categoria (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Tabla: PRODUCTO
CREATE TABLE producto (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    precio_actual NUMERIC(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    categoria_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Clave Foránea
    CONSTRAINT fk_producto_categoria 
        FOREIGN KEY (categoria_id) 
        REFERENCES categoria(id) 
        ON DELETE RESTRICT,
        
    -- Restricciones CHECK (Regla R5: stock y precio no negativos)
    CONSTRAINT chk_producto_precio CHECK (precio_actual >= 0),
    CONSTRAINT chk_producto_stock CHECK (stock >= 0)
);

-- 5. Tabla: CLIENTE
CREATE TABLE cliente (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Restricción UNIQUE (Regla R6: email único)
    CONSTRAINT uq_cliente_email UNIQUE (email)
);

-- 6. Tabla: PEDIDO
CREATE TABLE pedido (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL DEFAULT now(),
    forma_pago forma_pago_enum NOT NULL,
    cliente_id BIGINT NOT NULL,
    
    -- Clave Foránea
    CONSTRAINT fk_pedido_cliente 
        FOREIGN KEY (cliente_id) 
        REFERENCES cliente(id) 
        ON DELETE RESTRICT
);

-- 7. Tabla: DETALLE_PEDIDO (Tabla Intermedia / Entidad Asociativa)
CREATE TABLE detalle_pedido (
    pedido_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(10, 2) NOT NULL,
    
    -- Clave Primaria Compuesta
    CONSTRAINT pk_detalle_pedido PRIMARY KEY (pedido_id, producto_id),
    
    -- Claves Foráneas
    CONSTRAINT fk_detalle_pedido 
        FOREIGN KEY (pedido_id) 
        REFERENCES pedido(id) 
        ON DELETE RESTRICT,
    CONSTRAINT fk_detalle_producto 
        FOREIGN KEY (producto_id) 
        REFERENCES producto(id) 
        ON DELETE RESTRICT,
        
    -- Restricciones CHECK (Regla R4 y R5: cantidad mayor a cero y precio no negativo)
    CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detalle_precio CHECK (precio_unitario >= 0)
);

-- 8. Creación de ÍndicesJustificados

-- Índice 1: Optimiza la búsqueda del historial de pedidos emitidos por un cliente específico
CREATE INDEX idx_pedido_cliente_id ON pedido(cliente_id);

-- Índice 2: Acelera las consultas del catálogo público para listar productos activos de una categoría concreta
CREATE INDEX idx_producto_categoria_activo ON producto(categoria_id, activo);

-- =============================================================================
-- DATOS DE PRUEBA - FOOD STORE
-- =============================================================================

-- 1. Insertar Categorías
INSERT INTO categoria (nombre, activo) VALUES
('Pizzas', TRUE),
('Empanadas', TRUE),
('Bebidas', TRUE);

-- 2. Insertar Productos
-- Nota: La categoría 1 es Pizzas, 2 es Empanadas, 3 es Bebidas
INSERT INTO producto (nombre, precio_actual, stock, activo, categoria_id) VALUES
('Pizza Muzzarella', 1050.00, 30, TRUE, 1),
('Empanada de Carne', 150.00, 100, TRUE, 2),
('Coca Cola 1.5L', 500.00, 50, TRUE, 3);

-- 3. Insertar Clientes
INSERT INTO cliente (nombre, email) VALUES
('Juan Pérez', 'juan.perez@email.com'),
('María Gómez', 'maria.gomez@email.com'),
('Carlos López', 'carlos.lopez@email.com');

-- 4. Insertar Pedidos
-- Formas de pago válidas: 'EFECTIVO', 'TARJETA', 'TRANSFERENCIA'
INSERT INTO pedido (cliente_id, forma_pago, fecha) VALUES
(1, 'EFECTIVO', NOW() - INTERVAL '2 days'),      -- Pedido 1 (Cliente: Juan)
(2, 'TARJETA', NOW() - INTERVAL '1 day'),       -- Pedido 2 (Cliente: María)
(1, 'TRANSFERENCIA', NOW());                    -- Pedido 3 (Cliente: Juan)

-- 5. Insertar Detalle de Pedidos
-- Demuestra el registro de precios históricos al momento de la venta
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 1000.00), -- Pedido 1: 1 Muzzarella a precio histórico ($1000)
(1, 3, 2, 450.00),  -- Pedido 1: 2 Coca Colas a $450 c/u
(2, 2, 6, 150.00),  -- Pedido 2: 6 Empanadas a $150 c/u
(3, 1, 2, 1050.00); -- Pedido 3: 2 Muzzarellas al precio actual ($1050)
