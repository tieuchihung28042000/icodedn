# ICODEDN - Online Judge Platform

🚀 **ICODEDN** là một nền tảng chấm bài trực tuyến hiện đại dành cho lập trình thi đấu, được xây dựng dựa trên DMOJ (Don Mills Online Judge).

## ✨ Tính năng chính

- 🏆 **Chấm bài tự động** - Hỗ trợ nhiều ngôn ngữ lập trình
- 📊 **Bảng xếp hạng** - Theo dõi tiến độ và thành tích
- 🎯 **Cuộc thi** - Tổ chức các cuộc thi lập trình
- 👥 **Quản lý người dùng** - Hệ thống tài khoản và phân quyền
- 📝 **Bài tập đa dạng** - Thư viện bài tập phong phú
- 🔧 **Custom Checker** - Hỗ trợ kiểm tra tùy chỉnh

## 🛠️ Công nghệ sử dụng

- **Backend**: Django (Python)
- **Database**: MySQL 8.0
- **Cache**: Redis
- **Frontend**: HTML, CSS, JavaScript
- **Deployment**: Docker, Docker Compose
- **Web Server**: Gunicorn + Nginx

## 🚀 Triển khai nhanh

### Yêu cầu hệ thống
- Docker & Docker Compose
- 2GB RAM tối thiểu
- 10GB dung lượng ổ cứng

### 1. Clone repository
```bash
git clone https://github.com/yourusername/icodedn.git
cd icodedn
```

### 2. Cấu hình môi trường
```bash
# Sao chép file cấu hình
cp production.env.example .env

# Chỉnh sửa .env với thông tin của bạn
nano .env
```

### 3. Triển khai
```bash
# Cho môi trường phát triển
./deploy-local.sh

# Cho môi trường production
./deploy-production.sh
```

## 🌐 Truy cập

- **Website**: https://icodedn.com
- **Admin Panel**: https://icodedn.com/admin
- **API**: https://icodedn.com/api/

## 📋 Cấu hình môi trường

### Biến môi trường quan trọng:

```env
# Site Configuration
SITE_FULL_URL=https://icodedn.com
SITE_NAME=ICODEDN
ALLOWED_HOSTS=icodedn.com,www.icodedn.com

# Database
DB_NAME=dmoj
DB_USER=dmoj
DB_PASSWORD=your-strong-password

# Security
SECRET_KEY=your-secret-key-here
DEBUG=False
```

## 🔧 Lệnh hữu ích

```bash
# Xem logs
docker compose logs -f

# Khởi động lại
docker compose restart

# Dừng dịch vụ
docker compose down

# Truy cập shell
docker compose exec web bash

# Backup database
docker compose exec db mysqldump -u root -p dmoj > backup.sql
```

## 📚 Hướng dẫn sử dụng

### Tạo bài tập mới
1. Đăng nhập admin panel
2. Vào **Problems** → **Add Problem**
3. Điền thông tin bài tập
4. Upload test cases
5. Publish bài tập

### Tổ chức cuộc thi
1. Vào **Contests** → **Add Contest**
2. Cấu hình thời gian và quy tắc
3. Thêm bài tập vào cuộc thi
4. Công bố cuộc thi

## 🛡️ Bảo mật

- ✅ HTTPS bắt buộc
- ✅ Xác thực 2FA
- ✅ Rate limiting
- ✅ SQL injection protection
- ✅ XSS protection

## 🤝 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng:

1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Tạo Pull Request

## 📄 License

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

## 🔗 Liên kết

- **Website**: https://icodedn.com
- **Documentation**: https://docs.icodedn.com
- **Support**: admin@icodedn.com

## 🙏 Cảm ơn

Cảm ơn đội ngũ phát triển [DMOJ](https://github.com/DMOJ/online-judge) đã tạo ra nền tảng tuyệt vời này.

---

Made with ❤️ by ICODEDN Team
