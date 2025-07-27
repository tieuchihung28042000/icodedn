#!/bin/bash

# Script rebuild toàn bộ hệ thống DMOJ
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
echo -e "${BLUE}      REBUILD TOÀN BỘ HỆ THỐNG DMOJ              ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Lấy đường dẫn hiện tại
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}Thư mục dự án: ${PROJECT_ROOT}${NC}"

# Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[1/12] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# Tạo script để sửa lỗi bridge
echo -e "\n${YELLOW}[2/12] Tạo script sửa lỗi bridge...${NC}"
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

    # Tìm và sửa các cấu hình bridge
    if "BRIDGED_JUDGE_ADDRESS = 'localhost'" in content:
        content = content.replace("BRIDGED_JUDGE_ADDRESS = 'localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", 9999)')
    if "BRIDGED_DJANGO_ADDRESS = 'localhost'" in content:
        content = content.replace("BRIDGED_DJANGO_ADDRESS = 'localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", 9998)')
    
    if "BRIDGED_JUDGE_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_JUDGE_ADDRESS = ('localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0"')
    if "BRIDGED_DJANGO_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_DJANGO_ADDRESS = ('localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0"')
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Đã sửa cấu hình bridge trong {file_path}")
    return True

# Tìm tất cả các file settings.py và docker_settings.py
settings_files = []
for root, dirs, files in os.walk('/app'):
    for file in files:
        if file == 'settings.py' or file == 'docker_settings.py':
            settings_files.append(os.path.join(root, file))

if not settings_files:
    print("Không tìm thấy file cấu hình nào!")
    sys.exit(1)

# Sửa tất cả các file tìm được
for file_path in settings_files:
    fix_bridge_settings(file_path)
EOL
chmod +x "$PROJECT_ROOT/fix_bridge.py"
echo -e "${GREEN}✓ Đã tạo script sửa lỗi bridge${NC}"

# Tạo script để sửa lỗi site
echo -e "\n${YELLOW}[3/12] Tạo script sửa lỗi site...${NC}"
cat > "$PROJECT_ROOT/fix_site.py" << 'EOL'
#!/usr/bin/env python3
import os
import django
import sys

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

# Import Site model
from django.contrib.sites.models import Site

def create_or_update_site():
    try:
        # Kiểm tra xem đã có site nào chưa
        sites = Site.objects.all()
        if not sites.exists():
            print("Không tìm thấy site nào. Đang tạo site mặc định...")
            # Tạo site mặc định với ID=1
            site = Site.objects.create(id=1, domain='icodedn.com', name='DMOJ')
            print(f"Đã tạo site mặc định: {site.domain}")
            return True
        else:
            print("Đã tồn tại site:")
            for site in sites:
                print(f"ID: {site.id}, Domain: {site.domain}, Name: {site.name}")
                # Cập nhật domain nếu cần
                if site.domain == 'localhost:8000' or site.domain == 'example.com':
                    old_domain = site.domain
                    site.domain = 'icodedn.com'
                    site.name = 'DMOJ'
                    site.save()
                    print(f"Đã cập nhật domain từ {old_domain} thành {site.domain}")
                    return True
            return False
    except Exception as e:
        print(f"Lỗi khi tạo/cập nhật site: {str(e)}")
        return False

if __name__ == "__main__":
    success = create_or_update_site()
    sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/fix_site.py"
echo -e "${GREEN}✓ Đã tạo script sửa lỗi site${NC}"

# Tạo script để sửa lỗi static files
echo -e "\n${YELLOW}[4/12] Tạo script sửa lỗi static files...${NC}"
cat > "$PROJECT_ROOT/fix_static.py" << 'EOL'
#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

