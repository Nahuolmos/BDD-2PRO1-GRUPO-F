# Food Store — Unidad 3, Semana 5
## Índices, vistas y vistas materializadas

**Motor:** PostgreSQL 16+ — **Esquema base:** `schema.sql` (semanas 1-4, sin modificar)

### Estructura del repositorio
```
BDD-2PRO1-GRUPO-F-main/
├── schema.sql              # heredado, sin modificar (5 tablas + poblado masivo 200k pedidos)
├── data.sql                # heredado
├── queries.sql             # heredado (consultas analíticas)
├── indices.sql             # NUEVO Parte A — 3 índices aceptados + 1 descartado comentado
├── views.sql               # NUEVO Partes B y C — 3 vistas + 1 vista materializada + índices
├── specs/                  # NUEVO especificaciones Kiro (8 archivos .md)
│   ├── spec_indice_pedido_fecha.md
│   ├── spec_indice_detalle_pedido_pedido_id.md
│   ├── spec_indice_producto_activo_precio.md
│   ├── spec_indice_descartado.md
│   ├── spec_vista_productos_vigentes.md
│   ├── spec_vista_pedidos_con_cliente.md
│   ├── spec_vista_detalle_pedido.md
│   └── spec_vista_materializada.md
├── duia.md                 # Declaración Uso IA + bitácora
├── informe_mediciones.md   # EXPLAIN ANALYZE antes/después, escritura, equivalencia vistas
├── README.md               # este archivo
└── protocolo_seguridad.md  # protocolo de respaldo/transacción reversible
```

### Cómo reproducir las pruebas

#### 1. Restaurar base limpia (protocolo de seguridad)
```bash
# Respaldo previo si ya tenés datos
pg_dump -U postgres -d food_store -F c -f backup_previo.dump

# Recrear esquema + datos base + poblado masivo
psql -U postgres -d food_store -f schema.sql
psql -U postgres -d food_store -f data.sql
# El poblado masivo de 20k/50k/200k ya está al final de schema.sql; si lo separaste, ejecutar también:
# psql -U postgres -d food_store -f queries.sql
ANALYZE; -- actualizar estadísticas antes de medir
```

#### 2. Parte A — Medir índices (antes)
```sql
-- En psql, con \timing on
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM pedido WHERE fecha BETWEEN NOW()-'30 days'::interval AND NOW();
EXPLAIN (ANALYZE, BUFFERS) SELECT cl.id, SUM(dp.cantidad*dp.precio_unitario) FROM cliente cl JOIN pedido p ON p.cliente_id=cl.id JOIN detalle_pedido dp ON dp.pedido_id=p.id GROUP BY cl.id ORDER BY 2 DESC LIMIT 20;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM producto WHERE activo=TRUE AND categoria_id=1 ORDER BY precio_actual;
-- Registrar tiempos en informe_mediciones.md

-- Costo escritura (antes)
BEGIN;
\timing on
INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario)
SELECT (200000 - s.i), ((s.i % 50000)+1), 1, 1500 FROM generate_series(1,500) s(i) ON CONFLICT DO NOTHING;
ROLLBACK;
```

#### 3. Crear índices
```bash
psql -U postgres -d food_store -f indices.sql
psql -U postgres -d food_store -c "ANALYZE pedido; ANALYZE detalle_pedido; ANALYZE producto;"
```

#### 4. Parte A — Medir índices (después)
Repetir los mismos `EXPLAIN ANALYZE` y comparar: debe cambiar de `Seq Scan` a `Bitmap Heap Scan` / `Index Scan` y bajar tiempos (ver `informe_mediciones.md`).

#### 5. Partes B y C — Vistas
```bash
psql -U postgres -d food_store -f views.sql
```

Verificación de equivalencia (debe dar 0 filas):
```sql
-- Vista 1
(SELECT producto_id FROM v_productos_vigentes EXCEPT SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE)
UNION ALL
(SELECT pr.id FROM producto pr JOIN categoria c ON c.id=pr.categoria_id WHERE pr.activo=TRUE AND c.activo=TRUE EXCEPT SELECT producto_id FROM v_productos_vigentes);

-- Vista 2 (seguridad: debe fallar)
SELECT email FROM v_pedidos_con_cliente; -- ERROR esperado: column does not exist

-- Vista 3
SELECT * FROM v_detalle_pedido_con_producto WHERE pedido_id=1;

-- Materializada: comparar tiempos
\timing on
SELECT * FROM mv_facturacion_categoria_mes ORDER BY anio DESC, mes DESC;
-- vs query original
SELECT c.nombre, EXTRACT(YEAR FROM p.fecha)::int, EXTRACT(MONTH FROM p.fecha)::int, COUNT(DISTINCT p.id), SUM(dp.cantidad*dp.precio_unitario)
FROM categoria c JOIN producto pr ON pr.categoria_id=c.id AND pr.activo=true JOIN detalle_pedido dp ON dp.producto_id=pr.id JOIN pedido p ON p.id=dp.pedido_id WHERE c.activo=true GROUP BY 1,2,3 ORDER BY 2 DESC,3 DESC;

-- Refresh concurrente
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_facturacion_categoria_mes;
```
