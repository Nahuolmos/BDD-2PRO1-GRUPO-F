# spec: vista_materializada_facturacion_categoria_mes

Objetivo: materializar reporte agregado costoso "facturación por categoría y mes" (Consulta 1 de queries.sql) que hoy hace 3 JOINs + GROUP BY sobre ~300k filas + 50k productos + 200k pedidos. Sin materializar tarda >1s y hace Parallel Hash Join.

Definición requerida:
- Query base: 
  ```sql
  SELECT c.nombre AS categoria,
         EXTRACT(YEAR FROM p.fecha)::int AS anio,
         EXTRACT(MONTH FROM p.fecha)::int AS mes,
         COUNT(DISTINCT p.id) AS total_pedidos,
         SUM(dp.cantidad * dp.precio_unitario) AS facturacion_total
  FROM categoria c
  JOIN producto pr ON pr.categoria_id = c.id AND pr.activo = true
  JOIN detalle_pedido dp ON dp.producto_id = pr.id
  JOIN pedido p ON p.id = dp.pedido_id
  WHERE c.activo = true
  GROUP BY c.nombre, EXTRACT(YEAR FROM p.fecha), EXTRACT(MONTH FROM p.fecha)
  ```
- Materializar con: CREATE MATERIALIZED VIEW mv_facturacion_categoria_mes WITH DATA
- Índice único para REFRESH CONCURRENTLY: UNIQUE(categoria, anio, mes) -- permite refresh sin bloquear lecturas
- Un segundo índice opcional por anio/mes para filtros de dashboard

Criterio de aceptación:
- SELECT * FROM mv_facturacion_categoria_mes debe dar mismo resultado que la query original (verificación EXCEPT 0).
- Tiempo de SELECT sobre MV debe ser <10% del tiempo de la query original (ej. 1200ms -> <50ms) porque es Seq Scan sobre ~36 filas (3 categorías * 12 meses) ya agregadas.
- REFRESH MATERIALIZED VIEW CONCURRENTLY debe funcionar (requiere índice único).
- Documentar frecuencia de refresh: dado que es reporte contable mensual, se propone REFRESH cada 1 hora en horario comercial o diario a las 02:00 AM, y explicar implicancia (datos stale).

Implicancias: los usuarios ven datos con retraso hasta el próximo REFRESH; no apta para facturación en tiempo real. Ventaja: no bloquea lecturas con CONCURRENTLY.

Uso esperado: dashboard gerencial, cierre mensual, evita recalcular agregados en cada request.
