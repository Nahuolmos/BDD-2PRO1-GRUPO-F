-- =============================================================================
-- TRABAJO PRÁCTICO — Unidad 3, Semana 5 — Partes B y C: Vistas
-- Archivo: views.sql
-- Motor: PostgreSQL 16+
-- =============================================================================

-- -------------------------------------------------------------------------
-- Parte B — Vista 1: Productos vigentes con su categoría
-- Spec: specs/spec_vista_productos_vigentes.md
-- Objetivo: simplificar catálogo público y estandarizar filtro de vigencia.
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_productos_vigentes AS
SELECT
    pr.id           AS producto_id,
    pr.nombre       AS producto,
    pr.precio_actual,
    pr.stock,
    c.id            AS categoria_id,
    c.nombre        AS categoria
FROM producto pr
JOIN categoria c ON c.id = pr.categoria_id
WHERE pr.activo = TRUE
  AND c.activo = TRUE
  AND pr.eliminado = FALSE
  AND c.eliminado = FALSE;

COMMENT ON VIEW v_productos_vigentes IS 'Catálogo público: solo productos y categorías vigentes no eliminados (soft delete). Spec: spec_vista_productos_vigentes.md + spec_soft_delete.md';

-- Verificación de equivalencia (debe dar 0 filas si es correcta):
-- (SELECT producto_id FROM v_productos_vigentes)
-- EXCEPT
-- (SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE AND pr.eliminado=FALSE AND c.eliminado=FALSE);
-- Y viceversa con EXCEPT inverso.
-- Soft delete: UPDATE producto SET eliminado=TRUE WHERE id=1; -> debe desaparecer de la vista pero seguir en tabla con eliminado=TRUE

-- -------------------------------------------------------------------------
-- Parte B — Vista 2: Pedidos con datos del cliente (CRITERIO DE SEGURIDAD)
-- Spec: specs/spec_vista_pedidos_con_cliente.md
-- Objetivo: exponer pedido + cliente sin columna sensible (email), para poder
-- dar GRANT SELECT sobre la vista sin dar acceso a la tabla base cliente.
-- Nota modelo: el PDF pide "usuario sin contrasena". En este esquema la tabla
-- es cliente(id, nombre, email) y la columna sensible es email (PII). Se oculta
-- email para cumplir el mismo principio de seguridad.
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pedidos_con_cliente AS
SELECT
    p.id            AS pedido_id,
    p.fecha,
    p.forma_pago,
    p.cliente_id,
    cl.nombre       AS cliente_nombre,
    cl.created_at   AS cliente_alta
    -- cl.email INTENCIONALMENTE OMITIDO por seguridad
FROM pedido p
JOIN cliente cl ON cl.id = p.cliente_id;

COMMENT ON VIEW v_pedidos_con_cliente IS 'Pedidos con cliente sin exponer email (seguridad). Permite GRANT SELECT sin acceso a cliente. Spec: spec_vista_pedidos_con_cliente.md';

-- Ejemplo de privilegio seguro (ejecutar como superuser):
-- REVOKE ALL ON cliente FROM rol_reportes;
-- GRANT SELECT ON v_pedidos_con_cliente TO rol_reportes;

-- Verificación de equivalencia:
-- (SELECT pedido_id, fecha, forma_pago, cliente_id, cliente_nombre FROM v_pedidos_con_cliente)
-- EXCEPT
-- (SELECT p.id, p.fecha, p.forma_pago, p.cliente_id, cl.nombre FROM pedido p JOIN cliente cl ON cl.id=p.cliente_id)
-- debe dar 0 filas. Y SELECT email FROM v_pedidos_con_cliente debe fallar.

-- -------------------------------------------------------------------------
-- Parte B — Vista 3: Detalle de un pedido con nombre del producto
-- Spec: specs/spec_vista_detalle_pedido.md
-- Objetivo: simplificar ticket/comprobante y reportes de detalle.
-- -------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_detalle_pedido_con_producto AS
SELECT
    dp.pedido_id,
    dp.producto_id,
    pr.nombre               AS producto_nombre,
    pr.categoria_id,
    dp.cantidad,
    dp.precio_unitario,
    (dp.cantidad * dp.precio_unitario) AS subtotal,
    p.fecha                 AS fecha_pedido
