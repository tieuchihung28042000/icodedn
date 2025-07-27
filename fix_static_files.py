#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

def copy_resources_to_static():
    """
    Sao chép các file từ thư mục resources vào static và static_mount
    """
    # Đường dẫn đến thư mục static và resources
    STATIC_ROOT = '/app/static'
    STATIC_MOUNT = '/app/static_mount'
    RESOURCES_DIR = '/app/resources'
    
    print(f"Thư mục static: {STATIC_ROOT}")
    print(f"Thư mục static_mount: {STATIC_MOUNT}")
    print(f"Thư mục resources: {RESOURCES_DIR}")
    
    # Kiểm tra và tạo thư mục static nếu chưa tồn tại
    os.makedirs(STATIC_ROOT, exist_ok=True)
    os.makedirs(STATIC_MOUNT, exist_ok=True)
    
    # Sao chép các file từ resources vào static
    if os.path.exists(RESOURCES_DIR):
        print("Đang sao chép files từ resources vào static...")
        count = 0
        
        # Sao chép các file từ resources/libs
        libs_dir = os.path.join(RESOURCES_DIR, 'libs')
        if os.path.exists(libs_dir):
            for root, dirs, files in os.walk(libs_dir):
                for file in files:
                    src_path = os.path.join(root, file)
                    rel_path = os.path.relpath(src_path, RESOURCES_DIR)
                    dest_path = os.path.join(STATIC_ROOT, rel_path)
                    dest_dir = os.path.dirname(dest_path)
                    
                    # Tạo thư mục đích nếu chưa tồn tại
                    os.makedirs(dest_dir, exist_ok=True)
                    
                    # Sao chép file
                    try:
                        shutil.copy2(src_path, dest_path)
                        count += 1
                        if count % 100 == 0:
                            print(f"Đã sao chép {count} files...")
                    except Exception as e:
                        print(f"Lỗi khi sao chép {rel_path}: {str(e)}")
        
        # Sao chép các file từ resources/vnoj
        vnoj_dir = os.path.join(RESOURCES_DIR, 'vnoj')
        if os.path.exists(vnoj_dir):
            for root, dirs, files in os.walk(vnoj_dir):
                for file in files:
                    src_path = os.path.join(root, file)
                    rel_path = os.path.relpath(src_path, RESOURCES_DIR)
                    dest_path = os.path.join(STATIC_ROOT, rel_path)
                    dest_dir = os.path.dirname(dest_path)
                    
                    # Tạo thư mục đích nếu chưa tồn tại
                    os.makedirs(dest_dir, exist_ok=True)
                    
                    # Sao chép file
                    try:
                        shutil.copy2(src_path, dest_path)
                        count += 1
                        if count % 100 == 0:
                            print(f"Đã sao chép {count} files...")
                    except Exception as e:
                        print(f"Lỗi khi sao chép {rel_path}: {str(e)}")
        
        # Sao chép các file CSS và JS chính
        for root, dirs, files in os.walk(RESOURCES_DIR):
            for file in files:
                if file.endswith('.css') or file.endswith('.js') or file.endswith('.scss') or file.endswith('.png') or file.endswith('.svg') or file.endswith('.ico'):
                    src_path = os.path.join(root, file)
                    rel_path = os.path.relpath(src_path, RESOURCES_DIR)
                    dest_path = os.path.join(STATIC_ROOT, rel_path)
                    dest_dir = os.path.dirname(dest_path)
                    
                    # Tạo thư mục đích nếu chưa tồn tại
                    os.makedirs(dest_dir, exist_ok=True)
                    
                    # Sao chép file
                    try:
                        shutil.copy2(src_path, dest_path)
                        count += 1
                    except Exception as e:
                        print(f"Lỗi khi sao chép {rel_path}: {str(e)}")
        
        print(f"Đã sao chép tổng cộng {count} files từ resources vào static.")
        
        # Sao chép vào static_mount
        print("Đang sao chép files từ static vào static_mount...")
        count = 0
        for root, dirs, files in os.walk(STATIC_ROOT):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, STATIC_ROOT)
                dest_path = os.path.join(STATIC_MOUNT, rel_path)
                dest_dir = os.path.dirname(dest_path)
                
                # Tạo thư mục đích nếu chưa tồn tại
                os.makedirs(dest_dir, exist_ok=True)
                
                # Sao chép file
                try:
                    shutil.copy2(src_path, dest_path)
                    count += 1
                    if count % 100 == 0:
                        print(f"Đã sao chép {count} files vào static_mount...")
                except Exception as e:
                    print(f"Lỗi khi sao chép vào static_mount {rel_path}: {str(e)}")
        
        print(f"Đã sao chép tổng cộng {count} files vào static_mount.")
        print("Hoàn tất sao chép static files.")
        return True
    else:
        print(f"CẢNH BÁO: Thư mục resources không tồn tại: {RESOURCES_DIR}")
        return False

# Tạo các symbolic link cho các thư mục quan trọng
def create_symlinks():
    """
    Tạo các symbolic link cho các thư mục quan trọng
    """
    try:
        # Danh sách các thư mục cần tạo symbolic link
        symlinks = [
            ('/app/resources/libs', '/app/static/libs'),
            ('/app/resources/vnoj', '/app/static/vnoj'),
            ('/app/resources/icons', '/app/static/icons'),
            ('/app/resources/style.css', '/app/static/style.css'),
            ('/app/resources/common.js', '/app/static/common.js'),
            ('/app/resources/event.js', '/app/static/event.js'),
            ('/app/resources/mathjax_config.js', '/app/static/mathjax_config.js'),
            ('/app/resources/source_sans_pro.css', '/app/static/source_sans_pro.css')
        ]
        
        for src, dest in symlinks:
            if os.path.exists(src) and not os.path.exists(dest):
                # Tạo thư mục cha nếu cần
                parent_dir = os.path.dirname(dest)
                os.makedirs(parent_dir, exist_ok=True)
                
                # Tạo symbolic link
                os.symlink(src, dest)
                print(f"Đã tạo symbolic link: {src} -> {dest}")
        
        return True
    except Exception as e:
        print(f"Lỗi khi tạo symbolic link: {str(e)}")
        return False

if __name__ == "__main__":
    success1 = copy_resources_to_static()
    success2 = create_symlinks()
    
    if success1 and success2:
        print("Đã sửa xong static files!")
    else:
        print("Có lỗi xảy ra khi sửa static files!")
    
    sys.exit(0 if (success1 or success2) else 1) 