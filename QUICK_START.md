# 🚀 DMOJ Quick Start Guide

## 🎯 Deployment nhanh

### 1. Kiểm tra files cần thiết
```bash
./check-docker-files.sh
```

### 2. Deploy
```bash
./deploy-production.sh
```

### 3. Truy cập hệ thống
- 🌐 **URL**: http://localhost:8000
- 👤 **Admin**: admin / @654321
- 🔗 **Admin Panel**: http://localhost:8000/admin/

## 📋 Tài khoản mặc định

| Loại | Username | Password | Email |
|------|----------|----------|-------|
| Admin | `admin` | `@654321` | `admin@localhost` |

⚠️ **Quan trọng**: Đổi mật khẩu admin ngay sau khi đăng nhập!

## 🔧 Lệnh hữu ích

```bash
# Xem logs
docker compose logs web -f

# Restart services
docker compose restart

# Tạo user mới
docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings

# Load fixtures
docker compose exec web bash /app/init-fixtures.sh
```

## 🛠️ Troubleshooting

### Lỗi Language DoesNotExist
```bash
# Load fixtures thủ công
docker compose exec web python manage.py loaddata judge/fixtures/language_small.json --settings=dmoj.docker_settings
```

### Lỗi static files
```bash
# Rebuild static files
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings
```

### Lỗi database
```bash
# Restart database
docker compose restart db

# Check logs
docker compose logs db -f
```

## 📚 Tài liệu chi tiết

- [DOCKER_DEPLOYMENT_CHECKLIST.md](DOCKER_DEPLOYMENT_CHECKLIST.md) - Checklist đầy đủ
- [DOCKER_FIX_SUMMARY.md](DOCKER_FIX_SUMMARY.md) - Tóm tắt các fix đã thực hiện
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Hướng dẫn deployment chi tiết 