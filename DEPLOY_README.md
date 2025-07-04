# 🚀 ICODEDN.COM Deployment

## Quick Deploy

```bash
# 1. Clone repo
git clone <repo-url> /opt/icodedn
cd /opt/icodedn

# 2. Deploy
./deploy-icodedn.sh
```

## Files

- **`deploy-icodedn.sh`** - Main deploy script
- **`production.env.example`** - Environment template
- **`docker-compose.yml`** - Docker services (optimized for 1GB RAM)

## Environment Setup

Update `.env` file with:
```bash
# Generate SECRET_KEY
python3 -c "import secrets; print(secrets.token_urlsafe(50))"

# Update in .env:
SECRET_KEY=<generated-key>
DB_PASSWORD=<strong-password>
MYSQL_ROOT_PASSWORD=<strong-password>
```

## Resource Limits

- **MySQL**: 400MB RAM, 0.4 CPU
- **Redis**: 80MB RAM, 0.1 CPU  
- **Web**: 400MB RAM, 0.4 CPU
- **Celery**: 120MB RAM, 0.1 CPU
- **Total**: ~1GB RAM, 1 CPU

## Management

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Check resources
docker stats
```

## Access

- **Website**: http://icodedn.com
- **Admin**: http://icodedn.com/admin
- **Direct**: http://localhost:8000

---

**Note**: Nginx and Cloudflare should be configured separately. 