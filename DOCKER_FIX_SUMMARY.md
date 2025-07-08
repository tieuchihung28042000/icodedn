# 🔧 Tóm tắt các fix cho Docker Deployment

## ❌ Vấn đề gặp phải

1. **Language DoesNotExist Error**: Lỗi `Language matching query does not exist` khi truy cập `/accounts/register/`
2. **Thiếu fixtures**: Database không có dữ liệu Language cần thiết
3. **Thiếu static assets**: Một số file static không được copy đúng cách
4. **Submodules không được load**: Git submodules không có trong Docker build context

## ✅ Các fix đã thực hiện

### 1. 📋 Cập nhật Dockerfile
- ✅ Thêm kiểm tra fixtures directory
- ✅ Cải thiện error handling cho CSS build
- ✅ Thêm verification cho static assets
- ✅ Cải thiện health check

### 2. 🗄️ Fix Database & Fixtures
- ✅ Tạo script `init-fixtures.sh` để load fixtures
- ✅ Cập nhật `docker-compose.yml` để tự động load `language_small.json`
- ✅ Cập nhật `dmoj/docker_settings.py` để sử dụng `DEFAULT_USER_LANGUAGE = 'CPP17'`
- ✅ Thêm fixtures loading vào deployment script

### 3. 🎨 Fix Static Assets
- ✅ Cập nhật `.dockerignore` để bao gồm submodules
- ✅ Thêm verification cho `resources/libs/` và `resources/vnoj/`
- ✅ Đảm bảo `make_style.sh` được bao gồm trong build

### 4. 📋 Cải thiện Scripts
- ✅ Cập nhật `check-docker-files.sh` để kiểm tra fixtures
- ✅ Cập nhật `deploy-production.sh` để load fixtures
- ✅ Tạo `init-fixtures.sh` để load fixtures thủ công

### 5. 📚 Cập nhật Documentation
- ✅ Cập nhật `DOCKER_DEPLOYMENT_CHECKLIST.md`
- ✅ Thêm troubleshooting cho fixtures
- ✅ Thêm hướng dẫn kiểm tra database

## 🚀 Cách deploy sau khi fix

### Option 1: Sử dụng deployment script (Khuyến nghị)
```bash
./deploy-production.sh
```

### Option 2: Deploy thủ công
```bash
# 1. Kiểm tra files
./check-docker-files.sh

# 2. Build và start
docker compose down
docker compose build --no-cache
docker compose up -d

# 3. Load fixtures (nếu cần)
docker compose exec web bash /app/init-fixtures.sh

# 4. Tạo superuser
docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings
```

## 🔍 Kiểm tra sau deployment

### 1. Kiểm tra service status
```bash
docker compose ps
```

### 2. Kiểm tra logs
```bash
docker compose logs web -f
```

### 3. Kiểm tra database fixtures
```bash
docker compose exec web python manage.py shell --settings=dmoj.docker_settings -c "
from judge.models import Language
print(f'Languages loaded: {Language.objects.count()}')
for lang in Language.objects.all()[:5]:
    print(f'  - {lang.key}: {lang.name}')
"
```

### 4. Test registration page
```bash
curl -I http://localhost:8000/accounts/register/
# Should return 200 OK instead of 500 Internal Server Error
```

### 5. Test admin login
- 🌐 URL: http://localhost:8000/admin/
- 👤 Username: `admin`
- 🔑 Password: `admin123`

## 📁 Files đã thay đổi

1. **Dockerfile** - Cải thiện build process và verification
2. **docker-compose.yml** - Thêm fixtures loading
3. **dmoj/docker_settings.py** - Fix DEFAULT_USER_LANGUAGE
4. **.dockerignore** - Bao gồm submodules
5. **check-docker-files.sh** - Thêm kiểm tra fixtures
6. **deploy-production.sh** - Thêm fixtures loading step
7. **init-fixtures.sh** - Script load fixtures mới
8. **DOCKER_DEPLOYMENT_CHECKLIST.md** - Cập nhật documentation

## 🎯 Kết quả mong đợi

Sau khi áp dụng các fix này:

1. ✅ Registration page (`/accounts/register/`) hoạt động bình thường
2. ✅ Database có đầy đủ Language fixtures
3. ✅ Static assets được load đúng cách
4. ✅ Docker build không còn thiếu file
5. ✅ Deployment process tự động và ổn định

## 🆘 Troubleshooting

Nếu vẫn gặp lỗi:

1. **Kiểm tra logs**: `docker compose logs web -f`
2. **Kiểm tra database**: `docker compose exec db mysql -u dmoj -p dmoj`
3. **Load fixtures thủ công**: `docker compose exec web bash /app/init-fixtures.sh`
4. **Restart services**: `docker compose restart`
5. **Rebuild từ đầu**: `docker compose down && docker compose build --no-cache && docker compose up -d`

## 📞 Support

Nếu vẫn gặp vấn đề, hãy:
1. Chạy `./check-docker-files.sh` để kiểm tra files
2. Kiểm tra logs chi tiết
3. Đảm bảo git submodules đã được load đúng cách 