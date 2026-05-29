-- =============================================================================
-- Script: 08_monitoreo.sql
-- Proyecto: Abarrotera Tecnológico
-- Descripción: Consultas de monitoreo para PostgreSQL
-- Integrante 3: Seguridad, Monitoreo y Alta Disponibilidad
-- =============================================================================

-- 1. Sesiones activas y conexiones
-- =============================================================================

-- Conexiones totales
SELECT count(*) AS conexiones_totales FROM pg_stat_activity;

-- Sesiones activas vs idle
SELECT state, count(*) AS cantidad
FROM pg_stat_activity
GROUP BY state
ORDER BY count(*) DESC;

-- Detalle de sesiones activas
SELECT pid, usename AS usuario, datname AS base_datos,
       application_name, client_addr, state,
       query_start, left(query, 80) AS query_truncada
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start;

-- 2. Uso de conexiones vs límite
-- =============================================================================

SELECT count(*) AS conexiones_actuales,
       current_setting('max_connections')::int AS max_conexiones,
       round(count(*)::numeric / current_setting('max_connections')::int * 100, 1) AS porcentaje_uso
FROM pg_stat_activity;

-- 3. Bloqueos activos
-- =============================================================================

SELECT l.pid, l.locktype, l.relation::regclass AS tabla,
       l.mode, l.granted, a.usename, a.query, a.state
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.granted
ORDER BY a.query_start;

-- 4. Tamaño de la base de datos
-- =============================================================================

SELECT pg_size_pretty(pg_database_size('abarrotera2_bd')) AS tamaño_abarrotera2_bd,
       pg_size_pretty(pg_database_size('postgres')) AS tamaño_postgres;

-- 5. Tablas más grandes
-- =============================================================================

SELECT relname AS tabla,
       pg_size_pretty(pg_total_relation_size(oid)) AS tamaño_total,
       n_live_tup AS filas_vivas,
       n_dead_tup AS filas_muertas,
       round(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 1) AS porcentaje_muertas
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(oid) DESC
LIMIT 10;

-- 6. Estado de replicación (Maestro)
-- =============================================================================

SELECT client_addr, application_name, state, sync_state,
       write_lag, flush_lag, replay_lag,
       backend_start
FROM pg_stat_replication;

-- 7. WAL generado recientemente
-- =============================================================================

SELECT pg_size_pretty(count(*) * 16 * 1024::bigint) AS tamaño_wal_actual
FROM pg_ls_waldir()
WHERE name NOT LIKE '%.history';

-- 8. Consultas más lentas (si pg_stat_statements está activado)
-- =============================================================================

SELECT queryid,
       left(query, 100) AS query_truncada,
       calls,
       round(total_exec_time::numeric, 2) AS tiempo_total_ms,
       round(mean_exec_time::numeric, 2) AS tiempo_promedio_ms,
       round(100 * shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS cache_hit_ratio
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- 9. Cache hit ratio (lecturas en memoria vs disco)
-- =============================================================================

SELECT 'abarrotera2_bd' AS base_datos,
       round(sum(heap_blks_hit)::numeric / NULLIF(sum(heap_blks_hit + heap_blks_read), 0) * 100, 1) AS cache_hit_ratio
FROM pg_statio_user_tables;
