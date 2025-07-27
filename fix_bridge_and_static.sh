#!/bin/bash

# Sử dụng đường dẫn hiện tại
PROJECT_ROOT=$(pwd)
echo "===== DMOJ Fix Bridge và Static Files ====="
echo "Thư mục dự án: $PROJECT_ROOT"

# 1. Sửa lỗi bridge address
echo "1. Sửa lỗi bridge address..."
SETTINGS_FILE="$PROJECT_ROOT/dmoj/docker_settings.py"

if [ -f "$SETTINGS_FILE" ]; then
    # Sao lưu file cấu hình
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
    echo "   Đã sao lưu file cấu hình gốc tại ${SETTINGS_FILE}.bak"

    # Sửa cấu hình bridge
    sed -i 's/BRIDGED_JUDGE_ADDRESS = '"'"'localhost'"'"'/BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", 9999)/g' "$SETTINGS_FILE"
    sed -i 's/BRIDGED_DJANGO_ADDRESS = '"'"'localhost'"'"'/BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", 9998)/g' "$SETTINGS_FILE"
    sed -i 's/BRIDGED_JUDGE_ADDRESS = ('"'"'localhost'"'"', 9999)/BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", 9999)/g' "$SETTINGS_FILE"
    sed -i 's/BRIDGED_DJANGO_ADDRESS = ('"'"'localhost'"'"', 9998)/BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", 9998)/g' "$SETTINGS_FILE"

    echo "   Đã cập nhật cấu hình bridge trong file $SETTINGS_FILE"
else
    echo "   CẢNH BÁO: File $SETTINGS_FILE không tồn tại"
    # Tìm kiếm file settings.py trong thư mục hiện tại
    SETTINGS_FILES=$(find "$PROJECT_ROOT" -name "settings.py" -o -name "docker_settings.py")
    if [ -n "$SETTINGS_FILES" ]; then
        echo "   Tìm thấy các file cấu hình sau:"
        echo "$SETTINGS_FILES"
        echo "   Vui lòng kiểm tra và sửa thủ công các file này."
    fi
fi

# 2. Tạo script để sửa lỗi site
echo "2. Tạo script sửa lỗi site..."
cat > "$PROJECT_ROOT/fix_django_site.py" << 'EOL'
#!/usr/bin/env python
import os
import django

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

# Import Site model
from django.contrib.sites.models import Site

# Kiểm tra xem đã có site nào chưa
sites = Site.objects.all()
if not sites.exists():
    print("Không tìm thấy site nào. Đang tạo site mặc định...")
    # Tạo site mặc định với ID=1
    site = Site.objects.create(id=1, domain='icodedn.com', name='DMOJ')
    print(f"Đã tạo site mặc định: {site.domain}")
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
EOL

echo "   Đã tạo script sửa lỗi site tại $PROJECT_ROOT/fix_django_site.py"

# 3. Tạo script để sửa lỗi static files
echo "3. Tạo script sửa lỗi static files..."
cat > "$PROJECT_ROOT/fix_static_files.py" << 'EOL'
#!/usr/bin/env python
import os
import django
import shutil
from pathlib import Path

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

from django.conf import settings

# Đường dẫn đến thư mục static
STATIC_ROOT = getattr(settings, 'STATIC_ROOT', '/app/static')
STATIC_MOUNT = '/app/static_mount'
RESOURCES_DIR = os.path.join(os.getcwd(), 'resources')

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
else:
    print(f"CẢNH BÁO: Thư mục resources không tồn tại: {RESOURCES_DIR}")

print("Hoàn tất sao chép static files.")
EOL

echo "   Đã tạo script sửa lỗi static files tại $PROJECT_ROOT/fix_static_files.py"

# 4. Cấp quyền thực thi cho các script
echo "4. Cấp quyền thực thi cho các script..."
chmod +x "$PROJECT_ROOT/fix_django_site.py"
chmod +x "$PROJECT_ROOT/fix_static_files.py"
echo "   Đã cấp quyền thực thi cho các script"

# 5. Khởi động lại web container
echo "5. Khởi động lại web container..."
docker compose restart web
echo "   Đã khởi động lại web container"

# 6. Đợi web container khởi động
echo "6. Đợi web container khởi động (10 giây)..."
sleep 10
echo "   Đã đợi đủ thời gian"

# 7. Chạy script sửa lỗi site
echo "7. Chạy script sửa lỗi site..."
docker compose cp fix_django_site.py web:/app/
docker compose exec web python /app/fix_django_site.py
echo "   Đã chạy script sửa lỗi site"

# 8. Chạy script sửa lỗi static files
echo "8. Chạy script sửa lỗi static files..."
docker compose cp fix_static_files.py web:/app/
docker compose exec web python /app/fix_static_files.py
echo "   Đã chạy script sửa lỗi static files"

# 9. Thu thập static files
echo "9. Thu thập static files..."
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
echo "   Đã thu thập static files"

# 10. Khởi động lại web service
echo "10. Khởi động lại web service..."
docker compose restart web
echo "   Đã khởi động lại web service"

echo "===== Hoàn tất! ====="
echo "Hệ thống đã được sửa lỗi. Truy cập trang web tại: http://localhost:8000 hoặc domain của bạn." 