#!/bin/bash

# Script triển khai hoàn chỉnh cho tên miền icodedn.com
# Tác giả: Claude
# Phiên bản: 1.1

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hiển thị tiêu đề
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      TRIỂN KHAI DMOJ CHO ICODEDN.COM             ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Lấy đường dẫn hiện tại
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}Thư mục dự án: ${PROJECT_ROOT}${NC}"

# 1. Tạo file .env với cấu hình cho icodedn.com
echo -e "\n${YELLOW}[1/12] Tạo file .env với cấu hình cho icodedn.com...${NC}"
cat > "$PROJECT_ROOT/.env" << 'EOL'
# Cấu hình DMOJ cho icodedn.com
DEBUG=False
SECRET_KEY=change-this-to-a-secure-key-in-production
ALLOWED_HOSTS=localhost,127.0.0.1,icodedn.com,www.icodedn.com
CSRF_TRUSTED_ORIGINS=https://icodedn.com,http://icodedn.com,https://www.icodedn.com,http://www.icodedn.com

# Database
DB_NAME=dmoj
DB_USER=dmoj
DB_PASSWORD=dmoj123
DB_ROOT_PASSWORD=root123

# Site info
SITE_NAME=iCodeDN
SITE_LONG_NAME=iCodeDN Online Judge
SITE_ADMIN_EMAIL=admin@icodedn.com
SITE_FULL_URL=https://icodedn.com
EOL
chmod 600 "$PROJECT_ROOT/.env"
echo -e "${GREEN}✓ Đã tạo file .env${NC}"

# 1.5 Tạo file .gitignore để loại bỏ các file local
echo -e "\n${YELLOW}[1.5/12] Tạo file .gitignore...${NC}"
cat > "$PROJECT_ROOT/.gitignore" << 'EOL'
# Local development files
.env
docker-compose.local.yml
docker-compose.override.yml
.idea/
.vscode/
*.pyc
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Logs and databases
*.log
*.sqlite3
*.db

# Media and static files in development
/media/
/static/
/logs/

# Docker volumes
mysql_data/
redis_data/
static_files/
media_files/
problem_data/
EOL
echo -e "${GREEN}✓ Đã tạo file .gitignore${NC}"

# 2. Dừng các container hiện tại
echo -e "\n${YELLOW}[2/12] Dừng các container hiện tại...${NC}"
docker compose down || true
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 3. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[3/12] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 4. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[4/12] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
# Sử dụng sudo để đảm bảo quyền truy cập đầy đủ
sudo chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 5. Chỉnh sửa Dockerfile để không thay đổi quyền truy cập file static
echo -e "\n${YELLOW}[5/12] Sửa Dockerfile để tránh lỗi quyền truy cập...${NC}"
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    # Tạo bản sao lưu của Dockerfile
    cp "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT/Dockerfile.bak"
    
    # Thay thế lệnh chmod -R 777 bằng lệnh không gây lỗi
    sed -i 's/RUN chmod -R 777 \/app\/media/RUN mkdir -p \/app\/media \&\& chmod -R 777 \/app\/media/g' "$PROJECT_ROOT/Dockerfile"
    
    echo -e "${GREEN}✓ Đã sửa Dockerfile${NC}"
else
    echo -e "${RED}✗ Không tìm thấy Dockerfile${NC}"
fi

# 6. Xây dựng lại các container
echo -e "\n${YELLOW}[6/12] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 7. Khởi động các container
echo -e "\n${YELLOW}[7/12] Khởi động các container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động các container${NC}"

# 8. Đợi database khởi động
echo -e "\n${YELLOW}[8/12] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 9. Kiểm tra trạng thái container
echo -e "\n${YELLOW}[9/12] Kiểm tra trạng thái container...${NC}"
docker compose ps
container_status=$(docker compose ps | grep "dmoj_web" | grep -i "unhealthy")
if [ -n "$container_status" ]; then
    echo -e "${RED}✗ Container web không khỏe mạnh. Kiểm tra logs...${NC}"
    docker compose logs web
    
    echo -e "\n${YELLOW}Thử khởi động lại container web...${NC}"
    docker compose restart web
    sleep 10
    
    # Kiểm tra lại
    container_status=$(docker compose ps | grep "dmoj_web" | grep -i "unhealthy")
    if [ -n "$container_status" ]; then
        echo -e "${RED}✗ Container web vẫn không khỏe mạnh sau khi khởi động lại.${NC}"
    else
        echo -e "${GREEN}✓ Container web đã khỏe mạnh sau khi khởi động lại${NC}"
    fi
