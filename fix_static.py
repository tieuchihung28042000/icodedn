#!/usr/bin/env python3
import os
import shutil
from django.conf import settings

# Create necessary directories
os.makedirs(os.path.join(settings.STATIC_ROOT, 'cache', 'js'), exist_ok=True)
os.makedirs(os.path.join(settings.STATIC_ROOT, 'cache', 'css'), exist_ok=True)
os.makedirs(os.path.join(settings.STATIC_ROOT, 'icons'), exist_ok=True)
os.makedirs(os.path.join(settings.STATIC_ROOT, 'libs', 'featherlight'), exist_ok=True)
os.makedirs(os.path.join(settings.STATIC_ROOT, 'vnoj', 'mathjax', '3.2.0', 'es5'), exist_ok=True)

# Copy logo files if they exist in resources
if os.path.exists('resources/icons/logo.svg'):
    shutil.copy('resources/icons/logo.svg', os.path.join(settings.STATIC_ROOT, 'icons', 'logo.svg'))
if os.path.exists('resources/icons/logo.png'):
    shutil.copy('resources/icons/logo.png', os.path.join(settings.STATIC_ROOT, 'icons', 'logo.png'))

print("Static directories created successfully!")
