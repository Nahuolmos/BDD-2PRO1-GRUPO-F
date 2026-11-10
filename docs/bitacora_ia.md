# Bitácora de Uso de Inteligencia Artificial (Unidad 8 · TP8)
## Proyecto Food Store · Móvil en la feria

Esta bitácora documenta las interacciones con el asistente de IA durante el diseño e implementación de la solución móvil en SQLite, la sincronización mediante semáforo y la revisión de código.

---

### Registro de Prompts, Respuestas y Decisiones Técnicas

| N.º | Fase / Consigna | Prompt enviado a la IA | Propuesta de la IA (Resumen) | Decisión humana | Justificación técnica |
|---|---|---|---|:---:|---|
| **1** | **Consigna 1.b (Esquema SQLite)** | *"Diseña el esquema SQLite para la tablet del food truck que opera sin conexión. Necesitamos tablas para productos, borradores, ítems y cola de sincronización. ¿Qué tipos de datos recomiendas?"* | Propuso usar tablas estándar sin modo `STRICT` y tipo de dato `REAL` para los precios en pesos (con decimales). | **CORREGIDO** | En SQLite estándar el tipado dinámico permite insertar textos en columnas numéricas. Además, el tipo `REAL` introduce imprecisión por redondeo binario IEEE 754. Se exigió modo `STRICT` y conversión a enteros en centavos (`precio_centavos INTEGER`). |
| **2** | **Consigna 2.b (Semáforo SQL)** | *"Genera una consulta SQL en SQLite que compare la cola de sincronización contra la instantánea del servidor y clasifique en RECHAZADO, CONFLICTO o APROBADO."* | Propuso una consulta con múltiples subqueries correlacionadas y un `UPDATE` sin agrupar por solicitud, reevaluando todas las filas de la tabla. | **CORREGIDO** | Se reestructuró utilizando una Common Table Expression (`WITH evaluacion AS ...`) agrupada por `solicitud_uuid` y un filtro estricto `WHERE estado = 'PENDIENTE'` para garantizar idempotencia en ejecuciones repetidas. |
| **3** | **Consigna 3.c (Code Review U6)** | *"Revisa el script de mantenimiento maintenance.sql y sugiere mejoras para la compactación de espacio en PostgreSQL."* | Sugirió programar un `VACUUM FULL` periódico durante la madrugada para recuperar espacio físico en disco. | **DESCARTADO** | **Descarte fundamentado:** `VACUUM FULL` toma un bloqueo exclusivo total (`AccessExclusiveLock`) impidiendo la operatoria del sistema. Se mantuvo `VACUUM (ANALYZE)` que trabaja en segundo plano sin bloquear transacciones concurrentes. |

---

### Caso Más Significativo
El descarte de `VACUUM FULL` en la Unidad 6 y la corrección de `REAL` a `INTEGER` en la Unidad 8. Ambas situaciones demuestran que las sugerencias de la IA tienden a priorizar soluciones superficiales o teóricas sin medir el impacto operativo real (bloqueo total del motor en producción o desfasajes centesimales en facturación). La decisión humana garantizó alta disponibilidad y precisión contable.
