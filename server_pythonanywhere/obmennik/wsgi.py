"""
WSGI config for obmennik project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/4.0/howto/deployment/wsgi/
"""

import os
from django.core.wsgi import get_wsgi_application
from django.core.management import call_command

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'obmennik.settings')

application = get_wsgi_application()

try:
    call_command('create_admin')
except Exception as e:
    print(f'Ошибка создания пользователя: {e}')

