#!/bin/bash

# DMOJ Docker Deployment Script
# Usage: ./deploy.sh [local|production]

set -e

MODE=${1:-local}
COMPOSE_FILE="docker-compose.yml"

echo "🚀 DMOJ Deployment Script"
echo "=========================="
echo "Mode: $MODE"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Docker and Docker Compose are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Dependencies check passed"
}

# Create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p docker logs
    print_success "Directories created"
}

# Setup environment file
setup_environment() {
    print_status "Setting up environment..."
    
    if [ ! -f .env ]; then
        if [ "$MODE" = "production" ]; then
            print_warning ".env file not found. Please copy .env.example to .env and configure it for production."
            print_warning "Make sure to set proper values for:"
            echo "  - SECRET_KEY (generate a new one)"
            echo "  - ALLOWED_HOSTS (your domain)"
            echo "  - SITE_FULL_URL (your domain with https://)"
            echo "  - Database passwords"
            echo ""
            read -p "Do you want to continue with .env.example? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Please create .env file first"
                exit 1
            fi
            cp .env.example .env
        else
            print_status "Creating .env from .env.example for local development..."
            cp .env.example .env
            # Set development-friendly values
            sed -i 's/DEBUG=False/DEBUG=True/g' .env 2>/dev/null || sed -i '' 's/DEBUG=False/DEBUG=True/g' .env
            sed -i 's/SITE_FULL_URL=https:\/\/yourdomain.com/SITE_FULL_URL=http:\/\/localhost:8000/g' .env 2>/dev/null || sed -i '' 's/SITE_FULL_URL=https:\/\/yourdomain.com/SITE_FULL_URL=http:\/\/localhost:8000/g' .env
        fi
    fi
    
    print_success "Environment setup completed"
}

# Build and start services
deploy_services() {
    print_status "Building and starting services..."
    
    # Set Django settings module for Docker
    export DJANGO_SETTINGS_MODULE=dmoj.docker_settings
    
    # Build images
    print_status "Building Docker images..."
    docker compose -f $COMPOSE_FILE build
    
    # Start services
    print_status "Starting services..."
    docker compose -f $COMPOSE_FILE up -d
    
    # Wait for database to be ready
    print_status "Waiting for database to be ready..."
    sleep 30
    
    # Run migrations
    print_status "Running database migrations..."
    docker compose -f $COMPOSE_FILE exec -T web python manage.py migrate --settings=dmoj.docker_settings
    
    # Create superuser for local development
    if [ "$MODE" = "local" ]; then
        print_status "Creating default superuser for local development..."
        docker compose -f $COMPOSE_FILE exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@localhost', 'admin')
    print('Superuser created: admin/admin')
else:
    print('Superuser already exists')
"
    fi
    
    # Load initial data
    print_status "Loading initial data..."
    docker compose -f $COMPOSE_FILE exec -T web python manage.py shell --settings=dmoj.docker_settings -c "
from django.contrib.flatpages.models import FlatPage
from django.contrib.sites.models import Site

# Create About page if not exists
if not FlatPage.objects.filter(url='/about/').exists():
    about_page = FlatPage.objects.create(
        url='/about/',
        title='About',
        content='Welcome to DMOJ - Modern Online Judge'
    )
    about_page.sites.add(Site.objects.get_current())

# Create Custom Checkers page if not exists
if not FlatPage.objects.filter(url='/custom_checkers/').exists():
    checkers_page = FlatPage.objects.create(
        url='/custom_checkers/',
        title='Custom Checkers',
        content='Information about custom checkers for problems.'
    )
    checkers_page.sites.add(Site.objects.get_current())

print('Initial data loaded')
"
    
    print_success "Services deployed successfully"
}

# Show status and URLs
show_status() {
    print_status "Checking service status..."
    docker compose -f $COMPOSE_FILE ps
    
    echo ""
    print_success "🎉 DMOJ is now running!"
    echo ""
    echo "📍 URLs:"
    if [ "$MODE" = "local" ]; then
        echo "   Website: http://localhost:8000"
        echo "   Admin: http://localhost:8000/admin (admin/admin)"
    else
        echo "   Website: Check your SITE_FULL_URL in .env"
        echo "   Admin: {SITE_FULL_URL}/admin"
    fi
    echo ""
    echo "📊 Useful commands:"
    echo "   View logs: docker compose logs -f"
    echo "   Stop services: docker compose down"
    echo "   Restart: docker compose restart"
    echo "   Shell access: docker compose exec web bash"
    echo ""
    
    if [ "$MODE" = "production" ]; then
        print_warning "Production deployment notes:"
        echo "   - Make sure your Cloudflare tunnel points to port 8000"
        echo "   - Check that all environment variables are properly set"
        echo "   - Monitor logs for any issues: docker compose logs -f"
        echo "   - Set up regular backups for the database volume"
    fi
}

# Main execution
main() {
    echo "Starting deployment process..."
    echo ""
    
    check_dependencies
    create_directories
    setup_environment
    deploy_services
    show_status
    
    print_success "Deployment completed successfully! 🚀"
}

# Handle script arguments
case $MODE in
    local)
        print_status "Deploying for local development..."
        main
        ;;
    production)
        print_status "Deploying for production..."
        main
        ;;
    *)
        print_error "Invalid mode. Use: ./deploy.sh [local|production]"
        exit 1
        ;;
esac 