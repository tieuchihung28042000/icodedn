#!/bin/bash

# Dừng các container hiện tại
echo "Dừng các container hiện tại..."
docker compose down

# Xóa các volume để đảm bảo dữ liệu sạch
echo "Xóa các volume cũ..."
docker volume rm mysql_data redis_data static_files media_files problem_data || true

# Tạo file sửa lỗi site
echo "Tạo file sửa lỗi site..."
cat > fix_django_site.py << 'EOL'
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

# Tạo thư mục cần thiết
echo "Tạo các thư mục cần thiết..."
mkdir -p logs static media problems

# Cập nhật quyền cho các thư mục
echo "Cập nhật quyền cho các thư mục..."
chmod -R 777 logs static media problems

# Xây dựng lại các container
echo "Xây dựng lại các container..."
docker compose build

# Khởi động các container
echo "Khởi động các container..."
docker compose up -d

# Đợi database khởi động
echo "Đợi database khởi động hoàn tất (30 giây)..."
sleep 30

# Chạy migrations
echo "Chạy migrations..."
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings

# Tạo site mặc định
echo "Tạo site mặc định..."
docker compose cp fix_django_site.py web:/app/
docker compose exec web python /app/fix_django_site.py

# Thu thập static files
echo "Thu thập static files..."
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Khởi động lại web service
echo "Khởi động lại web service..."
docker compose restart web

echo "Hoàn tất! Hệ thống đã được thiết lập."
echo "Truy cập trang web tại: http://localhost:8000" 