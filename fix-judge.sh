#!/bin/bash
set -e

echo "===== Fixing DMOJ Judge Issues ====="

# Kiểm tra thư mục media
echo "Checking media directory..."
if [ ! -d "media" ]; then
  echo "Creating media directory..."
  mkdir -p media
fi

# Restart celery container (unhealthy)
echo "Restarting celery container..."
docker restart dmoj_celery

# Kiểm tra và tạo thư mục media trong container
echo "Setting up media directory in container..."
docker exec -it dmoj_web bash -c "mkdir -p /app/media/cache && chmod -R 777 /app/media"

# Thu thập static files
echo "Collecting static files..."
docker exec -it dmoj_web bash -c "python manage.py collectstatic --noinput"

# Kiểm tra judge status
echo "Checking judge status..."
docker exec -it dmoj_web bash -c "python manage.py shell -c \"from judge.models import Judge; print([(j.name, j.online) for j in Judge.objects.all()])\""

# Tạo judge nếu không có
echo "Creating judge if not exists..."
docker exec -it dmoj_web bash -c "python manage.py shell -c \"from judge.models import Judge; Judge.objects.get_or_create(name='judge1', defaults={'auth_key': 'judge_key', 'description': 'Default judge'})\""

# Khởi động judge bridge
echo "Starting judge bridge..."
docker exec -d dmoj_web bash -c "python manage.py runbridged &"

# Kiểm tra lại judge status
echo "Checking judge status again..."
sleep 5
docker exec -it dmoj_web bash -c "python manage.py shell -c \"from judge.models import Judge; print([(j.name, j.online) for j in Judge.objects.all()])\""

echo "===== Fix completed ====="
echo "Check https://icodedn.com/admin/judge/judge/ for judge status" 