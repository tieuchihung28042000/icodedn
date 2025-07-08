# 🔐 Fix Login Issue cho DMOJ

## ❌ Vấn đề gặp phải

Khi đăng nhập vào admin, gặp lỗi:
```
Forbidden (Origin checking failed - https://icodedn.com does not match any trusted origins.): /accounts/login/
```

## 🔍 Nguyên nhân

1. **ALLOWED_HOSTS** không bao gồm domain `icodedn.com`
2. **CSRF_TRUSTED_ORIGINS** chưa được cấu hình cho Django 4.0+
3. Django security mechanism chặn requests từ untrusted origins

## ✅ Giải pháp đã áp dụng

### 1. Cập nhật ALLOWED_HOSTS

**File: `dmoj/docker_settings.py`**
```python
# Trước
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Sau  
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1,icodedn.com').split(',')
```

### 2. Thêm CSRF_TRUSTED_ORIGINS

**File: `dmoj/docker_settings.py`**
```python
# CSRF trusted origins for Django 4.0+
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'http://127.0.0.1:8000', 
    'https://icodedn.com',
    'http://icodedn.com',
]

# Add environment variable support for additional trusted origins
if os.environ.get('CSRF_TRUSTED_ORIGINS'):
    additional_origins = os.environ.get('CSRF_TRUSTED_ORIGINS').split(',')
    CSRF_TRUSTED_ORIGINS.extend(additional_origins)
```

### 3. Cập nhật Docker Compose

**File: `docker-compose.yml`**
```yaml
environment:
  ALLOWED_HOSTS: ${ALLOWED_HOSTS:-localhost,127.0.0.1,icodedn.com}
  CSRF_TRUSTED_ORIGINS: ${CSRF_TRUSTED_ORIGINS:-https://icodedn.com,http://icodedn.com}
```

## 🚀 Cách áp dụng fix

### Option 1: Restart web container (nhanh)
```bash
./restart-web.sh
```

### Option 2: Restart thủ công
```bash
docker compose stop web
docker compose rm -f web
docker compose up -d web
```

### Option 3: Rebuild toàn bộ
```bash
docker compose down
docker compose up --build -d
```

## 🔧 Kiểm tra sau khi fix

### 1. Kiểm tra container status
```bash
docker compose ps
```

### 2. Kiểm tra logs
```bash
docker compose logs web -f
```

### 3. Test login
- Truy cập: https://icodedn.com/accounts/login/
- Username: `admin`
- Password: `@654321`

## 📊 Kết quả mong đợi

Sau khi fix:
- ✅ Không còn lỗi "Origin checking failed"
- ✅ Có thể đăng nhập admin bình thường
- ✅ CSRF protection vẫn hoạt động đúng
- ✅ Hỗ trợ cả HTTP và HTTPS

## 🔗 URLs được hỗ trợ

- ✅ http://localhost:8000
- ✅ http://127.0.0.1:8000
- ✅ https://icodedn.com
- ✅ http://icodedn.com

## 💡 Lưu ý quan trọng

1. **Environment Variables**: Có thể override qua .env file
```env
ALLOWED_HOSTS=localhost,127.0.0.1,icodedn.com,yourdomain.com
CSRF_TRUSTED_ORIGINS=https://icodedn.com,https://yourdomain.com
```

2. **Security**: Chỉ thêm domains bạn tin tưởng vào ALLOWED_HOSTS

3. **HTTPS**: Nên sử dụng HTTPS trong production

## 🔧 Troubleshooting

### Nếu vẫn gặp lỗi login:

1. **Kiểm tra environment variables:**
```bash
docker compose exec web env | grep -E "(ALLOWED_HOSTS|CSRF_TRUSTED_ORIGINS)"
```

2. **Kiểm tra Django settings:**
```bash
docker compose exec web python manage.py shell --settings=dmoj.docker_settings -c "
from django.conf import settings
print('ALLOWED_HOSTS:', settings.ALLOWED_HOSTS)
print('CSRF_TRUSTED_ORIGINS:', settings.CSRF_TRUSTED_ORIGINS)
"
```

3. **Clear browser cache/cookies**

4. **Kiểm tra logs chi tiết:**
```bash
docker compose logs web | grep -i "forbidden\|csrf\|origin"
```

## 📁 Files đã thay đổi

1. `dmoj/docker_settings.py` - Thêm ALLOWED_HOSTS và CSRF_TRUSTED_ORIGINS
2. `docker-compose.yml` - Cập nhật environment variables
3. `restart-web.sh` - Script restart nhanh (mới)
4. `LOGIN_FIX.md` - Tài liệu này 