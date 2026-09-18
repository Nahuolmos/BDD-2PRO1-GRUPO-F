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
  AND c.activo = TRUE;

COMMENT ON VIEW v_productos_vigentes IS 'Catálogo público: solo productos y categorías vigentes. Spec: spec_vista_productos_vigentes.md';

-- Verificación de equivalencia (debe dar 0 filas si es correcta):
-- (SELECT producto_id FROM v_productos_vigentes)
-- EXCEPT
-- (SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE);
-- Y viceversa con EXCEPT inverso.

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
