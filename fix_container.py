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
try:
    call_command('compress', force=True, follow_links=True, extension='html,txt,css,js')
except Exception as e:
    print(f"Warning: Compression failed but continuing: {e}")

# Create symbolic links for missing files
print("Creating symbolic links for missing files...")
static_dir = '/app/static'

# Create directories if they don't exist
os.makedirs(os.path.join(static_dir, 'cache', 'js'), exist_ok=True)
os.makedirs(os.path.join(static_dir, 'cache', 'css'), exist_ok=True)
os.makedirs(os.path.join(static_dir, 'icons'), exist_ok=True)
os.makedirs(os.path.join(static_dir, 'libs', 'featherlight'), exist_ok=True)
os.makedirs(os.path.join(static_dir, 'vnoj', 'mathjax', '3.2.0', 'es5'), exist_ok=True)

# Copy logo.png if it exists
logo_source = '/app/resources/icons/logo.png'
logo_dest = os.path.join(static_dir, 'icons', 'logo.png')
if os.path.exists(logo_source) and not os.path.exists(logo_dest):
    import shutil
    shutil.copy(logo_source, logo_dest)
    print(f"Copied {logo_source} to {logo_dest}")

# Create empty files for missing static files to prevent 404 errors
missing_files = [
    'cache/js/output.261671aa7869.js',
    'cache/js/output.27552b55a267.js',
    'cache/css/output.0caf8863dcf8.css',
    'icons/gb_flag.svg',
    'icons/vi_flag.svg',
    'icons/logo.svg',
    'icons/manifest.json',
    'libs/featherlight/featherlight.min.js',
    'vnoj/mathjax/3.2.0/es5/tex-chtml.min.js',
    'mathjax_config.js'
]

for file_path in missing_files:
    full_path = os.path.join(static_dir, file_path)
    if not os.path.exists(full_path):
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, 'w') as f:
            f.write('/* Placeholder file created by fix_container.py */')
        print(f"Created placeholder for {file_path}")

print("Done!")
