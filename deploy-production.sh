#!/bin/bash

echo "🚀 ICODEDN Production Deployment"
echo "================================="

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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check Docker
print_status "Checking Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running!"
    exit 1
fi

print_success "Docker is ready"

# Check .env file
print_status "Checking production environment..."
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo ""
    echo "Please create .env file from production.env.example:"
    echo "  cp production.env.example .env"
    echo ""
    echo "Then edit .env and set:"
    echo "  - SECRET_KEY (generate new one)"
    echo "  - DB_PASSWORD (strong password)"
    echo "  - MYSQL_ROOT_PASSWORD (strong password)"
    echo "  - EMAIL settings (if needed)"
    exit 1
fi

# Check required environment variables
print_status "Validating environment variables..."
source .env

if [ "$DEBUG" = "True" ]; then
    print_warning "DEBUG is set to True in production!"
fi

if [ "$SECRET_KEY" = "your-super-secret-key-here-change-this-in-production-please-use-50-chars" ]; then
    print_error "Please change SECRET_KEY in .env file!"
    exit 1
fi

if [ "$DB_PASSWORD" = "your-strong-database-password-here" ]; then
    print_error "Please change DB_PASSWORD in .env file!"
    exit 1
fi

print_success "Environment validation passed"

# Stop any existing containers
print_status "Stopping existing containers..."
docker compose down --remove-orphans 2>/dev/null || true

# Build and start production
print_status "Building production containers..."
docker compose up --build -d

# Wait for database
print_status "Waiting for database to be ready..."
sleep 30

# Run migrations
print_status "Running database migrations..."
docker compose exec -T web python manage.py migrate --settings=dmoj.docker_settings

# Collect static files
print_status "Collecting static files..."
docker compose exec -T web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Create superuser if needed
print_status "Setting up admin user..."
docker compose exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.auth import get_user_model
from django.contrib.flatpages.models import FlatPage
from django.contrib.sites.models import Site

User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@icodedn.com', 'admin123')
    print('Admin user created: admin/admin123')
else:
    print('Admin user already exists')

# Create essential pages
if not FlatPage.objects.filter(url='/about/').exists():
    about = FlatPage.objects.create(
        url='/about/',
        title='About ICODEDN',
        content='<h1>About ICODEDN</h1><p>ICODEDN is a modern online judge platform for competitive programming.</p>'
    )
    about.sites.add(Site.objects.get_current())
    print('About page created')

if not FlatPage.objects.filter(url='/custom_checkers/').exists():
    checkers = FlatPage.objects.create(
        url='/custom_checkers/',
        title='Custom Checkers',
        content='<h1>Custom Checkers</h1><p>Information about custom checkers for problem validation.</p>'
    )
    checkers.sites.add(Site.objects.get_current())
    print('Custom checkers page created')

print('Setup completed successfully')
"

# Check status
print_status "Checking service status..."
docker compose ps

echo ""
print_success "🎉 ICODEDN is now running in production!"
echo ""
echo "📍 URLs:"
echo "   Website: https://icodedn.com"
echo "   Admin: https://icodedn.com/admin"
echo ""
echo "🔧 Next steps:"
echo "1. Configure your Cloudflare tunnel to point to port 8000"
echo "2. Set up DNS: icodedn.com -> your tunnel"
echo "3. Test the website"
echo "4. Change default admin password"
echo ""
echo "📊 Useful commands:"
echo "   View logs: docker compose logs -f"
echo "   Stop: docker compose down"
echo "   Restart: docker compose restart"
echo "   Shell: docker compose exec web bash"
echo ""
print_warning "Security reminders:"
echo "   - Change default admin password immediately"
echo "   - Set up regular database backups"
echo "   - Monitor logs for any issues"
echo "   - Keep Docker images updated" 