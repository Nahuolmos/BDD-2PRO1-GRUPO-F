# BITACORA.md — Uso de IA (Unidad 5)

| Parte | Prompt enviado a la IA | Respuesta relevante (resumen) | Validación / corrección humana |
|---|---|---|---|
| A (spec) | Redactar requirements+design de roles con mínimo privilegio para Food Store (4 grupo + 2 login, 1 justificación por rol). | Propuso 6 roles + columna sin contrasena_hash + default privileges solo lectura. | Aceptado. Se guardó en docs/kiro_roles_spec/. |
| A (roles.sql) | Generar roles.sql con CREATE ROLE/GRANT/REVOKE desde el spec. | Borrador inicial traía `GRANT ALL ON ALL TABLES IN SCHEMA public TO rol_reportes` por comodidad. | **Corregido (caso IA de más):** se cambió a solo `GRANT SELECT ON vistas` para reportes; el ALL quedó solo para admin_datos. Si reportes leyera base con PII, rompería mínimo privilegio. |
| B (auditoría) | Qué nivel de log_statement usar para registrar modificación sin llenar disco. | Propuso log_statement='all' (registra hasta SELECTs). | Ajustado a 'mod': alcanza para INSERT/UPDATE/fallidos y no inunda el log. |
| C (simulacro) | Generar script fallidos->éxito->lectura masiva->escalamiento. | Borrador sin SET ROLE (corrido como superuser, el GRANT hubiera tenido éxito). | Corregido a SET ROLE rol_reportes para que el escalamiento falle como debe; si no falla es hallazgo Parte A. |
| C (reconstrucción) | Reconstruir incidente solo con log anonimizado + hipótesis contención. | Acertó fallidos+denegación pero omitió éxito y lectura masiva (no logueados con mod) e infirió origen externo sin evidencia de host. | Contraste en docs/informe_incidente.md; contención decidida por el equipo, no auto-ejecutada. |
| D (anonimización) | Consulta agregada por rol/mes sobre anon + equivalente sobre real. | Propuso GROUP BY correcto en ambas. | Se verifica con EXCEPT = 0 filas en docs/verificacion_equivalencia.md; PII real nunca sale. |

## Caso más significativo
El GRANT ALL a rol_reportes (Parte A): se detectó comparando el borrador contra el spec Kiro (reportes = solo vistas) y el principio de mínimo privilegio; de aplicarse, reportes leería tablas con PII. Se corrigió antes de aplicar.

## Historial Git
Avance por partes con commits legibles (paso previo, A, B, C x2, D x2). La verificación real (\du, logs, EXCEPT) se pegó en docs en commits aparte en vez de dejar TODOs. La próxima vez, correr la verificación justo después de cada script para no arrastrar plantillas.
