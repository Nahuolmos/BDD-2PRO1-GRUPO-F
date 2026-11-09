-- =============================================================================
-- TP UNIDAD 7: NoSQL y nuevas formas de almacenamiento | Food Store
-- Archivo: postgresql/consultas_postgresql.sql
-- Motor: PostgreSQL
-- Base de datos: food_store
-- Propósito: Consultas relacionales equivalentes para verificación cruzada
-- =============================================================================

-- =============================================================================
-- CONSIGNA 5: Consultas equivalentes a los apartados b) y c)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Consulta b) Equivalente: Pedidos con estado 'ENTREGADO'
-- Objetivo: Recuperar los pedidos cuyo estado sea ENTREGADO, mostrando su
-- identificador, estado, fecha y total acumulado.
-- -----------------------------------------------------------------------------
SELECT 
    p.id AS pedido_id,
    p.estado,
    to_char(p.fecha, 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS fecha,
    round(COALESCE(SUM(dp.cantidad * dp.precio_unitario), 0)::numeric, 2) AS total
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE p.estado = 'ENTREGADO'
  AND p.id IN (1, 2, 3, 4, 5)
GROUP BY p.id, p.estado, p.fecha
ORDER BY p.id;

-- -----------------------------------------------------------------------------
-- Consulta c) Equivalente: Pedidos que contengan el producto_id = 1 (Pizza Muzzarella)
-- Objetivo: Identificar unívocamente los pedidos que incluyen al menos una línea
-- con el producto indicado, mostrando el pedido y el detalle correspondiente.
-- -----------------------------------------------------------------------------
SELECT 
    p.id AS pedido_id,
    p.estado,
    dp.producto_id,
    pr.nombre AS producto_nombre,
    dp.cantidad,
    dp.precio_unitario,
    round((dp.cantidad * dp.precio_unitario)::numeric, 2) AS subtotal,
    (
        SELECT round(SUM(dp2.cantidad * dp2.precio_unitario)::numeric, 2)
        FROM detalle_pedido dp2
        WHERE dp2.pedido_id = p.id
    ) AS total
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
JOIN producto pr ON pr.id = dp.producto_id
WHERE dp.producto_id = 1
  AND p.id IN (1, 2, 3, 4, 5)
ORDER BY p.id;

-- =============================================================================
-- CONSULTAS COMPLEMENTARIAS (Para auditoría y verificación integral)
-- =============================================================================

-- Equivalente Consulta a): Todos los pedidos (id y estado)
SELECT 
    p.id AS pedido_id,
    p.estado
FROM pedido p
WHERE p.id IN (1, 2, 3, 4, 5)
ORDER BY p.id;

-- Equivalente Consulta d): Pedidos con total > 5000.00
SELECT 
    p.id AS pedido_id,
    p.estado,
    c.nombre AS cliente_nombre,
    round(SUM(dp.cantidad * dp.precio_unitario)::numeric, 2) AS total
FROM pedido p
JOIN cliente c ON c.id = p.cliente_id
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE p.id IN (1, 2, 3, 4, 5)
GROUP BY p.id, p.estado, c.nombre
HAVING SUM(dp.cantidad * dp.precio_unitario) > 5000
ORDER BY total DESC;
