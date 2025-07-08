#!/bin/bash

echo "🔄 Rebuilding DMOJ Docker with CSS fixes..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Step 1: Stopping existing containers...${NC}"
docker compose down

echo ""
echo -e "${BLUE}📋 Step 2: Rebuilding with CSS fixes...${NC}"
echo "   - Installing all npm dependencies (including dev dependencies)"
echo "   - Building CSS with sass and autoprefixer"
echo "   - This may take a few minutes..."
docker compose up --build -d

echo ""
echo -e "${BLUE}📋 Step 3: Checking build status...${NC}"
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Docker containers are running${NC}"
else
    echo -e "${RED}❌ Some containers failed to start${NC}"
    echo "Check logs with: docker compose logs"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Step 4: Testing web service...${NC}"
echo "Waiting for web service to be ready..."
sleep 10

if curl -f http://localhost:8000/ >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Web service is responding${NC}"
else
    echo -e "${YELLOW}⚠ Web service may still be starting...${NC}"
    echo "Check logs with: docker compose logs web"
fi

echo ""
echo -e "${GREEN}🎉 Rebuild completed!${NC}"
echo "======================================"
echo ""
echo -e "${BLUE}👤 Admin Account:${NC}"
echo "  🌐 URL: http://localhost:8000"
echo "  👤 Username: admin"
echo "  🔑 Password: @654321"
echo "  🔗 Admin Panel: http://localhost:8000/admin/"
echo ""
echo "📋 Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  View web logs: docker compose logs web -f"
echo "  Stop services: docker compose down" 