#!/bin/bash

echo "🚀 DMOJ Local Development Setup"
echo "==============================="

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

# Check Docker
print_status "Checking Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running! Please start Docker Desktop."
    exit 1
fi

print_success "Docker is ready"

# Clean up previous containers
print_status "Cleaning up previous containers..."
docker compose -f docker-compose.local.yml down --remove-orphans 2>/dev/null || true

# Build and start
print_status "Building and starting services..."
docker compose -f docker-compose.local.yml up --build

print_success "🎉 DMOJ Local is running!"
echo ""
echo "📍 Access URLs:"
echo "   Website: http://localhost:8000"
echo "   Admin: http://localhost:8000/admin (admin/admin)"
echo ""
echo "🛠️ Useful commands:"
echo "   Stop: docker compose -f docker-compose.local.yml down"
echo "   Logs: docker compose -f docker-compose.local.yml logs -f"
echo "   Shell: docker compose -f docker-compose.local.yml exec web bash" 