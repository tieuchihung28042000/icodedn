#!/bin/bash

echo "🔐 Fixing DMOJ Login Issue - Rebuilding Docker..."
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Step 1: Stopping all containers...${NC}"
docker compose down

echo ""
echo -e "${BLUE}📋 Step 2: Rebuilding web image with login fix...${NC}"
echo "   - ALLOWED_HOSTS: localhost,127.0.0.1,icodedn.com"
echo "   - CSRF_TRUSTED_ORIGINS: https://icodedn.com,http://icodedn.com"
echo "   - This may take a few minutes..."
docker compose build --no-cache web

echo ""
echo -e "${BLUE}📋 Step 3: Starting all services...${NC}"
docker compose up -d

echo ""
echo -e "${BLUE}📋 Step 4: Waiting for services to be ready...${NC}"
echo "Waiting for database to be ready..."
sleep 15

# Check if containers are running
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Containers are running${NC}"
else
    echo -e "${RED}❌ Some containers failed to start${NC}"
    echo "Check logs with: docker compose logs"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Step 5: Testing web service...${NC}"
echo "Waiting for web service to be ready..."
sleep 10

# Test if web service is responding
if curl -f http://localhost:8000/ >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Web service is responding${NC}"
else
    echo -e "${YELLOW}⚠ Web service may still be starting...${NC}"
    echo "Check logs with: docker compose logs web"
fi

echo ""
echo -e "${BLUE}📋 Step 6: Checking for CSRF errors...${NC}"
echo "Checking recent logs for CSRF errors..."
if docker compose logs web --tail=20 | grep -i "origin checking failed"; then
    echo -e "${RED}❌ CSRF errors still present${NC}"
    echo "Please check the logs for more details"
else
    echo -e "${GREEN}✅ No CSRF errors found in recent logs${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Login fix rebuild completed!${NC}"
echo "================================================="
echo ""
echo -e "${BLUE}👤 Admin Login Information:${NC}"
echo "  🌐 URL: https://icodedn.com/accounts/login/"
echo "  👤 Username: admin"
echo "  🔑 Password: @654321"
echo "  🔗 Admin Panel: https://icodedn.com/admin/"
echo ""
echo "🔧 If login still fails:"
echo "  1. Check logs: docker compose logs web -f"
echo "  2. Verify settings: docker compose exec web python manage.py shell --settings=dmoj.docker_settings -c \"from django.conf import settings; print('ALLOWED_HOSTS:', settings.ALLOWED_HOSTS); print('CSRF_TRUSTED_ORIGINS:', settings.CSRF_TRUSTED_ORIGINS)\""
echo "  3. Clear browser cache and cookies"
echo ""
echo "📋 Useful commands:"
echo "  View all logs:  docker compose logs -f"
echo "  View web logs:  docker compose logs web -f"
echo "  Check status:   docker compose ps" 