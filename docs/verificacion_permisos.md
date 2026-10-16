# Verificación permisos Parte A (real, 2026-10-15)

## \du
```
     Role name     |                         Attributes
-------------------+------------------------------------------------------------
 admin_datos       |
 app_web           |
 postgres          | Superuser, Create role, Create DB, Replication, Bypass RLS
 rol_app_escritura | Cannot login
 rol_app_lectura   | Cannot login
 rol_reportes      | Cannot login
 rol_soporte       | Cannot login
```
6 roles existen; grupos NOLOGIN, logins sin SUPERUSER. admin_datos sin atributos extra (no superuser).

## role_table_grants (4 roles grupo)
```
      grantee      |          table_name           | privilege_type
-------------------+-------------------------------+----------------
 rol_app_escritura | detalle_pedido                | INSERT
 rol_app_escritura | detalle_pedido                | SELECT
 rol_app_escritura | detalle_pedido                | UPDATE
 rol_app_escritura | pedido                        | INSERT
 rol_app_escritura | pedido                        | SELECT
 rol_app_escritura | pedido                        | UPDATE
 rol_app_lectura   | categoria                     | SELECT
 rol_app_lectura   | producto                      | SELECT
 rol_app_lectura   | usuario_anon                  | SELECT
 rol_app_lectura   | v_productos_vigentes          | SELECT
 rol_reportes      | usuario_anon                  | SELECT
 rol_reportes      | v_detalle_pedido_con_producto | SELECT
 rol_reportes      | v_pedidos_con_cliente         | SELECT
 rol_reportes      | v_productos_vigentes          | SELECT
 rol_soporte       | pedido                        | SELECT
(15 rows)
```

## Lectura (ni más ni menos vs spec)
- OK: escritura solo pedido/detalle, lectura catálogo/vistas, reportes solo vistas, soporte sin base sensible.
- Matices: el permiso columna de soporte (`usuario(id,nombre,mail,rol)` sin hash) no sale acá sino en `role_column_grants`; el `EXECUTE fn_total_pedido` va en `role_routine_grants`; `usuario_anon` aparece por `ALTER DEFAULT PRIVILEGES` (heredó lectura al crearse después); las MV no listan en esta vista (ver con `\z mv_ventas_dia_categoria`).
