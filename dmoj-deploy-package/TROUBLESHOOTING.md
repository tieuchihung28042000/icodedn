# Hướng dẫn xử lý lỗi DMOJ

Hướng dẫn này giúp bạn xử lý các lỗi thường gặp khi sử dụng DMOJ.

## 1. Lỗi "No judge is available"

### Triệu chứng
- Khi submit bài, hiển thị thông báo "No judge is available for this problem"
- Submissions bị stuck ở trạng thái "Queued"

### Nguyên nhân
- Judge server không hoạt động
- Kết nối giữa web và judge bị gián đoạn
- Judge không được cấu hình đúng

### Giải pháp
```bash
# Kiểm tra trạng thái judge container
docker-compose ps judge

# Kiểm tra logs của judge
docker-compose logs judge

# Restart judge container
docker-compose restart judge

# Kiểm tra kết nối từ web container đến judge
docker-compose exec web ping judge

# Kiểm tra cấu hình judge trong database
docker-compose exec web python manage.py shell -c "from judge.models import Judge; print([(j.name, j.online) for j in Judge.objects.all()])"

# Tạo judge mới nếu cần
docker-compose exec web python manage.py addjudge judge1 web 9999 --auth-key=key
```

## 2. Lỗi static files

### Triệu chứng
- Giao diện bị vỡ, thiếu CSS/JS
- Console browser hiển thị lỗi 404 cho các file static

### Nguyên nhân
- Static files chưa được build
- Volume static không được mount đúng
- Permissions không đúng

### Giải pháp
```bash
# Rebuild static files
docker-compose exec web python manage.py collectstatic --noinput
docker-compose exec web python manage.py compilemessages
docker-compose exec web python manage.py compilejsi18n

# Kiểm tra thư mục static
docker-compose exec web ls -la /app/static

# Kiểm tra cấu hình static trong settings
docker-compose exec web python -c "from django.conf import settings; print(settings.STATIC_ROOT, settings.STATIC_URL)"

# Restart web container
docker-compose restart web
```

## 3. Lỗi database

### Triệu chứng
- Lỗi "Could not connect to database"
- Lỗi migration

### Nguyên nhân
- Database chưa khởi động
- Credentials không đúng
- Migration chưa được apply

### Giải pháp
```bash
# Kiểm tra trạng thái database
docker-compose ps db

# Kiểm tra logs database
docker-compose logs db

# Kiểm tra kết nối database
docker-compose exec web python manage.py dbshell

# Chạy migrations
docker-compose exec web python manage.py migrate

# Kiểm tra migrations đã được apply
docker-compose exec web python manage.py showmigrations

# Restart database nếu cần
docker-compose restart db
```

## 4. Lỗi permissions

### Triệu chứng
- Lỗi "Permission denied" trong logs
- Không thể tạo/sửa files

### Nguyên nhân
- File permissions không đúng
- Volume mounts không đúng

### Giải pháp
```bash
# Kiểm tra permissions
docker-compose exec web ls -la /app/static /app/media /problems

# Fix permissions
docker-compose exec web chmod -R 777 /app/static /app/media /problems

# Kiểm tra volume mounts
docker-compose config
```

## 5. Lỗi WebSocket

### Triệu chứng
- Realtime updates không hoạt động
- Notifications không hiển thị

### Nguyên nhân
- WebSocket server không hoạt động
- Kết nối WebSocket bị chặn

### Giải pháp
```bash
# Kiểm tra trạng thái wsevent container
docker-compose ps wsevent

# Kiểm tra logs wsevent
docker-compose logs wsevent

# Restart wsevent container
docker-compose restart wsevent

# Kiểm tra cấu hình WebSocket trong settings
docker-compose exec web python -c "from django.conf import settings; print(settings.EVENT_DAEMON_USE, settings.EVENT_DAEMON_POST, settings.EVENT_DAEMON_GET)"
```

## 6. Lỗi Celery

### Triệu chứng
- Background tasks không hoạt động
- Lỗi "unhealthy" trong celery container

### Nguyên nhân
- Celery không kết nối được với Redis
- Celery worker crash

### Giải pháp
```bash
# Kiểm tra trạng thái celery container
docker-compose ps celery

# Kiểm tra logs celery
docker-compose logs celery

# Restart celery container
docker-compose restart celery

# Kiểm tra kết nối Redis
docker-compose exec redis redis-cli ping

# Kiểm tra celery tasks
docker-compose exec web celery -A dmoj inspect active
```

## 7. Lỗi khi deploy lên VPS

### Triệu chứng
- Script deploy không hoàn thành
- Containers không khởi động

### Nguyên nhân
- Thiếu dependencies
- Ports đã được sử dụng
- Không đủ quyền

### Giải pháp
```bash
# Kiểm tra Docker đã được cài đặt
ssh user@vps "docker --version"

# Kiểm tra ports đã được sử dụng
ssh user@vps "netstat -tuln | grep -E ':(8000|3306|6379)'"

# Kiểm tra disk space
ssh user@vps "df -h"

# Kiểm tra memory
ssh user@vps "free -h"

# Kiểm tra logs
ssh user@vps "cd ~/dmoj-deploy && docker-compose logs"
```

## 8. Lỗi HTTPS/Nginx

### Triệu chứng
- Không thể truy cập qua HTTPS
- Lỗi SSL

### Nguyên nhân
- Nginx không được cấu hình đúng
- Certbot không thành công

### Giải pháp
```bash
# Kiểm tra cấu hình Nginx
ssh user@vps "nginx -t"

# Kiểm tra logs Nginx
ssh user@vps "tail -f /var/log/nginx/error.log"

# Chạy lại Certbot
ssh user@vps "certbot --nginx -d your-domain.com"

# Kiểm tra SSL certificate
ssh user@vps "certbot certificates"

# Restart Nginx
ssh user@vps "systemctl restart nginx"
```

## Liên hệ hỗ trợ

Nếu bạn vẫn gặp vấn đề sau khi thử các giải pháp trên, vui lòng liên hệ với chúng tôi qua:
- GitHub Issues: https://github.com/your-repo/dmoj-deploy/issues
- Email: support@example.com 