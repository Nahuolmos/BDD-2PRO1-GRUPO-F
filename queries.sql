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

-- Consulta 3A: Ranking de Clientes por Gasto Acumulado (Función de Ventana)

SELECT 
    cl.id AS cliente_id,
    cl.nombre,
    SUM(dp.cantidad * dp.precio_unitario) AS gasto_total,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS posicion_ranking
FROM cliente cl
JOIN pedido p ON p.cliente_id = cl.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id
GROUP BY cl.id, cl.nombre
ORDER BY posicion_ranking ASC;

-- Consulta 3B: Productos cuyo precio supera el promedio de su categoría (CTE + Función de Ventana)

WITH promedios AS (
    SELECT 
        pr.id AS producto_id,
        pr.nombre,
        pr.precio_actual,
        c.nombre AS categoria,
        AVG(pr.precio_actual) OVER (PARTITION BY pr.categoria_id) AS promedio_cat
    FROM producto pr
    JOIN categoria c ON c.id = pr.categoria_id
    WHERE pr.activo = true 
      AND c.activo = true
)
SELECT 
    producto_id,
    nombre,
    precio_actual,
    categoria
FROM promedios
WHERE precio_actual > promedio_cat
ORDER BY precio_actual DESC;