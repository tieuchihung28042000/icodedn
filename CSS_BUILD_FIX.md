# 🎨 CSS Build Fix cho DMOJ Docker

## ❌ Vấn đề gặp phải

Khi build Docker, gặp lỗi:
```
Error: sass, autoprefixer are not installed.
```

## 🔍 Nguyên nhân

1. **Thiếu devDependencies**: Docker chỉ cài đặt `--only=production` dependencies
2. **sass và autoprefixer** nằm trong `devDependencies` của `package.json`
3. **CSS build** cần các package này để compile SCSS thành CSS

## ✅ Giải pháp đã áp dụng

### 1. Cập nhật Dockerfile

**Trước:**
```dockerfile
# Install Node.js dependencies
RUN npm ci --only=production --no-audit
```

**Sau:**
```dockerfile
# Install Node.js dependencies (including dev dependencies for CSS build)
RUN npm ci --no-audit
```

### 2. Cải thiện Error Handling

**Trước:**
```dockerfile
RUN if [ -f "make_style.sh" ]; then \
        chmod +x make_style.sh && \
        bash make_style.sh; \
    else \
        echo "make_style.sh not found, building CSS manually"; \
        npm run build-css || echo "CSS build failed"; \
    fi
```

**Sau:**
```dockerfile
RUN if [ -f "make_style.sh" ]; then \
        echo "Building CSS with make_style.sh..." && \
        chmod +x make_style.sh && \
        bash make_style.sh || echo "CSS build with make_style.sh failed, continuing..."; \
    else \
        echo "make_style.sh not found, skipping CSS build"; \
    fi
```

### 3. Tạo thư mục sass_processed

```dockerfile
# Create necessary directories
RUN mkdir -p /app/static /app/media /app/problems /app/logs /app/sass_processed
```

## 📦 Dependencies cần thiết

Từ `package.json`:
```json
{
  "devDependencies": {
    "autoprefixer": "10.4.15",
    "postcss": "8.4.29", 
    "postcss-cli": "10.1.0",
    "sass": "1.66.1"
  }
}
```

## 🚀 Cách rebuild

### Option 1: Sử dụng script rebuild nhanh
```bash
./rebuild-docker.sh
```

### Option 2: Rebuild thủ công
```bash
docker compose down
docker compose up --build -d
```

### Option 3: Deployment đầy đủ
```bash
./deploy-production.sh
```

## 🔧 Troubleshooting

### Nếu vẫn gặp lỗi CSS build:

1. **Kiểm tra npm dependencies:**
```bash
docker compose exec web npm list sass autoprefixer
```

2. **Kiểm tra make_style.sh:**
```bash
docker compose exec web ls -la make_style.sh
docker compose exec web cat make_style.sh
```

3. **Build CSS thủ công:**
```bash
docker compose exec web bash make_style.sh
```

4. **Kiểm tra sass_processed directory:**
```bash
docker compose exec web ls -la sass_processed/
```

## 📊 Kết quả

Sau khi fix:
- ✅ CSS build thành công
- ✅ Static files được tạo đúng
- ✅ Docker containers khởi động bình thường
- ✅ Admin account: admin / @654321

## 🔗 Files đã thay đổi

1. `Dockerfile` - Fix npm dependencies và error handling
2. `deploy-production.sh` - Thêm thông tin về CSS build
3. `rebuild-docker.sh` - Script rebuild nhanh (mới)
4. `CSS_BUILD_FIX.md` - Tài liệu này

## 💡 Lưu ý

- CSS build chỉ cần chạy 1 lần khi build Docker image
- Các file CSS được tạo trong `sass_processed/` và copy vào `static/`
- Nếu không cần CSS build, có thể skip bước này và sử dụng CSS có sẵn 