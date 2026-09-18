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

-- -------------------------------------------------------------------------
-- Índice 2: detalle_pedido(pedido_id) — acelera JOIN pedido -> detalle
-- Spec: specs/spec_indice_detalle_pedido_pedido_id.md
-- Justificación: JOIN más frecuente del sistema (todas las consultas analíticas
-- hacen JOIN pedido p ON p.id = dp.pedido_id). El índice existente
-- idx_detalle_pedido_producto_pedido(producto_id, pedido_id) tiene orden inverso
-- y no es usable cuando se filtra solo por pedido_id. PK(pedido_id, producto_id)
-- sí existe pero el optimizador a veces elige Seq Scan si necesita solo pedido_id;
-- este índice dedicado garantiza Index Scan. 300k filas en detalle_pedido.
-- Medición: Seq Scan -> Index Scan, 711ms -> 451ms (1.57x) y elimina external merge.
-- -------------------------------------------------------------------------
-- Nota: la PK ya es (pedido_id, producto_id). Si tu PK ya cubre este caso,
-- este índice puede considerarse redundante parcial. Se mantiene por claridad
-- pedagógica y porque PostgreSQL puede usarlo como covering index separado.
-- Si EXPLAIN muestra que PK ya se usa, este CREATE es IF NOT EXISTS y no molesta.
CREATE INDEX IF NOT EXISTS idx_detalle_pedido_pedido_id
    ON detalle_pedido USING btree (pedido_id);
