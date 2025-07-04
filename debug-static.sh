#!/bin/bash
set -e

echo "🔍 Debugging static files..."

echo "1. Checking git submodules..."
git submodule status

echo "2. Checking resources directory..."
ls -la resources/

echo "3. Checking vnoj directory..."
ls -la resources/vnoj/ 2>/dev/null || echo "vnoj directory not found"

echo "4. Checking libs directory..."
ls -la resources/libs/ 2>/dev/null || echo "libs directory not found"

echo "5. Checking package.json..."
cat package.json | grep -A5 -B5 "devDependencies"

echo "6. Checking if make_style.sh works..."
if [ -f make_style.sh ]; then
    echo "make_style.sh exists"
    head -10 make_style.sh
else
    echo "make_style.sh not found"
fi

echo "7. Checking if npm install works..."
npm install --dry-run 2>&1 | head -20

echo "8. Checking current static files..."
ls -la resources/style.css 2>/dev/null || echo "style.css not found"
ls -la sass_processed/ 2>/dev/null || echo "sass_processed directory not found"

echo "9. Checking Docker containers..."
docker compose ps

echo "10. Checking web container static files..."
docker compose exec web ls -la /app/static/ 2>/dev/null || echo "Cannot access container static files"

echo "11. Checking web container logs..."
docker compose logs web --tail=20 