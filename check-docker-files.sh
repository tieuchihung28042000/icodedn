#!/bin/bash

echo "🔍 Kiểm tra các file cần thiết cho Docker build..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 - OK"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ] && [ "$(ls -A "$1" 2>/dev/null)" ]; then
        echo -e "${GREEN}✓${NC} $1 - OK ($(ls -1 "$1" | wc -l) files)"
        return 0
    else
        echo -e "${RED}✗${NC} $1 - MISSING or EMPTY"
        return 1
    fi
}

check_optional_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1 - OK"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $1 - OPTIONAL (missing)"
        return 0
    fi
}

error_count=0

echo ""
echo "📋 Kiểm tra files cấu hình Docker..."
check_file "Dockerfile" || ((error_count++))
check_file "docker-compose.yml" || ((error_count++))
check_file ".dockerignore" || ((error_count++))
check_optional_file "docker-compose.local.yml"

echo ""
echo "🐍 Kiểm tra Python dependencies..."
check_file "requirements.txt" || ((error_count++))
check_file "additional_requirements.txt" || ((error_count++))
check_file "manage.py" || ((error_count++))

echo ""
echo "🌐 Kiểm tra Node.js dependencies..."
check_file "package.json" || ((error_count++))
check_file "package-lock.json" || ((error_count++))

echo ""
echo "🎨 Kiểm tra static assets..."
check_file "make_style.sh" || ((error_count++))
check_dir "resources/libs" || ((error_count++))
check_dir "resources/vnoj" || ((error_count++))
check_dir "resources" || ((error_count++))

echo ""
echo "⚙️ Kiểm tra Django settings..."
check_file "dmoj/settings.py" || ((error_count++))
check_file "dmoj/docker_settings.py" || ((error_count++))
check_file "dmoj/urls.py" || ((error_count++))
check_file "dmoj/wsgi.py" || ((error_count++))

echo ""
echo "🗄️ Kiểm tra database setup..."
check_file "docker/mysql-init.sql" || ((error_count++))
check_file "judge/fixtures/language_small.json" || ((error_count++))
check_optional_file "judge/fixtures/demo.json"
check_optional_file "production.env.example"
check_optional_file "init-fixtures.sh"

echo ""
echo "📁 Kiểm tra thư mục cần thiết..."
check_dir "judge" || ((error_count++))
check_dir "templates" || ((error_count++))
check_dir "locale" || ((error_count++))
check_dir "judge/fixtures" || ((error_count++))

echo ""
echo "🔧 Kiểm tra git submodules..."
if [ -f ".gitmodules" ]; then
    echo -e "${GREEN}✓${NC} .gitmodules - OK"
    
    # Check submodule status
    if command -v git >/dev/null 2>&1; then
        echo "Git submodule status:"
        git submodule status 2>/dev/null || echo "Cannot check git submodule status"
    fi
else
    echo -e "${RED}✗${NC} .gitmodules - MISSING"
    ((error_count++))
fi

echo ""
echo "📊 Tổng kết kiểm tra:"
if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}✅ Tất cả file cần thiết đã sẵn sàng cho Docker build!${NC}"
    echo ""
    echo "🚀 Bạn có thể build Docker image với lệnh:"
    echo "   docker compose build --no-cache"
    echo ""
    echo "📋 Hoặc build và chạy:"
    echo "   docker compose up --build -d"
    exit 0
else
    echo -e "${RED}❌ Có $error_count file/thư mục bị thiếu hoặc có vấn đề!${NC}"
    echo ""
    echo "🔧 Vui lòng kiểm tra và khắc phục các vấn đề trên trước khi build Docker image."
    exit 1
fi 