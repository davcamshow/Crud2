# Documento Técnico — Sistema de Gestión de Inventario

**Abarrotera Tecnológico**

---

## 1. Introducción

### 1.1 Objetivo

Desarrollar e implementar un sistema web de gestión de inventario para una tienda de abarrotes que permita administrar productos, controlar stock, gestionar ventas, y auditar movimientos de inventario, con un sistema de roles de usuario, alta disponibilidad mediante replicación de base de datos, y monitoreo continuo del desempeño del servidor PostgreSQL.

### 1.2 Problemática

Las tiendas de abarrotes tradicionales enfrentan los siguientes problemas:
- Control de inventario manual propenso a errores humanos
- Falta de trazabilidad sobre quién realizó cada operación
- Riesgo de pérdida de datos ante fallos del servidor
- Sin monitoreo de rendimiento de la base de datos
- Dificultad para auditar movimientos de inventario (entradas/salidas)
- Sin diferenciación de permisos entre administradores, cajeros y auditores

### 1.3 Justificación

Se requiere un sistema automatizado que:
- Elimine errores de cálculo manual mediante reglas de negocio en base de datos (triggers, procedimientos almacenados)
- Proporcione auditoría completa de inventario vía triggers automáticos
- Garantice disponibilidad mediante replicación streaming Maestro-Esclavo
- Permita monitorear en tiempo real el uso de CPU, RAM, sesiones y conexiones
- Implemente seguridad basada en roles (RBAC) a nivel de base de datos

---

## 2. Análisis

### 2.1 Requerimientos Funcionales

| ID | Requerimiento | Prioridad |
|---|---|---|
| RF-01 | El sistema debe permitir registrar, consultar, editar y eliminar productos | Alta |
| RF-02 | El sistema debe validar que el nombre del producto no esté duplicado | Alta |
| RF-03 | El sistema debe permitir registrar ventas con múltiples productos | Alta |
| RF-04 | El sistema debe descontar automáticamente el stock al registrar una venta | Alta |
| RF-05 | El sistema debe auditar automáticamente cada cambio de stock | Alta |
| RF-06 | El sistema debe evitar stock negativo y precios menores o iguales a cero | Alta |
| RF-07 | El sistema debe tener 3 roles: Admin, Cajero, Auditor | Alta |
| RF-08 | El sistema debe autenticar usuarios mediante usuario y contraseña | Alta |
| RF-09 | El registro público solo debe permitir roles de Gerente y Cliente | Media |
| RF-10 | El sistema debe tener categorías y proveedores para los productos | Media |

### 2.2 Requerimientos No Funcionales

| ID | Requerimiento | Prioridad |
|---|---|---|
| RNF-01 | La base de datos debe estar en PostgreSQL 17+ | Alta |
| RNF-02 | El backend debe usar Django 5.2 | Alta |
| RNF-03 | La replicación debe ser asíncrona tipo Streaming Replication | Alta |
| RNF-04 | El esclavo debe estar en modo hot_standby para consultas de solo lectura | Alta |
| RNF-05 | Las métricas de monitoreo deben incluir sesiones activas, conexiones, tamaño de BD | Media |
| RNF-06 | Las contraseñas y claves deben manejarse con variables de entorno | Alta |
| RNF-07 | El frontend debe ser responsivo con Bootstrap | Media |

### 2.3 Casos de Uso

#### CU-01: Iniciar Sesión
- **Actor**: Usuario (Admin, Cajero, Auditor)
- **Flujo**: Ingresa usuario/contraseña → sistema valida credenciales → redirige al listado
- **Alternativo**: Credenciales inválidas → muestra error

#### CU-02: Registrar Producto
- **Actor**: Admin
- **Flujo**: Completa formulario → sistema valida nombre único → guarda producto → registra alta inicial en auditoría
- **Precondición**: Usuario autenticado como Admin

#### CU-03: Registrar Venta
- **Actor**: Cajero
- **Flujo**: Selecciona productos → ingresa cantidades → sistema calcula subtotales y total → descuenta stock → registra auditoría
- **Precondición**: Usuario autenticado como Admin o Cajero

#### CU-04: Consultar Productos
- **Actor**: Cualquier usuario autenticado
- **Flujo**: Accede al listado → ve tabla con todos los productos
- **Postcondición**: Puede hacer clic en "Ver" para detalle

