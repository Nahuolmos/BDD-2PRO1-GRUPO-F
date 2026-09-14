# Informe de Trabajo Práctico 4: Optimización y Consultas Analíticas (Food Store)

---

## Parte 1: Laboratorio de Consultas Lentas, EXPLAIN y Optimización Medida

Tabla comparativa de rendimiento antes y después de la intervención:

| Consulta | Plan antes (nodo, cost, tiempo real) | Cambio aplicado | Plan después (nodo, cost, tiempo real) | Mejora / Decisión |
| :--- | :--- | :--- | :--- | :--- |
| **1. Facturación por categoría y mes** | `Parallel Hash Join` / `Seq Scan`<br>Cost: 32542.09<br>Tiempo: 1240.89 ms | Propuesta de índices `idx_detalle_pedido_producto_pedido` + `idx_pedido_id_fecha` y ajuste de memoria `SET work_mem = '64MB'`. | `Parallel Hash Join` / `Quicksort en RAM`<br>Cost: 32542.09<br>Tiempo: 1199.15 ms | **Aceptado:** Ligera aceleración (1.03x / 3.4%) al optimizar escaneos y garantizar ordenamiento en RAM sin desbordamiento a disco. |
| **2. Ranking de clientes por gasto total** | `Hash Join` / `Sort`<br>Cost: 32542.14<br>Tiempo: 711.15 ms (Disco: 10008kB) | Creación de índice `idx_pedido_cliente_id` y aumento de memoria de sesión `SET work_mem = '64MB'`. | `GroupAggregate` / `Quicksort en RAM`<br>Cost: 32542.14<br>Tiempo: 451.72 ms (Disco: 0kB) | **Aceptado:** Se eliminó por completo el derrame a disco (`external merge`) pasando a Quicksort en RAM, logrando una mejora de **1.57x (36.5%)**. |

---

## Parte 2: Lectura Crítica de Planes Interpretados por IA

Ejercicio de contraste crítico sobre la explicación generada por un asistente de IA frente al plan real de la Consulta 2 optimizada:

| Afirmación de la IA | ¿Correcta? | Corrección / evidencia del plan real |
| :--- | :---: | :--- |
| "La tabla cliente es la tabla externa y pedido es la interna." | **No** | En el `Hash Join` con `p.cliente_id = cl.id`, la tabla `cliente cl` se cargó dentro del nodo `Hash` (Memory: 1300kB) como tabla interna (*build input*), mientras que pedidos/detalles actuó como tabla externa (*probe input*). |
| "El costo del nodo Hash Join es de 11.149,36 ms." | **No** | Confunde el costo estimado en unidades arbitrarias de I/O (`cost=11149.36`) con el tiempo real en milisegundos. El tiempo real medido en ese nodo por `EXPLAIN ANALYZE` fue de **230.39 ms** (`actual time=54.949..230.391`). |
| "La mayor parte del tiempo de 451,72 ms se gastó en la unión de las tablas." | **No** | El join concluyó a los 230.39 ms. La mayor parte del tiempo (~218 ms) transcurrió en la etapa posterior de ordenamiento en memoria (`Sort`) y agregación (`GroupAggregate`), que llevaron la ejecución acumulada a 448.46 ms. |

---

## Parte 3: Consultas Resumen, Subconsultas y Verificación Formal

### 1. Consulta 3A: Ranking de Clientes (Función de Ventana)

* **Especificación:** Obtener un ranking completo de los clientes ordenados de mayor a menor según su gasto acumulado total (`SUM(dp.cantidad * dp.precio_unitario)`), utilizando `DENSE_RANK() OVER (ORDER BY gasto_total DESC)`. En caso de empate, comparten puesto sin saltar posiciones.
* **Verificación de Equivalencia:** Se ejecutó la prueba con `EXCEPT` entre la versión directa con ventana y la versión mediante CTE (`WITH`), retornando exactamente **0 filas**.

