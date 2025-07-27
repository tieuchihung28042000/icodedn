#!/bin/bash

# Script cấu hình DMOJ cho VPS với tên miền icodedn.com
# Tác giả: Claude
# Phiên bản: 1.0

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hiển thị tiêu đề
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      CẤU HÌNH DMOJ CHO VPS VỚI ICODEDN.COM       ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Lấy đường dẫn hiện tại
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}Thư mục dự án: ${PROJECT_ROOT}${NC}"

# 1. Tạo file .env với cấu hình cho VPS
echo -e "\n${YELLOW}[1/6] Tạo file .env với cấu hình cho VPS...${NC}"
cat > "$PROJECT_ROOT/.env" << 'EOL'
# Cấu hình DMOJ cho VPS
DEBUG=False
SECRET_KEY=change-this-to-a-secure-key-in-production
ALLOWED_HOSTS=localhost,127.0.0.1,icodedn.com
CSRF_TRUSTED_ORIGINS=https://icodedn.com,http://icodedn.com

# Database
DB_NAME=dmoj
DB_USER=dmoj
DB_PASSWORD=dmoj123
DB_ROOT_PASSWORD=root123

# Site info
SITE_NAME=iCodeDN
SITE_LONG_NAME=iCodeDN Online Judge
SITE_ADMIN_EMAIL=admin@icodedn.com
SITE_FULL_URL=https://icodedn.com
EOL
chmod 600 "$PROJECT_ROOT/.env"
echo -e "${GREEN}✓ Đã tạo file .env${NC}"

# 2. Tạo script sửa cấu hình Docker settings
echo -e "\n${YELLOW}[2/6] Tạo script sửa cấu hình Docker settings...${NC}"
cat > "$PROJECT_ROOT/fix_docker_settings.py" << 'EOL'
#!/usr/bin/env python3
import os
import sys

