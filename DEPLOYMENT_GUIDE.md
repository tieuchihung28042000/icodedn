# 🚀 Hướng dẫn triển khai ICODEDN

## 📋 Chuẩn bị

### 1. Tạo Git repository và push lên GitHub

```bash
# Khởi tạo Git repository
git init

# Thêm tất cả files
git add .

# Commit đầu tiên
git commit -m "Initial commit: ICODEDN Online Judge Platform"

# Tạo repository trên GitHub (https://github.com/new)
# Tên repository: icodedn
# Description: Online Judge Platform for Competitive Programming

# Thêm remote origin (thay yourusername bằng username GitHub của bạn)
git remote add origin https://github.com/yourusername/icodedn.git

# Push lên GitHub
git branch -M main
git push -u origin main
```

### 2. Cấu hình VPS

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Thêm user vào Docker group
sudo usermod -aG docker $USER

# Cài đặt Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Khởi động lại để áp dụng group changes
sudo reboot
```

### 3. Clone repository trên VPS

```bash
# Clone repository
git clone https://github.com/yourusername/icodedn.git
cd icodedn

# Tạo file .env từ template
cp production.env.example .env

# Chỉnh sửa cấu hình
nano .env
```

## ⚙️ Cấu hình production

### 1. Chỉnh sửa file .env

```env
# Django Settings
DEBUG=False
SECRET_KEY=your-super-secret-key-here-generate-new-one
ALLOWED_HOSTS=icodedn.com,www.icodedn.com

# Site Information
SITE_FULL_URL=https://icodedn.com
SITE_NAME=ICODEDN
SITE_LONG_NAME=ICODEDN - Online Judge Platform
SITE_ADMIN_EMAIL=admin@icodedn.com

# Database Configuration
DB_NAME=dmoj
DB_USER=dmoj
DB_PASSWORD=your-strong-database-password
DB_HOST=db
DB_PORT=3306

# Database Root Password
MYSQL_ROOT_PASSWORD=your-strong-root-password

# Redis Configuration
REDIS_URL=redis://redis:6379/0

# Security Settings
SECURE_SSL_REDIRECT=True
SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https
USE_TLS=True
```

### 2. Tạo SECRET_KEY mới

```bash
# Tạo SECRET_KEY mới
python3 -c "
import secrets
import string
alphabet = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
secret_key = ''.join(secrets.choice(alphabet) for i in range(50))
print('SECRET_KEY=' + secret_key)
"
```

## 🌐 Cấu hình Cloudflare Tunnel

### 1. Cài đặt Cloudflared

```bash
# Tải cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Đăng nhập Cloudflare
cloudflared tunnel login

# Tạo tunnel
cloudflared tunnel create icodedn

# Cấu hình DNS
cloudflared tunnel route dns icodedn icodedn.com
cloudflared tunnel route dns icodedn www.icodedn.com
```

### 2. Tạo file cấu hình tunnel

```bash
# Tạo thư mục cấu hình
sudo mkdir -p /etc/cloudflared

# Tạo file cấu hình
sudo nano /etc/cloudflared/config.yml
```

Nội dung file `config.yml`:

```yaml
tunnel: icodedn
credentials-file: /root/.cloudflared/your-tunnel-id.json

ingress:
  - hostname: icodedn.com
    service: http://localhost:8000
  - hostname: www.icodedn.com
    service: http://localhost:8000
  - service: http_status:404
```

### 3. Chạy tunnel như service

```bash
# Cài đặt service
sudo cloudflared service install

# Khởi động service
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Kiểm tra status
sudo systemctl status cloudflared
```

## 🚀 Triển khai ứng dụng

### 1. Chạy deployment script

```bash
# Cấp quyền thực thi
chmod +x deploy-production.sh

# Chạy deployment
./deploy-production.sh
```

### 2. Kiểm tra trạng thái

```bash
# Kiểm tra containers
docker compose ps

# Xem logs
docker compose logs -f

# Kiểm tra website
curl -I https://icodedn.com
```

## 🔧 Bảo trì và quản lý

### 1. Lệnh hữu ích

```bash
# Xem logs real-time
docker compose logs -f web

# Khởi động lại services
docker compose restart

# Backup database
docker compose exec db mysqldump -u root -p dmoj > backup-$(date +%Y%m%d).sql

# Restore database
docker compose exec -T db mysql -u root -p dmoj < backup-20240101.sql

# Truy cập shell container
docker compose exec web bash

# Chạy Django commands
docker compose exec web python manage.py collectstatic --noinput
docker compose exec web python manage.py migrate
```

### 2. Cập nhật code

```bash
# Pull code mới từ GitHub
git pull origin main

# Rebuild và restart
docker compose up --build -d

# Chạy migrations nếu cần
docker compose exec web python manage.py migrate
```

### 3. Monitoring

```bash
# Kiểm tra disk usage
df -h

# Kiểm tra memory usage
free -h

# Kiểm tra Docker containers
docker stats

# Kiểm tra logs
tail -f logs/django.log
```

## 🛡️ Bảo mật

### 1. Firewall

```bash
# Cài đặt ufw
sudo apt install ufw

# Cho phép SSH
sudo ufw allow ssh

# Cho phép HTTP/HTTPS (nếu cần)
sudo ufw allow 80
sudo ufw allow 443

# Kích hoạt firewall
sudo ufw enable
```

### 2. SSL/TLS

Cloudflare Tunnel tự động cung cấp SSL/TLS certificate.

### 3. Regular Updates

```bash
# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y

# Cập nhật Docker images
docker compose pull
docker compose up -d
```

## 📊 Backup Strategy

### 1. Database Backup

```bash
# Tạo script backup tự động
cat > backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/backup"
mkdir -p $BACKUP_DIR

# Backup database
docker compose exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD dmoj > $BACKUP_DIR/dmoj_$DATE.sql

# Compress backup
gzip $BACKUP_DIR/dmoj_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "dmoj_*.sql.gz" -mtime +7 -delete
EOF

chmod +x backup-db.sh

# Thêm vào crontab để chạy hàng ngày
echo "0 2 * * * /path/to/backup-db.sh" | crontab -
```

### 2. Files Backup

```bash
# Backup volumes
docker run --rm -v icodedn_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_data_backup.tar.gz -C /data .
docker run --rm -v icodedn_static_files:/data -v $(pwd):/backup alpine tar czf /backup/static_files_backup.tar.gz -C /data .
```

## 🎯 Troubleshooting

### 1. Container không start

```bash
# Kiểm tra logs
docker compose logs container_name

# Kiểm tra disk space
df -h

# Kiểm tra memory
free -h
```

### 2. Database connection issues

```bash
# Kiểm tra MySQL container
docker compose exec db mysql -u root -p -e "SHOW DATABASES;"

# Reset database password
docker compose exec db mysql -u root -p -e "ALTER USER 'dmoj'@'%' IDENTIFIED BY 'new_password';"
```

### 3. Website không load

```bash
# Kiểm tra Cloudflare tunnel
sudo systemctl status cloudflared

# Kiểm tra web container
docker compose logs web

# Test local connection
curl -I http://localhost:8000
```

## 📞 Support

- **Email**: admin@icodedn.com
- **Documentation**: https://docs.icodedn.com
- **GitHub Issues**: https://github.com/yourusername/icodedn/issues

---

🎉 **Chúc mừng! ICODEDN đã sẵn sàng phục vụ!** 