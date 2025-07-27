#!/bin/bash

echo "===== DMOJ Setup Fix Script ====="

# 1. Fix Git Submodules
echo "1. Fixing Git Submodules..."
git submodule init
git submodule update --recursive

# 2. Create necessary directories
echo "2. Creating necessary directories..."
mkdir -p media/cache media/problem_pdf media/problem_data media/profile_images
mkdir -p problems
mkdir -p mysql-data redis-data
mkdir -p docker/mysql
mkdir -p static/cache/js static/cache/css
mkdir -p static/icons
mkdir -p static/libs/featherlight
mkdir -p static/vnoj/mathjax/3.2.0/es5

# 3. Fix mysql-init.sql
echo "3. Fixing mysql-init.sql..."
cat > docker/mysql-init.sql << 'EOL'
-- MySQL initialization script for DMOJ
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS dmoj CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant privileges
GRANT ALL PRIVILEGES ON dmoj.* TO 'dmoj'@'%';
FLUSH PRIVILEGES;
EOL

cp docker/mysql-init.sql docker/mysql/mysql-init.sql
chmod 644 docker/mysql-init.sql docker/mysql/mysql-init.sql

# 4. Create a script to run inside the container to fix Django Site
echo "4. Creating fix_site.py..."
cat > fix_site.py << 'EOL'
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
EOL

# 5. Create a script to fix static files
echo "5. Creating fix_static.py..."
cat > fix_static.py << 'EOL'
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
EOL

# 6. Create a script to fix bridge
echo "6. Creating fix_bridge.py..."
cat > fix_bridge.py << 'EOL'
#!/usr/bin/env python3
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.settings')
django.setup()

from django.conf import settings

# Print bridge configuration
print("Bridge configuration:")
print(f"BRIDGED_JUDGE_ADDRESS: {settings.BRIDGED_JUDGE_ADDRESS}")
print(f"BRIDGED_DJANGO_ADDRESS: {settings.BRIDGED_DJANGO_ADDRESS}")
print(f"BRIDGED_DJANGO_CONNECT: {settings.BRIDGED_DJANGO_CONNECT}")

# Check if judge servers are configured
from judge.models import Judge
judges = Judge.objects.all()
print(f"Number of judges: {judges.count()}")
for judge in judges:
    print(f"Judge: {judge.name}, Online: {judge.online}, Last ping: {judge.last_ping}")
EOL

# 7. Create a script to fix container issues
echo "7. Creating fix_container.py..."
cat > fix_container.py << 'EOL'
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
EOL

echo "8. Creating fix_settings.py..."
cat > fix_settings.py << 'EOL'
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
EOL

echo "===== Setup Fix Script Complete ====="
echo "Now run the following commands:"
echo "1. chmod +x fix_setup.sh"
echo "2. ./fix_setup.sh"
echo "3. docker compose down"
echo "4. docker compose up -d"
echo "5. docker compose exec web python fix_container.py" 