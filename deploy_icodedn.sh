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

# 2. Dừng các container hiện tại
echo -e "\n${YELLOW}[2/12] Dừng các container hiện tại...${NC}"
docker compose down --remove-orphans
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 3. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[3/12] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 4. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[4/12] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"

# Sử dụng sudo để đảm bảo quyền truy cập
echo -e "${YELLOW}Đang cấp quyền cho các thư mục (có thể yêu cầu mật khẩu sudo)...${NC}"
sudo chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 5. Xây dựng lại các container
echo -e "\n${YELLOW}[5/12] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 6. Tạo file fix_judge_bridge.py
echo -e "\n${YELLOW}[6/12] Tạo file fix_judge_bridge.py...${NC}"
cat > "$PROJECT_ROOT/fix_judge_bridge.py" << 'EOL'
#!/usr/bin/env python3
import os
import re

# Đường dẫn đến file cấu hình
settings_path = '/app/dmoj/docker_settings.py'

print("Đang sửa lỗi bridge address trong docker_settings.py...")

# Đọc nội dung file
with open(settings_path, 'r') as f:
    content = f.read()

# Sửa BRIDGED_JUDGE_ADDRESS
content = re.sub(
    r'BRIDGED_JUDGE_ADDRESS\s*=\s*\(?\s*[\'"]localhost[\'"]\s*,\s*(\d+)\s*\)?',
    r'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", \1)',
    content
)

# Sửa BRIDGED_DJANGO_ADDRESS
content = re.sub(
    r'BRIDGED_DJANGO_ADDRESS\s*=\s*\(?\s*[\'"]localhost[\'"]\s*,\s*(\d+)\s*\)?',
    r'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", \1)',
    content
)

# Sửa DMOJ_JUDGE_SERVERS
content = re.sub(
    r'(DMOJ_JUDGE_SERVERS\s*=\s*\{[^}]*[\'"]host[\'"]\s*:\s*)[\'"]localhost[\'"]',
    r'\1"0.0.0.0"',
    content
)

# Thêm SECURE_PROXY_SSL_HEADER nếu chưa có
if 'SECURE_PROXY_SSL_HEADER' not in content:
    content += '\n# Cấu hình cho proxy\nSECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")\n'

# Ghi lại nội dung file
with open(settings_path, 'w') as f:
    f.write(content)

print("Đã sửa xong bridge address trong docker_settings.py")

# Tạo file .dmojrc cho judge
print("Đang tạo file .dmojrc cho judge...")
dmojrc_path = '/app/.dmojrc'

dmojrc_content = """[judge]
host = 0.0.0.0
port = 9999

[server]
host = icodedn.com
port = 9999
"""

with open(dmojrc_path, 'w') as f:
    f.write(dmojrc_content)

print("Đã tạo xong file .dmojrc cho judge")
print("Hoàn tất sửa lỗi bridge address")
EOL
chmod +x "$PROJECT_ROOT/fix_judge_bridge.py"

# 7. Tạo file fix_static_files.py
echo -e "\n${YELLOW}[7/12] Tạo file fix_static_files.py...${NC}"
cat > "$PROJECT_ROOT/fix_static_files.py" << 'EOL'
#!/usr/bin/env python3
import os
import shutil
import subprocess

print("Đang sửa lỗi static files...")

# Đường dẫn thư mục
resources_dir = '/app/resources'
static_dir = '/app/static'
static_mount_dir = '/app/static_mount'

# Tạo thư mục static nếu chưa tồn tại
os.makedirs(static_dir, exist_ok=True)
os.makedirs(static_mount_dir, exist_ok=True)

# Cấp quyền cho thư mục static
subprocess.run(['chmod', '-R', '777', static_dir])
subprocess.run(['chmod', '-R', '777', static_mount_dir])

# Sao chép tất cả các file từ resources sang static
print("Đang sao chép files từ resources sang static...")
for root, dirs, files in os.walk(resources_dir):
    for file in files:
        src_path = os.path.join(root, file)
        rel_path = os.path.relpath(src_path, resources_dir)
        dst_path = os.path.join(static_dir, rel_path)
        
        # Tạo thư mục đích nếu chưa tồn tại
        os.makedirs(os.path.dirname(dst_path), exist_ok=True)
        
        # Sao chép file
        try:
            shutil.copy2(src_path, dst_path)
            print(f"Đã sao chép: {rel_path}")
        except Exception as e:
            print(f"Lỗi khi sao chép {rel_path}: {e}")

# Sao chép tất cả các file từ resources sang static_mount
print("Đang sao chép files từ resources sang static_mount...")
for root, dirs, files in os.walk(resources_dir):
    for file in files:
        src_path = os.path.join(root, file)
        rel_path = os.path.relpath(src_path, resources_dir)
        dst_path = os.path.join(static_mount_dir, rel_path)
        
        # Tạo thư mục đích nếu chưa tồn tại
        os.makedirs(os.path.dirname(dst_path), exist_ok=True)
        
        # Sao chép file
        try:
            shutil.copy2(src_path, dst_path)
        except Exception as e:
            print(f"Lỗi khi sao chép {rel_path} vào static_mount: {e}")

print("Đã sao chép xong các file từ resources")
print("Hoàn tất sửa lỗi static files")
EOL
chmod +x "$PROJECT_ROOT/fix_static_files.py"

# 8. Khởi động các container
echo -e "\n${YELLOW}[8/12] Khởi động các container...${NC}"
# Chỉ khởi động DB và Redis trước
docker compose up -d db redis
echo -e "${GREEN}✓ Đã khởi động DB và Redis${NC}"

# 9. Đợi database khởi động
echo -e "\n${YELLOW}[9/12] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 10. Khởi động web container
echo -e "\n${YELLOW}[10/12] Khởi động web container và chạy migrations...${NC}"
docker compose up -d web
sleep 10
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy migrations${NC}"

# 11. Chạy các script sửa lỗi
echo -e "\n${YELLOW}[11/12] Chạy các script sửa lỗi...${NC}"
# Copy các script vào container
docker compose cp fix_judge_bridge.py web:/app/
docker compose cp fix_static_files.py web:/app/

# Chạy script sửa lỗi bridge
docker compose exec web python /app/fix_judge_bridge.py

# Chạy script sửa lỗi static files
docker compose exec web python /app/fix_static_files.py

# Tạo site mặc định
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

# Chạy collectstatic
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy các script sửa lỗi${NC}"

# 12. Khởi động lại web và khởi động các container còn lại
echo -e "\n${YELLOW}[12/12] Khởi động lại web và các container còn lại...${NC}"
docker compose restart web
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động lại các container${NC}"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! DMOJ đã được triển khai cho icodedn.com.${NC}"
echo -e "${GREEN}Truy cập trang web tại: https://icodedn.com${NC}"
echo -e "${BLUE}==================================================${NC}"

echo -e "\n${YELLOW}Lưu ý:${NC}"
echo -e "1. Nếu gặp lỗi về quyền truy cập static files, hãy chạy:"
echo -e "   ${BLUE}sudo docker compose exec web chmod -R 777 /app/static /app/static_mount${NC}"
echo -e "2. Nếu container web vẫn unhealthy, kiểm tra logs bằng:"
echo -e "   ${BLUE}docker compose logs web${NC}"
echo -e "3. Để tạo tài khoản admin, chạy:"
echo -e "   ${BLUE}docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings${NC}" 