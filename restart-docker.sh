#!/bin/bash

echo "===== Restarting DMOJ Docker containers ====="

# Stop and remove containers
echo "Stopping and removing containers..."
docker compose down

# Rebuild images
echo "Rebuilding images..."
docker compose build

# Start containers
echo "Starting containers..."
docker compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Check container status
echo "Checking container status..."
docker compose ps

# Check logs for any errors
echo "Checking logs for errors..."
docker compose logs --tail=20

echo "===== Restart complete ====="
echo "You can check the full logs with: docker compose logs -f"
echo "Access the site at: http://localhost:8000"
echo "Admin login: admin / @654321" 