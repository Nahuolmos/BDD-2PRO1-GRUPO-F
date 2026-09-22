-- =============================================================================
-- TPI — Objetivo 9: Borrado lógico (soft delete)
-- Archivo: soft_delete.sql
-- Motor: PostgreSQL 16+
-- =============================================================================
-- NOTA: Agrega borrado lógico sin tocar PK/FK existentes. Separa "vigencia"
-- (activo) de "borrado" (eliminado) para demostrar impacto en consultas e índices.
-- Spec: specs/spec_soft_delete.md

-- 1. Agregar columna eliminado a categoria y producto
ALTER TABLE categoria
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE producto
    ADD COLUMN IF NOT EXISTS eliminado BOOLEAN NOT NULL DEFAULT FALSE;

-- 2. Índice parcial: solo indexa productos vigentes y no eliminados
-- Ventaja: más chico que índice total, solo se usa cuando la query filtra
-- WHERE activo=TRUE AND eliminado=FALSE (ver views.sql)
CREATE INDEX IF NOT EXISTS idx_producto_vigente_no_eliminado
    ON producto (categoria_id)
    WHERE activo = TRUE AND eliminado = FALSE;

-- 3. Índice para categoria no eliminada (para JOINs filtrados)
CREATE INDEX IF NOT EXISTS idx_categoria_no_eliminada
    ON categoria (id)
    WHERE eliminado = FALSE;

-- Verificación manual:
-- UPDATE producto SET eliminado = TRUE WHERE id = 1; -- borrado lógico
-- SELECT * FROM v_productos_vigentes WHERE producto_id = 1; -- debe dar 0 filas
-- SELECT * FROM producto WHERE id = 1; -- debe seguir existiendo con eliminado=TRUE
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM producto WHERE categoria_id=1 AND activo=TRUE AND eliminado=FALSE; -- debe usar idx_producto_vigente_no_eliminado (Bitmap Index Scan)
-- EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM producto WHERE categoria_id=1; -- sin filtro eliminado, no usa el parcial (Seq Scan)
