# spec: indice_pedido_fecha

Objetivo: acelerar reportes por rango de fechas sobre pedido (consulta mas frecuente: pedidos del ultimo mes/trimestre y facturacion por mes).

Consulta afectada:
```sql
SELECT id, fecha, forma_pago, cliente_id
FROM pedido
WHERE fecha BETWEEN :desde AND :hasta
  AND fecha <= NOW();
-- tambien usada en:
-- JOIN pedido p ON p.id = dp.pedido_id WHERE p.fecha BETWEEN :desde AND :hasta
-- Frecuencia: diaria, reporte operativo y dashboard mensual
```

Columnas candidatas: fecha (alta selectividad, usado en BETWEEN y ORDER BY), id (PK ya indexado pero no ayuda a rango).

Tipo propuesto: B-tree sobre pedido(fecha) -- orden ASC por defecto, soporta BETWEEN y <, >.

Criterio de aceptacion: el plan pasa de Seq Scan sobre 200.000 filas a Index Scan / Bitmap Heap Scan usando el indice, y el tiempo baja al menos 50%. EXPLAIN ANALYZE debe mostrar "Index Scan using idx_pedido_fecha" o "Bitmap Index Scan".

Notas: tabla pedido = 200k filas (considerable). No crear indice parcial porque el filtro es por rango, no igualdad. No redundante con idx_pedido_id_fecha(id,fecha) existente porque ese tiene id primero y no sirve para buscar por fecha sola.
