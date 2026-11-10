# Trabajo Práctico N.º 8 · Unidad 8: Bases de Datos Móviles e Integración
## Food Store en la feria: La base de la tablet y el cierre de la capa de datos

* **Asignatura:** Bases de Datos II · Tecnicatura Universitaria en Programación (UTN)
* **Equipo de Trabajo:** Grupo F
* **Integrantes:** Ignacio Ariza, Nahuel Olmos, Facundo Cabrera
* **Repositorio de Trabajo:** [https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F](https://github.com/Nahuolmos/BDD-2PRO1-GRUPO-F)
* **Herramientas:** PostgreSQL 16+, SQLite 3.37+, Python 3.14 (simulador), Kiro y OpenCode
* **Fecha:** Noviembre 2026

---

## 1. La Base de la Tablet y Distribución de Datos (Consigna 1.a)

### 1.1 Qué datos viajan a la tablet y qué datos no viajan

El food truck opera en una feria gastronómica sin conectividad garantizada. Para brindar servicio continuo se implementa una arquitectura *offline-first* basada en SQLite. Por razones de seguridad física del dispositivo y minimización del consumo de almacenamiento, únicamente viaja una proyección de solo lectura del catálogo:

| Entidad / Columna | ¿Viaja a la tablet? | Destino en SQLite | Justificación técnica y de seguridad |
| :--- | :---: | :--- | :--- |
| `producto.id` | **SÍ** | `producto_cache.id` | Identificador único requerido para referenciar líneas de pedido. |
| `producto.nombre` | **SÍ** | `producto_cache.nombre` | Denominación para visualización del operador en la pantalla de venta. |
| `producto.precio_actual` | **SÍ (centavos)** | `producto_cache.precio_centavos` | Precio de referencia para calcular subtotales estimados sin conexión. |
| `producto.stock` | **SÍ** | `producto_cache.stock_visto` | Stock estimado al momento de la última copia para alertar faltantes. |
| `producto.activo` | **SÍ (0 / 1)** | `producto_cache.disponible` | Habilita u oculta el ítem en la interfaz de la tablet. |
| `producto.eliminado` | **SÍ (0 / 1)** | `producto_cache.eliminado` | Lápida (*tombstone*) para evitar venta de productos en baja lógica. |
| `producto.created_at` | **NO** | — | Metadato de auditoría del servidor sin utilidad operativa en la feria. |
| `producto.categoria_id` | **NO** | — | Para la venta rápida en el food truck no se requiere la jerarquía de categorías. |
| `cliente` (nombres, emails) | **NO** | — | **Privacidad de datos:** No se exponen datos personales de clientes en la tablet. |
| `usuario` (hashes de contraseñas) | **NO** | — | **Seguridad crítica:** Protección estricta ante robo o pérdida física de la tablet. |
| `auditoria_operaciones` | **NO** | — | Los registros de seguridad y trazabilidad residen solo en el servidor central. |

### 1.2 Justificación de diseño y Fuente de Verdad
* **Regla de oro:** *"El móvil propone, el servidor dispone."*  
  La tablet únicamente formula borradores y sugerencias. La **única fuente de verdad (*Single Source of Truth*) es PostgreSQL**.
* **Precios en centavos enteros (`INTEGER`):** Se evita el tipo `REAL` de SQLite para eliminar discrepancias por redondeo binario de punto flotante (IEEE 754), garantizando precisión aritmética absoluta.
* **Modo `STRICT` y claves foráneas activas:** Se utiliza SQLite 3.37+ con `PRAGMA foreign_keys = ON;` y tablas estrictas para impedir inconsistencias de tipos.

---

## 2. Sincronización y Simulación del Semáforo (Consigna 2.c)

El semáforo compara las solicitudes de la tablet en estado `PENDIENTE` contra la última instantánea de PostgreSQL (`snapshot_servidor`):
* 🔴 **Rojo (`RECHAZADO`):** Producto inexistente, baja lógica, no disponible o stock insuficiente.
* 🟡 **Amarillo (`CONFLICTO`):** El producto está disponible, pero el precio en el servidor difiere del precio visto.
* 🟢 **Verde (`SIMULADO_APROBADO`):** Coincidencia total en precio, disponibilidad y stock.

### Evidencias de los Casos de Prueba (C2 a C6)

#### Caso C2: Conflicto de precio y resolución posterior
* **Situación:** El operador armó el borrador `b_c2_uuid` con *Pizza Muzzarella* al precio visto de $1.050 (105.000 centavos). Previo a la sincronización, el servidor subió el precio a $1.200 (120.000 centavos).
* **Resultado del semáforo:**
  ```text
  [CONFLICTO] s_c2_uuid -> CONFLICTO: El precio unitario cambió en el servidor respecto al visto en la tablet
  ```
* **Resolución:** El cliente en mostrador acepta la diferencia. El operador actualiza el precio visto a 120.000 centavos y emite una nueva solicitud `s_c2_aceptado_uuid`:
  ```text
  [SIMULADO_APROBADO] s_c2_aceptado_uuid -> SIMULADO_APROBADO: Todos los ítems coinciden en disponibilidad, stock y precio
  ```

#### Caso C3: Quiebre de stock en el servidor
* **Situación:** El borrador `b_c3_uuid` solicita 10 unidades de *Pizza Especial* (id 4), pero el servidor solo tiene 5 unidades en stock.
* **Resultado del semáforo:**
  ```text
  [RECHAZADO] s_c3_uuid -> RECHAZADO: Stock insuficiente en servidor para la cantidad solicitada
  ```
* **Explicación:** El semáforo protege la integridad del inventario, impidiendo la confirmación de pedidos que el local no puede abastecer.

#### Caso C4: Producto dado de baja lógica en el servidor
* **Situación:** Se armó el borrador `b_c4_uuid` con el producto 6 (*Postre Chocotorta*), el cual fue dado de baja lógica (`eliminado = 1`, `disponible = 0`) en PostgreSQL.
* **Resultado del semáforo:**
  ```text
  [RECHAZADO] s_c4_uuid -> RECHAZADO: Producto dado de baja lógica en el servidor
  ```
* **Explicación:** Al actualizar el catálogo local mediante `SELECT * FROM producto_cache WHERE disponible = 1 AND eliminado = 0`, el postre deja de ofrecerse para nuevas ventas, preservando la fila en la base con su lápida (*tombstone*).

#### Caso C5: Solicitud limpia y sin discrepancias
* **Situación:** El borrador `b_c5_uuid` solicita 2 *Empanadas de Carne* al precio y stock vigentes.
* **Resultado del semáforo:**
  ```text
  [SIMULADO_APROBADO] s_c5_uuid -> SIMULADO_APROBADO: Todos los ítems coinciden en disponibilidad, stock y precio
  ```

#### Caso C6: Idempotencia y prevención de duplicación
* **Situación:** Debido a inestabilidad de señal, la tablet reenvía la misma solicitud con el UUID ya registrado (`s_c5_uuid`).
* **Resultado del semáforo:**
  ```text
  [OK IDEMPOTENCIA] Bloqueo exitoso por PK: UNIQUE constraint failed: cola_sync.solicitud_uuid
  ```
* **Explicación:** La clave primaria `solicitud_uuid` bloquea la duplicación a nivel de base. Además, el semáforo filtra por `WHERE estado = 'PENDIENTE'`, asegurando que ejecuciones reiteradas no alteren solicitudes previamente evaluadas.
* **Protección en un sistema de producción (Parada 8):** En una arquitectura distribuida real, la protección de idempotencia se delega en la cabecera HTTP `Idempotency-Key` (UUID del pedido). Un API Gateway o middleware valida esta clave contra una caché distribuida en Redis o una tabla transaccional en PostgreSQL con bloqueo optimista antes de procesar el pago o descontar stock.

### Comprobación de no alteración en PostgreSQL
Al concluir todas las simulaciones, se ejecutó en PostgreSQL:
```sql
SELECT COUNT(*) FROM pedido; -- Retorna los registros originales (5 pedidos)
SELECT id, nombre, stock FROM producto WHERE id IN (1, 4); -- Stock intacto
```
*Conclusión:* **Ningún pedido se insertó en PostgreSQL y el stock permaneció inmutable.** `SIMULADO_APROBADO` es una prueba de sincronización, no una venta real.

---

## 3. Integración y Revisión de la Capa de Datos (Consigna 3)

### 3.1 Mapa de la Capa de Datos (Consigna 3.a)

El proyecto Food Store integra tres motores de bases de datos complementarios:

| Motor | Rol en la Arquitectura | Qué datos almacena | Quién manda sobre cada dato (Autoridad) |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16+** | **Core Transaccional (OLTP Central)** | Catálogo oficial, precios, stock, ventas confirmadas, clientes, roles y auditoría. | **Manda sobre el inventario, precios vigentes y facturación real.** Es la única fuente de verdad (*Single Source of Truth*). |
| **MongoDB** | **Almacén Documental de Lectura (U7)** | Colección `pedidos` desnormalizada con objetos embebidos (`cliente`) y arreglos (`detalles`). | **Manda sobre la lectura rápida de comprobantes históricos.** Mantiene precios congelados al momento de la venta. |
| **SQLite 3.37+** | **Base Local Offline (Tablet U8)** | Caché de catálogo (`producto_cache`), borradores (`pedido_borrador`), ítems y `cola_sync`. | **Manda únicamente sobre los borradores locales en la tablet.** No decide stock, no decide precios ni emite ventas. |

---

### 3.2 Plan de Mantenimiento Integral (Consigna 3.b)

Como extensión al plan de mantenimiento de la Unidad 6, se definen las políticas operativas para el entorno distribuido:

1. **¿Qué se respalda y cómo se prueba la restauración?**
   * **PostgreSQL:** Respaldo diario automatizado en formato custom con `backup_foodstore.sh`. Se prueba mensualmente restaurando contra reloj en una base aislada (`foodstore_restore_test`) mediante `restore_test.sh`, validando conteos e integridad referencial (RTO observado: 1,5 segundos).
   * **SQLite:** Las bases en las tablets son efímeras y reconstruibles a partir de una instantánea fresca del servidor. No se respaldan archivos completos; únicamente se sincroniza la cola de borradores.
2. **Si se restaura un respaldo viejo de PostgreSQL, ¿qué hacen las tablets?**
   * Al detectarse una restauración histórica en el servidor central, se emite una señal de invalidación de versión. Las tablets **borran inmediatamente su `producto_cache`** y descargan una nueva instantánea (`servidor_snapshot.csv`). Las solicitudes encoladas deben reevaluarse obligatoriamente bajo el nuevo estado del servidor para evitar procesar ventas con stock inexistente.
3. **¿Cada cuánto y quién revisa las solicitudes en CONFLICTO o RECHAZADO?**
   * **En la tablet:** El **cajero / operador del food truck** revisa la cola al cierre de cada turno (cada 4 horas) para resolver discrepancias con los clientes o descartar borradores obsoletos.
   * **En el servidor:** El **administrador de base de datos / auditor** analiza diariamente los reportes de solicitudes rechazadas para identificar quiebres de stock recurrentes o intentos de fraude.

---

### 3.3 Code Review con IA de los Scripts de la Cursada (Consigna 3.c)

Se realizó una revisión asistida por IA de todos los scripts desarrollados durante la cursada (Unidades 4 a 8). A continuación se detallan los hallazgos más relevantes:

| Unidad | Script auditado | Hallazgo de la IA | Decisión humana | Justificación técnica y comprobación en base |
| :---: | :--- | :--- | :---: | :--- |
| **U5** | `sql/roles.sql` | Sugirió otorgar `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_reportes;` por simplicidad. | **CORREGIDO** | **Violación de Mínimo Privilegio:** Exponía PII de clientes (`contrasena_hash`, emails). Se restringió a `GRANT SELECT ON vistas`. Comprobado con `SET ROLE rol_reportes; SELECT * FROM cliente;` $\rightarrow$ `permission denied`. |
| **U6** | `maintenance.sql` | Propuso programar un `VACUUM FULL;` periódico semanal para recuperar espacio físico. | **DESCARTADO** | **Descarte con fundamento:** `VACUUM FULL` aplica un bloqueo exclusivo total (`AccessExclusiveLock`) congelando la base de datos. Se mantuvo `VACUUM (ANALYZE)` que trabaja en segundo plano sin interrumpir operaciones concurrentes. |
| **U8** | `movil/schema_sqlite.sql` | Propuso usar tipo `REAL` para almacenar precios decimales en pesos dentro de SQLite. | **CORREGIDO** | **Imprecisión de Punto Flotante:** La norma IEEE 754 genera desfasajes de centavos en cálculos acumulativos. Se corrigió a `precio_centavos INTEGER` con modo `STRICT`, asegurando cálculos exactos en centavos. |
| **U4** | `tp_fnbc_control_lote.sql` | Sugirió omitir la transacción explícita durante la migración de control de lote. | **CORREGIDO** | Se encapsuló la migración dentro de un bloque `BEGIN ... COMMIT` con plan de reversión (*rollback*) obligatorio para prevenir corrupción de datos en caso de fallo intermedio. |
