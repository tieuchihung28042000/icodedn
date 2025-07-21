#!/bin/bash

# Script to load mock data for VNOJ system
# Usage: ./scripts/load_mock_data.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CLEAR_DATA=false
LANGUAGES_ONLY=false
BASIC_ONLY=false
MIGRATE=true

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -c, --clear         Clear existing data before loading"
    echo "  -l, --languages     Load only language fixtures"
    echo "  -b, --basic         Load only basic fixtures (users, organizations, problems)"
    echo "  -n, --no-migrate    Skip database migrations"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  Load all mock data"
    echo "  $0 -c               Clear existing data and load all mock data"
    echo "  $0 -l               Load only language fixtures"
    echo "  $0 -b               Load only basic fixtures"
    echo "  $0 -c -b            Clear data and load basic fixtures"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clear)
            CLEAR_DATA=true
            shift
            ;;
        -l|--languages)
            LANGUAGES_ONLY=true
            shift
            ;;
        -b|--basic)
            BASIC_ONLY=true
            shift
            ;;
        -n|--no-migrate)
            MIGRATE=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Check if manage.py exists
if [ ! -f "manage.py" ]; then
    echo -e "${RED}Error: manage.py not found. Please run this script from the project root.${NC}"
    exit 1
fi

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ] && [ -z "$CONDA_DEFAULT_ENV" ]; then
    echo -e "${YELLOW}Warning: No virtual environment detected. Make sure you have activated your virtual environment.${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}Starting VNOJ mock data loading...${NC}"

# Run migrations if requested
if [ "$MIGRATE" = true ]; then
    echo -e "${YELLOW}Running database migrations...${NC}"
    python manage.py migrate
fi

# Build command arguments
CMD_ARGS=""
if [ "$CLEAR_DATA" = true ]; then
    CMD_ARGS="$CMD_ARGS --clear"
fi
if [ "$LANGUAGES_ONLY" = true ]; then
    CMD_ARGS="$CMD_ARGS --languages-only"
fi
if [ "$BASIC_ONLY" = true ]; then
    CMD_ARGS="$CMD_ARGS --basic-only"
fi

# Load mock data
echo -e "${YELLOW}Loading mock data...${NC}"
python manage.py load_mock_data $CMD_ARGS

echo -e "${GREEN}Mock data loaded successfully!${NC}"
echo ""
echo -e "${YELLOW}Default users created:${NC}"
echo "  - admin/admin (superuser)"
echo "  - teacher1/password123 (teacher)"
echo "  - student1/password123 (student)"
echo "  - student2/password123 (student)"
echo ""
echo -e "${YELLOW}Sample organizations:${NC}"
echo "  - VNOJ (public)"
echo "  - THPT ABC (private, access code: ABC2024)"
echo ""
echo -e "${YELLOW}Sample problems:${NC}"
echo "  - aplusb (A Plus B)"
echo "  - fibonacci (Dãy Fibonacci)"
echo "  - shortest_path (Đường đi ngắn nhất)"
echo ""
echo -e "${GREEN}You can now start the development server with:${NC}"
echo "  python manage.py runserver" 