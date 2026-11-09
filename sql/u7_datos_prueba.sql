-- =============================================================================
-- TRABAJO PRÁCTICO N.º 7 - FOOD STORE
-- Archivo: sql/u7_datos_prueba.sql
-- Propósito: Carga de 5 pedidos de prueba autocontenidos con reglas del dominio
-- =============================================================================

-- 1. Asegurar clientes de prueba
INSERT INTO cliente (id, nombre, email) OVERRIDING SYSTEM VALUE
VALUES 
    (1, 'Juan Pérez', 'juan.perez@email.com'),
    (2, 'María Gómez', 'maria.gomez@email.com'),
    (3, 'Carlos López', 'carlos.lopez@email.com')
ON CONFLICT (id) DO UPDATE 
SET nombre = EXCLUDED.nombre, email = EXCLUDED.email;

-- 2. Asegurar categorías
INSERT INTO categoria (id, nombre, activo) OVERRIDING SYSTEM VALUE
VALUES 
    (1, 'Pizzas', TRUE),
    (2, 'Empanadas', TRUE),
    (3, 'Bebidas', TRUE)
ON CONFLICT (id) DO NOTHING;

-- 3. Asegurar productos
INSERT INTO producto (id, nombre, precio_actual, stock, activo, categoria_id) OVERRIDING SYSTEM VALUE
VALUES 
    (1, 'Pizza Muzzarella', 1050.00, 30, TRUE, 1),
    (2, 'Empanada de Carne', 150.00, 100, TRUE, 2),
    (3, 'Coca Cola 1.5L', 500.00, 50, TRUE, 3)
ON CONFLICT (id) DO UPDATE
SET nombre = EXCLUDED.nombre, precio_actual = EXCLUDED.precio_actual;

-- 4. Asegurar columna 'estado' en pedido (si no existiera previamente)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'pedido' AND column_name = 'estado'
    ) THEN
        ALTER TABLE pedido ADD COLUMN estado VARCHAR(20) DEFAULT 'PENDIENTE';
    END IF;
END $$;

-- 5. Limpiar pedidos de prueba previos 1 a 5 para recarga limpia
DELETE FROM detalle_pedido WHERE pedido_id IN (1, 2, 3, 4, 5);
DELETE FROM pedido WHERE id IN (1, 2, 3, 4, 5);

-- 6. Insertar los 5 Pedidos
INSERT INTO pedido (id, cliente_id, forma_pago, fecha, estado) OVERRIDING SYSTEM VALUE
VALUES 
    (1, 1, 'EFECTIVO', '2026-03-15 19:30:00+00', 'ENTREGADO'),
    (2, 2, 'TARJETA', '2026-04-20 21:00:00+00', 'ENTREGADO'),
    (3, 3, 'TRANSFERENCIA', '2026-08-10 13:15:00+00', 'ENVIADO'),
    (4, 1, 'TARJETA', '2026-10-05 20:45:00+00', 'ENTREGADO'),
    (5, 2, 'EFECTIVO', '2026-11-02 21:30:00+00', 'PENDIENTE');

-- 7. Insertar Detalles de los 5 Pedidos con precios históricos
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
VALUES 
    -- Pedido 1 (Total: 2000 + 900 = 2900)
    (1, 1, 2, 1000.00),
    (1, 3, 2, 450.00),
    
    -- Pedido 2 (Total: 1800)
    (2, 2, 12, 150.00),
    
    -- Pedido 3 (Total: 3150 + 1500 = 4650)
    (3, 1, 3, 1050.00),
    (3, 3, 3, 500.00),
    
    -- Pedido 4 (Total: 4400 + 1920 = 6320)
    (4, 1, 4, 1100.00),
    (4, 2, 12, 160.00),
    
    -- Pedido 5 (Total: 960 + 500 = 1460)
    (5, 2, 6, 160.00),
    (5, 3, 1, 500.00);
