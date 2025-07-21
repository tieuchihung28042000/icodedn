#!/bin/bash

# Script deploy DMOJ lên VPS
echo "===== Deploy DMOJ lên VPS ====="

# Kiểm tra tham số
if [ -z "$1" ]; then
    echo "Sử dụng: $0 <vps_user@vps_host>"
    echo "Ví dụ: $0 root@example.com"
    exit 1
fi

VPS_HOST=$1
DEPLOY_DIR="/root/dmoj-deploy"

# Tạo thư mục deploy
echo "Tạo thư mục $DEPLOY_DIR trên VPS..."
ssh $VPS_HOST "mkdir -p $DEPLOY_DIR"

# Copy các file cần thiết
echo "Copy các file cần thiết..."
scp Dockerfile $VPS_HOST:$DEPLOY_DIR/
scp docker-compose.yml $VPS_HOST:$DEPLOY_DIR/
scp local_settings.py $VPS_HOST:$DEPLOY_DIR/
scp check-before-build.sh $VPS_HOST:$DEPLOY_DIR/
scp start.sh $VPS_HOST:$DEPLOY_DIR/
scp check-errors.sh $VPS_HOST:$DEPLOY_DIR/
scp -r docker $VPS_HOST:$DEPLOY_DIR/

# Tạo thư mục cần thiết
echo "Tạo các thư mục cần thiết..."
ssh $VPS_HOST "mkdir -p $DEPLOY_DIR/problems $DEPLOY_DIR/static $DEPLOY_DIR/media"

# Cấp quyền thực thi cho các script
echo "Cấp quyền thực thi cho các script..."
ssh $VPS_HOST "chmod +x $DEPLOY_DIR/*.sh"

# Cài đặt Docker và Docker Compose nếu chưa có
echo "Kiểm tra và cài đặt Docker nếu cần..."
ssh $VPS_HOST "if ! command -v docker &> /dev/null; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
fi"

echo "Kiểm tra và cài đặt Docker Compose nếu cần..."
ssh $VPS_HOST "if ! command -v docker-compose &> /dev/null; then
    curl -L \"https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi"

# Chạy script kiểm tra
echo "Chạy script kiểm tra..."
ssh $VPS_HOST "cd $DEPLOY_DIR && ./check-before-build.sh"

# Khởi động DMOJ
echo "Khởi động DMOJ..."
ssh $VPS_HOST "cd $DEPLOY_DIR && ./start.sh"

echo ""
echo "===== Deploy hoàn tất! ====="
echo "DMOJ đã được deploy tại: http://$VPS_HOST:8000"
echo "Admin: http://$VPS_HOST:8000/admin"
echo "Username: admin"
echo "Password: admin"
echo ""
echo "Để kiểm tra logs: ssh $VPS_HOST \"cd $DEPLOY_DIR && docker-compose logs -f\"" 