#### CU-05: Auditar Inventario
- **Actor**: Auditor
- **Flujo**: Accede a consultas de auditoría → revisa movimientos de stock
- **Precondición**: Usuario autenticado (solo lectura para Auditor)

#### CU-06: Verificar Replicación
- **Actor**: Admin
- **Flujo**: Consulta `pg_stat_replication` → verifica estado "streaming" y lag
- **Precondición**: Servidor esclavo configurado

### 2.4 Reglas de Negocio

| ID | Regla | Implementación |
|---|---|---|
| RN-01 | El stock de un producto nunca puede ser negativo | Trigger `trg_evitar_stock_negativo` |
| RN-02 | El precio de un producto debe ser mayor a 0 | Trigger `trg_validar_precio` |
| RN-03 | Al registrar una venta, el stock se descuenta automáticamente | Trigger `trg_descontar_stock_venta` |
| RN-04 | Cada cambio de stock se registra en la auditoría | Trigger `trg_auditoria_stock` |
| RN-05 | Cada producto nuevo genera un registro de "ALTA INICIAL" en auditoría | Trigger `trg_auditoria_nuevo_producto` |
| RN-06 | Solo Admin puede crear y eliminar productos | Validación en vistas Django |
| RN-07 | Solo Admin y Gerente pueden editar productos | Validación en vistas Django |
| RN-08 | El nombre del producto debe ser único (case-insensitive) | Validación AJAX + BD UNIQUE |
| RN-09 | El registro público no puede crear usuarios Admin | Exclusión explícita en formulario |
| RN-10 | El esclavo de replicación solo acepta consultas SELECT | `hot_standby = on` + `pg_is_in_recovery` |

---

## 3. Diseño

### 3.1 Modelo Entidad-Relación

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────┐
│  Categoria   │       │    Producto      │       │  Proveedor   │
├──────────────┤       ├──────────────────┤       ├──────────────┤
│ PK id        │──┐    │ PK id            │    ┌──│ PK id        │
│ nombre       │  └───→│ FK categoria_id   │    │   │ nombre_emp   │
│ descripcion  │       │ FK proveedor_id   │←───┘   │ rfc         │
└──────────────┘       │ nombre           │       │ telefono     │
                       │ descripcion      │       │ email        │
┌──────────────┐       │ precio           │       └──────────────┘
│  Auth_User   │       │ stock            │
│  (Django)    │       │ fecha_creacion   │       ┌──────────────────────┐
├──────────────┤       │ fecha_actualiz   │       │ AuditoriaInventario │
│ PK id        │       │ usuario_creador  │←──┐   ├──────────────────────┤
│ username     │       └──────────────────┘   │   │ PK id                │
│ password     │                              └───│ FK producto_id       │
│ is_staff     │       ┌──────────────────┐       │ accion               │
│ is_superuser │       │     Venta        │       │ stock_anterior       │
└──────────────┘       ├──────────────────┤       │ stock_nuevo          │
                       │ PK id            │       │ fecha_movimiento     │
┌──────────────┐       │ fecha_venta      │       └──────────────────────┘
│DetalleVenta  │       │ total            │
├──────────────┤       │ usuario_cajero   │←──┐
│ PK id        │       └──────────────────┘   │
│ FK venta_id  │←──────────┘                  │
│ FK producto  │←──┐                          │
│ cantidad     │   │                          │
│ precio_unit  │   │                          │
│ subtotal     │   │                          │
└──────────────┘   │                          │
                   └──────────────────────────┘
