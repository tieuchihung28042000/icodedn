FROM python:3.11-slim

# Cài đặt các gói cần thiết
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    gettext \
    curl \
    git \
    libmysqlclient-dev \
    nodejs \
    npm \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Thiết lập thư mục làm việc
WORKDIR /app

# Sao chép toàn bộ mã nguồn
COPY . /app/

# Cài đặt các gói Python
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r additional_requirements.txt

# Cài đặt các gói npm
RUN npm install

# Tạo thư mục media và cấp quyền
RUN mkdir -p /app/media/cache && chmod -R 777 /app/media

# Thu thập static files
RUN python manage.py collectstatic --noinput

# Tạo script khởi động
RUN echo '#!/bin/bash\n\
echo "Starting DMOJ web server..."\n\
echo "Waiting for database..."\n\
sleep 10\n\
python manage.py migrate --noinput\n\
python manage.py check\n\
echo "Starting judge bridge..."\n\
python manage.py runbridged &\n\
echo "Starting web server..."\n\
gunicorn dmoj.wsgi:application --bind 0.0.0.0:8000\n\
' > /app/start.sh && chmod +x /app/start.sh

# Mở cổng
EXPOSE 8000

# Khởi động
CMD ["/app/start.sh"] 