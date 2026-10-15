# Informe auditoría Parte B

## 1. Parámetros modificados (postgresql.conf / ALTER SYSTEM)
- log_connections = on (registra cada conexión, quién/desde dónde)
- log_disconnections = on (duración y cierre)
- log_statement = 'mod' (registra DDL + DML de modificación: INSERT/UPDATE/DELETE, no cada SELECT)
- Ver con: SHOW log_connections; SHOW log_statement; Reiniciar/recargar config.

## 3. Sobre el fragmento (docs/log_auditoria_prueba.txt TODO: pegar)
Útil: quién (user/database), qué (statement + ERROR login fallido), cuándo (timestamp), desde dónde (host/pid). Fuera de alcance: valores fila por fila (qué mail se leyó) y diffs old/new — eso lo daría pgaudit a nivel de nociones.

## 4. ¿El log es sensible? ¿Quién lo lee?
Sí: el log contiene mails, statements e intentos fallidos (enumeración de usuarios). Solo debe leerlo el rol admin_datos/DBA y root del SO (permisos 640 sobre pg_log, sin acceso a app_web ni reportes).
