-- =============================================================================
-- TRABAJO PRÁCTICO N.º 8 - FOOD STORE EN LA FERIA
-- Archivo: movil/pruebas_sqlite.sql
-- Motor: SQLite 3.37+
-- Propósito: Pruebas locales en la tablet (Consigna 1.c: C1, C7 y transacciones)
-- =============================================================================

PRAGMA foreign_keys = ON;

-- -----------------------------------------------------------------------------
-- 0. CARGA INICIAL DE CATÁLOGO EN LA TABLET (Copia local simulada)
-- -----------------------------------------------------------------------------
INSERT INTO producto_cache (id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia) VALUES
(1, 'Pizza Muzzarella', 105000, 30, 1, 0, '2026-11-10T10:00:00Z'),
(2, 'Empanada de Carne', 15000, 100, 1, 0, '2026-11-10T10:00:00Z'),
(3, 'Coca Cola 1.5L', 50000, 50, 1, 0, '2026-11-10T10:00:00Z'),
(4, 'Cerveza Quilmes 1L', 60000, 0, 0, 0, '2026-11-10T10:00:00Z'),  -- No disponible (sin stock)
(5, 'Postre Chocotorta', 40000, 10, 0, 1, '2026-11-10T10:00:00Z'); -- Eliminado (lápida / baja lógica)

-- -----------------------------------------------------------------------------
-- 1. CASO C1: Consulta del catálogo disponible sin conectarse al servidor
-- REQ-06: Consulta offline que lista únicamente productos disponibles y activos.
-- -----------------------------------------------------------------------------
SELECT 
    id, 
    nombre, 
    precio_centavos / 100.0 AS precio_pesos,
    stock_visto,
    disponible
FROM producto_cache
WHERE disponible = 1 AND eliminado = 0
ORDER BY id;

-- -----------------------------------------------------------------------------
-- 2. TRANSACCIÓN ATÓMICA DE BORRADOR COMPLETO GUARDADA (BEGIN ... COMMIT)
-- Registra cabecera de borrador, dos líneas y la solicitud en cola_sync.
-- -----------------------------------------------------------------------------
BEGIN TRANSACTION;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('b1000000-0000-0000-0000-000000000001', 'operador_feria_1', 'EFECTIVO', '2026-11-10T12:30:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES 
('b1000000-0000-0000-0000-000000000001', 1, 2, 105000), -- 2 Pizzas Muzzarella
('b1000000-0000-0000-0000-000000000001', 3, 2, 50000);  -- 2 Coca Colas

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('s1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'PENDIENTE', NULL);

COMMIT;

-- Verificación de persistencia tras COMMIT
SELECT 'Borrador confirmado' AS prueba, id_local, usuario, forma_pago FROM pedido_borrador WHERE id_local = 'b1000000-0000-0000-0000-000000000001';
SELECT id_local, producto_id, cantidad, precio_centavos_visto FROM item_borrador WHERE id_local = 'b1000000-0000-0000-0000-000000000001';
SELECT solicitud_uuid, id_local, estado FROM cola_sync WHERE solicitud_uuid = 's1000000-0000-0000-0000-000000000001';

-- -----------------------------------------------------------------------------
-- 3. TRANSACCIÓN DESHECHA (BEGIN ... ROLLBACK)
-- Simula un cliente que cancela el pedido en el mostrador antes de confirmar.
-- -----------------------------------------------------------------------------
BEGIN TRANSACTION;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('b_cancelado_0000-0000-0000-000000000002', 'operador_feria_1', 'TARJETA', '2026-11-10T12:35:00Z');

INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('b_cancelado_0000-0000-0000-000000000002', 2, 6, 15000);

-- El cliente se arrepiente y no compra
ROLLBACK;

-- Verificación de anulación: no debe existir ninguna fila en pedido_borrador ni item_borrador
SELECT 
    COUNT(*) AS filas_despues_de_rollback 
FROM pedido_borrador 
WHERE id_local = 'b_cancelado_0000-0000-0000-000000000002';

-- -----------------------------------------------------------------------------
-- 4. CASO C7: Cantidad en 0 y Producto inexistente dan error y no dejan filas
-- REQ-07: Comprobación de restricciones CHECK y FOREIGN KEY activas.
-- -----------------------------------------------------------------------------

-- 4.a Prueba con cantidad = 0 (Debe fallar por CHECK (cantidad > 0))
-- En sqlite3 o script, envolver en bloque para verificar el rechazo:
/*
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('b1000000-0000-0000-0000-000000000001', 2, 0, 15000);
-- ERROR ESPERADO: CHECK constraint failed: cantidad > 0
*/

-- 4.b Prueba con producto_id inexistente (Debe fallar por FOREIGN KEY)
/*
INSERT INTO item_borrador (id_local, producto_id, cantidad, precio_centavos_visto)
VALUES ('b1000000-0000-0000-0000-000000000001', 9999, 1, 15000);
-- ERROR ESPERADO: FOREIGN KEY constraint failed
*/

-- Comprobación final: La tabla item_borrador solo contiene las líneas válidas originales
SELECT 'Verificación integridad C7' AS control, COUNT(*) AS items_validos_totales FROM item_borrador;
