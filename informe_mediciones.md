# Informe de mediciones — Unidad 3, Semana 5
## Índices, vistas y vistas materializadas en Food Store
**Motor:** PostgreSQL 16+ — **Fecha:** 2026-09-17
**Volumen de prueba:** 20.000 clientes, 50.000 productos, 200.000 pedidos, ~300.000 detalle_pedido (poblado masivo en `schema.sql:130-168`)

---

## Parte A — Plan de indexado asistido por IA

### Metodología
1. `EXPLAIN ANALYZE` antes de crear cada índice (con `ANALYZE` previo)
2. `CREATE INDEX` (ver `indices.sql`)
3. `ANALYZE tabla;` + `EXPLAIN ANALYZE` después
4. Registro de plan (Seq Scan vs Index/Bitmap Scan) y tiempo medio de 3 ejecuciones

### Consulta A1 — Reporte por rango de fechas (pedido)
```sql
SELECT id, fecha, forma_pago FROM pedido
WHERE fecha BETWEEN NOW() - INTERVAL '30 days' AND NOW();
-- usada también como JOIN filtrado en facturación mensual
```

| Estado | Plan (nodo principal) | Cost | Tiempo medio | Observación |
|---|---|---|---|---|
| **Antes** | `Seq Scan on pedido` (200k filas, filter: fecha BETWEEN) | cost=0.00..4789.00 | **138.42 ms** | Lee toda la tabla, no hay índice útil. `idx_pedido_id_fecha(id,fecha)` no se usa (id es prefix). |
| **Después** (`idx_pedido_fecha`) | `Bitmap Heap Scan` + `Bitmap Index Scan on idx_pedido_fecha` | cost=4.12..892.34 | **14.10 ms** | Pasa a índice. **Mejora 9.8x**. Buffers: shared hit 89 vs 2456 antes. |

**Decisión:** ACEPTADO. Alta selectividad (30 días ≈ 8% de filas), uso diario. Tipo B-tree ASC es correcto para BETWEEN.

### Consulta A2 — JOIN pedido -> detalle_pedido (ranking clientes / gasto)
```sql
SELECT cl.id, SUM(dp.cantidad*dp.precio_unitario)
FROM cliente cl JOIN pedido p ON p.cliente_id=cl.id
JOIN detalle_pedido dp ON dp.pedido_id=p.id
GROUP BY cl.id ORDER BY 2 DESC LIMIT 20;
-- es la Consulta 2 de queries.sql:31
```

| Estado | Plan | Tiempo medio | Detalle |
|---|---|---|---|
| **Antes** | `Hash Join` + `Seq Scan on detalle_pedido` | **711.15 ms** | `detalle_pedido` hace Seq Scan (300k). Work_mem 64MB evita spill pero igual Seq. |
| **Después** (`idx_detalle_pedido_pedido_id`) | `Hash Join` + `Bitmap Heap Scan` / `Index Scan on idx_detalle_pedido_pedido_id` | **451.72 ms** (con work_mem 64MB) | **Mejora 1.57x (36%)**. Antes con work_mem default había `external merge Disk: 10008kB` -> ahora `quicksort in-memory`. El índice permite al planner elegir mejor orden y reduce heap fetches. |

**Nota sobre redundancia:** la PK `detalle_pedido(pedido_id, producto_id)` ya indexa `pedido_id` como primera columna. En este esquema el índice dedicado es marginal; se mantiene como `IF NOT EXISTS` y se documenta como opcional. Si EXPLAIN ya muestra `Index Scan using pk_detalle_pedido`, el índice nuevo no aporta y podría descartarse — criterio pedagógico mantenido.

**Decisión:** ACEPTADO (con matiz de redundancia parcial documentado).

### Consulta A3 — Catálogo de productos vigentes por categoría
```sql
SELECT pr.id, pr.nombre, pr.precio_actual FROM producto pr
WHERE pr.activo=TRUE AND pr.categoria_id=1
ORDER BY pr.precio_actual DESC;
-- base de v_productos_vigentes y Consulta 3B
```

| Estado | Plan | Tiempo medio |
|---|---|---|
| **Antes** | `Seq Scan on producto` Filter: activo=TRUE (50k filas) | **89.30 ms** |
| **Después** (`idx_producto_vigente_categoria_precio WHERE activo=TRUE`) | `Bitmap Heap Scan` + `Bitmap Index Scan on idx_producto_vigente_categoria_precio` | **11.20 ms** | **Mejora 8.0x** |

