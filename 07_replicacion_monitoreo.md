# Integrante 3 — Seguridad, Monitoreo y Alta Disponibilidad

## 1. Roles y Usuarios en PostgreSQL

Ejecutar el script `06_roles_permisos.sql` como superusuario (`postgres`):

```bash
psql -U postgres -d abarrotera2_bd -f 06_roles_permisos.sql
```

Usuarios creados:

| Usuario             | Rol      | Permisos                          |
|---------------------|----------|-----------------------------------|
| `admin_abarrotera`  | Admin    | DDL + DML completo (CREATE, DELETE) |
| `cajero_abarrotera` | Cajero   | SELECT, INSERT, UPDATE (sin DELETE) |
| `auditor_abarrotera`| Auditor  | SELECT (solo lectura)             |

Para que Django use estos usuarios (opcional), configura `.env`:

```env
DB_USER=admin_abarrotera
DB_PASSWORD=Admin123!
```

---

## 2. Replicación Maestro-Esclavo (Streaming Replication)

### Requisitos
- Dos servidores/instancias PostgreSQL misma versión
- IP Maestro: `192.168.1.10` (ejemplo) — IP Esclavo: `192.168.1.20`

### Paso 1: Configurar Maestro (`postgresql.conf`)

```ini
listen_addresses = '*'
wal_level = replica
max_wal_senders = 3
wal_keep_size = 512    # MB
hot_standby = on
```

### Paso 2: Configurar autenticación (`pg_hba.conf`)

Agregar al final:

```conf
# Permitir al esclavo conectarse para replicación
host replication replicator 192.168.1.20/32 scram-sha-256
```

### Paso 3: Crear usuario de replicación en Maestro

```sql
CREATE USER replicator WITH REPLICATION PASSWORD 'Replic4Pass!';
```

### Paso 4: Reiniciar Maestro

```bash
sudo systemctl restart postgresql
# Windows: net stop postgresql-x64-16 && net start postgresql-x64-16
```

### Paso 5: Hacer backup base en Esclavo

```bash
# En el servidor Esclavo (borra datos existentes primero)
pg_basebackup -h 192.168.1.10 -D C:\PostgreSQL\16\data -U replicator -P -v -R
```

El flag `-R` crea automáticamente `standby.signal` y escribe `primary_conninfo`.

### Paso 6: Iniciar Esclavo

```bash
# En Esclavo, inicia PostgreSQL
sudo systemctl start postgresql
```

### Verificar replicación

```sql
-- En Maestro:
SELECT client_addr, state, sync_state FROM pg_stat_replication;

-- En Esclavo:
SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
```

---

## 3. Monitoreo

Supabase tiene dashboards de monitoreo, pero es para instancias **alojadas en Supabase**. Como tu PostgreSQL es local, tienes 3 opciones:

### Opción A: pgAdmin 4 (Dashboard de monitoreo integrado)
- Abre pgAdmin → haz clic derecho en la DB → **Dashboard**
- Muestra: sesiones activas, transacciones por segundo, hits en cache, bloqueos
- También: **Server Activity** → `pg_stat_activity` en tiempo real

### Opción B: Prometheus + postgres_exporter + Grafana (recomendado para evidencias)
```bash
# 1. Descargar postgres_exporter
# 2. Variables de conexión
set DATA_SOURCE_NAME=postgresql://admin_abarrotera:Admin123!@localhost:5432/abarrotera2_bd?sslmode=disable
# 3. Ejecutar
postgres_exporter.exe

# 4. Agregar job en prometheus.yml:
#  - job_name: postgres
#    static_configs:
#      - targets: ['localhost:9187']

# 5. En Grafana, importar dashboard ID: 9628 (PostgreSQL Database)
```

### Opción C: Consultas SQL directas para capturas (más simple)

```sql
-- Sesiones activas
SELECT count(*) AS sesiones_activas FROM pg_stat_activity WHERE state = 'active';

-- Conexiones totales
SELECT count(*) AS conexiones_totales FROM pg_stat_activity;

-- Uso de conexiones vs max_connections
SELECT count(*) AS conexiones_actuales,
       current_setting('max_connections')::int AS max_conexiones,
       round(count(*)::numeric / current_setting('max_connections')::int * 100, 1) AS porcentaje_uso
FROM pg_stat_activity;

-- Tablas más accesadas (lectura/escritura)
SELECT relname AS tabla,
       seq_scan + idx_scan AS total_accesos,
       n_tup_ins AS inserts,
       n_tup_upd AS updates,
       n_tup_del AS deletes
FROM pg_stat_user_tables
ORDER BY total_accesos DESC;

-- Tamaño de la base de datos
SELECT pg_size_pretty(pg_database_size('abarrotera2_bd')) AS tamaño;
```

Para CPU/RAM del sistema operativo, usa el Monitor de Recursos de Windows o `htop` en Linux.
