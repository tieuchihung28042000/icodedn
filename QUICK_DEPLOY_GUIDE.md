# 🚀 Hướng dẫn Deploy Nhanh ICODEDN.COM

## 📋 Tóm tắt

Bạn đã có sẵn các script tự động để deploy DMOJ lên production với domain `icodedn.com` sử dụng Cloudflare tunnel.

## 🔧 Các File Đã Được Cấu Hình

1. **`production.env.example`** - Template environment cho production
2. **`deploy.sh`** - Script deploy chính (hỗ trợ local/production/cleanup)
3. **`deploy-production.sh`** - Script deploy production chuyên dụng
4. **`setup-cloudflare-tunnel.sh`** - Script setup Cloudflare tunnel
5. **`PRODUCTION_DEPLOY.md`** - Hướng dẫn chi tiết

## ⚡ Deploy Nhanh (3 Bước)

### Bước 1: Chuẩn bị VPS
```bash
# Trên VPS của bạn
git clone <repo-url> /opt/icodedn
cd /opt/icodedn
```

### Bước 2: Deploy Application
```bash
# Chạy script deploy production
./deploy-production.sh
```

Script sẽ:
- Tự động tạo file `.env` từ `production.env.example`
- Yêu cầu bạn cập nhật SECRET_KEY và passwords
- Build và deploy toàn bộ services
- Tự động migrate database
- Setup initial data

### Bước 3: Setup Cloudflare Tunnel
```bash
# Chạy script setup tunnel
./setup-cloudflare-tunnel.sh
```

Script sẽ:
- Cài đặt cloudflared
- Tạo tunnel tên "icodedn"
- Tự động tạo DNS records
- Setup systemd service tự khởi động

## 🔑 Thông Tin Quan Trọng

### Environment Variables Cần Thay Đổi:
```bash
# Generate SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# Cập nhật trong .env:
SECRET_KEY=<generated-key>
DB_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-password>
```

### Cấu Hình Cloudflare:
- Domain: `icodedn.com` và `www.icodedn.com`
- Tunnel trỏ về: `http://localhost:8000`
- SSL: Handled by Cloudflare
- No need for nginx SSL config

## 📊 Kiểm Tra Deployment

```bash
# Kiểm tra services
docker compose ps

# Xem logs
docker compose logs -f

# Kiểm tra tunnel
sudo systemctl status cloudflared-icodedn.service

# Test website
curl -I https://icodedn.com
```

## 🔄 Cập Nhật Deployment

```bash
# Khi có code mới
git pull
./deploy.sh production

# Hoặc dùng script chuyên dụng
./deploy-production.sh
```

## 🛠️ Troubleshooting

### Nếu Services Không Start:
```bash
# Xem logs chi tiết
docker compose logs web
docker compose logs db

# Restart services
docker compose restart
```

### Nếu Tunnel Không Hoạt Động:
```bash
# Xem logs tunnel
sudo journalctl -u cloudflared-icodedn.service -f

# Restart tunnel
sudo systemctl restart cloudflared-icodedn.service
```

### Nếu Cần Rebuild Hoàn Toàn:
```bash
# Cleanup và deploy lại
./deploy.sh cleanup
./deploy-production.sh
```

## 🎯 URLs Sau Khi Deploy

- **Website**: https://icodedn.com
- **Admin**: https://icodedn.com/admin
- **Internal**: http://localhost:8000 (cho tunnel)

## 📝 Ghi Chú

- **Database**: MySQL 8.0 với persistent volume
- **Redis**: Cho caching và Celery
- **Static Files**: Được serve qua Docker volume
- **SSL**: Handled by Cloudflare (không cần nginx SSL)
- **Auto-start**: Tất cả services tự khởi động khi reboot

## 🔒 Security

- Firewall: Chỉ mở port 22 (SSH)
- SSL: Cloudflare handles SSL termination
- Database: Chỉ accessible từ containers
- Passwords: Đã được hash và secure

## 💾 Backup

```bash
# Backup database
docker compose exec db mysqldump -u root -p dmoj > backup_$(date +%Y%m%d).sql

# Backup volumes
docker run --rm -v icodedncom_mysql_data:/data -v $(pwd):/backup alpine tar czf /backup/mysql_backup.tar.gz /data
```

---

**Lưu ý**: Tất cả scripts đã được tối ưu để không tạo thêm files không cần thiết và sẽ tự động cleanup khi cần. 