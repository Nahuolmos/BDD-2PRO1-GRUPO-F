# spec: indice_detalle_pedido_pedido_id

Objetivo: acelerar JOIN entre pedido y detalle_pedido en todas las consultas analiticas (facturacion, ranking clientes, gasto total). Hoy el JOIN hace Hash Join con Seq Scan sobre detalle_pedido (~300k filas).

Consulta afectada:
```sql
-- Consulta 2 y 3A de queries.sql
SELECT cl.id, SUM(dp.cantidad * dp.precio_unitario)
FROM cliente cl
JOIN pedido p ON p.cliente_id = cl.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id
GROUP BY cl.id;
-- Frecuencia: diaria / reporting
```

Columnas candidatas: detalle_pedido.pedido_id (FK, alta cardinalidad, usado siempre en JOIN), detalle_pedido.producto_id (usado en JOIN con producto).

Tipo propuesto: B-tree compuesto sobre detalle_pedido(pedido_id, producto_id) o simple sobre (pedido_id) si el compuesto existente no es selectivo. Evaluar orden: pedido_id primero porque es el JOIN mas frecuente (pedido -> detalle). El indice existente idx_detalle_pedido_producto_pedido(producto_id, pedido_id) tiene orden inverso y no ayuda cuando se filtra solo por pedido_id.

Criterio de aceptacion: EXPLAIN ANALYZE muestra cambio de Seq Scan a Index Scan / Bitmap Heap Scan sobre detalle_pedido, o al menos "Index Only Scan" si cubre. Tiempo medido debe bajar y evitar sort en disco.

Riesgo sobreindexacion: verificar redundancia con PK(pedido_id, producto_id) que ya es indice implicito, pero PK es (pedido_id, producto_id) - si el existente es (producto_id, pedido_id) es redundante parcial pero con orden diferente, justificar.
