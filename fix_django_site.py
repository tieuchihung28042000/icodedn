#!/usr/bin/env python
import os
import django

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.settings')
django.setup()

# Import Site model
from django.contrib.sites.models import Site

# Kiểm tra xem đã có site nào chưa
sites = Site.objects.all()
if not sites.exists():
    print("Không tìm thấy site nào. Đang tạo site mặc định...")
    # Tạo site mặc định với ID=1
    site = Site.objects.create(id=1, domain='localhost:8000', name='DMOJ')
    print(f"Đã tạo site mặc định: {site.domain}")
else:
    print("Đã tồn tại site:")
    for site in sites:
        print(f"ID: {site.id}, Domain: {site.domain}, Name: {site.name}") 