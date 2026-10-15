# BITACORA.md — Uso de IA (Unidad 5)

| Parte | Prompt enviado a la IA | Respuesta relevante (resumen) | Validación / corrección humana |
|---|---|---|---|
| A (spec) | Redactar requirements+design de roles con mínimo privilegio para Food Store (4 grupo + 2 login, 1 justificación por rol). | Propuso 6 roles + columna sin contrasena_hash + default privileges solo lectura. | Aceptado. Se guardó en docs/kiro_roles_spec/. |
| A (roles.sql) | Generar roles.sql con CREATE ROLE/GRANT/REVOKE desde el spec. | Borrador inicial traía `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_reportes` por comodidad. | **Corregido (caso IA de más):** se cambió a solo `GRANT SELECT ON vistas` para reportes; el ALL quedó solo para admin_datos. Si reportes leyera base con PII, rompería mínimo privilegio. |
