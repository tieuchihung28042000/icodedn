#!/bin/bash

# ICODEDN.COM Production Deployment Script
# Usage: ./deploy-production.sh

set -e

echo "🚀 ICODEDN.COM Production Deployment"
echo "===================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if we're in the right directory
if [[ ! -f "deploy.sh" ]]; then
    print_error "Please run this script from the ICODEDN project directory"
    exit 1
fi

print_status "Starting ICODEDN.COM production deployment..."

# Step 1: Backup existing data if any
if docker compose ps | grep -q "dmoj"; then
    print_status "Backing up existing database..."
    mkdir -p backups
    docker compose exec -T db mysqldump -u root -p${MYSQL_ROOT_PASSWORD:-root123} dmoj > "backups/backup_$(date +%Y%m%d_%H%M%S).sql" 2>/dev/null || true
    print_success "Backup completed (if database existed)"
fi

# Step 2: Stop existing services
print_status "Stopping existing services..."
docker compose down --remove-orphans 2>/dev/null || true

# Step 3: Clean up old images
print_status "Cleaning up old Docker images..."
docker images | grep "icodedncom" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

# Step 4: Setup environment
print_status "Setting up environment..."
if [[ ! -f ".env" ]]; then
    cp production.env.example .env
    print_warning "⚠️  .env file created from template"
    print_warning "Please update the following values in .env:"
    echo ""
    echo "1. SECRET_KEY - Generate with: python3 -c \"import secrets; print(secrets.token_urlsafe(50))\""
    echo "2. DB_PASSWORD - Set a strong database password"
    echo "3. MYSQL_ROOT_PASSWORD - Set a strong root password"
    echo "4. EMAIL_* - Configure email settings if needed"
    echo ""
    read -p "Press Enter after updating .env file..."
else
    print_status "Using existing .env file"
fi

# Step 5: Validate .env file
print_status "Validating .env configuration..."
if grep -q "your-super-secret-key-here" .env; then
    print_error "Please update SECRET_KEY in .env file"
    exit 1
fi

if grep -q "your-strong-database-password-here-change-this" .env; then
    print_error "Please update DB_PASSWORD in .env file"
    exit 1
fi

if grep -q "your-strong-root-password-here-change-this" .env; then
    print_error "Please update MYSQL_ROOT_PASSWORD in .env file"
    exit 1
fi

print_success "Environment validation passed"

# Step 6: Build and deploy
print_status "Building and deploying services..."
export DJANGO_SETTINGS_MODULE=dmoj.docker_settings

# Build with no cache
docker compose build --no-cache

# Start services
docker compose up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 45

# Check if services are running
if ! docker compose ps | grep -q "Up"; then
    print_error "Some services failed to start. Check logs with: docker compose logs"
    exit 1
fi

# Step 7: Run migrations
print_status "Running database migrations..."
docker compose exec -T web python manage.py migrate --settings=dmoj.docker_settings

# Step 8: Collect static files
print_status "Collecting static files..."
docker compose exec -T web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Step 9: Create superuser if needed
print_status "Setting up admin user..."
docker compose exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(is_superuser=True).exists():
    print('No superuser found. Please create one:')
    import sys
    sys.exit(1)
else:
    print('Superuser already exists')
" || {
    print_warning "No superuser found. Creating one now..."
    docker compose exec -T web python manage.py createsuperuser --settings=dmoj.docker_settings
}

# Step 10: Load initial data
print_status "Loading initial data..."
docker compose exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.flatpages.models import FlatPage
from django.contrib.sites.models import Site

# Update site domain
site = Site.objects.get_current()
site.domain = 'icodedn.com'
site.name = 'ICODEDN'
site.save()

# Create About page if not exists
if not FlatPage.objects.filter(url='/about/').exists():
    about_page = FlatPage.objects.create(
        url='/about/',
        title='About ICODEDN',
        content='<h1>Welcome to ICODEDN</h1><p>ICODEDN is a modern online judge platform for competitive programming.</p>'
    )
    about_page.sites.add(site)

print('Initial data loaded successfully')
"

# Step 11: Final status check
print_status "Checking final status..."
docker compose ps

echo ""
print_success "🎉 ICODEDN.COM deployment completed successfully!"
echo ""
echo "📍 Access Information:"
echo "   Website: https://icodedn.com"
echo "   Admin Panel: https://icodedn.com/admin"
echo "   Internal URL: http://localhost:8000 (for Cloudflare tunnel)"
echo ""
echo "📊 Management Commands:"
echo "   View logs: docker compose logs -f"
echo "   Restart: docker compose restart"
echo "   Stop: docker compose down"
echo "   Backup DB: docker compose exec db mysqldump -u root -p dmoj > backup.sql"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure Cloudflare tunnel to point to http://localhost:8000"
echo "2. Set up DNS records in Cloudflare"
echo "3. Configure email settings in .env if needed"
echo "4. Set up regular backups"
echo "5. Monitor logs for any issues"
echo ""
print_warning "Don't forget to:"
echo "- Set up Cloudflare tunnel"
echo "- Configure firewall (ufw allow 80,443,22)"
echo "- Set up monitoring"
echo "- Schedule regular backups"
echo ""
print_success "Deployment script completed! 🚀" 