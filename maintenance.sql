-- maintenance.sql — revisión semanal + mantenimiento justificado (PostgreSQL 16+)
-- Uso: psql -h localhost -U postgres -d foodstore -X -f maintenance.sql
-- NO usa VACUUM FULL (bloquea con ACCESS EXCLUSIVE y reescribe la tabla).

\echo '== A. Configuración de autovacuum/autoanalyze =='
SELECT name, setting FROM pg_settings
WHERE name IN ('autovacuum', 'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_threshold',
               'autovacuum_analyze_scale_factor', 'autovacuum_analyze_threshold')
ORDER BY name;

\echo '== B. Observación previa: tuplas muertas y estadísticas por tabla =='
SELECT relname, n_live_tup, n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS pct_muertas,
       n_mod_since_analyze,
       greatest(last_autovacuum, last_vacuum)  AS ultimo_vacuum,
       greatest(last_autoanalyze, last_analyze) AS ultimo_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

\echo '== C. Acción: solo donde la observación lo justifica =='
-- VACUUM (ANALYZE): tablas con > 10 % de tuplas muertas y al menos 1000 muertas.
--   Justificación: recupera espacio reutilizable y actualiza estadísticas sin bloquear
--   lecturas/escrituras (toma SHARE UPDATE EXCLUSIVE).
-- ANALYZE: tablas sin análisis, o con > 10 % de filas modificadas desde el último ANALYZE.
--   Justificación: el planner decide con estadísticas; no hay riesgo ni bloqueo relevante.
SELECT format('VACUUM (ANALYZE, VERBOSE) %I.%I;', schemaname, relname) AS accion
FROM pg_stat_user_tables
WHERE n_dead_tup >= 1000
  AND n_dead_tup > 0.10 * (n_live_tup + n_dead_tup)
UNION ALL
SELECT format('ANALYZE %I.%I;', schemaname, relname)
FROM pg_stat_user_tables
WHERE NOT (n_dead_tup >= 1000 AND n_dead_tup > 0.10 * (n_live_tup + n_dead_tup))
  AND (greatest(last_autoanalyze, last_analyze) IS NULL
       OR n_mod_since_analyze > 0.10 * greatest(n_live_tup, 1))
\gexec

\echo '== D. Verificación posterior =='
SELECT relname, n_dead_tup, n_mod_since_analyze,
       greatest(last_autovacuum, last_vacuum)  AS ultimo_vacuum,
       greatest(last_autoanalyze, last_analyze) AS ultimo_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