```sql
-- Versión Seleccionada para queries.sql (Directa con DENSE_RANK)
SELECT 
    cl.id AS cliente_id,
    cl.nombre,
    SUM(dp.cantidad * dp.precio_unitario) AS gasto_total,
    DENSE_RANK() OVER (ORDER BY SUM(dp.cantidad * dp.precio_unitario) DESC) AS posicion_ranking
FROM cliente cl
JOIN pedido p ON p.cliente_id = cl.id
JOIN detalle_pedido dp ON dp.pedido_id = p.id
GROUP BY cl.id, cl.nombre
ORDER BY posicion_ranking ASC;

---

### 2. Consulta 3B: Productos con Precio Superior al Promedio de su Categoría

* **Especificación:** Listar los productos activos (pr.activo = true) cuyo precio_actual supere el precio promedio de su respectiva categoría activa (c.activo = true), ordenados de forma descendente por precio.

* **Comparativa de Estructuras:**
--Versión 1 (Subconsulta Correlacionada): Ineficiente. Al evaluar la subconsulta en la cláusula WHERE por cada fila de producto, el motor degrada su rendimiento a $O(N^2)$, provocando un cuelgue temporal por el volumen masivo de datos.

--Versión 2 (CTE + Window Function): Optimizada. Resuelve el cálculo en $O(N \log N)$ mediante AVG() OVER (PARTITION BY pr.categoria_id) en una sola pasada.

```sql
-- Versión 1: Subconsulta Correlacionada en WHERE (Descartada por ineficiente O(N^2))
SELECT 
    pr.id AS producto_id,
    pr.nombre,
    pr.precio_actual,
    c.nombre AS categoria
FROM producto pr
JOIN categoria c ON c.id = pr.categoria_id
WHERE pr.activo = true 
  AND c.activo = true
  AND pr.precio_actual > (
      SELECT AVG(sub_pr.precio_actual)
      FROM producto sub_pr
      WHERE sub_pr.categoria_id = pr.categoria_id
        AND sub_pr.activo = true
  );

-- Versión 2: Seleccionada para queries.sql (CTE con Window Function O(N log N))
WITH promedios AS (
    SELECT 
        pr.id AS producto_id,
        pr.nombre,
        pr.precio_actual,
        c.nombre AS categoria,
        AVG(pr.precio_actual) OVER (PARTITION BY pr.categoria_id) AS promedio_cat
    FROM producto pr
    JOIN categoria c ON c.id = pr.categoria_id
    WHERE pr.activo = true 
      AND c.activo = true
)
SELECT 
    producto_id,
    nombre,
    precio_actual,
    categoria
FROM promedios
WHERE precio_actual > promedio_cat
ORDER BY precio_actual DESC;

---

## Parte 4: Competencia de Optimización

Registro de desempeño sobre la consulta analítica compleja asignada por la cátedra:

| Equipo | Plan antes (nodo, cost, tiempo real) | Estrategia Aplicada | Plan después (nodo, cost, tiempo real) | Mejora / Aceleración |
| :--- | :--- | :--- | :--- | :--- |
| **Mi Equipo** | *Pendiente (TBD)*<br>Cost: -<br>Tiempo: - ms | *Estrategia a definir según consulta asignada* | *Pendiente (TBD)*<br>Cost: -<br>Tiempo: - ms | **Pendiente de asignación por cátedra** |

---

## Declaración de Uso de Inteligencia Artificial (DUIA)

| Fase del Proyecto | Prompt / Solicitud enviada a la IA | Respuesta / Propuesta de la IA | Decisión y Justificación Técnica |
| :--- | :--- | :--- | :--- |
| **Parte 1: Optimización** | *"Analizar el plan EXPLAIN ANALYZE de la Consulta 2 y proponer mejoras para reducir el tiempo de ejecución."* | Identificó la falta de índice en `pedido.cliente_id` y sugirió incrementar `work_mem` a 64MB. | **Aceptada:** Se eliminó el derrame a disco (`external merge Disk: 10008kB`), reduciendo el tiempo de 711.15 ms a 451.72 ms (1.57x de mejora). |
| **Parte 2: Lectura Crítica** | *"Evaluar la precisión de una explicación sintética de un plan de join."* | Desglosó la diferencia entre costos relativos (`cost=...`) y tiempos reales (`actual time`), e identificó las tablas interna/externa en el Hash Join. | **Aceptada:** Se incorporó la matriz de validación en el informe para demostrar comprensión de los nodos de PostgreSQL. |
| **Parte 3: Subconsultas** | *"Generar dos versiones equivalentes para la comparación de precios contra el promedio de la categoría."* | Generó una versión con subconsulta correlacionada en `WHERE` y otra con CTE + `AVG() OVER (PARTITION BY ...)`. | **Parcialmente Aceptada:** Se aceptó la versión con función de ventana para `queries.sql` y se descartó la subconsulta correlacionada por su degradación a $O(N^2)$. |
