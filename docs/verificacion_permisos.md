# Verificación permisos Parte A (TODO: pegar salida real)

Correr tras aplicar sql/00_usuario_base.sql y sql/roles.sql:
```sql
\du
SELECT grantee, table_name, privilege_type FROM information_schema.role_table_grants
WHERE grantee IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes') ORDER BY 1,2,3;
```
TODO: pegar salida. Esperado: lectura solo SELECT catálogo/vistas, escritura solo pedido/detalle+función, soporte sin contrasena_hash, reportes solo vistas.
