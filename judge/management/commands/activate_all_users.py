from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Activates all inactive user accounts'

    def handle(self, *args, **options):
        inactive_users = User.objects.filter(is_active=False)
        count = inactive_users.count()
        
        if count > 0:
            inactive_users.update(is_active=True)
            self.stdout.write(self.style.SUCCESS(f'Successfully activated {count} user accounts'))
        else:
            self.stdout.write(self.style.SUCCESS('No inactive user accounts found')) 