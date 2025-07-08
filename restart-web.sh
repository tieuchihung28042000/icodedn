#!/bin/bash

echo "🔄 Restarting DMOJ web container with new settings..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Step 1: Stopping web container...${NC}"
docker compose stop web

echo ""
echo -e "${BLUE}📋 Step 2: Removing web container...${NC}"
docker compose rm -f web

echo ""
echo -e "${BLUE}📋 Step 3: Starting web container with new settings...${NC}"
echo "   - ALLOWED_HOSTS: localhost,127.0.0.1,icodedn.com"
echo "   - CSRF_TRUSTED_ORIGINS: https://icodedn.com,http://icodedn.com"
docker compose up -d web

echo ""
echo -e "${BLUE}📋 Step 4: Checking web container status...${NC}"
sleep 5

if docker compose ps web | grep -q "Up"; then
    echo -e "${GREEN}✅ Web container is running${NC}"
else
    echo -e "${RED}❌ Web container failed to start${NC}"
    echo "Check logs with: docker compose logs web"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Step 5: Testing web service...${NC}"
echo "Waiting for web service to be ready..."
sleep 10

if curl -f http://localhost:8000/ >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Web service is responding${NC}"
else
    echo -e "${YELLOW}⚠ Web service may still be starting...${NC}"
    echo "Check logs with: docker compose logs web"
fi

echo ""
echo -e "${GREEN}🎉 Web container restart completed!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}👤 Admin Login:${NC}"
echo "  🌐 URL: https://icodedn.com/accounts/login/"
echo "  👤 Username: admin"
echo "  🔑 Password: @654321"
echo "  🔗 Admin Panel: https://icodedn.com/admin/"
echo ""
echo "📋 Useful commands:"
echo "  View web logs: docker compose logs web -f"
echo "  Check status:  docker compose ps" 