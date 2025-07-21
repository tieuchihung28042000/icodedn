#!/bin/bash

# Script to run VNOJ with Docker and mock data
# Usage: ./scripts/docker_with_mock.sh [command]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Docker compose file
COMPOSE_FILE="docker-compose.mock.yml"

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start, up       Start all services with mock data"
    echo "  stop, down      Stop all services"
    echo "  restart         Restart all services"
    echo "  build           Build Docker images"
    echo "  logs            Show logs from all services"
    echo "  logs-web        Show logs from web service only"
    echo "  logs-db         Show logs from database service only"
    echo "  shell           Open shell in web container"
    echo "  load-mock       Load mock data only (using separate service)"
    echo "  clean           Remove all containers and volumes"
    echo "  status          Show status of all services"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start        Start VNOJ with mock data"
    echo "  $0 logs-web     Show web service logs"
    echo "  $0 shell        Open shell in web container"
    echo "  $0 clean        Clean up everything"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
        exit 1
    fi
}

# Function to check if compose file exists
check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}Error: $COMPOSE_FILE not found. Please run this script from the project root.${NC}"
        exit 1
    fi
}

# Function to start services
start_services() {
    echo -e "${GREEN}🚀 Starting VNOJ with Mock Data...${NC}"
    echo -e "${YELLOW}This will:${NC}"
    echo "  - Start MySQL database"
    echo "  - Start Redis cache"
    echo "  - Build and start web application"
    echo "  - Load comprehensive mock data"
    echo "  - Start development server on http://localhost:8000"
    echo ""
    
    docker-compose -f "$COMPOSE_FILE" up -d --build
    
    echo ""
    echo -e "${GREEN}✅ Services started successfully!${NC}"
    echo ""
    echo -e "${BLUE}📋 Mock Data Summary:${NC}"
    echo -e "${YELLOW}👤 Users:${NC}"
    echo "  - admin / admin (superuser)"
    echo "  - teacher1 / password123 (teacher)"
    echo "  - student1 / password123 (student)"
    echo "  - student2 / password123 (student)"
    echo ""
    echo -e "${YELLOW}🏢 Organizations:${NC}"
    echo "  - VNOJ (public)"
    echo "  - THPT ABC (private, access code: ABC2024)"
    echo ""
    echo -e "${YELLOW}📚 Sample Problems:${NC}"
    echo "  - aplusb (A Plus B)"
    echo "  - fibonacci (Fibonacci Sequence)"
    echo "  - shortest_path (Shortest Path)"
    echo ""
    echo -e "${YELLOW}🎯 Contest:${NC}"
    echo "  - practice_contest_2024 (Practice Contest 2024)"
    echo ""
    echo -e "${GREEN}🌐 Access your VNOJ instance at: http://localhost:8000${NC}"
    echo ""
    echo -e "${YELLOW}💡 Useful commands:${NC}"
    echo "  $0 logs-web     # View web service logs"
    echo "  $0 shell        # Open shell in web container"
    echo "  $0 stop         # Stop all services"
}

# Function to stop services
stop_services() {
    echo -e "${YELLOW}🛑 Stopping VNOJ services...${NC}"
    docker-compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✅ Services stopped successfully!${NC}"
}

# Function to restart services
restart_services() {
    echo -e "${YELLOW}🔄 Restarting VNOJ services...${NC}"
    docker-compose -f "$COMPOSE_FILE" restart
    echo -e "${GREEN}✅ Services restarted successfully!${NC}"
}

# Function to build images
build_images() {
    echo -e "${YELLOW}🏗️  Building Docker images...${NC}"
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    echo -e "${GREEN}✅ Images built successfully!${NC}"
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}📋 Showing logs from all services...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs -f
}

# Function to show web logs
show_web_logs() {
    echo -e "${BLUE}📋 Showing web service logs...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs -f web
}

# Function to show database logs
show_db_logs() {
    echo -e "${BLUE}📋 Showing database service logs...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs -f db
}

# Function to open shell
open_shell() {
    echo -e "${BLUE}🐚 Opening shell in web container...${NC}"
    docker-compose -f "$COMPOSE_FILE" exec web bash
}

# Function to load mock data only
load_mock_data() {
    echo -e "${YELLOW}🎭 Loading mock data using separate service...${NC}"
    docker-compose -f "$COMPOSE_FILE" --profile tools run --rm mock-loader
    echo -e "${GREEN}✅ Mock data loaded successfully!${NC}"
}

# Function to clean up
clean_up() {
    echo -e "${YELLOW}🧹 Cleaning up containers and volumes...${NC}"
    read -p "This will remove all containers and volumes. Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
        docker system prune -f
        echo -e "${GREEN}✅ Cleanup completed!${NC}"
    else
        echo -e "${YELLOW}Cleanup cancelled.${NC}"
    fi
}

# Function to show status
show_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Main script logic
case "${1:-start}" in
    start|up)
        check_docker
        check_compose_file
        start_services
        ;;
    stop|down)
        check_docker
        check_compose_file
        stop_services
        ;;
    restart)
        check_docker
        check_compose_file
        restart_services
        ;;
    build)
        check_docker
        check_compose_file
        build_images
        ;;
    logs)
        check_docker
        check_compose_file
        show_logs
        ;;
    logs-web)
        check_docker
        check_compose_file
        show_web_logs
        ;;
    logs-db)
        check_docker
        check_compose_file
        show_db_logs
        ;;
    shell)
        check_docker
        check_compose_file
        open_shell
        ;;
    load-mock)
        check_docker
        check_compose_file
        load_mock_data
        ;;
    clean)
        check_docker
        check_compose_file
        clean_up
        ;;
    status)
        check_docker
        check_compose_file
        show_status
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac 