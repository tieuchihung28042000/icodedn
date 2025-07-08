#!/bin/bash

echo "🔧 Loading DMOJ initial fixtures..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're running inside Docker or locally
if [ -f "/.dockerenv" ]; then
    PYTHON_CMD="python"
    SETTINGS="--settings=dmoj.docker_settings"
    echo -e "${BLUE}Running inside Docker container${NC}"
else
    PYTHON_CMD="python"
    SETTINGS=""
    echo -e "${BLUE}Running locally${NC}"
fi

echo ""
echo -e "${BLUE}📋 Loading Language fixtures...${NC}"
if $PYTHON_CMD manage.py loaddata judge/fixtures/language_small.json $SETTINGS; then
    echo -e "${GREEN}✅ Language fixtures loaded successfully${NC}"
else
    echo -e "${YELLOW}⚠ Language fixtures may already be loaded or failed to load${NC}"
fi

echo ""
echo -e "${BLUE}📋 Loading Demo fixtures (optional)...${NC}"
if $PYTHON_CMD manage.py loaddata judge/fixtures/demo.json $SETTINGS; then
    echo -e "${GREEN}✅ Demo fixtures loaded successfully${NC}"
else
    echo -e "${YELLOW}⚠ Demo fixtures may already be loaded or failed to load${NC}"
fi

echo ""
echo -e "${BLUE}📋 Creating default admin user (if needed)...${NC}"
$PYTHON_CMD manage.py shell $SETTINGS -c "
from django.contrib.auth import get_user_model
from judge.models import Profile, Language
User = get_user_model()

# Create admin user if not exists
if not User.objects.filter(username='admin').exists():
    print('Creating admin user...')
    admin_user = User.objects.create_superuser('admin', 'admin@localhost', 'admin123')
    print('✅ Admin user created successfully')
    print('   Username: admin')
    print('   Password: admin123')
    print('   Email: admin@localhost')
else:
    print('ℹ️ Admin user already exists')
    admin_user = User.objects.get(username='admin')

# Ensure admin has profile
if not hasattr(admin_user, 'profile'):
    try:
        default_lang = Language.objects.first()
        if default_lang:
            profile = Profile(user=admin_user, language=default_lang)
            profile.save()
            print('✅ Admin profile created')
        else:
            print('⚠️ No languages found, cannot create profile')
    except Exception as e:
        print(f'⚠️ Could not create profile: {e}')
else:
    print('ℹ️ Admin profile already exists')
" 2>/dev/null || echo "Could not create admin user - run manually"

echo ""
echo -e "${BLUE}📋 Manual superuser creation:${NC}"
echo "If you need to create additional users manually:"
echo "  docker compose exec web python manage.py createsuperuser --settings=dmoj.docker_settings"
echo "  OR"
echo "  python manage.py createsuperuser"

echo ""
echo -e "${GREEN}🎉 Fixtures loading completed!${NC}"
echo ""
echo -e "${BLUE}📊 Available languages:${NC}"
$PYTHON_CMD manage.py shell $SETTINGS -c "
from judge.models import Language
langs = Language.objects.all()
if langs.exists():
    for lang in langs[:10]:  # Show first 10 languages
        print(f'  - {lang.key}: {lang.name}')
    if langs.count() > 10:
        print(f'  ... and {langs.count() - 10} more')
else:
    print('  No languages found in database')
" 2>/dev/null || echo "Could not query database"

echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
echo "1. Create a superuser account"
echo "2. Access the web interface at http://localhost:8000"
echo "3. Go to admin panel to configure judges and problems" 