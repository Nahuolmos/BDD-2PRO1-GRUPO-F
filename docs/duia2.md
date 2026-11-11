# Declaración de Uso de IA (DUIA) — Unidad 3, Semana 5
## Food Store: Índices, vistas y vistas materializadas

**Proyecto:** Food Store (Base de Datos II - UTN)  
**Herramientas:** Kiro (especificación), OpenCode (agente de codificación en terminal) — Flujo obligatorio §5  
**Repositorio:** `BDD-2PRO1-GRUPO-F-main`  
**Fecha:** 2026-09-17

> Regla de cátedra: la IA escribe el SQL, la decisión nunca se delega. Cada propuesta fue leída línea por línea y aceptada/rechazada con criterio técnico.

---

## Bitácora por pieza (spec -> generación -> decisión)

### 1. Índice idx_pedido_fecha
- **Herramienta / propósito:** Kiro para especificar, OpenCode para generar `CREATE INDEX`.
- **Spec entregado:** `specs/spec_indice_pedido_fecha.md` — objetivo "acelerar reporte pedidos confirmados de un mes", consulta `WHERE fecha BETWEEN :desde AND :hasta`, columnas candidatas `fecha (alta selectividad)`, criterio "pasa de Seq Scan a Index/Bitmap Scan y baja >50%".
- **Prompt a IA:** "A partir de spec_indice_pedido_fecha.md, propone índice adecuado (tipo, columnas, orden, condición parcial si aplica) para PostgreSQL 16. Justifica tipo B-tree vs otro."
- **Propuesta IA:** `CREATE INDEX idx_pedido_fecha ON pedido(fecha ASC)` B-tree. Explicó que no debe ser parcial y que `idx_pedido_id_fecha(id,fecha)` no sirve por leftmost prefix.
- **Decisión:** **Aceptado sin cambios.** Verificado con `EXPLAIN ANALYZE`: Seq Scan 138ms -> Bitmap Heap Scan 14ms (9.8x). Incluido en `indices.sql:14`.

### 2. Índice idx_detalle_pedido_pedido_id
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_indice_detalle_pedido_pedido_id.md` — JOIN `pedido.id = detalle_pedido.pedido_id`, frecuencia diaria, candidato `pedido_id` alta cardinalidad.
- **Prompt:** "Analiza JOIN de queries.sql Consulta 2 y propone índice para detalle_pedido. Considera índice existente idx_detalle_pedido_producto_pedido(producto_id, pedido_id) y PK."
- **Propuesta IA:** `CREATE INDEX idx_detalle_pedido_pedido_id ON detalle_pedido(pedido_id)` y alternativa compuesta `(pedido_id, producto_id)`. Advirtió redundancia parcial con PK.
- **Decisión:** **Aceptado con matiz.** Se crea como `IF NOT EXISTS` y se documenta redundancia con PK. Medición 711ms -> 451ms (1.57x). Ver `indices.sql:24`.

### 3. Índice parcial idx_producto_vigente_categoria_precio
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_indice_producto_activo_precio.md` — filtro `activo=TRUE` + `categoria_id` + `ORDER BY precio_actual`, baja cardinalidad de `activo`.
- **Prompt:** "Catálogo filtra activo=TRUE (95% filas) y categoria_id. ¿Índice total sobre activo o parcial? Propone columnas y WHERE."
- **Propuesta IA:** `CREATE INDEX idx_producto_vigente_categoria_precio ON producto(categoria_id, precio_actual) WHERE activo=TRUE` — parcial B-tree. Explicó que índice sobre boolean solo es inútil y que el existente `idx_producto_categoria_activo` no es parcial.
- **Decisión:** **Aceptado.** 89ms -> 11ms (8x). Tamaño reducido. `indices.sql:35`.

### 4. Índice descartado por sobreindexación (requisito §4.1.6)
- **Herramienta:** OpenCode (propuesta inicial)
- **Spec:** `specs/spec_indice_descartado.md`
- **Prompt:** "¿Conviene indexar forma_pago y activo? Revisa cardinalidad."
- **Propuesta IA inicial:** `CREATE INDEX idx_pedido_forma_pago ON pedido(forma_pago)` y `idx_producto_activo ON producto(activo)` y `idx_pedido_cliente_fecha(cliente_id, fecha)`.
- **Propuesta revisada por humano:** Rechazada. Verificación `EXPLAIN SELECT * FROM pedido WHERE forma_pago='EFECTIVO'` sigue en `Seq Scan` (forma_pago 33% selectividad, activo 95% TRUE). Costo escritura +18% en 500 INSERT sin beneficio. `cliente+fecha` redundante con índices existentes.
- **Decisión:** **Descartado explícitamente.** No se incluye en `indices.sql` (comentado en `indices.sql:42-47`). Justificación en `informe_mediciones.md §6` y `spec_indice_descartado.md`.

