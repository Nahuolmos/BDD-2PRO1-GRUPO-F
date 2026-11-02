-- =============================================================================
-- TP Unidad 7 - Consultas equivalentes en PostgreSQL
-- Base de datos: food_store
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Consulta b) Equivalente: Pedidos con estado ENTREGADO
-- Nota: En PostgreSQL no existe columna "estado". Se deriva la misma lógica
-- utilizada en la migración a MongoDB (basada en la fecha del pedido).
-- -----------------------------------------------------------------------------
SELECT
    p.id AS pedido_id,
    CASE
        WHEN p.fecha < NOW() - INTERVAL '6 months' THEN 'ENTREGADO'
        WHEN p.fecha < NOW() - INTERVAL '3 months' THEN 'ENVIADO'
        WHEN p.fecha < NOW() - INTERVAL '1 month' THEN 'PROCESANDO'
        ELSE 'PENDIENTE'
    END AS estado,
    p.fecha,
    COALESCE((
        SELECT SUM(dp.cantidad * dp.precio_unitario)
        FROM detalle_pedido dp
        WHERE dp.pedido_id = p.id
    ), 0) AS total
FROM pedido p
WHERE
    CASE
        WHEN p.fecha < NOW() - INTERVAL '6 months' THEN 'ENTREGADO'
        WHEN p.fecha < NOW() - INTERVAL '3 months' THEN 'ENVIADO'
        WHEN p.fecha < NOW() - INTERVAL '1 month' THEN 'PROCESANDO'
        ELSE 'PENDIENTE'
    END = 'ENTREGADO'
ORDER BY p.fecha DESC;

-- -----------------------------------------------------------------------------
-- Consulta c) Equivalente: Pedidos que contienen producto_id = 50001
-- -----------------------------------------------------------------------------
SELECT DISTINCT
    p.id AS pedido_id,
    p.fecha,
    CASE
        WHEN p.fecha < NOW() - INTERVAL '6 months' THEN 'ENTREGADO'
        WHEN p.fecha < NOW() - INTERVAL '3 months' THEN 'ENVIADO'
        WHEN p.fecha < NOW() - INTERVAL '1 month' THEN 'PROCESANDO'
        ELSE 'PENDIENTE'
    END AS estado
FROM pedido p
JOIN detalle_pedido dp ON dp.pedido_id = p.id
WHERE dp.producto_id = 50001
ORDER BY p.id;

-- -----------------------------------------------------------------------------
-- Fin de consultas_postgresql.sql
-- =============================================================================