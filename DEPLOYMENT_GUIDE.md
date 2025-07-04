# DMOJ Production Deployment Guide

## 📋 Tổng quan

Hướng dẫn deploy DMOJ lên production server với domain icodedn.com sử dụng Docker, nginx và Cloudflare tunnel.

## 🔧 Cấu hình server

### 1. Cài đặt Docker và Docker Compose

```bash
# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Cài đặt Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Clone repository

```bash
cd ~
mkdir -p sites
cd sites
git clone https://github.com/your-repo/OJ.git icodedn.com
cd icodedn.com
```

### 3. Cấu hình environment

```bash
# Tạo file .env từ template
cp production.env.example .env

# Chỉnh sửa cấu hình
nano .env
```

**Các thông số quan trọng cần cấu hình:**

```env
# Domain và SSL
SITE_FULL_URL=https://icodedn.com
ALLOWED_HOSTS=icodedn.com,www.icodedn.com

# Database
DB_NAME=dmoj
DB_USER=dmoj
DB_PASSWORD=your-secure-password
DB_ROOT_PASSWORD=your-root-password

# Security
SECRET_KEY=your-50-character-secret-key
DEBUG=False

# Site info
SITE_NAME=ICODEDN
SITE_LONG_NAME=ICODEDN Online Judge
SITE_ADMIN_EMAIL=admin@icodedn.com
```

### 4. Tạo SECRET_KEY

```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

## 🚀 Deployment

### Tự động deploy (Khuyến nghị)

```bash
./deploy-production.sh
```

### Deploy thủ công

```bash
# 1. Stop containers cũ
docker compose down

# 2. Build với static assets
docker compose build --no-cache

# 3. Start services
docker compose up -d

# 4. Kiểm tra status
docker compose ps
```

## 🔍 Kiểm tra và troubleshooting

### Kiểm tra logs

```bash
# Xem logs tất cả services
docker compose logs

# Xem logs web service
docker compose logs web -f

# Xem logs database
docker compose logs db -f
```

### Kiểm tra service health

```bash
# Status containers
docker compose ps

# Test web service
curl -I http://localhost:8000/

# Test database connection
docker compose exec db mysql -u dmoj -p dmoj
```

### Khắc phục sự cố thường gặp

#### 1. Static files không load

```bash
# Rebuild với static assets
docker compose build --no-cache web
docker compose restart web
```

#### 2. Database connection error

```bash
# Kiểm tra database
docker compose logs db
docker compose exec db mysql -u root -p

# Reset database
docker compose down
docker volume rm $(docker volume ls -q | grep mysql)
docker compose up -d
```

#### 3. Container không start

```bash
# Xem logs chi tiết
docker compose logs web

# Kiểm tra resources
docker stats

# Restart service
docker compose restart web
```

## 📁 Cấu trúc Static Files

Dockerfile đã được cấu hình để tự động build static assets:

1. **Git submodules**: Tải assets từ DMOJ/site-assets
2. **NPM dependencies**: Cài đặt sass, postcss, autoprefixer
3. **CSS compilation**: Build SCSS thành CSS
4. **i18n files**: Compile JavaScript i18n
5. **Static collection**: Collect tất cả static files

## 🌐 Cấu hình Nginx

```nginx
server {
    listen 80;
    server_name icodedn.com www.icodedn.com;
    
    client_max_body_size 20M;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /root/sites/icodedn.com/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /media/ {
        alias /root/sites/icodedn.com/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
```

## ☁️ Cấu hình Cloudflare Tunnel

```bash
# Cài đặt cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Đăng nhập và tạo tunnel
cloudflared tunnel login
cloudflared tunnel create icodedn
cloudflared tunnel route dns icodedn icodedn.com

# Cấu hình tunnel
nano ~/.cloudflared/config.yml
```

**Config file:**

```yaml
tunnel: icodedn
credentials-file: /root/.cloudflared/tunnel-id.json

ingress:
  - hostname: icodedn.com
    service: http://localhost:80
  - hostname: www.icodedn.com
    service: http://localhost:80
  - service: http_status:404
```

## 📊 Monitoring

### Resource usage

```bash
# Docker stats
docker stats

# System resources
htop
df -h
free -h
```

### Service status

```bash
# All services
docker compose ps

# Web service health
curl -f http://localhost:8000/

# Database health
docker compose exec db mysqladmin ping
```

## 🔄 Cập nhật

```bash
# Pull code mới
git pull origin main

# Rebuild và deploy
./deploy-production.sh
```

## 📝 Lưu ý quan trọng

1. **Backup database** trước khi update
2. **Kiểm tra logs** sau mỗi lần deploy
3. **Monitor resources** trên VPS nhỏ
4. **SSL** được xử lý bởi Cloudflare
5. **Static files** được build tự động trong Docker

## 🆘 Hỗ trợ

Nếu gặp vấn đề:

1. Kiểm tra logs: `docker compose logs web -f`
2. Kiểm tra status: `docker compose ps`
3. Restart service: `docker compose restart web`
4. Rebuild: `./deploy-production.sh` 