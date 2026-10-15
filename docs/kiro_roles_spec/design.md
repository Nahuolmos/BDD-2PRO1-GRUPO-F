# Kiro — Design: roles Food Store (Parte A)

Decisiones:
- Roles de grupo NOLOGIN (4) + logins con IN ROLE mínimo (app_web en rol_app_escritura, admin_datos aparte).
- Lectura amplia solo donde no hay PII (producto, categoria); usuario/cliente solo por vistas o columnas.
- Columna: rol_soporte recibe SELECT(id, nombre, mail, rol) ON usuario, nunca contrasena_hash.
- Default privileges: futuras tablas en public heredan SELECT para lectura/reportes, nada de escritura automática.
- Orden: CREATE ROLE → REVOKE ALL por defecto → GRANT puntuales → ALTER DEFAULT PRIVILEGES.
