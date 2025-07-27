#!/usr/bin/env python3
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'dmoj.settings')
django.setup()

from django.conf import settings

# Print bridge configuration
print("Bridge configuration:")
print(f"BRIDGED_JUDGE_ADDRESS: {settings.BRIDGED_JUDGE_ADDRESS}")
print(f"BRIDGED_DJANGO_ADDRESS: {settings.BRIDGED_DJANGO_ADDRESS}")
print(f"BRIDGED_DJANGO_CONNECT: {settings.BRIDGED_DJANGO_CONNECT}")

# Check if judge servers are configured
from judge.models import Judge
judges = Judge.objects.all()
print(f"Number of judges: {judges.count()}")
for judge in judges:
    print(f"Judge: {judge.name}, Online: {judge.online}, Last ping: {judge.last_ping}")
