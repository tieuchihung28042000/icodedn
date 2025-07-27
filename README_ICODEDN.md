# Hướng dẫn triển khai DMOJ cho icodedn.com

Tài liệu này hướng dẫn cách triển khai hệ thống DMOJ (Online Judge) cho tên miền icodedn.com trên VPS.

## Các file cấu hình

1. **deploy_icodedn.sh**: Script chính để triển khai toàn bộ hệ thống
2. **fix_settings.py**: Script được tạo tự động để sửa lỗi cấu hình Django
3. **create_site.py**: Script được tạo tự động để tạo site mặc định

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

Chạy script triển khai với quyền sudo (để có thể cấp quyền cho các thư mục):

```bash
sudo ./deploy_icodedn.sh
```

Script này sẽ thực hiện các công việc sau:
- Tạo file .env với cấu hình cho icodedn.com
- Tạo file .gitignore để loại bỏ các file local
- Dừng các container hiện tại
- Xóa các volume cũ
- Tạo các thư mục cần thiết và cấp quyền đúng
- Tạo file cấu hình Django để sửa lỗi compressor
- Tạo script để tạo site mặc định
- Sửa Dockerfile để tránh lỗi quyền truy cập
- Xây dựng và khởi động các container
- Chạy migrations và sửa lỗi
- Khởi động lại container web

## Xử lý lỗi phổ biến

### 1. Lỗi Site.DoesNotExist

Lỗi: `django.contrib.sites.models.Site.DoesNotExist: Site matching query does not exist.`

Khắc phục: Script `create_site.py` được tạo tự động để sửa lỗi này. Nếu cần chạy lại:
```bash
docker compose cp create_site.py web:/app/
docker compose exec web python /app/create_site.py
```

Hoặc tạo site thủ công:
```bash
docker compose exec web python -c "from django.contrib.sites.models import Site; Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')"
```

### 2. Lỗi Django Compressor

Lỗi: `django.core.exceptions.ImproperlyConfigured: When using Django Compressor together with staticfiles, please add 'compressor.finders.CompressorFinder' to the STATICFILES_FINDERS setting.`

Khắc phục: Script `fix_settings.py` được tạo tự động để sửa lỗi này. Nếu cần chạy lại:
```bash
docker compose cp fix_settings.py web:/app/
docker compose exec web python /app/fix_settings.py
```

### 3. Lỗi quyền truy cập (Permission denied)

Nếu gặp lỗi "Operation not permitted" hoặc "Permission denied":

```bash
sudo chown -R $(whoami):$(whoami) /path/to/icodedn.com/static /path/to/icodedn.com/media
sudo chmod -R 777 /path/to/icodedn.com/static /path/to/icodedn.com/media
```

### 4. Lỗi container unhealthy

Kiểm tra logs:

```bash
docker compose logs web
```

Khởi động lại container:

```bash
docker compose restart web
```

### 5. Lỗi bridge address

Lỗi: `TypeError: bind(): AF_INET address must be tuple, not str`

Khắc phục: Script `fix_settings.py` được tạo tự động để sửa lỗi này. Nếu cần chạy lại:
```bash
docker compose cp fix_settings.py web:/app/
docker compose exec web python /app/fix_settings.py
```

## Cấu trúc thư mục

```
/home/chihung2k/sites/icodedn.com/
├── docker-compose.yml    # File cấu hình Docker Compose
├── .env                  # File cấu hình môi trường
├── .gitignore            # File gitignore
├── fix_settings.py       # Script sửa lỗi cấu hình
├── create_site.py        # Script tạo site mặc định
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