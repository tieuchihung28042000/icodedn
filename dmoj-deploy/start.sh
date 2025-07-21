#!/bin/bash

# Script khởi động DMOJ
echo "===== Khởi động DMOJ ====="

# Kiểm tra trước khi khởi động
if [ -f "./check-before-build.sh" ]; then
    chmod +x ./check-before-build.sh
    ./check-before-build.sh
    if [ $? -ne 0 ]; then
        echo "❌ Kiểm tra thất bại. Vui lòng khắc phục các lỗi trên."
        exit 1
    fi
fi

# Khởi động Docker Compose
echo "Khởi động Docker Compose..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    docker compose up -d
else
    echo "❌ Không tìm thấy Docker Compose"
    exit 1
fi

# Kiểm tra trạng thái
echo "Kiểm tra trạng thái các containers..."
sleep 5
if command -v docker-compose &> /dev/null; then
    docker-compose ps
elif command -v docker &> /dev/null; then
    docker compose ps
fi

echo ""
echo "===== DMOJ đã được khởi động! ====="
echo "Truy cập: http://localhost:8000"
echo "Admin: http://localhost:8000/admin"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Để xem logs: docker-compose logs -f"
echo "Để dừng: docker-compose down" 