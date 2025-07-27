#!/bin/bash

# Script triển khai hoàn chỉnh cho tên miền icodedn.com
# Phiên bản: 2.0

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
echo -e "\n${YELLOW}[1/10] Tạo file .env với cấu hình cho icodedn.com...${NC}"
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
echo -e "\n${YELLOW}[2/10] Dừng các container hiện tại...${NC}"
docker compose down --remove-orphans
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 3. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[3/10] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 4. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[4/10] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"

# Sử dụng sudo để đảm bảo quyền truy cập
echo -e "${YELLOW}Đang cấp quyền cho các thư mục (có thể yêu cầu mật khẩu sudo)...${NC}"
sudo chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 5. Sửa file docker_settings.py trước khi build
echo -e "\n${YELLOW}[5/10] Sửa file docker_settings.py...${NC}"
cat > "$PROJECT_ROOT/fix_settings.py" << 'EOL'
#!/usr/bin/env python3
import os
import re

# Đường dẫn đến file cấu hình
settings_path = 'dmoj/docker_settings.py'

print("Đang sửa cấu hình trong docker_settings.py...")

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

# Thêm STATICFILES_FINDERS nếu chưa có
if 'STATICFILES_FINDERS' not in content:
    finders = """
# Cấu hình cho compressor
STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
    'compressor.finders.CompressorFinder',
)
"""
    content += finders

# Ghi lại nội dung file
with open(settings_path, 'w') as f:
    f.write(content)

print("Đã sửa xong cấu hình trong docker_settings.py")
EOL
chmod +x "$PROJECT_ROOT/fix_settings.py"
python3 "$PROJECT_ROOT/fix_settings.py"
echo -e "${GREEN}✓ Đã sửa file docker_settings.py${NC}"

# 6. Xây dựng lại các container
echo -e "\n${YELLOW}[6/10] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 7. Khởi động các container cơ sở dữ liệu
echo -e "\n${YELLOW}[7/10] Khởi động DB và Redis...${NC}"
docker compose up -d db redis
echo -e "${GREEN}✓ Đã khởi động DB và Redis${NC}"

# 8. Đợi database khởi động
echo -e "\n${YELLOW}[8/10] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 9. Tạo script sửa lỗi trong container
echo -e "\n${YELLOW}[9/10] Chuẩn bị script sửa lỗi...${NC}"

# Script sửa lỗi bridge
cat > "$PROJECT_ROOT/fix_container.py" << 'EOL'
#!/usr/bin/env python3
import os
import sys
import re
import shutil
import subprocess
import django
from pathlib import Path

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

def fix_bridge_address():
    """Sửa lỗi bridge address"""
    print("Đang sửa lỗi bridge address...")
    
    # Đường dẫn đến file cấu hình
    settings_path = '/app/dmoj/docker_settings.py'
    
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
    
    # Thêm STATICFILES_FINDERS nếu chưa có
    if 'STATICFILES_FINDERS' not in content:
        finders = """
# Cấu hình cho compressor
STATICFILES_FINDERS = (
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
    'compressor.finders.CompressorFinder',
)
"""
        content += finders
    
    # Ghi lại nội dung file
    with open(settings_path, 'w') as f:
        f.write(content)
    
    print("Đã sửa xong bridge address")
    
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

def fix_static_files():
    """Sửa lỗi static files"""
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

def fix_django_site():
    """Tạo hoặc cập nhật site mặc định"""
    print("Đang tạo/cập nhật site mặc định...")
    
    from django.contrib.sites.models import Site
    
    try:
        site = Site.objects.get(id=1)
        site.domain = 'icodedn.com'
        site.name = 'iCodeDN'
        site.save()
        print("Đã cập nhật site mặc định")
    except Site.DoesNotExist:
        Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
        print("Đã tạo site mặc định")

if __name__ == "__main__":
    try:
        fix_bridge_address()
        fix_static_files()
        fix_django_site()
        print("Đã hoàn tất tất cả các sửa lỗi!")
    except Exception as e:
        print(f"Có lỗi xảy ra: {str(e)}")
        sys.exit(1)
EOL
chmod +x "$PROJECT_ROOT/fix_container.py"
echo -e "${GREEN}✓ Đã chuẩn bị script sửa lỗi${NC}"

# 10. Khởi động web container và chạy sửa lỗi
echo -e "\n${YELLOW}[10/10] Khởi động web container và sửa lỗi...${NC}"
docker compose up -d web
sleep 10

# Chạy migrations
echo -e "${YELLOW}Đang chạy migrations...${NC}"
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings

# Copy và chạy script sửa lỗi
echo -e "${YELLOW}Đang chạy script sửa lỗi...${NC}"
docker compose cp fix_container.py web:/app/
docker compose exec web python /app/fix_container.py

# Chạy collectstatic
echo -e "${YELLOW}Đang chạy collectstatic...${NC}"
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Khởi động lại web và khởi động các container còn lại
echo -e "${YELLOW}Đang khởi động lại các container...${NC}"
docker compose restart web
sleep 5
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
echo -e "3. Nếu vẫn gặp lỗi với Django Site, hãy chạy:"
echo -e "   ${BLUE}docker compose exec web python -c \"from django.contrib.sites.models import Site; Site.objects.filter(id=1).delete(); Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')\"${NC}"
echo -e "4. Để tạo tài khoản admin, chạy:"
echo -e "   ${BLUE}docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings${NC}" 