```

### 3.2 Modelo Relacional

**Categoria** (id_categoria, nombre, descripcion)
- PK: id_categoria

**Proveedor** (id_proveedor, nombre_empresa, rfc, telefono, email)
- PK: id_proveedor

**Producto** (id_producto, nombre, descripcion, precio, stock, id_categoria, id_proveedor, fecha_creacion, fecha_actualizacion, id_usuario_creador)
- PK: id_producto
- FK: id_categoria → Categoria(id_categoria)
- FK: id_proveedor → Proveedor(id_proveedor)
- FK: id_usuario_creador → Auth_User(id)

**Venta** (id_venta, fecha_venta, total, id_usuario_cajero)
- PK: id_venta
- FK: id_usuario_cajero → Auth_User(id)

**DetalleVenta** (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal)
- PK: id_detalle
- FK: id_venta → Venta(id_venta) ON DELETE CASCADE
- FK: id_producto → Producto(id_producto)

**AuditoriaInventario** (id_auditoria, id_producto, accion, stock_anterior, stock_nuevo, fecha_movimiento)
- PK: id_auditoria
- FK: id_producto → Producto(id_producto) ON DELETE CASCADE

### 3.3 Diccionario de Datos

#### Tabla: Categoria
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| nombre | VARCHAR | 100 | No | — | Nombre de la categoría (único) |
| descripcion | TEXT | — | Sí | — | Descripción opcional |

#### Tabla: Proveedor
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| nombre_empresa | VARCHAR | 200 | No | — | Nombre de la empresa |
| rfc | VARCHAR | 13 | Sí | — | RFC (único) |
| telefono | VARCHAR | 20 | Sí | — | Teléfono de contacto |
| email | VARCHAR | 254 | Sí | — | Correo electrónico |

#### Tabla: Producto
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| nombre | VARCHAR | 200 | No | — | Nombre del producto |
| descripcion | TEXT | — | No | — | Descripción del producto |
| precio | DECIMAL | 10,2 | No | — | Precio unitario |
| stock | INTEGER | — | No | — | Cantidad en inventario |
| categoria_id | BIGINT | — | Sí | — | FK a Categoria |
| proveedor_id | BIGINT | — | Sí | — | FK a Proveedor |
| fecha_creacion | TIMESTAMP | — | No | now() | Fecha de alta |
| fecha_actualizacion | TIMESTAMP | — | No | now() | Última modificación |
| usuario_creador_id | BIGINT | — | No | — | FK a Auth_User |

#### Tabla: Venta
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| fecha_venta | TIMESTAMP | — | No | now() | Fecha y hora de la venta |
| total | DECIMAL | 10,2 | No | 0.00 | Total de la venta |
| usuario_cajero_id | BIGINT | — | No | — | FK a Auth_User (cajero) |

#### Tabla: DetalleVenta
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| venta_id | BIGINT | — | No | — | FK a Venta (CASCADE) |
| producto_id | BIGINT | — | No | — | FK a Producto |
| cantidad | INTEGER | — | No | — | Cantidad vendida |
| precio_unitario | DECIMAL | 10,2 | No | — | Precio en el momento de la venta |
| subtotal | DECIMAL | 10,2 | No | — | cantidad × precio_unitario |

#### Tabla: AuditoriaInventario
| Columna | Tipo | Longitud | Nulo | Default | Descripción |
|---|---|---|---|---|---|
| id | BIGINT | — | No | Auto | Identificador único |
| producto_id | BIGINT | — | No | — | FK a Producto (CASCADE) |
| accion | VARCHAR | 50 | No | — | ENTRADA / SALIDA / ALTA INICIAL |
| stock_anterior | INTEGER | — | No | — | Stock antes del cambio |
| stock_nuevo | INTEGER | — | No | — | Stock después del cambio |
| fecha_movimiento | TIMESTAMP | — | No | now() | Fecha y hora del movimiento |

### 3.4 Normalización

El modelo relacional se encuentra en **Tercera Forma Normal (3FN)**:

- **1FN**: Todos los atributos son atómicos. No hay grupos repetitivos (DetalleVenta separa los productos de una venta en filas individuales).
- **2FN**: No existen dependencias parciales. Todas las llaves primarias son simples (single column) o compuestas donde cada atributo no clave depende de la llave completa.
- **3FN**: No hay dependencias transitivas. Los atributos como `precio_unitario` en DetalleVenta dependen directamente de la llave primaria, no de `producto_id`.

---

## 4. Arquitectura

### 4.1 Infraestructura

```
┌─────────────────────────────────────────────────────────┐
│                    Servidor Local                        │
│                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────┐ │
│  │   Django App  │    │  PostgreSQL  │    │ PostgreSQL │ │
│  │  (Puerto 8000)│    │  Maestro     │◄──►│  Esclavo   │ │
│  │  WSGI/ASGI    │    │  (Puerto 5432)│    │(Puerto 5434)│ │
│  └──────┬───────┘    └──────┬───────┘    └────────────┘ │
│         │                   │              Streaming     │
│         │                   │              Replication   │
│         ▼                   ▼                             │
│  ┌──────────────┐    ┌──────────────┐                    │
│  │   Template   │    │   pgAdmin 4  │                    │
│  │  Bootstrap 5 │    │  (Monitoreo) │                    │
│  └──────────────┘    └──────────────┘                    │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Distribución de Discos

