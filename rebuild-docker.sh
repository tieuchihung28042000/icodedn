#!/bin/bash
set -e

echo "===== Rebuilding DMOJ Docker containers ====="

# Kiểm tra xem có thư mục media và static không
echo "Checking directories..."
mkdir -p media static problems logs

# Backup dữ liệu hiện tại
echo "Backing up current data..."
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p backups/$timestamp
docker exec dmoj_db mysqldump -u root -p${DB_ROOT_PASSWORD:-root123} ${DB_NAME:-dmoj} > backups/$timestamp/db_backup.sql || echo "Database backup failed, continuing..."

# Stop các containers hiện tại
echo "Stopping current containers..."
docker compose down || echo "No containers to stop"

# Rebuild containers
echo "Building new containers..."
docker compose build --no-cache

# Khởi động lại hệ thống
echo "Starting containers..."
docker compose up -d

# Đợi web service khởi động
echo "Waiting for web service to start..."
sleep 30

# Kiểm tra trạng thái các containers
echo "Checking container status..."
docker compose ps

# Kiểm tra judge status
echo "Checking judge status..."
docker exec -it dmoj_web python manage.py shell -c "from judge.models import Judge; print([(j.name, j.online) for j in Judge.objects.all()])"

echo "===== Rebuild completed ====="
echo "Check https://icodedn.com/admin/judge/judge/ for judge status"
echo "If judge is not online, run: docker exec -it dmoj_web python manage.py runbridged &" 