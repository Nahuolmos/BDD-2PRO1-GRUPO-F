# spec: funciones_procedimientos_PLpgSQL

Objetivo: cumplir Objetivo 6 TPI (vistas, funciones y procedimientos en PL/pgSQL) con motor PostgreSQL 16+.

Qué se necesita (según TPI y cátedra):
- Al menos 1 función PL/pgSQL que RETORNE valor y se pueda usar en SELECT
- Al menos 1 procedimiento PL/pgSQL invocado con CALL, que use JSONB (requisito TPI) y haga DML transaccional

Propuestas:
1. **Función `fn_total_pedido(p_pedido_id BIGINT) RETURNS NUMERIC`** — suma `cantidad*precio_unitario` de `detalle_pedido` para un pedido. Si no existe, retorna 0. Uso: `SELECT fn_total_pedido(1);` en reportes.
2. **Procedimiento `pr_crear_pedido(p_cliente_id BIGINT, p_items JSONB)`** — crea un pedido con varios items en una sola transacción. `p_items` es JSONB array `[{"producto_id":1,"cantidad":2},...]`. Inserta en `pedido` y `detalle_pedido` usando `precio_actual` de `producto`, respetando soft delete (`eliminado=FALSE` y `activo=TRUE`).

Requisitos PL/pgSQL: bloques `BEGIN ... END`, variables, `LOOP` sobre `jsonb_array_elements`, `RAISE EXCEPTION` si producto no existe/eliminado, y `CALL` para invocar.

Criterio de aceptación:
- `SELECT fn_total_pedido(1)` = `SUM` manual por `EXCEPT 0`
- `CALL pr_crear_pedido(1, '[{"producto_id":2,"cantidad":3}]'::jsonb)` crea pedido + detalles atómicos (ROLLBACK si falla)
- Verificación con `EXPLAIN` no aplica (son objetos programables, no índices), pero se prueba con `SELECT` y `CALL`.
