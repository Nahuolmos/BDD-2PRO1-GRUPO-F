# TP N.º 8 · Food Store en la feria
**Base de Datos II · Tecnicatura Universitaria en Programación (UTN) · Grupo F**
Integrantes: Ignacio Ariza, Nahuel Olmos, Facundo Cabrera · Noviembre 2026
Herramientas: PostgreSQL 16+, SQLite 3.37+ (DB Browser for SQLite), Kiro y OpenCode

> Regla de oro: **el móvil propone, el servidor dispone.** La tablet solo consulta y arma borradores. Precio, stock y ventas los decide PostgreSQL. `SIMULADO_APROBADO` no es una venta.

---

## 1.a · Qué datos viajan a la tablet

| Columna / entidad | ¿Viaja? | Destino en SQLite |
|---|:---:|---|
| `producto.id` | Sí | `producto_cache.id` |
| `producto.nombre` | Sí | `producto_cache.nombre` |
| `producto.precio_actual` (en centavos) | Sí | `producto_cache.precio_centavos` |
| `producto.stock` | Sí | `producto_cache.stock_visto` |
| `producto.activo` | Sí | `producto_cache.disponible` |
| `producto.eliminado` | Sí | `producto_cache.eliminado` |
| `producto.created_at`, `producto.categoria_id` | No | — |
| Clientes (nombres, mails) | No | — |
| Usuarios (hashes de contraseña) | No | — |
| Auditoría | No | — |

Viaja solo lo necesario para mostrar el catálogo y armar borradores sin conexión; los datos personales y de seguridad quedan en el servidor porque la tablet puede perderse o robarse. La fuente de verdad es PostgreSQL: la tablet trabaja con una copia que puede quedar desactualizada.

---

## 2.c · Los casos

Procedimiento: en una copia de PostgreSQL (`foodstore_tp8`) se creó la vista `v_snapshot_movil` y se exportó el catálogo a `servidor_snapshot_antes.csv`. Se importó en SQLite (`snapshot_servidor`) y se cargó `producto_cache`. Con ese catálogo se armaron los borradores (`paso1_borradores.sql`). Después se cambió el servidor (`tp8_casos_servidor.sql`), se exportó una instantánea nueva (`servidor_snapshot.csv`) y se reemplazó `snapshot_servidor`. La fecha de cada copia está en la columna `fecha_copia` / `fecha_snapshot`.

### Primera pasada del semáforo (`semaforo.sql`)
![Semáforo, primera pasada](../capturas/tp8_semaforo_primera_pasada.png)

### C2 · Conflicto de precio y aceptación
- **Preparación:** borrador de una Pizza Muzzarella; después el precio sube en el servidor.
- **Comando:** `semaforo.sql` y luego `paso2_resolver.sql` + `semaforo.sql`.
- **Resultado:** la primera solicitud queda en `CONFLICTO`. Al aceptar el cliente se actualiza el precio del borrador y la solicitud nueva queda en `SIMULADO_APROBADO`.

![C2 aceptado](../capturas/tp8_c2_aceptado.png)

El precio visto por la tablet difería del vigente, y no había causa de rechazo, por eso es amarillo. La solicitud nueva usa el precio actualizado y por eso pasa.

### C3 · Stock insuficiente
- **Preparación:** borrador por 10 Coca Cola; el stock en el servidor baja a 5.
- **Resultado:** `RECHAZADO` (primera captura).
- El borrador pide más unidades de las que quedan, así que el semáforo lo marca en rojo.

### C4 · Producto dado de baja
- **Preparación:** borrador con "Postre Chocotorta"; después se da de baja lógica en el servidor (`eliminado = TRUE`).
- **Resultado:** `RECHAZADO` (primera captura). Al recargar el catálogo (`INSERT OR REPLACE` desde `snapshot_servidor`) el producto ya no aparece en la consulta de disponibles, pero la fila sigue en la tabla con `eliminado = 1`.

![C4, catálogo sin el postre](../capturas/tp8_c4_catalogo.png)
![C4, la fila sigue existiendo](../capturas/tp8_c4_fila_existe.png)

La baja lógica deja una "lápida": el producto se oculta pero no se borra, así los borradores viejos pueden seguir siendo evaluados.

### C5 · Borrador sin cambios
- **Preparación:** borrador con 2 Empanadas de Carne, sin cambios en el servidor.
- **Resultado:** `SIMULADO_APROBADO` (primera captura). Todo coincide en precio, disponibilidad y stock.

### C6 · Reenvío con el mismo UUID
- **Comando:** `caso_c6.sql` (inserta otra vez la solicitud de C5) y luego `semaforo.sql` de nuevo.
- **Resultado:** error `UNIQUE constraint failed: cola_sync.solicitud_uuid`; al repetir el semáforo no se reevalúa nada (solo se tocan las `PENDIENTE`).

