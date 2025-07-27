#!/bin/bash

# Script triển khai hoàn chỉnh cho tên miền icodedn.com
# Tác giả: Claude
# Phiên bản: 1.0

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

# 2. Dừng các container hiện tại
echo -e "\n${YELLOW}[2/12] Dừng các container hiện tại...${NC}"
docker compose down
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 3. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[3/12] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 4. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[4/12] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 5. Xây dựng lại các container
echo -e "\n${YELLOW}[5/12] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 6. Khởi động các container
echo -e "\n${YELLOW}[6/12] Khởi động các container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động các container${NC}"

# 7. Đợi database khởi động
echo -e "\n${YELLOW}[7/12] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 8. Chạy migrations
echo -e "\n${YELLOW}[8/12] Chạy migrations...${NC}"
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy migrations${NC}"

# 9. Copy các script sửa lỗi vào container
echo -e "\n${YELLOW}[9/12] Copy các script sửa lỗi vào container...${NC}"
docker compose cp fix_judge_bridge.py web:/app/
docker compose cp fix_static_files.py web:/app/
echo -e "${GREEN}✓ Đã copy các script vào container${NC}"

# 10. Chạy script sửa lỗi judge bridge
echo -e "\n${YELLOW}[10/12] Chạy script sửa lỗi judge bridge...${NC}"
docker compose exec web python /app/fix_judge_bridge.py
echo -e "${GREEN}✓ Đã chạy script sửa lỗi judge bridge${NC}"

# 11. Chạy script sửa lỗi static files
echo -e "\n${YELLOW}[11/12] Chạy script sửa lỗi static files...${NC}"
docker compose exec web python /app/fix_static_files.py
echo -e "${GREEN}✓ Đã chạy script sửa lỗi static files${NC}"

# 12. Tạo site mặc định
echo -e "\n${YELLOW}[12/12] Tạo site mặc định...${NC}"
docker compose exec web python -c "
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
"
echo -e "${GREEN}✓ Đã tạo site mặc định${NC}"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! DMOJ đã được triển khai cho icodedn.com.${NC}"
echo -e "${GREEN}Truy cập trang web thông qua Cloudflared tunnel tại: https://icodedn.com${NC}"
echo -e "${BLUE}==================================================${NC}"

echo -e "\n${YELLOW}Lưu ý về Cloudflared:${NC}"
echo -e "1. Đảm bảo Cloudflared tunnel đã được cấu hình đúng để trỏ đến cổng 8000 của container web"
echo -e "2. Kiểm tra file cấu hình Cloudflared tunnel (thường ở ~/.cloudflared/config.yml)"
echo -e "3. Cấu hình Cloudflared tunnel nên có dạng:"
echo -e "   url: http://localhost:8000"
echo -e "   hostname: icodedn.com" 