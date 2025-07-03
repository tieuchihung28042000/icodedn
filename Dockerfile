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

# Copy project
COPY . .

# Create necessary directories
RUN mkdir -p /app/static /app/media /app/problems /app/logs

    # Install Node.js dependencies and build assets
    RUN npm install
    RUN bash make_style.sh

# Skip collectstatic for now (will do it after container starts)
# ENV DJANGO_SETTINGS_MODULE=dmoj.docker_settings
# RUN python manage.py collectstatic --noinput --settings=dmoj.docker_settings

# Create non-root user (commented out for local development)
# RUN useradd --create-home --shell /bin/bash dmoj
# RUN chown -R dmoj:dmoj /app
# USER dmoj

# Expose port
EXPOSE 8000

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "--env", "DJANGO_SETTINGS_MODULE=dmoj.docker_settings", "dmoj.wsgi:application"] 