| Ruta | Propósito | Tablespace |
|---|---|---|
| `C:\Program Files\PostgreSQL\17\data` | Datos principales del maestro | `pg_default` |
| `C:\Program Files\PostgreSQL\17\data_slave` | Datos principales del esclavo | `pg_default` |
| `C:\data_disco1` | Tablespace de datos (`ts_datos`) | Separado para datos transaccionales |
| `C:\data_disco2` | Tablespace de índices (`ts_indices`) | Separado para mejorar rendimiento de búsquedas |
| `C:\data_disco3` | Tablespace de logs (`ts_logs`) | Separado para registros de auditoría |
| `C:\data_disco1_slave` | Tablespace de datos (esclavo) | Mapeado desde `C:\data_disco1` |
| `C:\data_disco2_slave` | Tablespace de índices (esclavo) | Mapeado desde `C:\data_disco2` |
| `C:\data_disco3_slave` | Tablespace de logs (esclavo) | Mapeado desde `C:\data_disco3` |

### 4.3 Arquitectura Cliente-Servidor

```
┌─────────┐     HTTP/HTTPS      ┌───────────┐     SQL      ┌────────────┐
│ Cliente  │───────────────────►│  Django   │─────────────►│ PostgreSQL │
│(Browser) │◄───────────────────│  WSGI     │◄─────────────│  Maestro   │
└─────────┘     HTML+CSS+JS     │  Gunicorn │    Result    │  (5432)    │
                                └───────────┘              └─────┬──────┘
                                                                  │ WAL
                                                                  │ Stream
                                                          ┌───────▼──────┐
                                                          │ PostgreSQL   │
                                                          │  Esclavo     │
                                                          │  (5434)      │
                                                          └──────────────┘
```

**Flujo de petición**:
1. El cliente (navegador) envía petición HTTP al servidor Django
2. Django procesa la URL, ejecuta la vista correspondiente
3. La vista interactúa con PostgreSQL Maestro (puerto 5432) para lectura/escritura
4. PostgreSQL Maestro replica los cambios vía Streaming WAL al Esclavo (puerto 5434)
5. Django renderiza la plantilla Bootstrap y envía la respuesta HTML al cliente

---

## 5. Instalación

### 5.1 Configuración del Entorno

```bash
# 1. Clonar repositorio
git clone <repo-url> abarrotera
cd abarrotera

# 2. Crear entorno virtual
python -m venv EntVirt
EntVirt\Scripts\activate

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Crear base de datos en PostgreSQL
psql -U postgres -c "CREATE DATABASE abarrotera2_bd;"

# 5. Configurar variables de entorno (copiar .env.example a .env)
copy .env.example .env
# Editar .env con valores reales

# 6. Ejecutar migraciones
python manage.py migrate

# 7. Crear superusuario
python manage.py createsuperuser

# 8. Ejecutar scripts SQL complementarios
psql -U postgres -d abarrotera2_bd -f 02_vistas.sql
psql -U postgres -d abarrotera2_bd -f 03_procedimientos.sql
psql -U postgres -d abarrotera2_bd -f 04_triggers.sql
psql -U postgres -d abarrotera2_bd -f 06_roles_permisos.sql

# 9. Iniciar servidor
python manage.py runserver
```

### 5.2 Variables de Entorno

| Variable | Descripción | Ejemplo |
|---|---|---|
| `SECRET_KEY` | Clave secreta de Django | `django-insecure-abc123...` |
| `DEBUG` | Modo debug | `True` |
| `ALLOWED_HOSTS` | Hosts permitidos | `localhost,127.0.0.1` |
| `DB_NAME` | Nombre de la BD | `abarrotera2_bd` |
| `DB_USER` | Usuario de BD | `postgres` |
| `DB_PASSWORD` | Contraseña de BD | `postgres` |
| `DB_HOST` | Host de BD | `localhost` |
| `DB_PORT` | Puerto de BD | `5432` |

### 5.3 Servicios Configurados

| Servicio | Puerto | Propósito | Estado |
|---|---|---|---|
| Django (runserver) | 8000 | Aplicación web | Iniciado manualmente |
| PostgreSQL 17 Maestro | 5432 | Base de datos principal | Automático (Windows Service) |
| PostgreSQL 17 Esclavo | 5434 | Réplica de solo lectura | Automático (Windows Service) |
| pgAdmin 4 | — | Administración y monitoreo visual | Iniciado manualmente |

---

## 6. Seguridad

### 6.1 Roles de Base de Datos