### 5. Vista v_productos_vigentes
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_vista_productos_vigentes.md` — columnas `producto_id, producto, precio_actual, stock, categoria_id, categoria`, filtro `pr.activo=TRUE AND c.activo=TRUE`.
- **Prompt:** "Genera vista v_productos_vigentes a partir de spec, con COMMENT y verificación EXCEPT."
- **Propuesta IA:** `CREATE OR REPLACE VIEW v_productos_vigentes AS SELECT ... FROM producto JOIN categoria ... WHERE activo=TRUE`. Correcta.
- **Decisión:** **Aceptado.** Verificación `EXCEPT` 0 filas (`informe_mediciones.md` Parte B). Incluido en `views.sql:10`.

### 6. Vista v_pedidos_con_cliente (seguridad)
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_vista_pedidos_con_cliente.md` — debe ocultar columna sensible (`email` como equivalente a `contrasena` del PDF, ya que el esquema usa `cliente` en vez de `usuario`).
- **Prompt:** "Vista pedidos con cliente sin exponer email, para GRANT SELECT sin acceso a tabla base. Aplica criterio seguridad teoría."
- **Propuesta IA:** Vista con `JOIN pedido-cliente` sin `cl.email`, con comentario y ejemplo `GRANT`. Propuso también `REVOKE ON cliente`.
- **Decisión:** **Aceptado.** Se adapta modelo: `cliente` no tiene `contrasena`, se oculta `email` (PII) cumpliendo mismo principio. Verificación: `SELECT email FROM v_pedidos_con_cliente` falla, `EXCEPT` 0 filas. `views.sql:22`.

### 7. Vista v_detalle_pedido_con_producto
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_vista_detalle_pedido.md` — columnas con `subtotal = cantidad*precio_unitario`.
- **Prompt:** "Genera vista detalle con nombre producto y subtotal calculado."
- **Propuesta IA:** Correcta, con 3 JOINs y cálculo.
- **Decisión:** **Aceptado.** `views.sql:43`, verificado con `pedido_id=1`.

### 8. Vista materializada mv_facturacion_categoria_mes
- **Herramienta:** Kiro + OpenCode
- **Spec:** `specs/spec_vista_materializada.md` — materializar Consulta 1 facturación por categoría y mes, `WITH DATA`, índice único para `REFRESH CONCURRENTLY`.
- **Prompt:** "Crea materialized view a partir de Consulta 1 de queries.sql con WITH DATA y UNIQUE(categoria, anio, mes). Documenta frecuencia refresh."
- **Propuesta IA:** `CREATE MATERIALIZED VIEW mv_facturacion_categoria_mes AS SELECT categoria, anio, mes, COUNT DISTINCT, SUM ... GROUP BY ... WITH DATA; CREATE UNIQUE INDEX idx_mv_facturacion_unique ON mv(categoria,anio,mes);` + índice secundario `(anio,mes)`.
- **Decisión:** **Aceptado.** Medición 1240ms -> 12ms (~100x). Refresh diario 02:00 CONCURRENTLY documentado. `views.sql:56`, `informe_mediciones.md` Parte C.

---

## Resumen de prompts/specs conservados
Todos los specs Kiro están en `specs/` tal cual se entregaron a OpenCode (ver carpeta). Ningún script se ejecutó sin lectura línea por línea; todos se probaron en transacción reversible (`BEGIN; ... ROLLBACK;`) y con `EXPLAIN ANALYZE` antes de `COMMIT`, siguiendo protocolo de seguridad `protocolo_seguridad.md`.

## Verificación de equivalencia (exigida §4.2.3)
Documentada en `informe_mediciones.md` Parte B y en comentarios de `views.sql`: cada vista se contrastó con su query manual vía `EXCEPT` y dio 0 filas. Caso de seguridad (vista sin email) verificado con error esperado al seleccionar columna oculta.

## Índice descartado y costo escritura
Ver `informe_mediciones.md §6` y `specs/spec_indice_descartado.md` — medición 500 INSERT: 342ms (sin índices) vs 404ms (con índices) = +18% overhead, justifica descartar índices de baja selectividad.
