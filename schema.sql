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
-- REGLAS Y RESTRICCIONES - FOOD STORE (TP2)
-- Autor: Facundo Cabrera
-- =============================================================================

BEGIN;
-- 1. Regla: Validar formato básico de correo electrónico en clientes
ALTER TABLE cliente
ADD CONSTRAINT chk_cliente_email_formato 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- 2. Regla: Evitar pedidos con fechas futuras
ALTER TABLE pedido
ADD CONSTRAINT chk_pedido_fecha_no_futura 
CHECK (fecha <= NOW());
COMMIT;

-- =============================================================================
-- SCRIPT DE POBLADO MASIVO - FOOD STORE (TP3)
-- Autor: Facundo Cabrera
-- =============================================================================

BEGIN;

-- 1. Insertar 20.000 Clientes de forma masiva
INSERT INTO cliente (nombre, email)
SELECT 
    'Cliente ' || i,
    'usuario' || i || '@correo' || (i % 100) || '.com'
FROM generate_series(1, 20000) AS s(i);

-- 2. Insertar 50.000 Productos distribuidos entre las categorías existentes (1, 2, 3)
INSERT INTO producto (nombre, precio_actual, stock, activo, categoria_id)
SELECT 
    'Producto Masivo ' || i,
    ROUND((500 + RANDOM() * 4500)::numeric, 2), -- Precios entre 500 y 5000
    CAST(RANDOM() * 200 AS INT),                -- Stock entre 0 y 200
    TRUE,
    ((i % 3) + 1)                               -- Distribución pareja en categorías 1, 2 y 3
FROM generate_series(1, 50000) AS s(i);

-- 3. Insertar 200.000 Pedidos asociados a clientes aleatorios
INSERT INTO pedido (cliente_id, forma_pago, fecha)
SELECT 
    ((i % 20000) + 1),                          -- Distribuido entre los 20.000 clientes
    CASE (i % 3) 
        WHEN 0 THEN 'EFECTIVO'::forma_pago_enum 
        WHEN 1 THEN 'TARJETA'::forma_pago_enum 
        ELSE 'TRANSFERENCIA'::forma_pago_enum 
    END,
    NOW() - (RANDOM() * INTERVAL '365 days')    -- Fechas aleatorias en el último año
FROM generate_series(1, 200000) AS s(i);

-- 4. Insertar Detalles de Pedido (1 o 2 ítems por pedido para llegar a ~300.000 detalles)
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
SELECT 
    p.id,
    ((p.id % 50000) + 1),                       -- Producto asociado
    (1 + (p.id % 5)),                           -- Cantidad entre 1 y 5
    1500.00                                     -- Precio unitario de referencia
FROM pedido p;

COMMIT;

-- 5. Actualizar estadísticas del optimizador (Obligatorio antes de medir con EXPLAIN)
ANALYZE cliente;
ANALYZE producto;
ANALYZE pedido;
ANALYZE detalle_pedido;

SELECT p1.nombre, p1.precio_actual
FROM producto p1
WHERE p1.precio_actual > (
    SELECT AVG(p2.precio_actual)
    FROM producto p2
    WHERE p2.categoria_id = p1.categoria_id
)
ORDER BY p1.precio_actual DESC;

-- Verificación de equivalencia para la consulta de productos de alto precio
(
  SELECT id FROM producto WHERE precio_actual > 1000 AND activo = TRUE
)
EXCEPT
(
  SELECT p.id FROM producto p WHERE p.activo = TRUE AND p.precio_actual > 1000
);