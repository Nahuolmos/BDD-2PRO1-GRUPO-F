# Normalización — Food Store — 3FN / BCNF
**Motor:** PostgreSQL 16+ — **Fecha:** 2026-09-22 — **Tablas:** 5 + soft delete

## Dependencias funcionales (DFs)

**categoria(id → nombre, activo, eliminado, created_at)**
- Clave: `id` (IDENTITY PK)
- `nombre` no determina nada (no es superclave) — no hay DF transitiva.

**producto(id → nombre, precio_actual, stock, activo, eliminado, categoria_id, created_at)**
- `id → categoria_id`, `categoria_id` no → `nombre` (FK, no transitiva)
- No hay `nombre → precio` ni `categoria_id → precio` (precios por producto).

**cliente(id → nombre, email, created_at)**
- `id → email`, `email → id` (UNIQUE) — ambas son superclaves candidatas → BCNF.
- `id → nombre` directo, sin transitiva.

**pedido(id → fecha, forma_pago, cliente_id)**
- `id → cliente_id`, `cliente_id` no determina `forma_pago`.
- Sin atributos no clave que dependan transitivamente.

**detalle_pedido((pedido_id, producto_id) → cantidad, precio_unitario)**
- PK compuesta, todos los no clave dependen de **toda** la clave, no de parte → 2FN OK.
- `pedido_id → cliente_id` no existe aquí (está en `pedido`), no hay transitiva en esta tabla.

## Verificación formas normales

**1FN:** Todos los atributos atómicos (sin listas/arrays), PKs definidas. OK.

**2FN:** Solo `detalle_pedido` tiene clave compuesta y sus atributos (`cantidad`, `precio_unitario`) dependen de ambos (`pedido+producto`), no de uno solo. OK.

**3FN:** En ninguna tabla un no clave determina a otro no clave. Ej. en `producto`, `precio_actual` no determina `stock`. En `pedido`, `cliente_id` no determina `forma_pago`. OK. Soft delete `eliminado` depende directo de `id`, no crea transitiva.

**BCNF:** Todo determinante es superclave. Se cumple porque las únicas DFs tienen como determinante `id` (o PK compuesta) o `email` (UNIQUE, superclave candidata). No hay DF del tipo `nombre → categoria` . OK.

## Conclusión
El modelo está en **3FN y BCNF**. El paso de ER a relacional ya resolvió N:M con `detalle_pedido` y 1:N con FKs, sin redundancia. Agregar `eliminado` no rompe la forma normal.
