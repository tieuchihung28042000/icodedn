# 🚀 DMOJ Docker Deployment Checklist

Checklist này đảm bảo tất cả các file cần thiết đã được chuẩn bị đầy đủ trước khi deploy lên VPS.

## ✅ Pre-deployment Checklist

### 1. 📋 Files cấu hình Docker
- [ ] `Dockerfile` - Có và được cấu hình đúng
- [ ] `docker-compose.yml` - Có và cấu hình production
- [ ] `.dockerignore` - Có và loại trừ files không cần thiết
- [ ] `docker/mysql-init.sql` - Script khởi tạo database

### 2. 🐍 Python Dependencies
- [ ] `requirements.txt` - Danh sách packages Python chính
- [ ] `additional_requirements.txt` - Packages bổ sung
- [ ] `manage.py` - Django management script

### 3. 🌐 Node.js Dependencies
- [ ] `package.json` - Cấu hình Node.js và scripts
- [ ] `package-lock.json` - Lock file cho dependencies
- [ ] `make_style.sh` - Script build CSS

### 4. 🎨 Static Assets
- [ ] `resources/libs/` - Submodule từ DMOJ/site-assets
- [ ] `resources/vnoj/` - Submodule từ VNOI-Admin/vnoj-static
- [ ] `resources/` - Thư mục chứa tất cả static files
- [ ] `.gitmodules` - Cấu hình git submodules

### 5. ⚙️ Django Configuration
- [ ] `dmoj/settings.py` - Settings chính
- [ ] `dmoj/docker_settings.py` - Settings cho Docker
- [ ] `dmoj/urls.py` - URL routing
- [ ] `dmoj/wsgi.py` - WSGI application

### 6. 📁 Core Directories
- [ ] `judge/` - Core judge application
- [ ] `templates/` - Django templates
- [ ] `locale/` - Internationalization files

### 7. 🔧 Environment & Scripts
- [ ] `production.env.example` - Template cho environment variables
- [ ] `check-docker-files.sh` - Script kiểm tra files
- [ ] `deploy-production.sh` - Script deployment
- [ ] `init-fixtures.sh` - Script load fixtures

## 🚀 Deployment Steps

### Step 1: Kiểm tra files cần thiết
```bash
# Chạy script kiểm tra
./check-docker-files.sh
```

### Step 2: Chuẩn bị environment
```bash
# Tạo file .env từ template
cp production.env.example .env

# Chỉnh sửa các thông tin production
nano .env
```

### Step 3: Deploy
```bash
# Chạy script deployment
./deploy-production.sh
```

## 🔍 Kiểm tra sau deployment

### Health Check
```bash
# Kiểm tra status containers
docker compose ps

# Kiểm tra web service
curl -I http://localhost:8000/

# Kiểm tra logs
docker compose logs web -f
```

### Static Files Check
```bash
# Kiểm tra static files trong container
docker compose exec web ls -la /app/static/

# Kiểm tra CSS files
docker compose exec web ls -la /app/static/css/
```

### Database Check
```bash
# Kiểm tra database connection
docker compose exec db mysql -u dmoj -p dmoj

# Kiểm tra migrations
docker compose exec web python manage.py showmigrations --settings=dmoj.docker_settings

# Kiểm tra fixtures
docker compose exec web python manage.py shell --settings=dmoj.docker_settings -c "from judge.models import Language; print(f'Languages: {Language.objects.count()}')"
```

## 🛠️ Troubleshooting

### Static Files Issues
```bash
# Rebuild static files
docker compose exec web python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Check submodules
git submodule status
git submodule update --init --recursive
```

### Database Issues
```bash
# Restart database
docker compose restart db

# Check database logs
docker compose logs db -f

# Load fixtures manually
docker compose exec web bash /app/init-fixtures.sh

# Reset database (⚠️ Mất data)
docker compose down
docker volume rm $(docker volume ls -q | grep mysql)
docker compose up -d
```

### Container Issues
```bash
# Rebuild containers
docker compose build --no-cache

# Check system resources
docker stats

# Clean up Docker
docker system prune -f
```

## 📊 Production Optimization

### 1. Resource Limits
Đã cấu hình limits trong `docker-compose.yml`:
- Web: 400MB RAM, 0.4 CPU
- Database: 400MB RAM, 0.4 CPU
- Redis: 80MB RAM, 0.1 CPU

### 2. Security
- [ ] Uncomment user creation trong Dockerfile cho production
- [ ] Cấu hình SSL/TLS
- [ ] Cấu hình firewall
- [ ] Thay đổi default passwords

### 3. Monitoring
- [ ] Setup log rotation
- [ ] Monitor disk space
- [ ] Monitor container health
- [ ] Backup database regularly

## 🚨 Emergency Procedures

### Quick Restart
```bash
docker compose restart web
```

### Full Restart
```bash
docker compose down
docker compose up -d
```

### Rollback
```bash
# Stop current deployment
docker compose down

# Pull previous version
git checkout <previous-commit>

# Redeploy
./deploy-production.sh
```

## 📞 Support

Nếu gặp vấn đề:
1. Kiểm tra logs: `docker compose logs -f`
2. Kiểm tra status: `docker compose ps`
3. Chạy health check: `./check-docker-files.sh`
4. Restart services: `docker compose restart`

---

**Lưu ý quan trọng**: Luôn backup database trước khi deploy và test trên môi trường staging trước khi deploy production. 