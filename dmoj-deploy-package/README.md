# DMOJ Docker Deployment

Bộ triển khai DMOJ (Online Judge) sử dụng Docker, đã được đóng gói đầy đủ để tránh lỗi khi deploy trên VPS.

## Tính năng

- ✅ Đóng gói đầy đủ các thành phần cần thiết
- ✅ Tự động cài đặt và cấu hình
- ✅ Hỗ trợ tất cả các ngôn ngữ lập trình
- ✅ Tích hợp judge server
- ✅ Tự động khởi động lại khi gặp lỗi
- ✅ Dễ dàng backup và restore
- ✅ Tối ưu hóa cho VPS với tài nguyên hạn chế

## Cấu trúc thư mục

```
dmoj-deploy/
├── docker/
│   └── mysql/
│       └── mysql-init.sql      # Script khởi tạo MySQL
├── problems/                   # Thư mục chứa bài tập
├── static/                     # Thư mục chứa static files
├── media/                      # Thư mục chứa media files
├── Dockerfile                  # File build Docker image
├── docker-compose.yml          # File cấu hình Docker Compose
├── local_settings.py           # Cấu hình Django
├── .env.example                # Mẫu file environment variables
├── check-before-build.sh       # Script kiểm tra trước khi build
├── start.sh                    # Script khởi động
└── check-errors.sh             # Script kiểm tra lỗi
```

## Yêu cầu hệ thống

- Docker
- Docker Compose
- 2GB RAM trở lên
- 10GB disk space trở lên

## Hướng dẫn cài đặt

### 1. Clone repository

```bash
git clone https://github.com/your-repo/dmoj-deploy.git
cd dmoj-deploy
```

### 2. Cấu hình môi trường

```bash
cp .env.example .env
# Chỉnh sửa file .env theo nhu cầu
```

### 3. Cấp quyền thực thi cho các script

```bash
chmod +x *.sh
```

### 4. Kiểm tra trước khi build

```bash
./check-before-build.sh
```

### 5. Khởi động DMOJ

```bash
./start.sh
```

### 6. Kiểm tra lỗi (nếu cần)

```bash
./check-errors.sh
```

## Triển khai lên VPS

Sử dụng script `deploy-vps.sh` để triển khai lên VPS:

```bash
./deploy-vps.sh user@your-vps-host
```

## Truy cập

- Web UI: http://localhost:8000
- Admin: http://localhost:8000/admin
- Username: admin
- Password: admin

## Các lệnh hữu ích

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

### Backup database

```bash
docker-compose exec db mysqldump -u dmoj -pdmojpass dmoj > backup.sql
```

### Restore database

```bash
cat backup.sql | docker-compose exec -T db mysql -u dmoj -pdmojpass dmoj
```

## Troubleshooting

### 1. Lỗi "No judge is available"

- Kiểm tra judge container có đang chạy không
- Kiểm tra kết nối giữa web và judge
- Restart judge container

### 2. Lỗi static files

- Rebuild static files:
  ```bash
  docker-compose exec web python manage.py collectstatic --noinput
  docker-compose exec web python manage.py compilemessages
  docker-compose exec web python manage.py compilejsi18n
  ```

### 3. Lỗi database

- Kiểm tra kết nối database:
  ```bash
  docker-compose exec web python manage.py dbshell
  ```

## Cấu trúc Docker Compose

- **db**: MySQL database
- **redis**: Redis cache
- **web**: Django web server + judge bridge
- **celery**: Background tasks
- **wsevent**: WebSocket server
- **judge**: Judge server

## Hỗ trợ

Nếu gặp vấn đề, vui lòng tạo issue hoặc liên hệ với chúng tôi. 