#!/usr/bin/env python3
from django.contrib.sites.models import Site

# Update or create the site with id=1
Site.objects.update_or_create(
    id=1,
    defaults={
        'domain': 'icodedn.com',
        'name': 'iCodeDN'
    }
)
print("Django Site updated successfully!")