| Rol | LOGIN | Privilegios |
|---|---|---|
| `rol_admin` | No | ALL PRIVILEGES + CREATE ON SCHEMA |
| `rol_cajero` | No | SELECT, INSERT, UPDATE (sin DELETE) |
| `rol_auditor` | No | SELECT (solo lectura) |

### 6.2 Usuarios de Base de Datos

| Usuario | Contraseña | Rol Asignado | Permisos Efectivos |
|---|---|---|---|
| `admin_abarrotera` | `Admin123!` | `rol_admin` | CREATE, SELECT, INSERT, UPDATE, DELETE, DROP |
| `cajero_abarrotera` | `Cajero123!` | `rol_cajero` | SELECT, INSERT, UPDATE (sin DELETE, sin DDL) |
| `auditor_abarrotera` | `Auditor123!` | `rol_auditor` | SELECT (solo lectura) |

### 6.3 Permisos a Nivel de Esquema

```sql
-- Permisos otorgados a roles
GRANT CONNECT ON DATABASE abarrotera2_bd TO rol_admin, rol_cajero, rol_auditor;
GRANT USAGE ON SCHEMA public TO rol_admin, rol_cajero, rol_auditor;
GRANT CREATE ON SCHEMA public TO rol_admin;

-- Admin: DDL + DML completo
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO rol_admin;

-- Cajero: DML limitado
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO rol_cajero;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO rol_cajero;

-- Auditor: solo SELECT
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_auditor;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO rol_auditor;
```

### 6.4 Seguridad en Django

| Medida | Configuración |
|---|---|
| CSRF Protection | Habilitado en todos los formularios |
| Clickjacking | `X_FRAME_OPTIONS = 'DENY'` |
| Content-Type Sniffing | `SECURE_CONTENT_TYPE_NOSNIFF = True` |
| Cookies HttpOnly | `SESSION_COOKIE_HTTPONLY = True` |
| Cookies Seguras (HTTPS) | `SESSION_COOKIE_SECURE = True` (producción) |
| Expiración de sesión | 8 horas (`SESSION_COOKIE_AGE = 28800`) |
| HSTS (producción) | 1 año (`SECURE_HSTS_SECONDS = 31536000`) |
| Registro público | Solo roles Gerente/Cliente (nunca Admin) |
| Logout por POST | Evita cierre de sesión forzado |
| Validación de contraseñas | 4 validadores de Django |

### 6.5 Respaldos

```bash
# Backup completo de la base de datos
pg_dump -U postgres -d abarrotera2_bd -F c -f "backup_abarrotera_$(date +%Y%m%d).dump"

# Backup del esquema completo (sin datos)
pg_dump -U postgres -d abarrotera2_bd -s -f "esquema_abarrotera.sql"

# Backup de solo datos
pg_dump -U postgres -d abarrotera2_bd -a -f "datos_abarrotera.sql"

# Restaurar backup
pg_restore -U postgres -d abarrotera2_bd -c "backup_abarrotera_20260528.dump"
```

### 6.6 Replicación

#### Configuración del Maestro (`postgresql.conf`)
```ini
listen_addresses = '*'
wal_level = replica
max_wal_senders = 3
wal_keep_size = 512MB
hot_standby = on
```

#### Configuración del Esclavo
```bash
# Crear backup base
pg_basebackup -h 127.0.0.1 -p 5432 -U postgres -D "C:\Program Files\PostgreSQL\17\data_slave" -P -v -R

# El flag -R genera automáticamente:
# - standby.signal  → indica modo standby
# - postgresql.auto.conf → contiene primary_conninfo
```

#### Verificación
```sql
-- En el Maestro:
SELECT client_addr, state, sync_state, write_lag FROM pg_stat_replication;
-- Resultado: streaming | async | ~0ms

-- En el Esclavo:
SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
-- Resultado: true | mismo LSN
```

---

## 7. Monitoreo y Auditoría

### 7.1 Métricas Disponibles

