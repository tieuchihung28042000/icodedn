#!/bin/bash

# Đường dẫn đến file docker_settings.py
SETTINGS_FILE="/Users/nguyencamquyen/Downloads/OJ/dmoj/docker_settings.py"

# Sao lưu file cấu hình
cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
echo "Đã sao lưu file cấu hình gốc tại ${SETTINGS_FILE}.bak"

# Sửa cấu hình bridge
sed -i '' 's/BRIDGED_JUDGE_ADDRESS = ('"'"'localhost'"'"', 9999)/BRIDGED_JUDGE_ADDRESS = ('"'"'0.0.0.0'"'"', 9999)/g' "$SETTINGS_FILE"
sed -i '' 's/BRIDGED_DJANGO_ADDRESS = ('"'"'localhost'"'"', 9998)/BRIDGED_DJANGO_ADDRESS = ('"'"'0.0.0.0'"'"', 9998)/g' "$SETTINGS_FILE"

echo "Đã cập nhật cấu hình bridge trong file $SETTINGS_FILE"

# Hiển thị cấu hình đã sửa
echo "Cấu hình bridge mới:"
grep -A 2 "BRIDGED_JUDGE_ADDRESS" "$SETTINGS_FILE" 