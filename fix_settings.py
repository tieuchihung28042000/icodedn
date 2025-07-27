#!/usr/bin/env python3
import os
import sys

# Check if docker_settings.py exists
if not os.path.exists('dmoj/docker_settings.py'):
    print("dmoj/docker_settings.py does not exist!")
    sys.exit(1)

# Read the current settings
with open('dmoj/docker_settings.py', 'r') as f:
    settings = f.read()

# Make sure DEBUG is True
if 'DEBUG = False' in settings:
    settings = settings.replace('DEBUG = False', 'DEBUG = True')
elif 'DEBUG = True' not in settings:
    settings = settings.replace('# Debug mode', '# Debug mode\nDEBUG = True')

# Make sure STATIC_ROOT and MEDIA_ROOT are correct
if "STATIC_ROOT = '/app/static'" in settings:
    settings = settings.replace("STATIC_ROOT = '/app/static'", "STATIC_ROOT = '/app/static'")
if "MEDIA_ROOT = '/app/media'" in settings:
    settings = settings.replace("MEDIA_ROOT = '/app/media'", "MEDIA_ROOT = '/app/media'")

# Write the updated settings
with open('dmoj/docker_settings.py', 'w') as f:
    f.write(settings)

print("Settings updated successfully!")