| Métrica | Consulta SQL | Propósito |
|---|---|---|
| Conexiones activas | `SELECT count(*) FROM pg_stat_activity WHERE state='active'` | Monitorear carga activa |
| Conexiones totales | `SELECT count(*) FROM pg_stat_activity` | Control de conexiones |
| % de uso de conexiones | `SELECT count(*)::numeric / current_setting('max_connections')::int * 100` | Capacidad restante |
| Tamaño de BD | `SELECT pg_size_pretty(pg_database_size('abarrotera2_bd'))` | Crecimiento de la BD |
| Tablas más grandes | `SELECT relname, pg_total_relation_size(oid) FROM pg_stat_user_tables ORDER BY 2 DESC` | Identificar tablas pesadas |
| Cache hit ratio | `SELECT sum(heap_blks_hit)::numeric / NULLIF(sum(heap_blks_hit+heap_blks_read),0)*100` | Eficiencia de caché |
| Estado replicación | `SELECT state, sync_state, write_lag FROM pg_stat_replication` | Salud de la replicación |
| Bloqueos activos | `SELECT * FROM pg_locks WHERE NOT granted` | Detectar contención |
| Filas muertas | `SELECT n_dead_tup, n_live_tup FROM pg_stat_user_tables` | Necesidad de VACUUM |

### 7.2 Logs de PostgreSQL

Los logs de PostgreSQL se almacenan en los directorios `log/` dentro de cada data directory:
- Maestro: `C:\Program Files\PostgreSQL\17\data\log\`
- Esclavo: `C:\Program Files\PostgreSQL\17\data_slave\log\`

### 7.3 Dashboards

**pgAdmin 4 Dashboard** (monitoreo visual):
- Conectarse al servidor en pgAdmin
- Seleccionar la base de datos `abarrotera2_bd`
- Clic derecho → **Dashboard**
- Muestra en tiempo real:
  - Sesiones activas
  - Transacciones por segundo
  - Tuplas insertadas/actualizadas/eliminadas
  - Hits en caché vs lecturas de disco
  - Bloqueos activos

### 7.4 Evidencias de Monitoreo (Capturas)

Para generar evidencias del funcionamiento del sistema:

```powershell
# 1. Conexiones activas
psql -U postgres -d abarrotera2_bd -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"

# 2. Estado de replicación
psql -U postgres -d postgres -c "SELECT client_addr, state, write_lag FROM pg_stat_replication;"

# 3. Tamaño de base de datos
psql -U postgres -d abarrotera2_bd -c "SELECT pg_size_pretty(pg_database_size('abarrotera2_bd'));"

# 4. Tablas más accesadas
psql -U postgres -d abarrotera2_bd -c "SELECT relname, seq_scan+idx_scan AS accesos FROM pg_stat_user_tables ORDER BY accesos DESC;"
```

---

## 8. Optimización

### 8.1 Índices Existentes

Django crea automáticamente índices para las llaves foráneas:
- `abarrotera_producto_categoria_id_04cac3ed` → `producto(categoria_id)`
- `abarrotera_producto_proveedor_id_bdb527a6` → `producto(proveedor_id)`

### 8.2 Índices Recomendados

```sql
-- Índice para búsqueda de productos por nombre (búsquedas textuales)
CREATE INDEX idx_producto_nombre ON abarrotera_producto USING gin(to_tsvector('spanish', nombre));

-- Índice compuesto para ventas del día (optimiza la vista v_ventas_del_dia)
CREATE INDEX idx_venta_fecha ON abarrotera_venta(fecha_venta);

-- Índice para ordenar productos por precio (consultas de reporting)
CREATE INDEX idx_producto_precio ON abarrotera_producto(precio);

-- Índice para búsqueda en auditoría por fecha (optimiza sp_purgar_auditoria)
CREATE INDEX idx_auditoria_fecha ON abarrotera_auditoriainventario(fecha_movimiento);

-- Índice para búsqueda en auditoría por producto
CREATE INDEX idx_auditoria_producto ON abarrotera_auditoriainventario(producto_id);
```

### 8.3 Consultas de Rendimiento

```sql
-- Consultas más lentas (requiere pg_stat_statements)
SELECT queryid, left(query, 80), calls, round(total_exec_time::numeric, 2) AS tiempo_total_ms,
       round(mean_exec_time::numeric, 2) AS promedio_ms
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Cache hit ratio (ideal: >99%)
SELECT 'abarrotera2_bd' AS base_datos,
       round(sum(heap_blks_hit)::numeric / NULLIF(sum(heap_blks_hit + heap_blks_read), 0) * 100, 1) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Filas muertas (necesidad de VACUUM)
SELECT relname, n_dead_tup, n_live_tup,
       round(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 1) AS porcentaje_muertas
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;
```

---

## 9. Recuperación

### 9.1 Simulación de Fallos

#### Prueba 1: Caída del Esclavo
```powershell
# 1. Detener el esclavo
Stop-Service postgresql-x64-17-slave

