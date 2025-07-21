#!/bin/bash

# Script kiểm tra trước khi build DMOJ
echo "===== Kiểm tra trước khi build DMOJ ====="

# Kiểm tra Docker
echo "1. Kiểm tra Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker đã được cài đặt"
else
    echo "❌ Docker chưa được cài đặt"
    exit 1
fi

# Kiểm tra Docker Compose
echo "2. Kiểm tra Docker Compose..."
if command -v docker-compose &> /dev/null || command -v docker compose &> /dev/null; then
    echo "✅ Docker Compose đã được cài đặt"
else
    echo "❌ Docker Compose chưa được cài đặt"
    exit 1
fi

# Kiểm tra các file cần thiết
echo "3. Kiểm tra các file cần thiết..."
required_files=("Dockerfile" "docker-compose.yml" "local_settings.py" "docker/mysql/mysql-init.sql")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file: OK"
    else
        echo "❌ $file: Không tìm thấy"
        exit 1
    fi
done

# Kiểm tra các thư mục cần thiết
echo "4. Kiểm tra các thư mục cần thiết..."
required_dirs=("problems" "static" "media")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir: OK"
    else
        echo "❌ $dir: Không tìm thấy"
        mkdir -p "$dir"
        echo "  ✅ Đã tạo thư mục $dir"
    fi
done

# Kiểm tra port
echo "5. Kiểm tra port..."
if netstat -tuln | grep -q ":8000 "; then
    echo "❌ Port 8000 đã được sử dụng"
    echo "  ⚠️ Vui lòng đóng ứng dụng đang sử dụng port 8000"
else
    echo "✅ Port 8000: OK"
fi

if netstat -tuln | grep -q ":3306 "; then
    echo "❌ Port 3306 đã được sử dụng"
    echo "  ⚠️ Vui lòng đóng MySQL/MariaDB đang sử dụng port 3306"
else
    echo "✅ Port 3306: OK"
fi

if netstat -tuln | grep -q ":6379 "; then
    echo "❌ Port 6379 đã được sử dụng"
    echo "  ⚠️ Vui lòng đóng Redis đang sử dụng port 6379"
else
    echo "✅ Port 6379: OK"
fi

echo ""
echo "===== Kiểm tra hoàn tất! ====="
echo "Bạn có thể tiếp tục build DMOJ với lệnh: docker-compose up -d" 