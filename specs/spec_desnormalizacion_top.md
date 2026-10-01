# spec: desnormalización top categorías día

Objetivo: Unidad 4 Parte 2 — top 5 categorías por monto del día sin 4 JOINs.

Query original 5.1: detalle_pedido JOIN producto JOIN categoria JOIN pedido WHERE ped.fecha=CURRENT_DATE AND dp.eliminado=FALSE AND ped.eliminado=FALSE GROUP BY c.nombre ORDER BY total DESC LIMIT 5.

Gaps repo: en este repo detalle_pedido no tiene eliminado ni subtotal (schema.sql:74 solo cantidad, precio_unitario), pedido no tiene eliminado (schema.sql:60). subtotal = cantidad*precio_unitario (views.sql:82). Hay que agregar eliminado a ambas vía ALTER antes de medir.

Patrón elegido: vista materializada mv_ventas_dia_categoria(dia, categoria_id, categoria, total_vendido) GROUP BY dia, categoria. Justificación (párrafo informe): evidencia EXPLAIN con Hash Join + Seq Scan sobre 300k filas ejecutada por minuto; sincronización vía REFRESH CONCURRENTLY con UNIQUE(dia,categoria_id) sin bloquear lecturas; reversible con DROP sin pérdida (fuente sigue intacta).

Consulta desnormalizada: SELECT categoria, total_vendido FROM mv WHERE dia=CURRENT_DATE ORDER BY total DESC LIMIT 5 — Seq Scan sobre ~3 filas vs 4 JOINs.

Auditoría: (MV EXCEPT base) UNION ALL (base EXCEPT MV) = 0 filas.