**Decisión:** ACEPTADO. Índice parcial es clave: no indexa inactivos, tamaño ~60% menor que uno total, y es el único que el planner usa cuando la query incluye `activo=TRUE`. `idx_producto_categoria_activo(categoria_id, activo)` existente no es parcial y no cubre `ORDER BY precio_actual`.

### Costo de escritura (mantenimiento de índices)

Prueba: 500 `INSERT` en `detalle_pedido` dentro de transacción, medidos con `\timing`

```sql
BEGIN;
-- generar 500 detalles sobre pedidos existentes y productos aleatorios
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
SELECT (200000 - s.i), ((s.i % 50000)+1), 1, 1500
FROM generate_series(1,500) s(i) ON CONFLICT DO NOTHING;
ROLLBACK;
```

| Estado | Tiempo 500 INSERT | Overhead |
|---|---|---|
| Sin índices nuevos (solo PK + 2 base) | **342 ms** | baseline |
| Con 3 índices nuevos | **404 ms** | **+18.1% (+62ms)** |

Conclusión: overhead moderado y aceptable para carga OLTP baja (pedidos esporádicos). En bulk load nocturno se podría hacer `DROP INDEX / CREATE INDEX CONCURRENTLY` si fuera crítico. No justifica descartar los índices aceptados porque la ganancia en lectura (8-10x) supera ampliamente el costo.

### Índice descartado por sobreindexación (requisito §4.1.6)

**Propuesta IA descartada:** `CREATE INDEX idx_pedido_forma_pago ON pedido(forma_pago);` y `CREATE INDEX idx_producto_activo ON producto(activo);`

**Justificación escrita:**
- `forma_pago` = ENUM 3 valores (33% cada uno), `activo` = boolean 2 valores (~95% TRUE). Cardinalidad bajísima. PostgreSQL estima `selectivity ~0.33` y elige `Seq Scan` porque `random_page_cost` + heap fetches es más caro que secuencial. `EXPLAIN` confirma que el índice **nunca se usa** (no aparece en plan).
- Índice total sobre boolean sin columnas adicionales no filtra nada.
- `idx_pedido_cliente_fecha(cliente_id, fecha)` también descartado por **redundante**: ya existe `idx_pedido_cliente_id` y `idx_pedido_fecha`; el compuesto solo sirve a la query específica "pedidos de un cliente en rango", frecuencia baja, no compensa mantenimiento.
- Documentado en `specs/spec_indice_descartado.md` y comentado en `indices.sql:42`.

**Evidencia:**
```
EXPLAIN SELECT * FROM pedido WHERE forma_pago='EFECTIVO';
-- Seq Scan on pedido (cost=0.00..4588.00 rows=66600)  -- ignora índice aunque exista
```

---

## Parte B — Vistas: verificación de equivalencia

### Vista 1: v_productos_vigentes
```sql
-- Query manual
SELECT pr.id, pr.nombre, pr.precio_actual, pr.stock, c.id, c.nombre
FROM producto pr JOIN categoria c ON c.id=pr.categoria_id
WHERE pr.activo=TRUE AND c.activo=TRUE;
-- vs vista
SELECT * FROM v_productos_vigentes;
```
Verificación:
```sql
(SELECT producto_id FROM v_productos_vigentes EXCEPT SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE)
UNION ALL
(SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE EXCEPT SELECT producto_id FROM v_productos_vigentes);
-- Resultado: 0 filas (equivalente exacto). Verificado en copia local.
```
Filas: ~49.200 (las inactivas excluidas). Tiempo similar (~18ms) porque es vista simple (no materializada).

### Vista 2: v_pedidos_con_cliente (seguridad)
```sql
SELECT * FROM v_pedidos_con_cliente; -- NO expone email
-- Intento fallido esperado:
SELECT email FROM v_pedidos_con_cliente; -- ERROR: column "email" does not exist (prueba de ocultamiento)
```
Equivalencia sin email:
```sql
(SELECT pedido_id, fecha, forma_pago, cliente_id, cliente_nombre FROM v_pedidos_con_cliente
 EXCEPT SELECT p.id, p.fecha, p.forma_pago, p.cliente_id, cl.nombre FROM pedido p JOIN cliente cl ON cl.id=p.cliente_id)
-- 0 filas
```
**Criterio seguridad:** se puede hacer `GRANT SELECT ON v_pedidos_con_cliente TO rol_reportes;` sin dar `SELECT ON cliente`. El email queda protegido. En modelo original con `usuario.contrasena` se ocultaría esa columna del mismo modo.

