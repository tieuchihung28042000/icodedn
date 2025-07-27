# Hướng dẫn triển khai DMOJ cho icodedn.com

Tài liệu này hướng dẫn cách triển khai hệ thống DMOJ (Online Judge) cho tên miền icodedn.com trên VPS.

## Các file cấu hình

1. **deploy_icodedn.sh**: Script chính để triển khai toàn bộ hệ thống
2. **fix_judge_bridge.py**: Script sửa lỗi judge bridge
3. **fix_static_files.py**: Script sửa lỗi static files

## Các bước triển khai

### 1. Chuẩn bị

Đảm bảo bạn đã cài đặt các phần mềm sau:
- Docker
- Docker Compose
- Git

### 2. Clone repository

```bash
git clone https://github.com/tieuchihung28042000/icodedn.git
cd icodedn
```

### 3. Triển khai hệ thống

Chạy script triển khai:

```bash
chmod +x deploy_icodedn.sh
./deploy_icodedn.sh
```

Script này sẽ thực hiện các công việc sau:
- Tạo file .env với cấu hình cho icodedn.com
- Dừng các container hiện tại
- Xóa các volume cũ
- Tạo các thư mục cần thiết
- Xây dựng và khởi động các container
- Chạy migrations
- Sửa lỗi judge bridge và static files
- Tạo site mặc định

## Cấu trúc thư mục

```
/home/chihung2k/sites/icodedn.com/
├── docker-compose.yml    # File cấu hình Docker Compose
├── .env                  # File cấu hình môi trường
├── logs/                 # Thư mục chứa log
├── static/               # Thư mục chứa static files
├── media/                # Thư mục chứa media files
└── problems/             # Thư mục chứa dữ liệu bài tập
```

## Cấu hình Docker

File `docker-compose.yml` định nghĩa các service:
- **db**: MySQL database
- **redis**: Redis cache
- **web**: Web server (Django)
- **celery**: Celery worker
- **judge**: Judge server

## Các lỗi thường gặp và cách khắc phục

### 1. Lỗi bridge address

Lỗi: `TypeError: bind(): AF_INET address must be tuple, not str`

Khắc phục: Chạy script `fix_judge_bridge.py` để sửa cấu hình bridge:
```bash
docker compose exec web python /app/fix_judge_bridge.py
```

### 2. Lỗi static files

Lỗi: Thiếu các file CSS, JavaScript, hình ảnh

Khắc phục: Chạy script `fix_static_files.py` để sao chép các file từ resources vào static:
```bash
docker compose exec web python /app/fix_static_files.py
```

### 3. Lỗi site không tồn tại

Lỗi: `django.contrib.sites.models.Site.DoesNotExist: Site matching query does not exist.`

Khắc phục: Tạo site mặc định:
```bash
docker compose exec web python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()
from django.contrib.sites.models import Site
Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')
"
```

## Kiểm tra hệ thống

Sau khi triển khai xong, truy cập:
- https://icodedn.com

## Bảo trì hệ thống

### Khởi động lại hệ thống

```bash
docker compose restart
```

### Xem log

```bash
docker compose logs -f web
docker compose logs -f judge
```

### Cập nhật code

```bash
git pull
docker compose build
docker compose up -d
```

## Liên hệ hỗ trợ

Nếu gặp vấn đề, vui lòng liên hệ:
- Email: admin@icodedn.com 