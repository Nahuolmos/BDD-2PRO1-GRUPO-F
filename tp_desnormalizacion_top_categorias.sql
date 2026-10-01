-- =============================================================================
-- TP Unidad 4 Parte 2: Desnormalización controlada top 5 categorías del día
-- Motor: PostgreSQL 16+
-- Spec: specs/spec_desnormalizacion_top.md
-- =============================================================================
-- ADAPTACIÓN repo: la consigna usa dp.subtotal, dp.eliminado, ped.eliminado.
-- En este repo detalle_pedido solo tiene (cantidad, precio_unitario) en
-- schema.sql:74 y pedido sin eliminado en schema.sql:60. subtotal se calcula
-- como cantidad*precio_unitario (views.sql:82). Se agregan las columnas
-- eliminado faltantes para poder filtrar como pide 5.1.

-- -------------------------------------------------------------------------
-- 0. Pre-requisitos (idempotentes)
-- -------------------------------------------------------------------------
ALTER TABLE pedido ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE detalle_pedido ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

-- -------------------------------------------------------------------------
-- 5.2(a) Consulta original 5.1 adaptada (medir con EXPLAIN ANALYZE)
-- -------------------------------------------------------------------------
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT c.nombre AS categoria,
--        SUM(dp.cantidad * dp.precio_unitario) AS total_vendido
-- FROM detalle_pedido dp
-- JOIN producto pr ON pr.id = dp.producto_id
-- JOIN categoria c ON c.id = pr.categoria_id
-- JOIN pedido ped ON ped.id = dp.pedido_id
-- WHERE ped.fecha::date = CURRENT_DATE
--   AND dp.eliminado = FALSE
--   AND ped.eliminado = FALSE
-- GROUP BY c.nombre
-- ORDER BY total_vendido DESC
-- LIMIT 5;
-- Reportar: tiempo y nodo dominante (esperado: Hash Join + Seq Scan sobre
-- detalle_pedido ~300k filas, ver informe_mediciones.md:41 como referencia).

-- -------------------------------------------------------------------------
-- 5.2(b) Patrón elegido: vista materializada (justificación en informe)
-- Evidencia: 4 JOINs + GROUP BY ejecutados por minuto. Sincronización:
-- REFRESH CONCURRENTLY con índice UNIQUE, sin bloquear lecturas.
-- Reversible: DROP MATERIALIZED VIEW, la fuente no se toca.
-- Alternativa descartada: columna precalculada con trigger (tiempo real total
-- pero overhead en cada INSERT y más código de sincronización).
-- -------------------------------------------------------------------------

-- -------------------------------------------------------------------------
-- 5.2(c) Estructura desnormalizada + sincronización
-- Pre-agrega por día y categoría: el panel lee 3 filas en vez de 300k.
-- -------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS mv_ventas_dia_categoria;

CREATE MATERIALIZED VIEW mv_ventas_dia_categoria AS
SELECT
    (ped.fecha::date) AS dia,
    c.id AS categoria_id,
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unitario) AS total_vendido,
    COUNT(*) AS lineas
FROM detalle_pedido dp
JOIN producto pr ON pr.id = dp.producto_id
JOIN categoria c ON c.id = pr.categoria_id
JOIN pedido ped ON ped.id = dp.pedido_id
WHERE dp.eliminado = FALSE
  AND ped.eliminado = FALSE
GROUP BY (ped.fecha::date), c.id, c.nombre
WITH DATA;

-- UNIQUE obligatorio para REFRESH CONCURRENTLY
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_ventas_dia_cat_unique
    ON mv_ventas_dia_categoria (dia, categoria_id);

CREATE INDEX IF NOT EXISTS idx_mv_ventas_dia_fecha
    ON mv_ventas_dia_categoria (dia);

-- Sincronización: refresco frecuente sin bloquear lecturas (cron cada 1-5 min)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_ventas_dia_categoria;
-- Reversible sin pérdida: DROP MATERIALIZED VIEW IF EXISTS mv_ventas_dia_categoria;

-- -------------------------------------------------------------------------
-- 5.2(d) Consulta desnormalizada (mismo reporte, sin JOINs)
-- EXPLAIN (ANALYZE, BUFFERS) para tabla antes/después del informe.
-- -------------------------------------------------------------------------
-- SELECT categoria, total_vendido
-- FROM mv_ventas_dia_categoria
-- WHERE dia = CURRENT_DATE
-- ORDER BY total_vendido DESC
-- LIMIT 5;
-- Esperado después: Seq/Index Scan sobre ~3 filas (una por categoría),
-- ~10ms vs ~1000ms del plan con 4 JOINs. Registrar en informe breve.

-- -------------------------------------------------------------------------
-- 5.2(e) Auditoría desincronización (debe dar 0 filas)
-- -------------------------------------------------------------------------
-- (SELECT dia, categoria_id, categoria, total_vendido FROM mv_ventas_dia_categoria
--  EXCEPT
--  SELECT (ped.fecha::date), c.id, c.nombre, SUM(dp.cantidad*dp.precio_unitario)
--  FROM detalle_pedido dp
--  JOIN producto pr ON pr.id = dp.producto_id
--  JOIN categoria c ON c.id = pr.categoria_id
--  JOIN pedido ped ON ped.id = dp.pedido_id
--  WHERE dp.eliminado = FALSE AND ped.eliminado = FALSE
--  GROUP BY (ped.fecha::date), c.id, c.nombre)
-- UNION ALL
-- (SELECT (ped.fecha::date), c.id, c.nombre, SUM(dp.cantidad*dp.precio_unitario)
--  FROM detalle_pedido dp
--  JOIN producto pr ON pr.id = dp.producto_id
--  JOIN categoria c ON c.id = pr.categoria_id
--  JOIN pedido ped ON ped.id = dp.pedido_id
--  WHERE dp.eliminado = FALSE AND ped.eliminado = FALSE
--  GROUP BY (ped.fecha::date), c.id, c.nombre
--  EXCEPT
--  SELECT dia, categoria_id, categoria, total_vendido FROM mv_ventas_dia_categoria);