def copy_resources_to_static():
    # Đường dẫn đến thư mục static và resources
    STATIC_ROOT = '/app/static'
    STATIC_MOUNT = '/app/static_mount'
    RESOURCES_DIR = '/app/resources'

    print(f"Thư mục static: {STATIC_ROOT}")
    print(f"Thư mục resources: {RESOURCES_DIR}")

    # Kiểm tra và tạo thư mục static nếu chưa tồn tại
    os.makedirs(STATIC_ROOT, exist_ok=True)
    os.makedirs(STATIC_MOUNT, exist_ok=True)

    # Sao chép các file từ resources vào static
    if os.path.exists(RESOURCES_DIR):
        print("Đang sao chép files từ resources vào static...")
        for root, dirs, files in os.walk(RESOURCES_DIR):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, RESOURCES_DIR)
                dest_path = os.path.join(STATIC_ROOT, rel_path)
                dest_dir = os.path.dirname(dest_path)
                
                # Tạo thư mục đích nếu chưa tồn tại
                os.makedirs(dest_dir, exist_ok=True)
                
                # Sao chép file
                try:
                    shutil.copy2(src_path, dest_path)
                    print(f"Đã sao chép: {rel_path}")
                except Exception as e:
                    print(f"Lỗi khi sao chép {rel_path}: {str(e)}")
        
        # Sao chép vào static_mount
        print("Đang sao chép files từ static vào static_mount...")
        for root, dirs, files in os.walk(STATIC_ROOT):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, STATIC_ROOT)
                dest_path = os.path.join(STATIC_MOUNT, rel_path)
                dest_dir = os.path.dirname(dest_path)
                
                # Tạo thư mục đích nếu chưa tồn tại
                os.makedirs(dest_dir, exist_ok=True)
                
                # Sao chép file
                try:
                    shutil.copy2(src_path, dest_path)
                except Exception as e:
                    print(f"Lỗi khi sao chép vào static_mount {rel_path}: {str(e)}")
        
        print("Hoàn tất sao chép static files.")
        return True
    else:
        print(f"CẢNH BÁO: Thư mục resources không tồn tại: {RESOURCES_DIR}")
        return False

if __name__ == "__main__":
    success = copy_resources_to_static()
    sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/fix_static.py"
echo -e "${GREEN}✓ Đã tạo script sửa lỗi static files${NC}"

# Dừng các container hiện tại
echo -e "\n${YELLOW}[5/12] Dừng các container hiện tại...${NC}"
docker compose down
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[6/12] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# Xây dựng lại các container
echo -e "\n${YELLOW}[7/12] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# Khởi động các container
echo -e "\n${YELLOW}[8/12] Khởi động các container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động các container${NC}"

# Đợi database khởi động
echo -e "\n${YELLOW}[9/12] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# Chạy migrations
echo -e "\n${YELLOW}[10/12] Chạy migrations...${NC}"
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy migrations${NC}"

# Chạy các script sửa lỗi
echo -e "\n${YELLOW}[11/12] Chạy các script sửa lỗi...${NC}"
# Copy scripts vào container
docker compose cp fix_bridge.py web:/app/
docker compose cp fix_site.py web:/app/
docker compose cp fix_static.py web:/app/

# Chạy các script
echo "Đang chạy script sửa lỗi bridge..."
docker compose exec web python /app/fix_bridge.py

echo "Đang chạy script sửa lỗi site..."
docker compose exec web python /app/fix_site.py

echo "Đang chạy script sửa lỗi static files..."
docker compose exec web python /app/fix_static.py

# Thu thập static files
echo "Đang thu thập static files..."
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy các script sửa lỗi${NC}"

# Khởi động lại web service
echo -e "\n${YELLOW}[12/12] Khởi động lại web service...${NC}"
docker compose restart web
echo -e "${GREEN}✓ Đã khởi động lại web service${NC}"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! Hệ thống đã được rebuild.${NC}"
echo -e "${GREEN}Truy cập trang web tại: http://localhost:8000 hoặc domain của bạn.${NC}"
echo -e "${BLUE}==================================================${NC}" 