else
    echo -e "${GREEN}✓ Tất cả container đang chạy bình thường${NC}"
fi

# 10. Tạo script sửa lỗi judge bridge
echo -e "\n${YELLOW}[10/12] Tạo script sửa lỗi judge bridge...${NC}"
cat > "$PROJECT_ROOT/fix_bridge.py" << 'EOL'
#!/usr/bin/env python3
import os
import sys

def fix_bridge_settings(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} không tồn tại!")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Sửa cấu hình bridge
    original_content = content
    
    # Sửa các định dạng khác nhau có thể gặp
    if "BRIDGED_JUDGE_ADDRESS = 'localhost'" in content:
        content = content.replace("BRIDGED_JUDGE_ADDRESS = 'localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", 9999)')
    
    if "BRIDGED_DJANGO_ADDRESS = 'localhost'" in content:
        content = content.replace("BRIDGED_DJANGO_ADDRESS = 'localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", 9998)')
    
    if "BRIDGED_JUDGE_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_JUDGE_ADDRESS = ('localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0"')
    
    if "BRIDGED_DJANGO_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_DJANGO_ADDRESS = ('localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0"')
    
    # Sửa cấu hình DMOJ_JUDGE_SERVERS
    if "'localhost': {" in content:
        content = content.replace("'localhost': {", "'0.0.0.0': {")
        
        # Cập nhật host trong cấu hình
        if "'host': 'localhost'" in content:
            content = content.replace("'host': 'localhost'", "'host': '0.0.0.0'")
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        print(f"Đã sửa cấu hình bridge trong {file_path}")
        return True
    else:
        print(f"Không cần sửa cấu hình trong {file_path}")
        return False

# Tìm và sửa tất cả các file cấu hình có thể
settings_files = [
    '/app/dmoj/docker_settings.py',
    '/app/dmoj/settings.py',
    '/app/martor/settings.py'
]

success = False
for file_path in settings_files:
    if fix_bridge_settings(file_path):
        success = True

sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/fix_bridge.py"
echo -e "${GREEN}✓ Đã tạo script sửa lỗi judge bridge${NC}"

# 11. Chạy migrations và sửa lỗi bridge
echo -e "\n${YELLOW}[11/12] Chạy migrations và sửa lỗi...${NC}"
docker compose exec -T web python manage.py migrate --settings=dmoj.docker_settings || echo "Lỗi khi chạy migrations"
docker compose cp fix_bridge.py web:/app/
docker compose exec -T web python /app/fix_bridge.py || echo "Lỗi khi sửa bridge"
echo -e "${GREEN}✓ Đã chạy migrations và sửa lỗi${NC}"

# 12. Tạo site mặc định
echo -e "\n${YELLOW}[12/12] Tạo site mặc định...${NC}"
docker compose exec -T web python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()
from django.contrib.sites.models import Site
sites = Site.objects.all()
if not sites.exists():
    Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
    print('Đã tạo site mặc định')
else:
    site = sites.first()
    site.domain = 'icodedn.com'
    site.name = 'iCodeDN'
    site.save()
    print('Đã cập nhật site mặc định')
" || echo "Lỗi khi tạo site mặc định"
echo -e "${GREEN}✓ Đã tạo site mặc định${NC}"

# Kiểm tra lại trạng thái cuối cùng
echo -e "\n${YELLOW}Kiểm tra trạng thái cuối cùng...${NC}"
docker compose ps
docker compose logs --tail=20 web

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! DMOJ đã được triển khai cho icodedn.com.${NC}"
echo -e "${GREEN}Truy cập trang web tại: https://icodedn.com${NC}"
echo -e "${BLUE}==================================================${NC}"

echo -e "\n${YELLOW}Nếu vẫn gặp lỗi, hãy thử các lệnh sau:${NC}"
echo -e "1. Kiểm tra logs: ${GREEN}docker compose logs web${NC}"
echo -e "2. Khởi động lại container: ${GREEN}docker compose restart web${NC}"
echo -e "3. Kiểm tra quyền truy cập: ${GREEN}sudo chown -R $(whoami):$(whoami) $PROJECT_ROOT/static $PROJECT_ROOT/media${NC}" 