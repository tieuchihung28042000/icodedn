#!/bin/bash

# Cloudflare Tunnel Setup Script for ICODEDN.COM
# Usage: ./setup-cloudflare-tunnel.sh

set -e

echo "🌐 Cloudflare Tunnel Setup for ICODEDN.COM"
echo "==========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Step 1: Install cloudflared
print_status "Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    print_status "Downloading cloudflared..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
            ;;
        aarch64|arm64)
            CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    wget -q $CLOUDFLARED_URL -O cloudflared.deb
    sudo dpkg -i cloudflared.deb
    rm cloudflared.deb
    
    print_success "cloudflared installed successfully"
else
    print_success "cloudflared is already installed"
fi

# Step 2: Login to Cloudflare
print_status "Logging into Cloudflare..."
print_warning "A browser window will open. Please login to your Cloudflare account."
read -p "Press Enter to continue..."

cloudflared tunnel login

if [ $? -ne 0 ]; then
    print_error "Failed to login to Cloudflare"
    exit 1
fi

print_success "Successfully logged into Cloudflare"

# Step 3: Create tunnel
TUNNEL_NAME="icodedn"
print_status "Creating tunnel: $TUNNEL_NAME"

# Check if tunnel already exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    print_warning "Tunnel '$TUNNEL_NAME' already exists"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
else
    cloudflared tunnel create $TUNNEL_NAME
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    print_success "Tunnel created with ID: $TUNNEL_ID"
fi

# Step 4: Create config file
print_status "Creating tunnel configuration..."
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: ~/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: icodedn.com
    service: http://localhost:8000
    originRequest:
      httpHostHeader: icodedn.com
  - hostname: www.icodedn.com
    service: http://localhost:8000
    originRequest:
      httpHostHeader: icodedn.com
  - service: http_status:404
EOF

print_success "Configuration file created at ~/.cloudflared/config.yml"

# Step 5: Create DNS records
print_status "Setting up DNS records..."
print_warning "Creating DNS records for icodedn.com and www.icodedn.com"

cloudflared tunnel route dns $TUNNEL_ID icodedn.com
cloudflared tunnel route dns $TUNNEL_ID www.icodedn.com

print_success "DNS records created"

# Step 6: Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/cloudflared-icodedn.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel for ICODEDN
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/cloudflared tunnel --config $HOME/.cloudflared/config.yml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-icodedn.service
sudo systemctl start cloudflared-icodedn.service

print_success "Systemd service created and started"

# Step 7: Check status
print_status "Checking tunnel status..."
sleep 5

if sudo systemctl is-active --quiet cloudflared-icodedn.service; then
    print_success "Cloudflare tunnel is running"
else
    print_error "Cloudflare tunnel failed to start"
    echo "Check logs with: sudo journalctl -u cloudflared-icodedn.service -f"
    exit 1
fi

# Step 8: Test connectivity
print_status "Testing connectivity..."
sleep 10

if curl -s -o /dev/null -w "%{http_code}" https://icodedn.com | grep -q "200\|301\|302"; then
    print_success "Website is accessible via https://icodedn.com"
else
    print_warning "Website might not be accessible yet. DNS propagation can take up to 24 hours."
fi

echo ""
print_success "🎉 Cloudflare Tunnel setup completed!"
echo ""
echo "📍 Tunnel Information:"
echo "   Tunnel Name: $TUNNEL_NAME"
echo "   Tunnel ID: $TUNNEL_ID"
echo "   Config File: ~/.cloudflared/config.yml"
echo ""
echo "🌐 Domains:"
echo "   Primary: https://icodedn.com"
echo "   WWW: https://www.icodedn.com"
echo ""
echo "🔧 Management Commands:"
echo "   Check status: sudo systemctl status cloudflared-icodedn.service"
echo "   View logs: sudo journalctl -u cloudflared-icodedn.service -f"
echo "   Restart: sudo systemctl restart cloudflared-icodedn.service"
echo "   Stop: sudo systemctl stop cloudflared-icodedn.service"
echo ""
echo "📊 Cloudflare Commands:"
echo "   List tunnels: cloudflared tunnel list"
echo "   Tunnel info: cloudflared tunnel info $TUNNEL_ID"
echo "   Delete tunnel: cloudflared tunnel delete $TUNNEL_ID"
echo ""
print_warning "Important Notes:"
echo "- DNS propagation can take up to 24 hours"
echo "- Make sure your DMOJ application is running on port 8000"
echo "- Check Cloudflare dashboard for additional SSL/Security settings"
echo "- The tunnel will auto-start on system boot"
echo ""
print_success "Setup completed successfully! 🚀" 