#!/bin/bash

# Script khắc phục lỗi DMOJ Docker
echo "===== Khắc phục lỗi DMOJ Docker ====="

# Đảm bảo thư mục media tồn tại
echo "1. Đảm bảo thư mục media tồn tại"
mkdir -p media/cache media/martor media/profile_images
chmod -R 777 media

# Khởi động lại các container
echo "2. Khởi động lại các container"
docker-compose down
docker-compose up -d

# Đợi các container khởi động
echo "3. Đợi các container khởi động..."
sleep 10

# Kiểm tra trạng thái các container
echo "4. Kiểm tra trạng thái các container"
docker-compose ps

# Khởi động judge bridge trong container web
echo "5. Khởi động judge bridge trong container web"
docker exec -d dmoj_web bash -c "python manage.py runbridged --settings=dmoj.docker_settings"

# Tạo judge nếu cần
echo "6. Tạo judge nếu cần"
docker exec -d dmoj_web bash -c "python manage.py shell --settings=dmoj.docker_settings -c \"from judge.models import Judge; Judge.objects.get_or_create(name='local', auth_key='key', is_blocked=False, is_disabled=False)\""

# Kiểm tra judge status
echo "7. Kiểm tra judge status"
docker exec dmoj_web bash -c "python manage.py shell --settings=dmoj.docker_settings -c \"from judge.models import Judge; print([(j.name, j.online) for j in Judge.objects.all()])\""

# Khắc phục lỗi celery unhealthy
echo "8. Khắc phục lỗi celery unhealthy"
docker restart dmoj_celery

echo "===== Hoàn tất ====="
echo "Hãy kiểm tra https://icodedn.com/admin/judge/judge/ để xem trạng thái judge" 