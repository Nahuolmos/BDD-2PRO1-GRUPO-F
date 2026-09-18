# spec: vista_productos_vigentes_con_categoria

Objetivo: simplificar y estandarizar acceso al catálogo público (productos vigentes con su categoría). Evitar que cada consulta repita el JOIN y el filtro activo=TRUE.

Definición requerida:
- Tablas base: producto pr JOIN categoria c ON c.id = pr.categoria_id
- Columnas a exponer: pr.id AS producto_id, pr.nombre AS producto, pr.precio_actual, pr.stock, c.id AS categoria_id, c.nombre AS categoria
- Filtro de vigencia: pr.activo = TRUE AND c.activo = TRUE (solo productos y categorías vigentes)
- Orden sugerido: por categoria, luego producto (no obligatorio en vista, pero definido en consultas que la usan)
- Seguridad: no expone columnas sensibles (no hay password en este modelo; expone solo datos públicos)

Criterio de aceptación:
- SELECT * FROM v_productos_vigentes debe retornar exactamente las mismas filas que la consulta manual:
  ```sql
  SELECT pr.id, pr.nombre, pr.precio_actual, pr.stock, c.id, c.nombre
  FROM producto pr JOIN categoria c ON c.id = pr.categoria_id
  WHERE pr.activo = TRUE AND c.activo = TRUE;
  ```
- Verificación con EXCEPT debe dar 0 filas de diferencia.
- La vista es simple (no materializada), siempre refleja datos en tiempo real.

Uso esperado: catálogo web, reporte de productos disponibles, base para vista materializada de facturación.
