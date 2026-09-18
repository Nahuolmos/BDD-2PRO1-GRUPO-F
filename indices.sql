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
-- Alternativa compuesta recomendada si se quiere covering:
-- CREATE INDEX IF NOT EXISTS idx_detalle_pedido_pedido_producto
--     ON detalle_pedido (pedido_id, producto_id);

-- -------------------------------------------------------------------------
-- Índice 3: PARCIAL sobre producto — catálogo de vigentes
-- Spec: specs/spec_indice_producto_activo_precio.md
-- Justificación: catálogo público filtra WHERE activo=TRUE (95% filas) + categoria_id
-- y ordena por precio. Un índice completo sobre (activo) es inútil por baja
-- cardinalidad (2 valores). Un índice PARCIAL WHERE activo=TRUE con
-- (categoria_id, precio_actual) reduce tamaño, solo indexa vigentes, y da
-- Bitmap Index Scan cuando la query incluye activo=TRUE.
-- Tabla producto = 50.000 filas. Frecuencia: cada request del catálogo.
-- Medición: Seq Scan 89ms -> Bitmap Heap Scan 11ms (~8x) en filtro categoría=1.
-- -------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_producto_vigente_categoria_precio
    ON producto USING btree (categoria_id, precio_actual)
    WHERE activo = TRUE;
-- Mantenimiento: solo se actualiza cuando producto es vigente; menor costo.

-- -------------------------------------------------------------------------
-- Índice DESCARTADO por sobreindexación (documentado, NO se crea)
-- Spec: specs/spec_indice_descartado.md
-- Propuesta de IA: CREATE INDEX idx_pedido_forma_pago ON pedido(forma_pago);
-- Motivo descarte: forma_pago es ENUM de 3 valores (33% cada uno) -> baja
-- selectividad, el optimizador sigue prefiriendo Seq Scan. EXPLAIN no muestra
-- cambio de plan. Costo extra en escritura (+18% en 500 INSERT) sin beneficio.
-- Tampoco se crea idx_producto_activo(activo) por igual motivo (boolean).
-- Decisión: RECHAZADO explícitamente. Ver informe_mediciones.md §6.
-- -------------------------------------------------------------------------
-- -- DESCARTADO -- NO EJECUTAR:
-- CREATE INDEX idx_pedido_forma_pago ON pedido(forma_pago);
-- CREATE INDEX idx_producto_activo ON producto(activo);
-- CREATE INDEX idx_pedido_cliente_fecha ON pedido(cliente_id, fecha); -- redundante

-- -------------------------------------------------------------------------
-- Verificación post-creación (ejecutar manualmente):
-- EXPLAIN ANALYZE SELECT * FROM pedido WHERE fecha BETWEEN NOW()-'30 days'::interval AND NOW();
-- EXPLAIN ANALYZE SELECT * FROM detalle_pedido WHERE pedido_id = 123;
-- EXPLAIN ANALYZE SELECT * FROM producto WHERE activo=TRUE AND categoria_id=1 ORDER BY precio_actual;
-- -------------------------------------------------------------------------
