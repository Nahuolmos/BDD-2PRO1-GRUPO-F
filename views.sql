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
