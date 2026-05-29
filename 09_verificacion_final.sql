-- =============================================================================
-- Script: 09_verificacion_final.sql
-- Proyecto: Abarrotera Tecnológico
-- Descripción: Verificación final de todo lo configurado
-- Integrante 3: Seguridad, Monitoreo y Alta Disponibilidad
-- =============================================================================

-- 1. Verificar usuarios y roles
-- =============================================================================
\echo '=== USUARIOS Y ROLES ==='
SELECT r.rolname AS usuario,
       CASE WHEN r.rolcanlogin THEN 'Sí' ELSE 'No' END AS puede_iniciar_sesion,
       string_agg(m.rolname, ', ') AS roles_heredados
FROM pg_roles r
LEFT JOIN pg_auth_members a ON r.oid = a.member
LEFT JOIN pg_roles m ON a.roleid = m.oid
WHERE r.rolname IN ('admin_abarrotera','cajero_abarrotera','auditor_abarrotera')
GROUP BY r.rolname, r.rolcanlogin
ORDER BY r.rolname;

-- 2. Verificar replicación
-- =============================================================================
\echo '=== REPLICACIÓN (MAESTRO) ==='
SELECT client_addr, application_name, state, sync_state, write_lag
FROM pg_stat_replication;

-- 3. Verificar estado del esclavo
-- =============================================================================
\echo '=== ESTADO DEL ESCLAVO (conectar a puerto 5434) ==='
-- Conectarse al esclavo y ejecutar:
-- SELECT pg_is_in_recovery() AS en_modo_standby,
--        pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();

-- 4. Verificar conexiones activas
-- =============================================================================
\echo '=== CONEXIONES ACTIVAS ==='
SELECT count(*) AS conexiones_actuales,
       current_setting('max_connections')::int AS max_conexiones,
       round(count(*)::numeric / current_setting('max_connections')::int * 100, 1) AS porcentaje_uso
FROM pg_stat_activity;

\echo '=== DETALLE DE CONEXIONES ==='
SELECT pid, usename, datname, state, application_name, client_addr, query_start
FROM pg_stat_activity
ORDER BY state, query_start;

\echo '=== MONITOREO COMPLETADO ==='