#!/bin/bash

# ICODEDN.COM Deploy Script
# Usage: ./deploy-icodedn.sh

set -e

echo "🚀 Deploying ICODEDN.COM"
echo "========================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check Docker
print_status "Checking Docker..."
if ! command -v docker &> /dev/null || ! docker info &> /dev/null; then
    print_error "Docker is not installed or not running!"
    exit 1
fi

# Create directories
print_status "Creating directories..."
mkdir -p data/{mysql,redis,static,media,problems} static media logs backups

# Setup environment
print_status "Setting up environment..."
if [[ ! -f ".env" ]]; then
    cp production.env.example .env
    print_warning "Please update .env file with your settings:"
    echo "  - SECRET_KEY (generate new one)"
    echo "  - DB_PASSWORD and MYSQL_ROOT_PASSWORD"
    echo ""
    read -p "Press Enter after updating .env..."
fi

# Validate .env
if grep -q "your-super-secret-key-here" .env || grep -q "your-strong-database-password-here-change-this" .env; then
    print_error "Please update SECRET_KEY and passwords in .env file"
    exit 1
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Clean up
print_status "Cleaning up old images..."
docker images | grep "icodedncom" | awk '{print $3}' | xargs docker rmi -f 2>/dev/null || true

# Build and start
print_status "Building and starting services..."
docker compose build --no-cache
docker compose up -d

# Wait for database
print_status "Waiting for database..."
for i in {1..30}; do
    if docker compose exec -T db mysqladmin ping -h localhost --silent 2>/dev/null; then
        break
    fi
    sleep 2
done

# Run migrations and setup
print_status "Running migrations and setup..."
docker compose exec -T web python manage.py migrate --settings=dmoj.docker_settings
docker compose exec -T web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Setup initial data
print_status "Setting up initial data..."
docker compose exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.auth import get_user_model
from django.contrib.flatpages.models import FlatPage
from django.contrib.sites.models import Site

# Update site
site = Site.objects.get_current()
site.domain = 'icodedn.com'
site.name = 'ICODEDN'
site.save()

# Create pages
if not FlatPage.objects.filter(url='/about/').exists():
    about = FlatPage.objects.create(url='/about/', title='About ICODEDN', content='Welcome to ICODEDN')
    about.sites.add(site)

print('Setup completed')
"

# Create superuser if needed
if ! docker compose exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.auth import get_user_model
exit(0 if get_user_model().objects.filter(is_superuser=True).exists() else 1)
" 2>/dev/null; then
    print_warning "Creating superuser..."
    docker compose exec -T web python manage.py createsuperuser --settings=dmoj.docker_settings
fi

# Final check
docker compose ps

echo ""
print_success "🎉 ICODEDN.COM deployed successfully!"
echo ""
echo "📍 Access:"
echo "   Website: http://icodedn.com"
echo "   Admin: http://icodedn.com/admin"
echo "   Direct: http://localhost:8000"
echo ""
echo "📊 Commands:"
echo "   Logs: docker compose logs -f"
echo "   Restart: docker compose restart"
echo "   Stop: docker compose down"
echo ""
print_success "Deployment completed! 🚀" 