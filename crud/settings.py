import os
from pathlib import Path
from decouple import config, Csv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SEGURIDAD — Claves y modo de ejecución

# SECRET_KEY se carga desde variables de entorno (.env).
# En producción, generar una nueva con: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
SECRET_KEY = config('SECRET_KEY')

# DEBUG debe ser False en producción. Se controla desde .env.
DEBUG = config('DEBUG', default=False, cast=bool)

# Hosts permitidos. En producción, agregar el dominio real.
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1', cast=Csv())

# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'abarrotera',
    'crispy_forms',
    'crispy_bootstrap4',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'crud.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'crud.wsgi.application'


# ==============================================================================
# BASE DE DATOS — Credenciales cargadas desde .env
# ==============================================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='abarrotera2_bd'),
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
    }
}


# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = 'es-mx'

TIME_ZONE = 'America/Mexico_City'

USE_I18N = True

USE_TZ = True


# ==============================================================================
# ARCHIVOS ESTÁTICOS
# ==============================================================================

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Directorios adicionales de archivos estáticos (para desarrollo)
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ==============================================================================
# AUTENTICACIÓN — Redirecciones de login/logout
# ==============================================================================

LOGIN_URL = 'login'
LOGIN_REDIRECT_URL = 'productos:lista'
LOGOUT_REDIRECT_URL = 'login'


# ==============================================================================
# CRISPY FORMS
# ==============================================================================

CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap4"
CRISPY_TEMPLATE_PACK = "bootstrap4"


# ==============================================================================
# SEGURIDAD — Headers y cookies (protección para producción)
# ==============================================================================

# Protección contra clickjacking — impide que la página se cargue en iframes.
X_FRAME_OPTIONS = 'DENY'

# Protección contra sniffing de Content-Type.
SECURE_CONTENT_TYPE_NOSNIFF = True

# Las sesiones expiran al cerrar el navegador.
SESSION_EXPIRE_AT_BROWSER_CLOSE = True

# Duración máxima de sesión: 8 horas (en segundos).
SESSION_COOKIE_AGE = 28800

# La cookie de sesión no es accesible desde JavaScript.
SESSION_COOKIE_HTTPONLY = True

# Configuraciones adicionales que solo aplican en producción (HTTPS).
if not DEBUG:
    # Cookies solo se envían por HTTPS.
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True

    # Redirigir todo el tráfico HTTP a HTTPS.
    SECURE_SSL_REDIRECT = True

    # Header HSTS — indica al navegador que solo use HTTPS.
    SECURE_HSTS_SECONDS = 31536000  # 1 año
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
