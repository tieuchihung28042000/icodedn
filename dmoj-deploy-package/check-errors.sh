#!/bin/bash

# Script kiểm tra lỗi DMOJ
echo "===== Kiểm tra lỗi DMOJ ====="

# Kiểm tra trạng thái containers
echo "1. Kiểm tra trạng thái containers..."
if command -v docker-compose &> /dev/null; then
    docker-compose ps
elif command -v docker &> /dev/null; then
    docker compose ps
else
    echo "❌ Không tìm thấy Docker Compose"
    exit 1
fi

# Kiểm tra logs
echo ""
echo "2. Kiểm tra logs web container..."
if command -v docker-compose &> /dev/null; then
    docker-compose logs --tail=50 web | grep -i "error\|exception\|failed"
elif command -v docker &> /dev/null; then
    docker compose logs --tail=50 web | grep -i "error\|exception\|failed"
fi

echo ""
echo "3. Kiểm tra logs celery container..."
if command -v docker-compose &> /dev/null; then
    docker-compose logs --tail=50 celery | grep -i "error\|exception\|failed"
elif command -v docker &> /dev/null; then
    docker compose logs --tail=50 celery | grep -i "error\|exception\|failed"
fi

echo ""
echo "4. Kiểm tra logs judge container..."
if command -v docker-compose &> /dev/null; then
    docker-compose logs --tail=50 judge | grep -i "error\|exception\|failed"
elif command -v docker &> /dev/null; then
    docker compose logs --tail=50 judge | grep -i "error\|exception\|failed"
fi

# Kiểm tra kết nối
echo ""
echo "5. Kiểm tra kết nối web..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/

echo ""
echo "6. Kiểm tra judge status..."
if command -v docker-compose &> /dev/null; then
    docker-compose exec web python -c "from judge.models import Judge; print('Judges:', [(j.name, j.online) for j in Judge.objects.all()])"
elif command -v docker &> /dev/null; then
    docker compose exec web python -c "from judge.models import Judge; print('Judges:', [(j.name, j.online) for j in Judge.objects.all()])"
fi

echo ""
echo "===== Kiểm tra hoàn tất! ====="
echo "Nếu có lỗi, vui lòng kiểm tra logs đầy đủ với lệnh: docker-compose logs" 