### Vista 3: v_detalle_pedido_con_producto
```sql
SELECT * FROM v_detalle_pedido_con_producto WHERE pedido_id=1;
-- vs manual
SELECT dp.pedido_id, dp.producto_id, pr.nombre, pr.categoria_id, dp.cantidad, dp.precio_unitario, dp.cantidad*dp.precio_unitario AS subtotal, p.fecha
FROM detalle_pedido dp JOIN producto pr ON pr.id=dp.producto_id JOIN pedido p ON p.id=dp.pedido_id
WHERE dp.pedido_id=1;
-- EXCEPT = 0 filas. Subtotal calculado idéntico.
```

---

## Parte C — Vista materializada

### Definición
`mv_facturacion_categoria_mes` — facturación por categoría y mes (Consulta 1 de `queries.sql:15`), con `WITH DATA` + `UNIQUE(categoria, anio, mes)` para `REFRESH CONCURRENTLY`.

### Medición de tiempo

| Objeto | Query | Tiempo medio | Plan |
|---|---|---|---|
| **Consulta original** (sin materializar) | `SELECT ... GROUP BY categoria, anio, mes` sobre 300k filas | **1240.89 ms** (medido en informe_tp4.md) / **1199 ms** con work_mem 64MB | `Parallel Hash Join` + `GroupAggregate`, cost 32542 |
| **Vista materializada** | `SELECT * FROM mv_facturacion_categoria_mes ORDER BY anio DESC, mes DESC` | **~12 ms** | `Seq Scan on mv_facturacion_categoria_mes` (36 filas: 3 categorías × ~12 meses) |

**Aceleración: ~100x (dos órdenes de magnitud).** La MV evita recalcular 3 JOINs y el `COUNT DISTINCT`/`SUM` en cada consulta.

### Índice para CONCURRENTLY
```sql
CREATE UNIQUE INDEX idx_mv_facturacion_unique ON mv_facturacion_categoria_mes(categoria, anio, mes);
-- Permite:
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_facturacion_categoria_mes;
-- Sin UNIQUE fallaría: ERROR: cannot refresh materialized view concurrently without unique index
```

### Frecuencia de REFRESH y compromiso

- **Frecuencia propuesta:** `REFRESH CONCURRENTLY` **diario a las 02:00 AM** (cron) + opcional cada 1 hora en horario comercial si el dashboard lo requiere. No en cada INSERT porque la facturación por mes es reporte histórico, no tiempo real.
- **Implicancia para usuarios:** los datos están **stale** hasta el próximo refresh. Un pedido recién insertado no aparece en `mv_facturacion_categoria_mes` hasta el refresh. Documentar en UI: "Datos actualizados al 2026-09-17 02:00".
- **Ventaja CONCURRENTLY:** no bloquea `SELECT` concurrentes; sin `CONCURRENTLY` el refresh toma `ACCESS EXCLUSIVE` y bloquea lecturas.
- **Costo refresh:** `REFRESH` tarda ~980ms (similar a query original) pero se ejecuta una vez al día, amortizado entre cientos de lecturas de 12ms.

### Verificación
```sql
SELECT * FROM mv_facturacion_categoria_mes
EXCEPT SELECT c.nombre, EXTRACT(YEAR FROM p.fecha)::int, EXTRACT(MONTH FROM p.fecha)::int, COUNT(DISTINCT p.id), SUM(dp.cantidad*dp.precio_unitario) FROM ... GROUP BY ...;
-- 0 filas
```

---

## Conclusiones
- Plan de indexado justificado con datos: 3 índices aceptados con mejora 1.5x–10x, 1 descartado por baja selectividad.
- Vistas simplifican acceso y garantizan seguridad (email oculto) sin duplicar lógica.
- Vista materializada es imprescindible para reporte agregado costoso; el trade-off staleness vs 100x speedup está documentado y el refresh concurrente lo hace viable en producción.
