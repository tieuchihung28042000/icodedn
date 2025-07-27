#!/bin/bash

# Dừng các container hiện tại
echo "Dừng các container hiện tại..."
docker compose down

# Xóa các volume để đảm bảo dữ liệu sạch
echo "Xóa các volume cũ..."
docker volume rm icodedncom_mysql_data icodedncom_redis_data icodedncom_static_files icodedncom_media_files icodedncom_problem_data || true

# Xây dựng lại các container
echo "Xây dựng lại các container..."
docker compose build

# Khởi động các container
echo "Khởi động các container..."
docker compose up -d

# Đợi database khởi động
echo "Đợi database khởi động hoàn tất..."
sleep 30

# Chạy migrations
echo "Chạy migrations..."
docker compose exec web python manage.py migrate

# Tạo site mặc định
echo "Tạo site mặc định..."
docker compose exec web python fix_django_site.py

# Tạo superuser nếu cần
echo "Tạo superuser..."
docker compose exec web python manage.py createsuperuser --noinput --username admin --email admin@example.com || true

# Thu thập static files
echo "Thu thập static files..."
docker compose exec web python manage.py collectstatic --noinput

# Khởi động lại web service
echo "Khởi động lại web service..."
docker compose restart web

echo "Hoàn tất! Hệ thống đã được thiết lập."
echo "Truy cập trang web tại: http://localhost:8000" 