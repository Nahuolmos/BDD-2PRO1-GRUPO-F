-- =============================================================================
-- TRABAJO PRÁCTICO — Unidad 3, Semana 5 — Parte A: Plan de indexado
-- Archivo: indices.sql
-- Motor: PostgreSQL 16+
-- =============================================================================
-- NOTA: No modifica tablas base. Solo agrega índices. Ejecutar después de
-- haber registrado EXPLAIN ANALYZE "antes" (ver informe_mediciones.md).

-- -------------------------------------------------------------------------
-- Índice 1: pedido(fecha) — acelera reportes por rango temporal
-- Spec: specs/spec_indice_pedido_fecha.md
-- Justificación: tabla pedido = 200.000 filas. Filtro fecha BETWEEN es alta
-- selectividad y muy frecuente (reporte mensual, dashboard). B-tree ordenado
-- permite Index Scan / Bitmap Heap Scan en lugar de Seq Scan.
-- No es redundante con idx_pedido_id_fecha(id,fecha) porque ese tiene id primero
-- y no sirve para búsqueda solo por fecha (leftmost prefix).
-- Medición: Seq Scan -> Bitmap Heap Scan, 138ms -> 14ms (~9.8x) en rango de 30 días.
-- -------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_pedido_fecha
    ON pedido USING btree (fecha ASC);
-- Para ANALYZE después de crear:
-- ANALYZE pedido;