# 2. Verificar que el maestro sigue funcionando
psql -U postgres -d abarrotera2_bd -p 5432 -c "INSERT INTO test_recovery VALUES (1);"

# 3. Verificar que la replicación ya no está activa
psql -U postgres -d postgres -p 5432 -c "SELECT count(*) AS esclavos FROM pg_stat_replication;"
-- Resultado: 0

# 4. Reanudar el esclavo
Start-Service postgresql-x64-17-slave

# 5. Verificar que se recupera automáticamente
psql -U postgres -d abarrotera2_bd -p 5434 -h 127.0.0.1 -c "SELECT * FROM test_recovery;"
```

#### Prueba 2: Caída del Maestro
```powershell
# 1. Promover el esclavo a maestro (pérdida mínima de datos)
& "C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" promote -D "C:\Program Files\PostgreSQL\17\data_slave"

# 2. El antiguo esclavo (ahora maestro en puerto 5434) acepta escrituras
psql -U postgres -d abarrotera2_bd -p 5434 -h 127.0.0.1 -c "CREATE TABLE ventas_emergencia (id serial, dato text);"

# 3. Restaurar el maestro original desde el backup
pg_restore -U postgres -d abarrotera2_bd -c "backup_abarrotera.dump"
```

### 9.2 Recovery (Recuperación ante Desastres)

**Estrategia**: Respaldo + Replicación

| Escenario | Acción | RPO | RTO |
|---|---|---|---|
| Fallo del esclavo | Iniciar servicio automáticamente | 0 (sin pérdida maestro) | ~5 segundos |
| Corrupción del esclavo | Repetir `pg_basebackup` desde maestro | 0 | ~2 minutos |
| Fallo del maestro | Promover esclavo a maestro | ~1-5 segundos (WAL) | ~10 segundos |
| Desastre total | Restaurar desde `pg_dump` | Último backup | Variable |
| Error de datos | Restaurar backup point-in-time | Último backup | Variable |

---

## 10. Conclusiones

1. **Seguridad**: Se implementó un sistema de roles y usuarios a nivel de base de datos PostgreSQL (Admin, Cajero, Auditor) con permisos granulares que garantizan el principio de mínimo privilegio. A nivel de aplicación, Django proporciona autenticación segura con CSRF, HSTS, cookies HttpOnly y protección contra clickjacking.

2. **Alta Disponibilidad**: La replicación Streaming Maestro-Esclavo entre dos instancias de PostgreSQL 17 (puertos 5432 y 5434) funciona correctamente con latencia menor a 1 ms. El esclavo opera en `hot_standby` permitiendo consultas de solo lectura. En caso de fallo del maestro, el esclavo puede promoverse a maestro en segundos.

3. **Auditoría**: Los triggers automáticos en la base de datos registran cada cambio de stock en la tabla `auditoriainventario`, proporcionando trazabilidad completa de todas las operaciones (entradas, salidas, altas iniciales).

4. **Monitoreo**: Las consultas SQL de monitoreo sobre `pg_stat_activity`, `pg_stat_replication`, `pg_stat_user_tables` y `pg_database_size` permiten capturar métricas en tiempo real de conexiones, sesiones, tamaño de BD, estado de replicación y rendimiento de caché.

5. **Integridad de Datos**: Las reglas de negocio implementadas vía triggers (`evitar_stock_negativo`, `validar_precio`, `descontar_stock_venta`) garantizan la consistencia de los datos a nivel de base de datos, independientemente de la aplicación.

6. **Portabilidad**: El uso de Django ORM permite migrar la base de datos sin cambios en la lógica de negocio, mientras que los procedimientos almacenados y triggers mantienen la integridad a nivel de PostgreSQL.

---

## 11. Anexos

### 11.1 Scripts SQL Generados

| Archivo | Descripción |
|---|---|
| `01_creacion_tablas.sql` | Migraciones Django para creación de tablas |
| `02_vistas.sql` | 5 vistas: productos críticos, catálogo completo, ventas del día, top vendidos, historial auditoría |
| `03_procedimientos.sql` | 5 procedimientos: abastecer inventario, descuento masivo, aumento por proveedor, actualizar total venta, purgar auditoría |
| `04_triggers.sql` | 5 triggers con funciones: auditoría stock, evitar stock negativo, descontar stock venta, validar precio, auditoría nuevo producto |
| `05_indices.sql` | Índices recomendados para optimización |
| `06_roles_permisos.sql` | Creación de roles, usuarios y permisos |
| `08_monitoreo.sql` | Consultas de monitoreo y métricas |
| `09_verificacion_final.sql` | Script de verificación integral |

### 11.2 Capturas y Evidencias

Para generar las evidencias requeridas, ejecutar los siguientes comandos y capturar la salida:

**Evidencia 1 — Usuarios y Roles:**
```powershell
psql -U postgres -d abarrotera2_bd -c "SELECT r.rolname AS usuario, string_agg(m.rolname, ', ') AS roles FROM pg_roles r LEFT JOIN pg_auth_members a ON r.oid = a.member LEFT JOIN pg_roles m ON a.roleid = m.oid WHERE r.rolname IN ('admin_abarrotera','cajero_abarrotera','auditor_abarrotera') GROUP BY r.rolname;"
```

**Evidencia 2 — Replicación:**
```powershell
psql -U postgres -d postgres -p 5432 -c "SELECT client_addr, application_name, state, sync_state, write_lag FROM pg_stat_replication;"
psql -U postgres -d postgres -p 5434 -h 127.0.0.1 -c "SELECT pg_is_in_recovery() AS standby_mode, pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();"
```

**Evidencia 3 — Monitoreo (Conexiones):**
```powershell
psql -U postgres -d abarrotera2_bd -c "SELECT state, count(*) AS cantidad FROM pg_stat_activity GROUP BY state;"
```

**Evidencia 4 — Monitoreo (Tamaño BD):**
```powershell
psql -U postgres -d abarrotera2_bd -c "SELECT pg_size_pretty(pg_database_size('abarrotera2_bd')) AS tamaño_bd;"
```

**Evidencia 5 — Replicación funcional:**
```powershell
# Insertar en maestro
psql -U postgres -d abarrotera2_bd -p 5432 -c "INSERT INTO abarrotera_producto (nombre, descripcion, precio, stock) VALUES ('Producto Test', 'Test replicación', 10.50, 100);"
# Leer en esclavo
psql -U postgres -d abarrotera2_bd -p 5434 -h 127.0.0.1 -c "SELECT id, nombre, precio, stock FROM abarrotera_producto WHERE nombre = 'Producto Test';"
# Verificar que esclavo rechaza escrituras
psql -U postgres -d abarrotera2_bd -p 5434 -h 127.0.0.1 -c "INSERT INTO abarrotera_producto (nombre, descripcion, precio, stock) VALUES ('Fallo', 'debe fallar', 1, 1);"
```

### 11.3 Manual Técnico

**Tecnologías utilizadas:**

| Componente | Tecnología | Versión |
|---|---|---|
| Backend | Django | 5.2.9 |
| Base de datos | PostgreSQL | 17 |
| Conector BD | psycopg2-binary | 2.9.11 |
| Frontend | Bootstrap | 5.3 |
| JavaScript | jQuery | 3.7 |
| Formularios | django-crispy-forms | 2.5 |
| Configuración | python-decouple | 3.8 |

**Estructura del proyecto:**
```
/
├── manage.py
├── requirements.txt
├── crud/              # Configuración Django
├── abarrotera/        # App principal
├── templates/         # HTML (Bootstrap 5)
├── static/            # CSS, JS, imágenes
├── 01-09_*.sql        # Scripts SQL
└── DOCUMENTO_FINAL.md # Este documento
```

### 11.4 Manual de Usuario

**Inicio de sesión:**
- Acceder a `http://localhost:8000`
- Ingresar usuario y contraseña

**Roles y capacidades:**

| Acción | Admin | Gerente | Cliente |
|---|---|---|---|
| Ver listado de productos | ✅ | ✅ | ✅ |
| Ver detalle de producto | ✅ | ✅ | ✅ |
| Crear producto | ✅ | ❌ | ❌ |
| Editar producto | ✅ | ✅ | ❌ |
| Eliminar producto | ✅ | ❌ | ❌ |
| Panel de administración | ✅ | ❌ | ❌ |

**Registro de nuevos usuarios:**
- Acceder a `http://localhost:8000/registro/`
- Completar formulario (solo roles Gerente o Cliente)
- Los administradores solo se crean vía `python manage.py createsuperuser`

**Panel de Administración Django:**
- Acceder a `http://localhost:8000/admin/`
- Disponible solo para superusuarios

---

*Documento generado para el proyecto "Abarrotera Tecnológico — Sistema de Gestión de Inventario"*
