-- =============================================================================
-- Script: 06_roles_permisos.sql
-- Proyecto: Abarrotera Tecnológico
-- Descripción: Creación de usuarios de PostgreSQL con roles y permisos
-- Integrante 3: Seguridad, Monitoreo y Alta Disponibilidad
-- =============================================================================

-- 1. Crear roles (grupos lógicos) en PostgreSQL
-- =============================================================================

DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_admin') THEN
      CREATE ROLE rol_admin WITH NOLOGIN;
   END IF;
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_cajero') THEN
      CREATE ROLE rol_cajero WITH NOLOGIN;
   END IF;
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'rol_auditor') THEN
      CREATE ROLE rol_auditor WITH NOLOGIN;
   END IF;
END
$$;

-- 2. Otorgar permisos a nivel de base de datos
-- =============================================================================

-- Conectar a la base de datos
GRANT CONNECT ON DATABASE abarrotera2_bd TO rol_admin, rol_cajero, rol_auditor;

-- Esquema público
GRANT USAGE ON SCHEMA public TO rol_admin, rol_cajero, rol_auditor;

-- Admin: todos los privilegios (SELECT, INSERT, UPDATE, DELETE, DDL)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO rol_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO rol_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO rol_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO rol_admin;

-- Cajero: solo SELECT, INSERT, UPDATE en tablas de transacciones (no DELETE)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO rol_cajero;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_cajero;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO rol_cajero;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO rol_cajero;

-- Auditor: solo SELECT (solo lectura)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_auditor;

-- 3. Crear usuarios (login) con verificación de existencia
-- =============================================================================

DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin_abarrotera') THEN
      CREATE USER admin_abarrotera WITH PASSWORD 'Admin123!' IN ROLE rol_admin;
   END IF;
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'cajero_abarrotera') THEN
      CREATE USER cajero_abarrotera WITH PASSWORD 'Cajero123!' IN ROLE rol_cajero;
   END IF;
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'auditor_abarrotera') THEN
      CREATE USER auditor_abarrotera WITH PASSWORD 'Auditor123!' IN ROLE rol_auditor;
   END IF;
END
$$;

-- 4. Verificar usuarios creados
-- =============================================================================

SELECT rolname AS usuario, 
       CASE WHEN rolcanlogin THEN 'Sí' ELSE 'No' END AS puede_iniciar_sesion,
       CASE WHEN rolsuper THEN 'Sí' ELSE 'No' END AS superusuario
FROM pg_roles
WHERE rolname IN ('admin_abarrotera', 'cajero_abarrotera', 'auditor_abarrotera', 
                  'rol_admin', 'rol_cajero', 'rol_auditor')
ORDER BY rolname;

-- 5. Verificar permisos por usuario
-- =============================================================================

SELECT r.rolname AS usuario, string_agg(m.rolname, ', ') AS roles_asignados
FROM pg_roles r
LEFT JOIN pg_auth_members a ON r.oid = a.member
LEFT JOIN pg_roles m ON a.roleid = m.oid
WHERE r.rolname IN ('admin_abarrotera','cajero_abarrotera','auditor_abarrotera')
GROUP BY r.rolname
ORDER BY r.rolname;
