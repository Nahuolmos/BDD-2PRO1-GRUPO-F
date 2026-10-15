# Kiro — Requirements: roles Food Store (Parte A)

R1. rol_app_lectura: permite SELECT en catálogo y pedidos para la app de lectura, sin escribir.
R2. rol_app_escritura: permite operar pedidos (INSERT/UPDATE pedido, detalle_pedido) más lo de lectura, sin tocar usuarios ni permisos.
R3. rol_soporte: permite ver pedidos y datos básicos de usuario para atender reclamos, sin ver contrasena_hash.
R4. rol_reportes: permite solo SELECT sobre vistas de reporte, sin acceso a tablas base sensibles.
R5. app_web (login): cuenta de la app web, hereda solo rol_app_escritura, sin login extra.
R6. admin_datos (login): cuenta administradora de datos, única con DDL/DML amplio, sin SUPERUSER.
R7. Verificación: cada rol debe tener exactamente lo especificado (ni más ni menos), comprobable con \du y role_table_grants.
