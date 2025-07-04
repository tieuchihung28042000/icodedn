#!/bin/bash
set -e

echo "🧹 Cleaning up Docker completely and rebuilding..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}1. Stopping all containers...${NC}"
docker compose down -v

echo -e "${YELLOW}2. Removing all containers...${NC}"
docker container prune -f

echo -e "${YELLOW}3. Removing all images...${NC}"
docker image prune -a -f

echo -e "${YELLOW}4. Removing all volumes...${NC}"
docker volume prune -f

echo -e "${YELLOW}5. Removing all networks...${NC}"
docker network prune -f

echo -e "${YELLOW}6. Removing all build cache...${NC}"
docker builder prune -a -f

echo -e "${YELLOW}7. Creating necessary directories...${NC}"
mkdir -p static media logs problems

echo -e "${YELLOW}8. Building containers from scratch...${NC}"
docker compose build --no-cache --pull

echo -e "${YELLOW}9. Starting services...${NC}"
docker compose up -d

echo -e "${YELLOW}10. Waiting for services to start...${NC}"
sleep 60

echo -e "${YELLOW}11. Checking service status...${NC}"
docker compose ps

echo -e "${YELLOW}12. Checking static files...${NC}"
ls -la static/ || echo "Static directory empty"
ls -la media/ || echo "Media directory empty"

echo -e "${YELLOW}13. Checking web service health...${NC}"
for i in {1..30}; do
    if curl -f http://localhost:8000/ >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Web service is healthy!${NC}"
        break
    fi
    echo "Waiting for web service... ($i/30)"
    sleep 5
done

echo -e "${YELLOW}14. Checking container static files...${NC}"
docker compose exec web ls -la /app/static/ | head -10

echo -e "${YELLOW}15. Checking mounted static files...${NC}"
docker compose exec web ls -la /app/static_mount/ | head -10

if [ -f static/style.css ]; then
    echo -e "${GREEN}✓ Static files are mounted correctly!${NC}"
else
    echo -e "${RED}❌ Static files not found in mounted directory${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs web --tail=20
fi

echo -e "${GREEN}🎉 Clean rebuild completed!${NC}"
echo -e "${GREEN}Website should be available at: https://icodedn.com${NC}" 