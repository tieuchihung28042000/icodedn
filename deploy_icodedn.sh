#!/bin/bash

# Script triển khai hoàn chỉnh cho tên miền icodedn.com
# Tác giả: Claude
# Phiên bản: 1.2

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
echo -e "\n${YELLOW}[1/13] Tạo file .env với cấu hình cho icodedn.com...${NC}"
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

# 2. Tạo file .gitignore để loại bỏ các file local
echo -e "\n${YELLOW}[2/13] Tạo file .gitignore...${NC}"
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

# 3. Dừng các container hiện tại
echo -e "\n${YELLOW}[3/13] Dừng các container hiện tại...${NC}"
docker compose down || true
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 4. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[4/13] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 5. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[5/13] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
# Sử dụng sudo để đảm bảo quyền truy cập đầy đủ
sudo chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 6. Tạo file cấu hình Django để sửa lỗi compressor
echo -e "\n${YELLOW}[6/13] Tạo file cấu hình Django để sửa lỗi compressor...${NC}"
cat > "$PROJECT_ROOT/fix_settings.py" << 'EOL'
#!/usr/bin/env python3
import os
import sys
import re

def fix_settings(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} không tồn tại!")
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Sửa cấu hình bridge
    original_content = content
    
    # Thêm CompressorFinder vào STATICFILES_FINDERS nếu chưa có
    if "STATICFILES_FINDERS" in content and "CompressorFinder" not in content:
        pattern = r"(STATICFILES_FINDERS\s*=\s*\[\s*['\"]django\.contrib\.staticfiles\.finders\.FileSystemFinder['\"]\s*,\s*['\"]django\.contrib\.staticfiles\.finders\.AppDirectoriesFinder['\"]\s*)"
        replacement = r"\1, 'compressor.finders.CompressorFinder'"
        content = re.sub(pattern, replacement, content)
    
    # Sửa cấu hình bridge
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
        print(f"Đã sửa cấu hình trong {file_path}")
        return True
    else:
        print(f"Không cần sửa cấu hình trong {file_path}")
        return False

# Tìm và sửa tất cả các file cấu hình có thể
settings_files = [
    '/app/dmoj/docker_settings.py',
    '/app/dmoj/settings.py'
]

success = False
for file_path in settings_files:
    if fix_settings(file_path):
        success = True

sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/fix_settings.py"
echo -e "${GREEN}✓ Đã tạo file cấu hình Django${NC}"

# 7. Tạo script để tạo site
echo -e "\n${YELLOW}[7/13] Tạo script để tạo site...${NC}"
cat > "$PROJECT_ROOT/create_site.py" << 'EOL'
#!/usr/bin/env python3
import os
import django
import sys

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

# Import các model cần thiết
from django.contrib.sites.models import Site
from django.db import connection

def create_site():
    # Kiểm tra xem bảng django_site đã tồn tại chưa
    with connection.cursor() as cursor:
        cursor.execute("SHOW TABLES LIKE 'django_site'")
        table_exists = cursor.fetchone()
        
        if not table_exists:
            print("Bảng django_site chưa tồn tại, đang tạo...")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS django_site (
                    id int(11) NOT NULL AUTO_INCREMENT,
                    domain varchar(100) NOT NULL,
                    name varchar(50) NOT NULL,
                    PRIMARY KEY (id),
                    UNIQUE KEY django_site_domain_a2e37b91_uniq (domain)
                )
            """)
            print("Đã tạo bảng django_site")
    
    # Kiểm tra xem đã có site nào chưa
    try:
        sites = Site.objects.all()
        if not sites.exists():
            site = Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
            print(f"Đã tạo site mặc định: {site.domain}")
        else:
            # Cập nhật site đầu tiên
            site = sites.first()
            site.domain = 'icodedn.com'
            site.name = 'iCodeDN'
            site.save()
            print(f"Đã cập nhật site mặc định: {site.domain}")
    except Exception as e:
        print(f"Lỗi khi tạo/cập nhật site: {e}")
        # Thử tạo site bằng SQL thuần túy
        try:
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM django_site WHERE id=1")
                cursor.execute("INSERT INTO django_site (id, domain, name) VALUES (1, 'icodedn.com', 'iCodeDN')")
                print("Đã tạo site mặc định bằng SQL")
        except Exception as e2:
            print(f"Lỗi khi tạo site bằng SQL: {e2}")
            return False
    
    return True

if __name__ == "__main__":
    success = create_site()
    sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/create_site.py"
echo -e "${GREEN}✓ Đã tạo script tạo site${NC}"

# 8. Sửa Dockerfile để tránh lỗi quyền truy cập
echo -e "\n${YELLOW}[8/13] Sửa Dockerfile để tránh lỗi quyền truy cập...${NC}"
if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
    # Tạo bản sao lưu của Dockerfile
    cp "$PROJECT_ROOT/Dockerfile" "$PROJECT_ROOT/Dockerfile.bak"
    
    # Thay thế lệnh chmod -R 777 bằng lệnh không gây lỗi
    sed -i 's/RUN chmod -R 777 \/app\/media/RUN mkdir -p \/app\/media \&\& chmod -R 777 \/app\/media/g' "$PROJECT_ROOT/Dockerfile"
    
    echo -e "${GREEN}✓ Đã sửa Dockerfile${NC}"
else
    echo -e "${RED}✗ Không tìm thấy Dockerfile${NC}"
fi

# 9. Xây dựng lại các container
echo -e "\n${YELLOW}[9/13] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 10. Khởi động các container
echo -e "\n${YELLOW}[10/13] Khởi động các container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động các container${NC}"

# 11. Đợi database khởi động
echo -e "\n${YELLOW}[11/13] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 12. Chạy migrations và sửa lỗi
echo -e "\n${YELLOW}[12/13] Chạy migrations và sửa lỗi...${NC}"
# Chạy migrations
docker compose exec -T web python manage.py migrate --settings=dmoj.docker_settings || echo "Lỗi khi chạy migrations"

# Sửa lỗi compressor và bridge
docker compose cp fix_settings.py web:/app/
docker compose exec -T web python /app/fix_settings.py || echo "Lỗi khi sửa cấu hình"

# Tạo site mặc định
docker compose cp create_site.py web:/app/
docker compose exec -T web python /app/create_site.py || echo "Lỗi khi tạo site"

# Chạy collectstatic
docker compose exec -T web python manage.py collectstatic --noinput --settings=dmoj.docker_settings || echo "Lỗi khi chạy collectstatic"

echo -e "${GREEN}✓ Đã chạy migrations và sửa lỗi${NC}"

# 13. Khởi động lại container web
echo -e "\n${YELLOW}[13/13] Khởi động lại container web...${NC}"
docker compose restart web
echo -e "${GREEN}✓ Đã khởi động lại container web${NC}"

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
echo -e "4. Tạo site thủ công: ${GREEN}docker compose exec web python -c \"from django.contrib.sites.models import Site; Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')\"${NC}"
echo -e "5. Sửa lỗi compressor: ${GREEN}docker compose exec web python -c \"import re; from django.conf import settings; print('CompressorFinder' in settings.STATICFILES_FINDERS)\"${NC}" 