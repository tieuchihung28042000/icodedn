# Hướng dẫn triển khai DMOJ cho icodedn.com

## Giới thiệu

Đây là hướng dẫn triển khai DMOJ Online Judge cho tên miền icodedn.com. Script triển khai đã được cập nhật để khắc phục các lỗi phổ biến.

## Các lỗi đã được sửa

1. Lỗi `django.contrib.sites.models.Site.DoesNotExist`: Site mặc định không tồn tại
2. Lỗi `TypeError: bind(): AF_INET address must be tuple, not str`: Định dạng địa chỉ bridge không đúng
3. Lỗi `ImproperlyConfigured: When using Django Compressor together with staticfiles, please add 'compressor.finders.CompressorFinder'`: Thiếu cấu hình cho compressor
4. Lỗi `Not Found: /static/...`: Các file static không được sao chép đúng cách
5. Lỗi `chmod: Operation not permitted`: Vấn đề về quyền truy cập file

## Cách triển khai

1. Đảm bảo đã cài đặt Docker và Docker Compose
2. Clone repository về máy chủ
3. Chạy script triển khai:

```bash
chmod +x deploy_icodedn_v2.sh
sudo ./deploy_icodedn_v2.sh
```

## Cấu hình Cloudflared

Đã cấu hình sẵn Cloudflared trên VPS. Script này không thực hiện bất kỳ thay đổi nào đối với cấu hình Cloudflared hiện có.

## Các lệnh hữu ích

1. Kiểm tra logs của container:
```bash
docker compose logs web
```

2. Tạo tài khoản admin:
```bash
docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings
```

3. Khởi động lại các container:
```bash
docker compose restart
```

4. Sửa lỗi site mặc định:
```bash
docker compose exec web python -c "from django.contrib.sites.models import Site; Site.objects.filter(id=1).delete(); Site.objects.create(id=1, domain='icodedn.com', name='iCodeDN')"
```

5. Sửa lỗi quyền truy cập static files:
```bash
sudo docker compose exec web chmod -R 777 /app/static /app/static_mount
```

## Xử lý sự cố

Nếu gặp lỗi "container unhealthy", hãy kiểm tra logs và thực hiện các bước sau:

1. Kiểm tra logs:
```bash
docker compose logs web
```

2. Khởi động lại container web:
```bash
docker compose restart web
```

3. Nếu vẫn gặp lỗi, hãy thực hiện lại toàn bộ quá trình triển khai:
```bash
sudo ./deploy_icodedn_v2.sh
```
