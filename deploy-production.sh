#!/bin/bash
set -e

echo "🚀 Deploying DMOJ to production..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Warning: .env file not found. Creating from production.env.example...${NC}"
    if [ -f production.env.example ]; then
        cp production.env.example .env
        echo -e "${GREEN}✓ Created .env from production.env.example${NC}"
        echo -e "${YELLOW}Please edit .env file with your settings before continuing!${NC}"
        exit 1
    else
        echo -e "${RED}Error: production.env.example not found!${NC}"
        exit 1
    fi
fi

# Stop existing containers
echo -e "${YELLOW}Stopping existing containers...${NC}"
docker compose down

# Remove old volumes (optional - uncomment if needed)
# echo -e "${YELLOW}Cleaning up old volumes...${NC}"
# docker volume prune -f

# Build with no cache to ensure fresh build
echo -e "${YELLOW}Building containers with fresh assets...${NC}"
docker compose build --no-cache

# Start services
echo -e "${YELLOW}Starting services...${NC}"
docker compose up -d

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 30

# Check service status
echo -e "${YELLOW}Checking service status...${NC}"
docker compose ps

# Check web service health
echo -e "${YELLOW}Checking web service health...${NC}"
for i in {1..30}; do
    if curl -f http://localhost:8000/ >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Web service is healthy!${NC}"
        break
    fi
    echo "Waiting for web service... ($i/30)"
    sleep 5
done

# Show logs if service is not healthy
if ! curl -f http://localhost:8000/ >/dev/null 2>&1; then
    echo -e "${RED}❌ Web service is not responding. Showing logs:${NC}"
    docker compose logs web --tail=50
    exit 1
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}Website should be available at: https://icodedn.com${NC}"
echo ""
echo "Useful commands:"
echo "  docker compose logs web -f    # View web logs"
echo "  docker compose ps             # Check service status"
echo "  docker compose restart web    # Restart web service"
echo "  docker compose down           # Stop all services" 