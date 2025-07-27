import os
from .settings import *

# Override settings for Docker environment

# Debug mode
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'

# Secret key
SECRET_KEY = os.environ.get('SECRET_KEY', 'docker-dev-key-change-in-production')

# Allowed hosts
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1,icodedn.com').split(',')

# CSRF trusted origins for Django 4.0+
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'https://icodedn.com',
    'http://icodedn.com',
]

# Add environment variable support for additional trusted origins
if os.environ.get('CSRF_TRUSTED_ORIGINS'):
    additional_origins = os.environ.get('CSRF_TRUSTED_ORIGINS').split(',')
    CSRF_TRUSTED_ORIGINS.extend(additional_origins)

# Site configuration
SITE_ID = 1  # Make sure this is set to 1 for Django Sites framework

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.mysql'),
        'NAME': os.environ.get('DB_NAME', 'dmoj'),
        'USER': os.environ.get('DB_USER', 'dmoj'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'dmoj123'),
        'HOST': os.environ.get('DB_HOST', 'db'),
        'PORT': os.environ.get('DB_PORT', '3306'),
        'OPTIONS': {
            'charset': 'utf8mb4',
            'sql_mode': 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO',
        },
    }
}

# Redis configuration
REDIS_URL = os.environ.get('REDIS_URL', 'redis://redis:6379/0')

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': REDIS_URL,
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# Celery configuration
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

# Site information
SITE_NAME = os.environ.get('SITE_NAME', 'DMOJ')
SITE_LONG_NAME = os.environ.get('SITE_LONG_NAME', 'DMOJ: Modern Online Judge')
SITE_ADMIN_EMAIL = os.environ.get('SITE_ADMIN_EMAIL', 'admin@example.com')
SITE_FULL_URL = os.environ.get('SITE_FULL_URL', 'http://localhost:8000')

# Static and media files
STATIC_ROOT = '/app/static'
MEDIA_ROOT = '/app/media'
DMOJ_PROBLEM_DATA_ROOT = '/app/problems'

# Security settings for production
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True

# Logging
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/app/logs/django.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
}

# Email configuration (optional)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Default user language - use CPP17 which exists in language_small.json
DEFAULT_USER_LANGUAGE = 'CPP17'

# Disable password validation for easier development
AUTH_PASSWORD_VALIDATORS = []

# Disable some features that require additional setup
EVENT_DAEMON_USE = False
ENABLE_FTS = False

# Bridge configuration
BRIDGED_JUDGE_ADDRESS = [('localhost', 9999)]
BRIDGED_DJANGO_ADDRESS = [('localhost', 9998)]
BRIDGED_DJANGO_CONNECT = None

# Disable email verification and auto-activate accounts
REGISTRATION_AUTO_LOGIN = True
REGISTRATION_EMAIL_VERIFICATION = False
REGISTRATION_NO_EMAIL_VERIFICATION = True
ACCOUNT_EMAIL_VERIFICATION = 'none'
ACCOUNT_EMAIL_REQUIRED = False
ACCOUNT_ACTIVATION_DAYS = 7

# Automatically activate user accounts
REGISTRATION_BACKEND = 'registration.backends.simple.SimpleBackend'
REGISTRATION_OPEN = True

# Override django-registration's auto-login behavior
DMOJ_SIMPLE_REGISTRATION = True

# Override registration-related settings
DMOJ_REGISTRATION_DISABLE_PASSWORD_VALIDATOR = True
DMOJ_REGISTRATION_DISABLE_EMAIL_ACTIVATION = True

# Judge server configuration
DMOJ_JUDGE_SERVERS = {
    'judge1': {
        'auth': 'key',
        'host': 'web',
        'port': 9999,
    },
} 