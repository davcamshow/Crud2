# Abarrotera Tecnológico — Sistema de Gestión de Inventario

Sistema web de gestión de inventario para una tienda de abarrotes, desarrollado con **Django 5.2** y **PostgreSQL**. Permite administrar productos con un sistema de roles (Administrador, Gerente, Cliente) y operaciones CRUD completas con validaciones en tiempo real.

---

## 📋 Tabla de Contenidos

- [Tecnologías](#-tecnologías)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Ejecución](#-ejecución)
- [Funcionalidades](#-funcionalidades)
- [Roles y Permisos](#-roles-y-permisos)
- [Seguridad](#-seguridad)
- [Comandos Útiles](#-comandos-útiles)
- [Buenas Prácticas](#-buenas-prácticas)
- [Mejoras Futuras](#-mejoras-futuras)

---

## 🛠 Tecnologías

| Componente       | Tecnología                  | Versión  |
| ---------------- | --------------------------- | -------- |
| **Backend**      | Django                      | 5.2.9    |
| **Base de datos** | PostgreSQL                 | —        |
| **Conector BD**  | psycopg2-binary             | 2.9.11   |
| **Frontend**     | Bootstrap                   | 5.3      |
| **JavaScript**   | jQuery                      | 3.7      |
| **Formularios**  | django-crispy-forms + BS4   | 2.5 / 6.0|
| **Configuración**| python-decouple             | 3.8      |
| **Idioma**       | Español (es-mx)             | —        |

---

## 🏗 Arquitectura

```
Cliente (Navegador)
    │
    ▼
┌─────────────────────────────┐
│  Django (WSGI/ASGI)         │
│  ├── Middleware de seguridad│
│  ├── Autenticación          │
│  ├── Vistas (FBV)           │
│  └── Templates (Bootstrap)  │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│  PostgreSQL                  │
│  └── abarrotera2_bd          │
└─────────────────────────────┘
```

- **Patrón**: MVT (Model-View-Template) de Django
- **Vistas**: Function-Based Views (FBV) con decoradores
- **Autenticación**: Sistema nativo de Django (`django.contrib.auth`)
- **Formularios**: ModelForms con crispy-forms para renderizado Bootstrap
- **Validaciones**: Server-side (Django) + Client-side (jQuery AJAX)

---

## 📁 Estructura del Proyecto

```
pagweb2/
├── .env                    # Variables de entorno (NO subir a git)
├── .env.example            # Template de configuración
├── .gitignore              # Archivos excluidos de git
├── manage.py               # CLI de Django
├── requirements.txt        # Dependencias Python
├── README.md
│
├── crud/                   # Proyecto Django (configuración)
│   ├── settings.py         # Configuración principal
│   ├── urls.py             # URLs raíz
│   ├── wsgi.py             # Entry point WSGI
│   └── asgi.py             # Entry point ASGI
│
├── abarrotera/             # App principal
│   ├── models.py           # Modelo Producto
│   ├── views.py            # Vistas CRUD + Auth
│   ├── forms.py            # Formularios (Producto, Registro)
│   ├── urls.py             # URLs de la app
│   ├── admin.py            # Configuración del admin
│   └── migrations/         # Migraciones de BD
│
├── templates/              # Templates HTML
│   ├── base.html           # Layout principal
│   ├── login.html          # Inicio de sesión
│   ├── registro.html       # Registro de usuarios
│   └── productos/          # Templates CRUD
│       ├── lista.html
│       ├── crear.html
│       ├── editar.html
│       ├── detalle.html
│       └── eliminar.html
│
├── static/                 # Archivos estáticos
│   ├── css/styles.css      # Estilos personalizados
│   ├── js/validaciones.js  # Validaciones jQuery
│   └── img/box.png         # Favicon
│
└── EntVirt/                # Entorno virtual Python
```

---

## ✅ Requisitos Previos

- **Python** 3.10+
- **PostgreSQL** 14+
- **pip** (gestor de paquetes de Python)
- **Git** (control de versiones)

---

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/abarrotera-tecnologico.git
cd abarrotera-tecnologico
```

### 2. Crear y activar entorno virtual

```bash
# Windows
python -m venv EntVirt
EntVirt\Scripts\activate

# Linux / macOS
python3 -m venv EntVirt
source EntVirt/bin/activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Crear la base de datos en PostgreSQL

```sql
CREATE DATABASE abarrotera2_bd;
```

### 5. Configurar variables de entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env     # Linux/macOS
copy .env.example .env   # Windows
```

Editar `.env` con tus valores reales (ver sección [Configuración](#-configuración)).

### 6. Ejecutar migraciones

```bash
python manage.py migrate
```

### 7. Crear superusuario (administrador)

```bash
python manage.py createsuperuser
```

### 8. Iniciar el servidor

```bash
python manage.py runserver
```

Acceder a: [http://localhost:8000](http://localhost:8000)

---

## ⚙ Configuración

Todas las configuraciones sensibles se manejan mediante variables de entorno en el archivo `.env`:

| Variable          | Descripción                          | Ejemplo                     |
| ----------------- | ------------------------------------ | --------------------------- |
| `SECRET_KEY`      | Clave secreta de Django              | `django-insecure-xxxx...`   |
| `DEBUG`           | Modo debug (`True`/`False`)          | `True`                      |
| `ALLOWED_HOSTS`   | Hosts permitidos (separados por `,`) | `localhost,127.0.0.1`       |
| `DB_NAME`         | Nombre de la base de datos           | `abarrotera2_bd`            |
| `DB_USER`         | Usuario de PostgreSQL                | `postgres`                  |
| `DB_PASSWORD`     | Contraseña de PostgreSQL             | `tu-contraseña`             |
| `DB_HOST`         | Host de la base de datos             | `localhost`                 |
| `DB_PORT`         | Puerto de PostgreSQL                 | `5432`                      |

### Generar una nueva SECRET_KEY

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

> ⚠️ **Importante:** Nunca subir el archivo `.env` al repositorio. Ya está incluido en `.gitignore`.

---

## ▶ Ejecución

### Desarrollo

```bash
python manage.py runserver
```

### Producción

Para producción, asegúrate de:

1. Configurar `DEBUG=False` en `.env`
2. Configurar `ALLOWED_HOSTS` con tu dominio real
3. Generar una nueva `SECRET_KEY` segura
4. Usar un servidor WSGI como **Gunicorn**:

```bash
pip install gunicorn
gunicorn crud.wsgi:application --bind 0.0.0.0:8000
```

5. Recolectar archivos estáticos:

```bash
python manage.py collectstatic
```

---

## 🎯 Funcionalidades

### Autenticación
- ✅ Inicio de sesión con usuario y contraseña
- ✅ Registro público de nuevos usuarios (Gerente / Cliente)
- ✅ Cierre de sesión seguro (vía POST)
- ✅ Protección de rutas con `@login_required`

### Gestión de Productos (CRUD)
- ✅ **Listar** — Tabla responsiva con todos los productos
- ✅ **Crear** — Formulario con validación AJAX de nombre duplicado
- ✅ **Editar** — Modificar datos de productos existentes
- ✅ **Ver detalle** — Información completa del producto
- ✅ **Eliminar** — Confirmación antes de eliminar

### Validaciones
- ✅ Validación server-side con Django Forms
- ✅ Validación client-side con jQuery (nombre, precio, stock)
- ✅ Verificación AJAX de productos duplicados

### Panel de Administración
- ✅ Admin de Django en `/admin/` con:
  - Lista de productos con filtros y búsqueda
  - Campos de solo lectura para fechas

---

## 👥 Roles y Permisos

| Acción            | Admin | Gerente | Cliente |
| ----------------- | :---: | :-----: | :-----: |
| Ver productos     |  ✅   |   ✅    |   ✅    |
| Ver detalle       |  ✅   |   ✅    |   ✅    |
| Crear producto    |  ✅   |   ❌    |   ❌    |
| Editar producto   |  ✅   |   ✅    |   ❌    |
| Eliminar producto |  ✅   |   ❌    |   ❌    |
| Panel admin       |  ✅   |   ❌    |   ❌    |

> **Nota:** Los administradores solo pueden crearse mediante `python manage.py createsuperuser` o desde el panel de administración. El registro público solo permite roles de Gerente y Cliente.

---

## 🔒 Seguridad

### Configuración implementada

- ✅ **Variables de entorno** — Credenciales y claves fuera del código fuente (`.env`)
- ✅ **CSRF Protection** — Tokens CSRF en todos los formularios
- ✅ **Clickjacking** — `X_FRAME_OPTIONS = 'DENY'`
- ✅ **Content-Type Sniffing** — `SECURE_CONTENT_TYPE_NOSNIFF = True`
- ✅ **Cookies HttpOnly** — Sesión no accesible desde JavaScript
- ✅ **Sesiones con expiración** — 8 horas máximo, se cierra al cerrar navegador
- ✅ **Logout por POST** — Previene ataques de logout forzado
- ✅ **Validación de contraseñas** — 4 validadores de Django habilitados
- ✅ **Roles protegidos** — Sin escalación de privilegios en el registro

### Configuración de producción (activada con `DEBUG=False`)

- ✅ **HTTPS forzado** — `SECURE_SSL_REDIRECT = True`
- ✅ **Cookies seguras** — `SESSION_COOKIE_SECURE` y `CSRF_COOKIE_SECURE`
- ✅ **HSTS** — Headers Strict-Transport-Security con 1 año de duración

---

## 📌 Comandos Útiles

```bash
# Crear migraciones después de cambiar modelos
python manage.py makemigrations

# Aplicar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser

# Recolectar archivos estáticos
python manage.py collectstatic

# Verificar configuración de seguridad para producción
python manage.py check --deploy

# Abrir shell de Django
python manage.py shell

# Ver migraciones pendientes
python manage.py showmigrations
```

---

## 📐 Buenas Prácticas

- **PEP 8** — Código formateado según estándares de Python
- **Variables de entorno** — Sin credenciales hardcodeadas en el código
- **Separación de responsabilidades** — Models, Views, Templates, Forms separados
- **Validación en dos capas** — Server-side (Django) + Client-side (jQuery)
- **CSRF en todos los formularios** — Protección nativa de Django
- **Permisos por rol** — Verificación en views con decoradores y condicionales
- **`.gitignore` robusto** — Excluye archivos sensibles y generados
- **Docstrings** — Documentación en vistas principales

---

## 🚀 Mejoras Futuras

Las siguientes mejoras se recomiendan para llevar el proyecto al siguiente nivel:

### Prioridad Alta
- [ ] **API REST** — Implementar endpoints con Django REST Framework
- [ ] **Rate Limiting** — Limitar intentos de login y peticiones a la API
- [ ] **Logging** — Agregar sistema de logs para auditoría de acciones
- [ ] **Tests unitarios** — Cobertura de models, views y forms

### Prioridad Media
- [ ] **Paginación** — Para la lista de productos cuando crezca el inventario
- [ ] **Búsqueda y filtros** — En la vista de lista de productos
- [ ] **Grupos de Django** — Usar `django.contrib.auth.models.Group` en vez de flags
- [ ] **Imágenes de productos** — Subida y almacenamiento de imágenes
- [ ] **CORS** — Configurar `django-cors-headers` si se agrega frontend separado

### Prioridad Baja
- [ ] **Docker** — Containerización con Docker Compose (Django + PostgreSQL)
- [ ] **CI/CD** — Pipeline de integración continua (GitHub Actions)
- [ ] **Soft delete** — Marcar productos como inactivos en vez de eliminar
- [ ] **Exportación** — Exportar inventario a CSV/Excel
- [ ] **Dashboard** — Panel con estadísticas de inventario y gráficas

---

## 📄 Licencia

Este proyecto fue desarrollado con fines educativos.

---

<p align="center">
  <strong>Abarrotera Tecnológico</strong> © 2025 — Sistema de Gestión de Inventario
</p>
