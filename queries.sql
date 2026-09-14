-- =============================================================================
-- TRABAJO PRÁCTICO 4: OPTIMIZACIÓN Y CONSULTAS ANALÍTICAS
-- =============================================================================

SET work_mem = '64MB';

CREATE INDEX IF NOT EXISTS idx_detalle_pedido_producto_pedido 
ON detalle_pedido (producto_id, pedido_id);

CREATE INDEX IF NOT EXISTS idx_pedido_id_fecha 
ON pedido (id, fecha);

--Consulta 1 : Facturacion por categoria y mes
SELECT 
    c.nombre AS categoria,
    EXTRACT(YEAR FROM p.fecha) AS anio,
    EXTRACT(MONTH FROM p.fecha) AS mes,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
FROM categoria c
JOIN producto pr ON pr.categoria_id = c.id AND pr.activo = true
JOIN detalle_pedido dp ON dp.producto_id = pr.id
JOIN pedido p ON p.id = dp.pedido_id
WHERE c.activo = true
GROUP BY c.nombre, EXTRACT(YEAR FROM p.fecha), EXTRACT(MONTH FROM p.fecha)
ORDER BY anio DESC, mes DESC, facturacion_total DESC;

-- Consulta 2: Ranking de Clientes con Mayor Gasto Total
SELECT 
    cl.id AS cliente_id,
    cl.nombre,
    COUNT(DISTINCT p.id) AS total_pedidos,
    SUM(dp.cantidad * dp.precio_unitario) AS gasto_total
FROM cliente cl
JOIN pedido p ON p.cliente_id = cl.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id
GROUP BY cl.id, cl.nombre
ORDER BY gasto_total DESC
LIMIT 20;