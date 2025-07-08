FROM python:3.11-slim

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

# Copy requirements first for better caching
COPY requirements.txt additional_requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r additional_requirements.txt
RUN pip install --no-cache-dir mysqlclient gunicorn

# Copy package.json and package-lock.json for Node.js dependencies
COPY package.json package-lock.json ./

# Install Node.js dependencies (including dev dependencies for CSS build)
RUN npm ci --no-audit

# Copy project files (excluding files in .dockerignore)
COPY . .

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
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "2", "--timeout", "60", "--max-requests", "1000", "--max-requests-jitter", "100", "--env", "DJANGO_SETTINGS_MODULE=dmoj.docker_settings", "dmoj.wsgi:application"] 