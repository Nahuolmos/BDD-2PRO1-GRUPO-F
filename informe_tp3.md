# Trabajo Práctico 3: Optimización Asistida por IA - Food Store

* **Alumno:** Facundo Cabrera
* **Asignatura:** Base de Datos II (UTN)
* **Proyecto:** Food Store

---

## Parte 1: Poblado Masivo de Datos
Se ejecutó un script de inserción masiva sobre una copia de trabajo de la base de datos aplicando el protocolo de seguridad de la cátedra. El volumen final generado consistió en:
* **20.000** Clientes.
* **50.000** Productos distribuidos en las categorías existentes.
* **200.000** Pedidos con sus respectivos detalles.
* Ejecución posterior de `ANALYZE` sobre las tablas afectadas para actualizar las estadísticas del optimizador de PostgreSQL.

---

## Parte 2: Laboratorio de Consultas Lentas, EXPLAIN y Optimización Medida

Tabla comparativa de rendimiento antes y después de la intervención:

| Consulta | Plan antes (nodo, cost, tiempo real) | Cambio aplicado | Plan después (nodo, cost, tiempo real) | Mejora / Decisión |
| :--- | :--- | :--- | :--- | :--- |
| **1. Productos por categoría y precio** | `Sort` / `Bitmap Heap Scan`<br>Cost: 2228.83<br>Tiempo: 13.318 ms | Propuesta de índice compuesto con orden (`categoria_id`, `activo`, `precio_actual DESC`). | `Sort` / `Bitmap Heap Scan`<br>Cost: 2223.39<br>Tiempo: 13.253 ms | **Descartado / Sin cambios:** El motor evaluó que el costo de usar un índice alternativo era mayor al de ordenar en memoria RAM con *quicksort*. Se mantuvo el índice preexistente por criterio técnico. |
| **3. Agregación y recaudación de detalles** | `HashAggregate` / `Seq Scan`<br>Cost: 22438.82<br>Tiempo: 233.711 ms (Disco: 6992kB) | Creación de índice con columnas incluidas (`producto_id` + `INCLUDE (cantidad, precio_unitario)`). | `GroupAggregate` / `Index Only Scan`<br>Cost: 10226.53<br>Tiempo: 144.943 ms (Disco: 0kB) | **Aceptado:** Se eliminó por completo el recorrido secuencial masivo y el cuello de botella de lectura en disco, logrando una mejora notable en eficiencia y uso de recursos. |

---

## Parte 3: Lectura Crítica de Planes Interpretados por IA

Ejercicio de contraste crítico sobre la explicación generada por un asistente de IA frente al plan real de la Consulta 3 optimizada:

| Afirmación de la IA | ¿Correcta? | Corrección / evidencia del plan real |
| :--- | :---: | :--- |
| "El tiempo de ejecución es de 2.163 milisegundos." | **No** | Confunde el *Planning Time* (2.163 ms) con el *Execution Time* real de la consulta, que fue de 144.943 ms. |
| "La mejora se debe al filtro de categoría que evita procesar filas." | **No** | La tabla `detalle_pedido` no maneja categorías; la optimización real provino de reemplazar el `Seq Scan` por un `Index Only Scan` utilizando el índice `idx_detalle_agregacion`. |

---

## Parte 4: Consultas Resumen, Subconsultas y Verificación Formal

### 1. Consulta de Resumen / Agregación
* **Especificación:** Obtener para cada categoría vigente (`activo = TRUE`) el nombre de la categoría y la cantidad total de productos asociados, incluyendo aquellas categorías sin productos (mostrando 0). Ordenar de mayor a menor cantidad.
* **Implementación SQL:**
  ```sql
  SELECT c.nombre AS categoria, COUNT(p.id) AS total_productos
  FROM categoria c
  LEFT JOIN producto p ON c.id = p.categoria_id AND p.activo = TRUE
  WHERE c.activo = TRUE
  GROUP BY c.id, c.nombre
  ORDER BY total_productos DESC;

Herramienta,Para qué se usó,Prompt / Spec (resumen),Se aceptó / se descartó por qué
Kiro / Asistente IA,Generación del script de población masiva con generate_series.,"""Generá un script SQL para PostgreSQL que inserte 50.000 filas en producto...""","Aceptado: Se leyó línea por línea, se validó el respeto a restricciones y se ejecutó dentro de una transacción."
Kiro / Asistente IA,Propuesta de índices para mitigar cuellos de botella en consultas agregadas.,"""Analiza el plan de ejecución y sugiere índices para optimizar el HashAggregate...""","Aceptado parcialmente: El índice de agregación mejoró notablemente a un Index Only Scan, mientras que el índice de ordenamiento de la consulta 1 fue descartado al comprobarse que el motor ya operaba de manera óptima en memoria."
Kiro / Asistente IA,Asistencia estructural y sintáctica en consultas SQL complejas (subconsultas correlacionadas y funciones de agregación con LEFT JOIN).,"""Ayúdame a estructurar la consulta con subconsulta correlacionada y la verificación lógica con EXCEPT...""","Aceptado: Se verificó la lógica de negocio y se validó la equivalencia de resultados mediante el operador EXCEPT, retornando cero filas."
Kiro / Asistente IA,Redacción y organización formal del informe técnico en Markdown (informe_tp3.md).,"""Estructura el informe técnico cubriendo poblado, benchmarking con EXPLAIN, análisis crítico y consultas resumen...""",Aceptado: Se revisó y adaptó todo el contenido para que refleje fielmente los resultados obtenidos de la ejecución local en el motor de base de datos.