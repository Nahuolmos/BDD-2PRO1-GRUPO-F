-- health_check.sql — chequeo diario de salud (PostgreSQL 16+)
-- Uso: psql -h localhost -U postgres -d foodstore -X -f health_check.sql

\echo '== 1. Tamaño de la base =='
SELECT current_database() AS base, pg_size_pretty(pg_database_size(current_database())) AS tamano;

\echo '== 2. Actividad de conexiones =='
SELECT numbackends AS conexiones, xact_commit, xact_rollback,
       round(100.0 * xact_rollback / NULLIF(xact_commit + xact_rollback, 0), 2) AS pct_rollback
FROM pg_stat_database WHERE datname = current_database();

SELECT state, count(*) AS sesiones
FROM pg_stat_activity WHERE datname = current_database()
GROUP BY state ORDER BY sesiones DESC;

\echo '== 3. Estado de tablas (tuplas muertas, autovacuum, autoanalyze) =='
SELECT relname, n_live_tup, n_dead_tup,
       round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS pct_muertas,
       last_autovacuum, last_autoanalyze, last_vacuum, last_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

\echo '== 4. Consultas activas (excluye esta sesión) =='
SELECT pid, usename, state, now() - query_start AS duracion, left(query, 120) AS query
FROM pg_stat_activity
WHERE datname = current_database() AND state <> 'idle' AND pid <> pg_backend_pid()
ORDER BY duracion DESC;

\echo '== 5. Alertas: transacciones abiertas o consultas largas (> 5 min) =='
SELECT pid, state, now() - xact_start AS xact_abierta, left(query, 120) AS query
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid()
  AND (state = 'idle in transaction' OR now() - query_start > interval '5 minutes');
