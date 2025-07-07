#!/bin/bash

# Production deployment script for DMOJ
# This script ensures all required files are present before deployment

set -e  # Exit on any error

echo "🚀 DMOJ Production Deployment Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "Dockerfile" ] || [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: Not in DMOJ project directory${NC}"
    echo "Please run this script from the DMOJ project root directory"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Checking required files...${NC}"
if [ -f "check-docker-files.sh" ]; then
    chmod +x check-docker-files.sh
    if ! ./check-docker-files.sh; then
        echo -e "${RED}❌ Pre-deployment check failed!${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ Warning: check-docker-files.sh not found, skipping file check${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 2: Checking environment file...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ Warning: .env file not found${NC}"
    echo "Please create .env file from production.env.example:"
    echo "  cp production.env.example .env"
    echo "  nano .env  # Edit with your production settings"
    echo ""
    read -p "Continue without .env file? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}📋 Step 3: Stopping existing containers...${NC}"
docker compose down

echo ""
echo -e "${BLUE}📋 Step 4: Cleaning up old images and volumes...${NC}"
echo "This will remove old Docker images and unused volumes"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune -f
    # Don't remove volumes by default to preserve data
    # docker volume prune -f
fi

echo ""
echo -e "${BLUE}📋 Step 5: Building Docker images...${NC}"
echo "This may take several minutes..."
docker compose build --no-cache

echo ""
echo -e "${BLUE}📋 Step 6: Starting services...${NC}"
docker compose up -d

echo ""
echo -e "${BLUE}📋 Step 7: Waiting for services to be ready...${NC}"
echo "Waiting for database to be ready..."
timeout=60
counter=0
while ! docker compose exec db mysqladmin ping -h localhost --silent; do
    if [ $counter -eq $timeout ]; then
        echo -e "${RED}❌ Database failed to start within $timeout seconds${NC}"
        docker compose logs db
        exit 1
    fi
    echo "Waiting for database... ($counter/$timeout)"
    sleep 2
    ((counter++))
done

echo ""
echo -e "${BLUE}📋 Step 8: Running database migrations...${NC}"
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings

echo ""
echo -e "${BLUE}📋 Step 9: Loading initial fixtures...${NC}"
echo "Loading language fixtures..."
docker compose exec web python manage.py loaddata judge/fixtures/language_small.json --settings=dmoj.docker_settings || echo "Language fixtures already loaded or failed to load"

echo ""
echo -e "${BLUE}📋 Step 10: Collecting static files...${NC}"
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

echo ""
echo -e "${BLUE}📋 Step 11: Checking service status...${NC}"
docker compose ps

echo ""
echo -e "${BLUE}📋 Step 12: Testing web service...${NC}"
if curl -f http://localhost:8000/ >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Web service is responding${NC}"
else
    echo -e "${RED}❌ Web service is not responding${NC}"
    echo "Check logs with: docker compose logs web"
fi

echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo "======================================"
echo ""
echo "📊 Service Status:"
docker compose ps
echo ""
echo "🌐 Access your application at: http://localhost:8000"
echo ""
echo "📋 Useful commands:"
echo "  View logs:           docker compose logs -f"
echo "  View web logs:       docker compose logs web -f"
echo "  View database logs:  docker compose logs db -f"
echo "  Restart services:    docker compose restart"
echo "  Stop services:       docker compose down"
echo ""
echo "🔧 Troubleshooting:"
echo "  If services fail to start, check logs with: docker compose logs"
echo "  If database issues, try: docker compose restart db"
echo "  If static files missing, run: docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings"
echo ""
echo -e "${GREEN}✅ Deployment successful!${NC}" 