def fix_docker_settings(file_path):
    if not os.path.exists(file_path):
        print(f"File {file_path} không tồn tại!")
        return False

    with open(file_path, 'r') as f:
        content = f.read()

    # Sửa cấu hình bridge
    if "BRIDGED_JUDGE_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_JUDGE_ADDRESS = ('localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0"')
    if "BRIDGED_DJANGO_ADDRESS = ('localhost'" in content:
        content = content.replace("BRIDGED_DJANGO_ADDRESS = ('localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0"')
    
    # Sửa cấu hình site
    if "SITE_NAME = os.environ.get('SITE_NAME', 'DMOJ')" in content:
        content = content.replace("SITE_NAME = os.environ.get('SITE_NAME', 'DMOJ')", "SITE_NAME = os.environ.get('SITE_NAME', 'iCodeDN')")
    if "SITE_LONG_NAME = os.environ.get('SITE_LONG_NAME', 'DMOJ: Modern Online Judge')" in content:
        content = content.replace("SITE_LONG_NAME = os.environ.get('SITE_LONG_NAME', 'DMOJ: Modern Online Judge')", "SITE_LONG_NAME = os.environ.get('SITE_LONG_NAME', 'iCodeDN Online Judge')")
    if "SITE_ADMIN_EMAIL = os.environ.get('SITE_ADMIN_EMAIL', 'admin@example.com')" in content:
        content = content.replace("SITE_ADMIN_EMAIL = os.environ.get('SITE_ADMIN_EMAIL', 'admin@example.com')", "SITE_ADMIN_EMAIL = os.environ.get('SITE_ADMIN_EMAIL', 'admin@icodedn.com')")
    if "SITE_FULL_URL = os.environ.get('SITE_FULL_URL', 'http://localhost:8000')" in content:
        content = content.replace("SITE_FULL_URL = os.environ.get('SITE_FULL_URL', 'http://localhost:8000')", "SITE_FULL_URL = os.environ.get('SITE_FULL_URL', 'https://icodedn.com')")
    
    # Sửa cấu hình judge server
    if "'localhost': {" in content:
        content = content.replace("'localhost': {", "'icodedn.com': {")
    
    # Thêm cấu hình SECURE_PROXY_SSL_HEADER cho proxy
    if "SECURE_HSTS_PRELOAD = True" in content and "SECURE_PROXY_SSL_HEADER" not in content:
        content = content.replace("SECURE_HSTS_PRELOAD = True", "SECURE_HSTS_PRELOAD = True\n    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')")
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Đã sửa cấu hình trong {file_path}")
    return True

# Tìm file docker_settings.py
docker_settings_path = os.path.join('/app', 'dmoj', 'docker_settings.py')
if os.path.exists(docker_settings_path):
    fix_docker_settings(docker_settings_path)
else:
    print(f"Không tìm thấy file {docker_settings_path}")
    # Tìm tất cả các file settings.py và docker_settings.py
    settings_files = []
    for root, dirs, files in os.walk('/app'):
        for file in files:
            if file == 'settings.py' or file == 'docker_settings.py':
                settings_files.append(os.path.join(root, file))
    
    if not settings_files:
        print("Không tìm thấy file cấu hình nào!")
        sys.exit(1)
    
    # Sửa tất cả các file tìm được
    for file_path in settings_files:
        fix_docker_settings(file_path)
EOL
chmod +x "$PROJECT_ROOT/fix_docker_settings.py"
echo -e "${GREEN}✓ Đã tạo script sửa cấu hình Docker settings${NC}"

# 3. Tạo script sửa cấu hình Site
echo -e "\n${YELLOW}[3/6] Tạo script sửa cấu hình Site...${NC}"
cat > "$PROJECT_ROOT/fix_site_config.py" << 'EOL'
#!/usr/bin/env python3
import os
import django
import sys

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

# Import Site model
from django.contrib.sites.models import Site

def create_or_update_site():
    try:
        # Kiểm tra xem đã có site nào chưa
        sites = Site.objects.all()
        if not sites.exists():
            print("Không tìm thấy site nào. Đang tạo site mặc định...")
            # Tạo site mặc định với ID=1
            site = Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
            print(f"Đã tạo site mặc định: {site.domain}")
            return True
        else:
            print("Đã tồn tại site:")
            for site in sites:
                print(f"ID: {site.id}, Domain: {site.domain}, Name: {site.name}")
                # Cập nhật domain nếu cần
                if site.domain != 'icodedn.com':
                    old_domain = site.domain
                    site.domain = 'icodedn.com'
                    site.name = 'iCodeDN'
                    site.save()
                    print(f"Đã cập nhật domain từ {old_domain} thành {site.domain}")
                    return True
            return True
    except Exception as e:
        print(f"Lỗi khi tạo/cập nhật site: {str(e)}")
        return False

if __name__ == "__main__":
    success = create_or_update_site()
    sys.exit(0 if success else 1)
EOL
chmod +x "$PROJECT_ROOT/fix_site_config.py"
echo -e "${GREEN}✓ Đã tạo script sửa cấu hình Site${NC}"

# 4. Tạo script sửa cấu hình Nginx
echo -e "\n${YELLOW}[4/6] Tạo script cấu hình Nginx...${NC}"
mkdir -p "$PROJECT_ROOT/nginx"
cat > "$PROJECT_ROOT/nginx/icodedn.conf" << 'EOL'
server {
    listen 80;
    server_name icodedn.com www.icodedn.com;

    # Redirect HTTP to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name icodedn.com www.icodedn.com;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/icodedn.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/icodedn.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy no-referrer-when-downgrade;

    # Proxy settings
    client_max_body_size 50M;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 300s;
    proxy_connect_timeout 75s;

    # Static files
    location /static/ {
        alias /home/chihung2k/sites/icodedn.com/static/;
        expires 30d;
        access_log off;
    }

    # Media files
    location /media/ {
        alias /home/chihung2k/sites/icodedn.com/media/;
        expires 30d;
        access_log off;
    }

    # Main application
    location / {
        proxy_pass http://localhost:8000;
    }
}
EOL
echo -e "${GREEN}✓ Đã tạo cấu hình Nginx${NC}"

# 5. Tạo script cài đặt SSL với Certbot
echo -e "\n${YELLOW}[5/6] Tạo script cài đặt SSL...${NC}"
cat > "$PROJECT_ROOT/setup_ssl.sh" << 'EOL'
#!/bin/bash

# Cài đặt Certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Lấy chứng chỉ SSL
certbot --nginx -d icodedn.com -d www.icodedn.com --non-interactive --agree-tos --email admin@icodedn.com

# Thiết lập tự động gia hạn
echo "0 3 * * * certbot renew --quiet" | crontab -
EOL
chmod +x "$PROJECT_ROOT/setup_ssl.sh"
echo -e "${GREEN}✓ Đã tạo script cài đặt SSL${NC}"

# 6. Tạo script triển khai hoàn chỉnh
echo -e "\n${YELLOW}[6/6] Tạo script triển khai hoàn chỉnh...${NC}"
cat > "$PROJECT_ROOT/deploy_vps.sh" << 'EOL'
#!/bin/bash

set -e  # Dừng script nếu có lỗi

# Màu sắc cho output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hiển thị tiêu đề
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      TRIỂN KHAI DMOJ TRÊN VPS - ICODEDN.COM      ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Lấy đường dẫn hiện tại
PROJECT_ROOT=$(pwd)
echo -e "${GREEN}Thư mục dự án: ${PROJECT_ROOT}${NC}"

# 1. Dừng các container hiện tại
echo -e "\n${YELLOW}[1/12] Dừng các container hiện tại...${NC}"
docker compose down
echo -e "${GREEN}✓ Đã dừng các container${NC}"

# 2. Xóa các volume để đảm bảo dữ liệu sạch
echo -e "\n${YELLOW}[2/12] Xóa các volume cũ...${NC}"
docker volume ls | grep -E "_mysql_data|_redis_data|_static_files|_media_files|_problem_data" | awk '{print $2}' | xargs -r docker volume rm || true
echo -e "${GREEN}✓ Đã xóa các volume cũ${NC}"

# 3. Tạo các thư mục cần thiết
echo -e "\n${YELLOW}[3/12] Tạo các thư mục cần thiết...${NC}"
mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
chmod -R 777 "$PROJECT_ROOT/logs" "$PROJECT_ROOT/static" "$PROJECT_ROOT/media" "$PROJECT_ROOT/problems"
echo -e "${GREEN}✓ Đã tạo và cấp quyền cho các thư mục cần thiết${NC}"

# 4. Xây dựng lại các container
echo -e "\n${YELLOW}[4/12] Xây dựng lại các container...${NC}"
docker compose build
echo -e "${GREEN}✓ Đã xây dựng lại các container${NC}"

# 5. Khởi động các container
echo -e "\n${YELLOW}[5/12] Khởi động các container...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Đã khởi động các container${NC}"

# 6. Đợi database khởi động
echo -e "\n${YELLOW}[6/12] Đợi database khởi động hoàn tất (30 giây)...${NC}"
sleep 30
echo -e "${GREEN}✓ Đã đợi đủ thời gian${NC}"

# 7. Chạy migrations
echo -e "\n${YELLOW}[7/12] Chạy migrations...${NC}"
docker compose exec web python manage.py migrate --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã chạy migrations${NC}"

# 8. Copy các script sửa lỗi vào container
echo -e "\n${YELLOW}[8/12] Copy các script sửa lỗi vào container...${NC}"
docker compose cp fix_docker_settings.py web:/app/
docker compose cp fix_site_config.py web:/app/
echo -e "${GREEN}✓ Đã copy các script vào container${NC}"

# 9. Chạy các script sửa lỗi
echo -e "\n${YELLOW}[9/12] Chạy các script sửa lỗi...${NC}"
echo "Đang chạy script sửa cấu hình Docker settings..."
docker compose exec web python /app/fix_docker_settings.py

echo "Đang chạy script sửa cấu hình Site..."
docker compose exec web python /app/fix_site_config.py
echo -e "${GREEN}✓ Đã chạy các script sửa lỗi${NC}"

# 10. Thu thập static files
echo -e "\n${YELLOW}[10/12] Thu thập static files...${NC}"
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
echo -e "${GREEN}✓ Đã thu thập static files${NC}"

# 11. Cài đặt Nginx và SSL
echo -e "\n${YELLOW}[11/12] Cài đặt Nginx và SSL...${NC}"
if command -v nginx &> /dev/null; then
    echo "Nginx đã được cài đặt"
else
    echo "Đang cài đặt Nginx..."
    apt-get update
    apt-get install -y nginx
fi

# Copy file cấu hình Nginx
cp "$PROJECT_ROOT/nginx/icodedn.conf" /etc/nginx/sites-available/icodedn.conf
ln -sf /etc/nginx/sites-available/icodedn.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default || true

# Kiểm tra cấu hình Nginx
nginx -t && systemctl reload nginx
echo -e "${GREEN}✓ Đã cài đặt và cấu hình Nginx${NC}"

# Cài đặt SSL nếu cần
if [ ! -d "/etc/letsencrypt/live/icodedn.com" ]; then
    echo "Đang cài đặt SSL..."
    bash "$PROJECT_ROOT/setup_ssl.sh"
    echo -e "${GREEN}✓ Đã cài đặt SSL${NC}"
else
    echo -e "${GREEN}✓ SSL đã được cài đặt${NC}"
fi

# 12. Khởi động lại web service
echo -e "\n${YELLOW}[12/12] Khởi động lại web service...${NC}"
docker compose restart web
echo -e "${GREEN}✓ Đã khởi động lại web service${NC}"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! DMOJ đã được triển khai trên VPS.${NC}"
echo -e "${GREEN}Truy cập trang web tại: https://icodedn.com${NC}"
echo -e "${BLUE}==================================================${NC}"
EOL
chmod +x "$PROJECT_ROOT/deploy_vps.sh"
echo -e "${GREEN}✓ Đã tạo script triển khai hoàn chỉnh${NC}"

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}HOÀN TẤT! Các script cấu hình đã được tạo.${NC}"
echo -e "${GREEN}Để triển khai trên VPS, hãy chạy: ./deploy_vps.sh${NC}"
echo -e "${BLUE}==================================================${NC}" 