#!/usr/bin/env python3
import os
import django
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

from django.contrib.sites.models import Site
from django.core.management import call_command

# Try to create the Site
try:
    site = Site.objects.get(id=1)
    print(f"Site exists: {site.domain}")
except Site.DoesNotExist:
    print("Site does not exist, creating...")
    Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
    print("Site created successfully!")

# Run migrations
print("Running migrations...")
call_command('migrate')

# Collect static files
print("Collecting static files...")
call_command('collectstatic', interactive=False)

# Compress static files
print("Compressing static files...")
call_command('compress', force=True)

print("Done!")
