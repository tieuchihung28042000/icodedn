#!/bin/bash

# Script để tắt xác thực email trong DMOJ
echo "===== Tắt xác thực email trong DMOJ ====="

# Đảm bảo file cấu hình tồn tại
echo "1. Kiểm tra file cấu hình..."
docker exec dmoj_web bash -c "[ -f /app/dmoj/docker_settings.py ] && echo 'File cấu hình tồn tại' || echo 'File cấu hình không tồn tại'"

# Thêm cấu hình tắt xác thực email
echo "2. Thêm cấu hình tắt xác thực email..."
docker exec dmoj_web bash -c "echo '
# Disable email verification
SEND_ACTIVATION_EMAIL = False
ACCOUNT_EMAIL_VERIFICATION = \"none\"
REGISTRATION_AUTO_LOGIN = True
ACCOUNT_EMAIL_REQUIRED = False
REGISTRATION_EMAIL_VERIFICATION = False
' >> /app/dmoj/docker_settings.py"

# Kiểm tra cấu hình đã được thêm
echo "3. Kiểm tra cấu hình đã được thêm..."
docker exec dmoj_web bash -c "grep -A 5 'Disable email verification' /app/dmoj/docker_settings.py"

# Khởi động lại container web
echo "4. Khởi động lại container web..."
docker restart dmoj_web

# Đợi container khởi động
echo "5. Đợi container khởi động..."
sleep 10

# Kiểm tra trạng thái container
echo "6. Kiểm tra trạng thái container..."
docker ps | grep dmoj_web

echo "===== Hoàn tất ====="
echo "Bây giờ người dùng có thể đăng ký và đăng nhập mà không cần xác thực email." 