-- =============================================================================
-- TRABAJO PRÁCTICO N.º 1 - FOOD STORE
-- Descripción: Carga inicial de datos de prueba
-- =============================================================================

-- 1. Insertar Categorías
INSERT INTO categoria (nombre, activo) VALUES
('Pizzas', TRUE),
('Empanadas', TRUE),
('Bebidas', TRUE);

-- 2. Insertar Productos
-- Relacionados con las categorías creadas (1: Pizzas, 2: Empanadas, 3: Bebidas)
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
-- Formas de pago válidas según el ENUM: 'EFECTIVO', 'TARJETA', 'TRANSFERENCIA'
INSERT INTO pedido (cliente_id, forma_pago, fecha) VALUES
(1, 'EFECTIVO', NOW() - INTERVAL '2 days'),      -- Pedido 1 (Juan)
(2, 'TARJETA', NOW() - INTERVAL '1 day'),       -- Pedido 2 (María)
(1, 'TRANSFERENCIA', NOW());                    -- Pedido 3 (Juan)

-- 5. Insertar Detalle de Pedidos
-- Muestra el registro del precio histórico al momento de cada venta
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 1000.00), -- Pedido 1: Muzzarella cobrada a valor histórico ($1000)
(1, 3, 2, 450.00),  -- Pedido 1: 2 Coca Colas
(2, 2, 6, 150.00),  -- Pedido 2: 6 Empanadas
(3, 1, 2, 1050.00); -- Pedido 3: Muzzarella cobrada al precio actualizado ($1050)