#!/usr/bin/env python
import os
import django

# Thiết lập môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.docker_settings')
django.setup()

from django.conf import settings

# Kiểm tra cấu hình bridge
print("Cấu hình bridge hiện tại:")
print(f"BRIDGED_JUDGE_ADDRESS: {settings.BRIDGED_JUDGE_ADDRESS}")
print(f"BRIDGED_DJANGO_ADDRESS: {settings.BRIDGED_DJANGO_ADDRESS}")

# Kiểm tra xem địa chỉ có đúng định dạng không
def check_address(address):
    if isinstance(address, str):
        print(f"Địa chỉ {address} không đúng định dạng. Cần là tuple (host, port)")
        return False
    elif isinstance(address, (list, tuple)) and len(address) == 2:
        print(f"Địa chỉ {address} đúng định dạng (host, port)")
        return True
    else:
        print(f"Địa chỉ {address} không đúng định dạng. Cần là tuple (host, port)")
        return False

check_address(settings.BRIDGED_JUDGE_ADDRESS)
check_address(settings.BRIDGED_DJANGO_ADDRESS)

print("\nĐể sửa lỗi này, bạn cần cập nhật cấu hình trong file dmoj/docker_settings.py:")
print("BRIDGED_JUDGE_ADDRESS = ('0.0.0.0', 9999)")
print("BRIDGED_DJANGO_ADDRESS = ('0.0.0.0', 9998)") 