# spec: vista_detalle_pedido_con_producto

Objetivo: simplificar consulta de detalle de un pedido con el nombre del producto (evitar JOIN repetido en aplicación y reportes de impresión de ticket).

Definición requerida:
- Tablas base: detalle_pedido dp JOIN producto pr ON pr.id = dp.producto_id JOIN pedido p ON p.id = dp.pedido_id
- Columnas a exponer: dp.pedido_id, dp.producto_id, pr.nombre AS producto_nombre, pr.categoria_id, dp.cantidad, dp.precio_unitario, (dp.cantidad * dp.precio_unitario) AS subtotal, p.fecha AS fecha_pedido
- Filtro: ninguno en la vista (parametrizable con WHERE pedido_id = :id al consultarla)
- Cálculo: subtotal derivado, reutilizable

Criterio de aceptación:
- Para un pedido dado (ej. id=1), SELECT * FROM v_detalle_pedido_con_producto WHERE pedido_id=1 debe retornar exactamente lo mismo que:
  ```sql
  SELECT dp.pedido_id, dp.producto_id, pr.nombre, pr.categoria_id, dp.cantidad, dp.precio_unitario,
         dp.cantidad * dp.precio_unitario AS subtotal, p.fecha
  FROM detalle_pedido dp
  JOIN producto pr ON pr.id=dp.producto_id
  JOIN pedido p ON p.id=dp.pedido_id
  WHERE dp.pedido_id=1;
  ```
- Verificación con EXCEPT = 0 filas.

Uso esperado: impresión de comprobante, validación de carrito, reporte de auditoría de precios históricos (precio_unitario vs precio_actual).
