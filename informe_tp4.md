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