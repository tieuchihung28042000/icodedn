#!/bin/bash

echo "=== Fixing Password Validation Issue ==="
echo

echo "1. Stopping containers..."
docker compose down

echo "2. Rebuilding web container with new settings..."
docker compose build --no-cache web

echo "3. Starting containers..."
docker compose up -d

echo "4. Waiting for containers to be ready..."
sleep 30

echo "5. Checking if password validation is disabled..."
docker compose exec web python manage.py shell --settings=dmoj.docker_settings -c "
from django.conf import settings
print('AUTH_PASSWORD_VALIDATORS:', getattr(settings, 'AUTH_PASSWORD_VALIDATORS', 'Not found'))
if hasattr(settings, 'AUTH_PASSWORD_VALIDATORS') and not settings.AUTH_PASSWORD_VALIDATORS:
    print('✅ Password validation is DISABLED - you can now use simple passwords')
else:
    print('❌ Password validation is still ENABLED')
"

echo
echo "=== Instructions ==="
echo "Now you can change password to simple ones like:"
echo "- admin123"
echo "- 123456"
echo "- @654321"
echo
echo "If you still get validation errors, try refreshing the page and try again." 