#!/bin/bash

# Đường dẫn đến thư mục gốc của dự án
PROJECT_ROOT="/Users/nguyencamquyen/Downloads/OJ"
cd "$PROJECT_ROOT"

echo "===== DMOJ System Fix Script ====="
echo "Thư mục dự án: $PROJECT_ROOT"

# 1. Sửa cấu hình bridge trong docker_settings.py
echo "1. Sửa cấu hình bridge..."
SETTINGS_FILE="$PROJECT_ROOT/dmoj/docker_settings.py"

# Sao lưu file cấu hình
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
echo "   Đã sao lưu file cấu hình gốc tại ${SETTINGS_FILE}.bak"

# Sửa cấu hình bridge
sed -i '' 's/BRIDGED_JUDGE_ADDRESS = ('"'"'localhost'"'"', 9999)/BRIDGED_JUDGE_ADDRESS = ('"'"'0.0.0.0'"'"', 9999)/g' "$SETTINGS_FILE"
sed -i '' 's/BRIDGED_DJANGO_ADDRESS = ('"'"'localhost'"'"', 9998)/BRIDGED_DJANGO_ADDRESS = ('"'"'0.0.0.0'"'"', 9998)/g' "$SETTINGS_FILE"

echo "   Đã cập nhật cấu hình bridge trong file $SETTINGS_FILE"

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
    site = Site.objects.create(id=1, domain='localhost:8000', name='DMOJ')
    print(f"Đã tạo site mặc định: {site.domain}")
else:
    print("Đã tồn tại site:")
    for site in sites:
        print(f"ID: {site.id}, Domain: {site.domain}, Name: {site.name}")
EOL

echo "   Đã tạo script sửa lỗi site tại $PROJECT_ROOT/fix_django_site.py"

# 3. Tạo các thư mục cần thiết
echo "3. Tạo các thư mục cần thiết..."
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo "   Đã tạo và cấp quyền cho các thư mục cần thiết"

# 4. Dừng và khởi động lại các container
echo "4. Dừng và khởi động lại các container..."
docker compose down
echo "   Đã dừng các container"

# 5. Xóa các volume để đảm bảo dữ liệu sạch
echo "5. Xóa các volume cũ..."
docker volume rm mysql_data redis_data static_files media_files problem_data || true
echo "   Đã xóa các volume cũ"

# 6. Xây dựng lại các container
echo "6. Xây dựng lại các container..."
docker compose build
echo "   Đã xây dựng lại các container"

# 7. Khởi động các container
echo "7. Khởi động các container..."
docker compose up -d
echo "   Đã khởi động các container"

# 8. Đợi database khởi động
echo "8. Đợi database khởi động hoàn tất (30 giây)..."
sleep 30
echo "   Đã đợi đủ thời gian"

# 9. Chạy migrations
echo "9. Chạy migrations..."
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings
echo "   Đã chạy migrations"

# 10. Tạo site mặc định
echo "10. Tạo site mặc định..."
docker compose cp fix_django_site.py web:/app/
docker compose exec web python /app/fix_django_site.py
echo "   Đã tạo site mặc định"

# 11. Thu thập static files
echo "11. Thu thập static files..."
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
echo "   Đã thu thập static files"

# 12. Khởi động lại web service
echo "12. Khởi động lại web service..."
docker compose restart web
echo "   Đã khởi động lại web service"

echo "===== Hoàn tất! ====="
echo "Hệ thống đã được thiết lập. Truy cập trang web tại: http://localhost:8000" 