![C6, error de clave primaria](../capturas/tp8_c6_error_pk.png)
![C6, semáforo repetido](../capturas/tp8_c6_semaforo_repetido.png)

No se duplica la solicitud porque `solicitud_uuid` es clave primaria. En un sistema real la protección iría en el servidor (parada 8): una clave de idempotencia por solicitud, verificada en PostgreSQL dentro de la misma transacción que registra el pedido (por ejemplo, una restricción `UNIQUE` sobre ese UUID), para que los reintentos de la tablet no generen pedidos dobles.

### C7 · Restricciones de la tablet (consigna 1.c)
Una cantidad en 0 falla por `CHECK` y un producto inexistente falla por clave foránea; no queda ninguna fila nueva.

![C7, errores](../capturas/tp8_c7_errores.png)

### Comprobación: PostgreSQL no cambió por culpa de la tablet
Se ejecutó `tp8_verificacion.sql` (pedidos, detalles y stock) dos veces: después de preparar el servidor y al terminar toda la simulación. Los resultados son idénticos.

![Verificación 1](../capturas/tp8_pg_verificacion_1.png)
![Verificación 2](../capturas/tp8_pg_verificacion_2.png)

Los únicos cambios en PostgreSQL (precio de la pizza, stock de la Coca, baja del postre) los hicimos nosotros para preparar los casos; la tablet no escribió nada. `SIMULADO_APROBADO` no creó pedidos ni descontó stock.

---

## 3.a · Mapa de la capa de datos

| Motor | Qué guarda | Quién manda |
|---|---|---|
| **PostgreSQL** | Catálogo, precios, stock, ventas confirmadas, clientes, roles, auditoría | **Manda sobre precio, stock y ventas.** Fuente de verdad. |
| **MongoDB** (Unidad 7) | Colección `pedidos` desnormalizada, con cliente y detalles embebidos | Manda sobre la lectura de comprobantes históricos; los datos se copian desde PostgreSQL. |
| **SQLite** (tablet) | `producto_cache`, borradores, ítems y `cola_sync` | Manda **solo sobre sus borradores**. No decide precio, stock ni ventas. |

---

## 3.b · Plan de mantenimiento (agregado al plan de la Unidad 6)

- **¿Qué se respalda y cómo se prueba la restauración?** Se respalda PostgreSQL con `backup_foodstore.sh` (formato custom, diario). La restauración se prueba con `restore_test.sh` en una base aparte, comparando conteos y validaciones de integridad (RTO observado: 1,5 s). La base de la tablet no se respalda: se reconstruye desde una instantánea nueva del servidor; solo importa la cola de borradores pendientes.
- **Si se restaura un respaldo viejo de PostgreSQL, ¿qué hacen las tablets?** Descartan su `producto_cache`, bajan una instantánea nueva y vuelven a evaluar las solicitudes pendientes contra el estado restaurado, porque precios, stock o bajas pueden haber retrocedido.
- **¿Cada cuánto y quién revisa `CONFLICTO` y `RECHAZADO`?** El operador de la feria al cierre de cada turno, para resolverlas con el cliente; y un responsable de datos revisa diariamente las rechazadas para detectar faltantes de stock o patrones raros.

---

## 3.c · Code review con IA

| Unidad | Script | Hallazgo de la IA | Decisión | Motivo y comprobación |
|:---:|---|---|:---:|---|
| 5 | `sql/roles.sql` | Dar `GRANT ALL` sobre todas las tablas al rol de reportes | **Corregido** | Viola el mínimo privilegio y expone datos personales. Se dejó `GRANT SELECT` solo sobre vistas. Comprobado con `SET ROLE rol_reportes; SELECT * FROM cliente;` → `permission denied`. |
| 6 | `maintenance.sql` | Programar un `VACUUM FULL` periódico | **Descartado** | Toma un bloqueo exclusivo sobre la tabla y la reescribe: frena la operación. Se mantuvo `VACUUM (ANALYZE)`, que no bloquea lecturas ni escrituras. El script lo aclara en su encabezado. |
| 8 | `movil/schema_sqlite.sql` | Guardar precios como `REAL` en pesos | **Corregido** | El punto flotante binario acumula errores de centavos. Se usó `precio_centavos INTEGER` y tablas `STRICT`. Comprobado: con `STRICT`, insertar un texto no numérico en esa columna falla. |

---

## Archivos de este TP
`movil/schema_sqlite.sql` · `movil/pruebas_sqlite.sql` · `movil/semaforo.sql` · `movil/paso1_borradores.sql` · `movil/paso2_resolver.sql` · `movil/caso_c6.sql` · `movil/servidor_snapshot_antes.csv` · `movil/servidor_snapshot.csv` · `movil/foodstore_movil.db` · `postgresql/tp8_snapshot.sql` · `postgresql/tp8_casos_servidor.sql` · `postgresql/tp8_verificacion.sql` · `docs/kiro/` · `docs/bitacora_ia.md` · `docs/DUIA.md`
