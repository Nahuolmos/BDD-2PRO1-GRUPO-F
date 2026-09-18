# spec: indice_producto_filtro_activo

Objetivo: acelerar filtros por vigencia (activo = TRUE) combinados con categoria y precio en catálogo y reporte de productos sobre promedio.

Consulta afectada:
```sql
-- Query 3B y catalogo publico
SELECT pr.id, pr.nombre, pr.precio_actual, c.nombre AS categoria
FROM producto pr
JOIN categoria c ON c.id = pr.categoria_id
WHERE pr.activo = TRUE
  AND c.activo = TRUE
  AND pr.precio_actual > :umbral
ORDER BY pr.precio_actual DESC;

-- Tambien:
SELECT * FROM producto WHERE activo = TRUE AND categoria_id = :cat;
-- Frecuencia: muy alta (catálogo público), cada request
```

Columnas candidatas: activo (baja cardinalidad, solo 2 valores), categoria_id (media), precio_actual (alta, usado en ORDER BY y >). 

Tipo propuesto: indice parcial B-tree sobre producto(categoria_id, precio_actual) WHERE activo = TRUE. Alternativa compuesta (activo, categoria_id). La opcion parcial evita indexar filas inactivas (~baja proporcion) y reduce tamaño y mantenimiento. Si la proporcion de inactivos es <5%, el parcial es mas eficiente.

Criterio de aceptacion: EXPLAIN ANALYZE pasa de Seq Scan sobre 50.000 productos a Bitmap Index Scan sobre el indice parcial. Tiempo baja. El indice debe ser usado cuando la query incluye WHERE activo = TRUE.

Notas: idx_producto_categoria_activo(categoria_id, activo) existente tiene orden categoria->activo, no es parcial. El nuevo indice parcial es complementario y mas selectivo para el caso activo=TRUE.
