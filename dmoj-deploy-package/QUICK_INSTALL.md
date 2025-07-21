# Hướng dẫn cài đặt nhanh DMOJ

Hướng dẫn này giúp bạn cài đặt DMOJ nhanh chóng trên máy tính cá nhân hoặc VPS.

## Cài đặt trên máy tính cá nhân

### 1. Chuẩn bị

Đảm bảo bạn đã cài đặt:
- Docker
- Docker Compose

### 2. Tải về và chuẩn bị

```bash
# Clone repository
git clone https://github.com/your-repo/dmoj-deploy.git
cd dmoj-deploy

# Cấp quyền thực thi cho các script
chmod +x *.sh

# Tạo file .env từ mẫu
cp .env.example .env
```

### 3. Chạy kiểm tra và khởi động

```bash
# Kiểm tra trước khi build
./check-before-build.sh

# Khởi động DMOJ
./start.sh
```

### 4. Truy cập

- Web UI: http://localhost:8000
- Admin: http://localhost:8000/admin
- Username: admin
- Password: admin

## Cài đặt trên VPS

### 1. Chuẩn bị

Trên máy tính cá nhân:
```bash
# Clone repository
git clone https://github.com/your-repo/dmoj-deploy.git
cd dmoj-deploy

# Cấp quyền thực thi cho script deploy
chmod +x deploy-vps.sh
```

### 2. Deploy lên VPS

```bash
# Deploy lên VPS
./deploy-vps.sh user@your-vps-host
```

### 3. Truy cập

- Web UI: http://your-vps-ip:8000
- Admin: http://your-vps-ip:8000/admin
- Username: admin
- Password: admin

## Các lệnh thường dùng

### Xem logs

```bash
docker-compose logs -f
```

### Restart services

```bash
docker-compose restart
```

### Dừng và xóa containers

```bash
docker-compose down
```

### Kiểm tra lỗi

```bash
./check-errors.sh
```

## Cấu hình HTTPS

Để cấu hình HTTPS với Nginx và Let's Encrypt:

```bash
# Cài đặt Nginx và Certbot
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# Cấu hình Nginx
cat > /etc/nginx/sites-available/dmoj << 'EOF'
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Kích hoạt cấu hình
ln -s /etc/nginx/sites-available/dmoj /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Cài đặt SSL
certbot --nginx -d your-domain.com
```

## Hỗ trợ

Nếu gặp vấn đề, vui lòng tạo issue hoặc liên hệ với chúng tôi. 