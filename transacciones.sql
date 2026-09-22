-- =============================================================================
-- TPI — Objetivo 8: Transacciones, atomicidad y concurrencia
-- Archivo: transacciones.sql
-- Motor: PostgreSQL 16+
-- Spec: specs/spec_transacciones.md
-- =============================================================================
-- NOTA: Ejecutar ejemplos en 2 sesiones psql separadas para probar aislamiento.

-- -------------------------------------------------------------------------
-- 1. Atomicidad: pedido + detalles en una transacción
-- Si un detalle falla (stock/trigger), todo hace ROLLBACK
-- -------------------------------------------------------------------------
BEGIN;
    INSERT INTO pedido (cliente_id, forma_pago) VALUES (1, 'EFECTIVO') RETURNING id; -- supongamos id 999
    -- Usar el id retornado (ej. 999) para detalles
    INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES (999, 1, 1, (SELECT precio_actual FROM producto WHERE id=1));
    INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
    VALUES (999, 2, 9999, (SELECT precio_actual FROM producto WHERE id=2)); -- falla por trigger stock
    -- Si la línea anterior falla, hacer ROLLBACK, sino COMMIT
-- ROLLBACK; -- descomentar para probar: no debe quedar pedido 999
-- COMMIT;

-- Verificación atomicidad:
-- SELECT * FROM pedido WHERE id=999; -- debe dar 0 filas si hubo ROLLBACK

-- -------------------------------------------------------------------------
-- 2. Transacción exitosa con COMMIT
-- -------------------------------------------------------------------------
BEGIN;
    INSERT INTO pedido (cliente_id, forma_pago) VALUES (1, 'TARJETA') RETURNING id;
    -- Con el id, insertar detalle válido
    -- INSERT INTO detalle_pedido ...
COMMIT;
-- Ver: SELECT * FROM pedido ORDER BY id DESC LIMIT 1;

-- -------------------------------------------------------------------------
-- 3. Niveles de aislamiento — probar en 2 sesiones
-- Sesión A y B: abrir 2 psql
-- -------------------------------------------------------------------------
-- Sesión A:
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SELECT * FROM producto WHERE id=1; -- lee stock=30

-- Sesión B (concurrente):
-- BEGIN;
-- UPDATE producto SET stock = stock -1 WHERE id=1;
-- COMMIT;

-- Sesión A (sigue en REPEATABLE READ):
-- SELECT * FROM producto WHERE id=1; -- sigue viendo stock=30 (snapshot), no ve el -1
-- COMMIT;
-- SELECT * FROM producto WHERE id=1; -- ahora ve stock=29 (READ COMMITTED vería 29 antes del COMMIT)

-- Con READ COMMITTED (default) la segunda lectura sí vería el cambio de B.
-- Documentar en informe_concurrencia.md qué anomalía evita cada nivel.

-- -------------------------------------------------------------------------
-- 4. Uso de procedimiento con transacción implícita (pr_crear_pedido)
-- CALL ya es atómico: si un item falla, todo hace ROLLBACK
-- -------------------------------------------------------------------------
-- BEGIN; -- opcional, CALL maneja su propia transacción si no hay BEGIN
-- CALL pr_crear_pedido(1, '[{"producto_id":1,"cantidad":1},{"producto_id":999,"cantidad":1}]'::jsonb); -- debe hacer ROLLBACK total
-- SELECT * FROM pedido ORDER BY id DESC LIMIT 2; -- no debe haber pedido nuevo
