#!/bin/bash

echo "===== Activating all user accounts ====="

# Activate all existing users
echo "Activating existing users..."
docker exec -it dmoj_web python manage.py activate_all_users --settings=dmoj.docker_settings

# Update database directly
echo "Updating database directly..."
docker exec -it dmoj_db mysql -u root -p${DB_ROOT_PASSWORD:-root123} -e "USE ${DB_NAME:-dmoj}; UPDATE auth_user SET is_active = 1 WHERE is_active = 0;"

echo "===== Activation complete ====="
echo "All user accounts should now be active." 