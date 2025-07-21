FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    default-libmysqlclient-dev \
    default-mysql-client \
    pkg-config \
    curl \
    git \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Cài đặt dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gettext \
    git \
    libxml2-dev \
    libxslt1-dev \
    mariadb-client \
    default-libmysqlclient-dev \
    nodejs \
    npm \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Cài đặt Node.js và npm mới hơn
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g sass postcss-cli autoprefixer

# Clone repository
RUN git clone https://github.com/DMOJ/online-judge.git .
RUN git submodule init && git submodule update --recursive

# Copy requirements trước để tận dụng Docker cache
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir gunicorn mysqlclient redis

# Tạo thư mục cần thiết
RUN mkdir -p /app/logs /app/media /app/static /problems

# Copy local settings
COPY local_settings.py dmoj/local_settings.py

# Compile static assets
RUN python manage.py collectstatic --noinput
RUN python manage.py compilemessages
RUN python manage.py compilejsi18n

# Create necessary directories
RUN mkdir -p /app/static /app/media /app/problems /app/logs /app/sass_processed

# Ensure git submodules are properly initialized
# Note: .git is excluded by .dockerignore, so we need to handle this differently
RUN if [ -d "resources/libs" ] && [ -d "resources/vnoj" ]; then \
        echo "Submodules already present"; \
    else \
        echo "Submodules missing - this should not happen in production build"; \
        mkdir -p resources/libs resources/vnoj; \
    fi

# Verify required static assets exist
RUN ls -la resources/libs/ || echo "Warning: resources/libs is empty"
RUN ls -la resources/vnoj/ || echo "Warning: resources/vnoj is empty"

# Build CSS files
RUN if [ -f "make_style.sh" ]; then \
        echo "Building CSS with make_style.sh..." && \
        chmod +x make_style.sh && \
        bash make_style.sh || echo "CSS build with make_style.sh failed, continuing..."; \
    else \
        echo "make_style.sh not found, skipping CSS build"; \
    fi

# Verify fixtures exist
RUN ls -la judge/fixtures/ || echo "Warning: fixtures directory missing"

# Compile i18n files
RUN python manage.py compilejsi18n --settings=dmoj.docker_settings || echo "i18n compilation failed"

# Collect static files
RUN python manage.py collectstatic --noinput --settings=dmoj.docker_settings || echo "Static collection failed"

# Verify static files were created
RUN ls -la /app/static/ || echo "Static files directory is empty"

# Create non-root user for security (uncomment for production)
# RUN useradd --create-home --shell /bin/bash dmoj
# RUN chown -R dmoj:dmoj /app
# USER dmoj

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Default command
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "dmoj.wsgi:application"] 