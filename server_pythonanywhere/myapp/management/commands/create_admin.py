# myapp/management/commands/create_admin.py
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User

class Command(BaseCommand):
    help = 'Creates an admin user if it does not exist'

    def handle(self, *args, **kwargs):
        username = 'admin'
        password = '111'

        # Проверяем, есть ли уже пользователь с таким именем
        if not User.objects.filter(username=username).exists():
            User.objects.create_superuser(username=username, password=password)
            self.stdout.write(self.style.SUCCESS(f'Admin user "{username}" created successfully'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Admin user "{username}" already exists'))
