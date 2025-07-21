from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth import login as auth_login
from django.contrib.auth.models import User
from django.utils import timezone

User = get_user_model()

def activate_user(user):
    """
    Activate a user account immediately.
    """
    user.is_active = True
    user.save()
    return user

def auto_activate_registration(request, user, **kwargs):
    """
    Auto-activate user after registration.
    """
    # Activate the user
    user.is_active = True
    user.last_login = timezone.now()
    user.save()
    
    # Log the user in
    user.backend = 'django.contrib.auth.backends.ModelBackend'
    auth_login(request, user)
    
    return user 