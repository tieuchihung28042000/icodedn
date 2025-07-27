#!/usr/bin/env python3
import os
import sys
import json

def fix_judge_bridge():
    """
    Sửa lỗi judge bridge bằng cách đảm bảo BRIDGED_JUDGE_ADDRESS và BRIDGED_DJANGO_ADDRESS
    được định dạng đúng là tuple, không phải string.
    """
    # Đường dẫn đến các file cấu hình
    settings_paths = [
        '/app/dmoj/docker_settings.py',
        '/app/dmoj/settings.py'
    ]
    
    fixed = False
    
    for settings_path in settings_paths:
        if not os.path.exists(settings_path):
            print(f"File {settings_path} không tồn tại!")
            continue
        
        print(f"Đang kiểm tra file {settings_path}...")
        
        with open(settings_path, 'r') as f:
            content = f.read()
        
        # Sửa cấu hình bridge
        original_content = content
        
        # Sửa các định dạng khác nhau có thể gặp
        if "BRIDGED_JUDGE_ADDRESS = 'localhost'" in content:
            content = content.replace("BRIDGED_JUDGE_ADDRESS = 'localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0", 9999)')
            fixed = True
        
        if "BRIDGED_DJANGO_ADDRESS = 'localhost'" in content:
            content = content.replace("BRIDGED_DJANGO_ADDRESS = 'localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0", 9998)')
            fixed = True
        
        if "BRIDGED_JUDGE_ADDRESS = ('localhost'" in content:
            content = content.replace("BRIDGED_JUDGE_ADDRESS = ('localhost'", 'BRIDGED_JUDGE_ADDRESS = ("0.0.0.0"')
            fixed = True
        
        if "BRIDGED_DJANGO_ADDRESS = ('localhost'" in content:
            content = content.replace("BRIDGED_DJANGO_ADDRESS = ('localhost'", 'BRIDGED_DJANGO_ADDRESS = ("0.0.0.0"')
            fixed = True
        
        # Sửa cấu hình DMOJ_JUDGE_SERVERS
        if "'localhost': {" in content:
            content = content.replace("'localhost': {", "'0.0.0.0': {")
            
            # Cập nhật host trong cấu hình
            if "'host': 'localhost'" in content:
                content = content.replace("'host': 'localhost'", "'host': '0.0.0.0'")
            
            fixed = True
        
        if content != original_content:
            with open(settings_path, 'w') as f:
                f.write(content)
            print(f"Đã sửa cấu hình bridge trong {settings_path}")
        else:
            print(f"Không cần sửa cấu hình trong {settings_path}")
    
    # Sửa cấu hình judge trong container
    try:
        # Tạo script để sửa cấu hình judge
        judge_script = """
import os
import sys
import json

# Đường dẫn đến file cấu hình judge
judge_config_path = '/app/.dmojrc'

# Tạo cấu hình mặc định nếu không tồn tại
if not os.path.exists(judge_config_path):
    config = {
        'id': 'judge1',
        'key': 'key',
        'problem_storage_root': '/app/problems',
        'runtime': {
            'id_name': 'icodedn.com',
            'host': '0.0.0.0',
            'port': 9999
        }
    }
    with open(judge_config_path, 'w') as f:
        json.dump(config, f, indent=4)
    print(f"Đã tạo file cấu hình judge mới: {judge_config_path}")
    sys.exit(0)

# Đọc cấu hình hiện tại
try:
    with open(judge_config_path, 'r') as f:
        config = json.load(f)
except Exception as e:
    print(f"Lỗi khi đọc file cấu hình judge: {str(e)}")
    sys.exit(1)

# Cập nhật cấu hình
if 'runtime' in config:
    config['runtime']['host'] = '0.0.0.0'
    config['runtime']['id_name'] = 'icodedn.com'
else:
    config['runtime'] = {
        'id_name': 'icodedn.com',
        'host': '0.0.0.0',
        'port': 9999
    }

# Lưu cấu hình
try:
    with open(judge_config_path, 'w') as f:
        json.dump(config, f, indent=4)
    print(f"Đã cập nhật cấu hình judge: {judge_config_path}")
except Exception as e:
    print(f"Lỗi khi lưu file cấu hình judge: {str(e)}")
    sys.exit(1)
"""
        
        # Lưu script vào file tạm
        with open('/tmp/fix_judge_config.py', 'w') as f:
            f.write(judge_script)
        
        # Chạy script trong container judge
        os.system("docker compose exec judge python /tmp/fix_judge_config.py")
        fixed = True
    except Exception as e:
        print(f"Lỗi khi sửa cấu hình judge: {str(e)}")
    
    return fixed

if __name__ == "__main__":
    success = fix_judge_bridge()
    if success:
        print("Đã sửa xong cấu hình judge bridge!")
    else:
        print("Không tìm thấy cấu hình cần sửa hoặc có lỗi xảy ra!")
    sys.exit(0 if success else 1) 