FROM detalle_pedido dp
JOIN producto pr ON pr.id = dp.producto_id
JOIN pedido p    ON p.id = dp.pedido_id;

COMMENT ON VIEW v_detalle_pedido_con_producto IS 'Detalle con nombre de producto y subtotal calculado. Spec: spec_vista_detalle_pedido.md';

-- Verificación para pedido_id=1:
-- SELECT * FROM v_detalle_pedido_con_producto WHERE pedido_id=1;
-- vs query manual con JOIN debe coincidir exacto (EXCEPT 0).

-- =============================================================================
-- Parte C — Vista materializada: Facturación por categoría y mes
-- Spec: specs/spec_vista_materializada.md
-- Objetivo: acelerar reporte agregado costoso (3 JOINs + GROUP BY sobre 300k filas)
-- =============================================================================

DROP MATERIALIZED VIEW IF EXISTS mv_facturacion_categoria_mes;

CREATE MATERIALIZED VIEW mv_facturacion_categoria_mes AS
SELECT
    c.nombre                                AS categoria,
    EXTRACT(YEAR FROM p.fecha)::int         AS anio,
    EXTRACT(MONTH FROM p.fecha)::int        AS mes,
    COUNT(DISTINCT p.id)                    AS total_pedidos,
    SUM(dp.cantidad * dp.precio_unitario)   AS facturacion_total
FROM categoria c
JOIN producto pr ON pr.categoria_id = c.id AND pr.activo = TRUE AND pr.eliminado = FALSE
JOIN detalle_pedido dp ON dp.producto_id = pr.id
JOIN pedido p ON p.id = dp.pedido_id
WHERE c.activo = TRUE AND c.eliminado = FALSE
GROUP BY c.nombre, EXTRACT(YEAR FROM p.fecha), EXTRACT(MONTH FROM p.fecha)
WITH DATA;

COMMENT ON MATERIALIZED VIEW mv_facturacion_categoria_mes IS 'Reporte agregado costoso materializado. Refrescar con REFRESH CONCURRENTLY. Spec: spec_vista_materializada.md';

-- Índice ÚNICO obligatorio para REFRESH CONCURRENTLY (y para búsquedas por PK lógica)
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_facturacion_unique
    ON mv_facturacion_categoria_mes (categoria, anio, mes);

-- Índice adicional para filtros por año/mes (dashboard)
CREATE INDEX IF NOT EXISTS idx_mv_facturacion_anio_mes
    ON mv_facturacion_categoria_mes (anio, mes);

-- Uso:
-- SELECT * FROM mv_facturacion_categoria_mes ORDER BY anio DESC, mes DESC, facturacion_total DESC;
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_facturacion_categoria_mes;
-- Ver informe_mediciones.md para tiempos: ~1200ms original vs ~12ms sobre MV (~100x).

-- Verificación de equivalencia (debe dar 0):
-- (SELECT categoria, anio, mes, total_pedidos, facturacion_total FROM mv_facturacion_categoria_mes)
-- EXCEPT
-- (SELECT c.nombre, EXTRACT(YEAR FROM p.fecha)::int, EXTRACT(MONTH FROM p.fecha)::int, COUNT(DISTINCT p.id), SUM(dp.cantidad*dp.precio_unitario)
--  FROM categoria c JOIN producto pr ON pr.categoria_id=c.id AND pr.activo=true AND pr.eliminado=false
--  JOIN detalle_pedido dp ON dp.producto_id=pr.id JOIN pedido p ON p.id=dp.pedido_id WHERE c.activo=true AND c.eliminado=false
--  GROUP BY c.nombre, EXTRACT(YEAR FROM p.fecha), EXTRACT(MONTH FROM p.fecha));
