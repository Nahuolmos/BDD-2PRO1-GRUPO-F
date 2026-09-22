# spec: triggers_reglas_negocio

Objetivo: cumplir Objetivo 7 TPI (reglas con CHECK/UNIQUE + triggers) en PostgreSQL 16+.

Reglas ya cubiertas con CHECK/UNIQUE: `chk_producto_precio`, `uq_cliente_email`, etc. Falta trigger.

Propuestas:
1. **Trigger `trg_validar_stock` BEFORE INSERT ON detalle_pedido** — valida que `producto.stock >= cantidad` y que `producto` esté `activo=TRUE AND eliminado=FALSE`. Si no, `RAISE EXCEPTION`. Usa función PL/pgSQL `fn_validar_stock()`.
2. **Trigger de auditoría `trg_auditoria_pedido` AFTER UPDATE ON pedido** — opcional, demuestra tablas de transición (NEW/OLD) o `REFERENCING OLD TABLE AS`.

Criterio: trigger debe impedir DML inválido (ej. insertar detalle con stock insuficiente o producto borrado) y ser verificable con `INSERT` que falla vs que pasa.

Nota TPI: exige tablas de transición en triggers y PL/pgSQL — se documenta con `REFERENCING` si aplica.
