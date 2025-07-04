# Production Deployment Guide for ICODEDN.COM

## 📋 Prerequisites

1. **VPS Requirements:**
   - Ubuntu 20.04+ or CentOS 8+
   - 2GB+ RAM
   - 20GB+ Storage
   - Docker & Docker Compose installed

2. **Domain Setup:**
   - Domain: `icodedn.com`
   - Cloudflare account with domain configured
   - Cloudflare tunnel setup

## 🚀 Deployment Steps

### 1. Prepare VPS

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again to apply docker group
```

### 2. Deploy Application

```bash
# Clone repository
git clone <your-repo-url> /opt/icodedn
cd /opt/icodedn

# Make deploy script executable
chmod +x deploy.sh

# Run production deployment
./deploy.sh production
```

### 3. Configure Environment

The script will create `.env` from `production.env.example`. Update these values:

```bash
# Generate SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# Edit .env file
nano .env
```

**Important values to change:**
- `SECRET_KEY`: Use generated key above
- `DB_PASSWORD`: Strong database password
- `MYSQL_ROOT_PASSWORD`: Strong root password
- `EMAIL_*`: Configure email settings if needed

### 4. Setup Cloudflare Tunnel

```bash
# Install cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create icodedn

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: icodedn
credentials-file: ~/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: icodedn.com
    service: http://localhost:8000
  - hostname: www.icodedn.com
    service: http://localhost:8000
  - service: http_status:404
EOF

# Start tunnel
cloudflared tunnel run icodedn
```

### 5. Setup Nginx (Optional)

If you want to use nginx as reverse proxy:

```bash
# Install nginx
sudo apt install nginx -y

# Create nginx config
sudo tee /etc/nginx/sites-available/icodedn.com << EOF
server {
    listen 80;
    server_name icodedn.com www.icodedn.com;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /static/ {
        alias /opt/icodedn/static/;
        expires 30d;
    }
    
    location /media/ {
        alias /opt/icodedn/media/;
        expires 30d;
    }
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/icodedn.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Setup System Services

Create systemd service for auto-start:

```bash
sudo tee /etc/systemd/system/icodedn.service << EOF
[Unit]
Description=ICODEDN Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/icodedn
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable icodedn.service
sudo systemctl start icodedn.service
```

## 🔧 Maintenance Commands

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Update deployment
git pull
./deploy.sh production

# Backup database
docker compose exec db mysqldump -u root -p dmoj > backup_$(date +%Y%m%d).sql

# Clean up old deployment
./deploy.sh cleanup
```

## 🛡️ Security Recommendations

1. **Firewall Setup:**
   ```bash
   sudo ufw allow ssh
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw enable
   ```

2. **Regular Updates:**
   - Keep system updated
   - Update Docker images regularly
   - Monitor security advisories

3. **Backup Strategy:**
   - Daily database backups
   - Weekly full system backups
   - Store backups off-site

## 🚨 Troubleshooting

### Common Issues:

1. **Container won't start:**
   ```bash
   docker compose logs web
   ```

2. **Database connection issues:**
   ```bash
   docker compose exec db mysql -u root -p
   ```

3. **Static files not loading:**
   ```bash
   docker compose exec web python manage.py collectstatic --noinput
   ```

4. **Permission issues:**
   ```bash
   sudo chown -R $USER:$USER /opt/icodedn
   ```

## 📊 Monitoring

Set up monitoring for:
- Container health
- Database performance
- Disk usage
- Memory usage
- Response times

## 🔗 Useful Links

- [Docker Documentation](https://docs.docker.com/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [DMOJ Documentation](https://docs.dmoj.ca/) 