#!/bin/bash
################################################################################
# 🚀 DigitalOcean Server Initialization Script
#
# Purpose: Complete setup of Ubuntu server with RustDesk, Docker, Node.js, Python
# Version: 2.0
# Author: Mahdi Bagheban (MahdiArts)
# License: MIT
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
}

# Start
print_header "🚀 SERVER INITIALIZATION - RustDesk + Dev Tools"

log_info "Starting server setup at $(date)"
log_info "Running as: $(whoami)"
log_info "Hostname: $(hostname)"
log_info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

print_header "📦 STEP 1: Update System Packages"
log_info "Updating package lists..."
sudo apt-get update -qq
log_info "Upgrading packages..."
sudo apt-get upgrade -y -qq
log_info "Installing essential tools..."
sudo apt-get install -y curl wget git build-essential apt-transport-https ca-certificates gnupg lsb-release 2>&1 | tail -1
log_success "System updated"

print_header "🐳 STEP 2: Install Docker"
log_info "Downloading Docker installation script..."
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 2>/dev/null
log_info "Running Docker installer..."
sudo sh /tmp/get-docker.sh
log_info "Configuring Docker daemon..."
sudo usermod -aG docker root
sudo systemctl start docker
sudo systemctl enable docker
log_success "Docker installed: $(docker --version)"
log_info "Docker ready to use"

print_header "📦 STEP 3: Install Node.js LTS"
log_info "Adding NodeSource repository..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | grep -E "(^Searching|^Install)" || true
log_info "Installing Node.js..."
sudo apt-get install -y nodejs 2>&1 | tail -1
log_success "Node.js installed: $(node -v)"
log_success "npm installed: $(npm -v)"

print_header "🐍 STEP 4: Install Python 3"
log_info "Installing Python and development tools..."
sudo apt-get install -y python3 python3-pip python3-dev python3-venv python3-setuptools 2>&1 | tail -1
log_success "Python installed: $(python3 --version)"
log_success "pip installed: $(pip3 --version)"
log_info "Upgrading pip..."
pip3 install --upgrade pip --quiet 2>&1 | tail -1

print_header "🛠️ STEP 5: Install Essential Development Tools"
log_info "Installing additional tools..."
sudo apt-get install -y git nano vim curl wget jq htop tmux screen unzip zip net-tools openssh-server 2>&1 | tail -1
log_success "Development tools installed"

print_header "🔥 STEP 6: Configure UFW Firewall"
log_info "Installing UFW..."
sudo apt-get install -y ufw 2>&1 | tail -1
log_info "Setting default policies..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
log_info "Opening required ports..."
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 5900/tcp    # RustDesk
sudo ufw allow 5901/tcp    # RustDesk
sudo ufw allow 21115/tcp   # RustDesk
sudo ufw allow 21116/tcp   # RustDesk
sudo ufw allow 21117/tcp   # RustDesk
sudo ufw allow 21118/tcp   # RustDesk
sudo ufw allow 21119/tcp   # RustDesk
log_info "Enabling firewall..."
sudo ufw enable 2>&1 | tail -1
log_success "UFW Firewall configured"

print_header "🦀 STEP 7: Setup RustDesk Server OSS"
log_info "Creating RustDesk directories..."
sudo mkdir -p /opt/rustdesk
sudo mkdir -p /var/log/rustdesk
cd /opt/rustdesk || exit 1

log_info "Downloading RustDesk Server OSS v1.41.9..."
RUSTDESK_VERSION="1.41.9"
if [ ! -f "hbbs" ]; then
    wget -q "https://github.com/rustdesk/rustdesk-server/releases/download/$RUSTDESK_VERSION/rustdesk-server-linux-x64.zip"
    unzip -q rustdesk-server-linux-x64.zip
    rm rustdesk-server-linux-x64.zip
fi

log_info "Setting executable permissions..."
chmod +x hbbr hbbs
log_success "RustDesk binaries ready"

log_info "Creating systemd service files..."
sudo tee /etc/systemd/system/rustdesk-hbbs.service > /dev/null << 'SERVICE1'
[Unit]
Description=RustDesk Signal Server (hbbs)
After=network.target
Wants=rustdesk-hbbr.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rustdesk
ExecStart=/opt/rustdesk/hbbs
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="RUST_LOG=debug"

[Install]
WantedBy=multi-user.target
SERVICE1

sudo tee /etc/systemd/system/rustdesk-hbbr.service > /dev/null << 'SERVICE2'
[Unit]
Description=RustDesk Relay Server (hbbr)
After=network.target rustdesk-hbbs.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/rustdesk
ExecStart=/opt/rustdesk/hbbr
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="RUST_LOG=debug"

[Install]
WantedBy=multi-user.target
SERVICE2

log_info "Reloading systemd daemon..."
sudo systemctl daemon-reload

log_info "Starting RustDesk services..."
sudo systemctl enable rustdesk-hbbs rustdesk-hbbr
sudo systemctl start rustdesk-hbbs rustdesk-hbbr

log_info "Waiting for RustDesk to initialize..."
sleep 5

log_success "RustDesk Server started"
log_info "Service status:"
sudo systemctl status rustdesk-hbbs --no-pager | grep Active || true
sudo systemctl status rustdesk-hbbr --no-pager | grep Active || true

print_header "🔑 STEP 8: Extract RustDesk Keys"
log_info "Checking for RustDesk configuration..."
if [ -f "id_ed25519.pub" ]; then
    KEY=$(cat id_ed25519.pub | head -1)
    echo "$KEY" > /tmp/rustdesk_key.txt
    log_success "RustDesk public key extracted"
    log_info "Key (first 50 chars): ${KEY:0:50}..."
else
    log_warning "Key file not yet generated - will be available after first connection"
    log_info "Keys will be in: /opt/rustdesk/id_ed25519* (after initialization)"
fi

print_header "✅ INITIALIZATION COMPLETE"
echo ""
echo "📊 INSTALLED COMPONENTS:"
echo "  ✓ Ubuntu 24.04 LTS"
echo "  ✓ Docker $(docker --version | cut -d' ' -f3)"
echo "  ✓ Node.js $(node -v)"
echo "  ✓ npm $(npm -v | head -1)"
echo "  ✓ Python $(python3 --version | cut -d' ' -f2)"
echo "  ✓ pip $(pip3 --version | cut -d' ' -f2)"
echo "  ✓ RustDesk Server v$RUSTDESK_VERSION"
echo "  ✓ UFW Firewall (enabled)"
echo ""
echo "🔥 OPEN PORTS:"
echo "  • 22   - SSH (remote terminal access)"
echo "  • 80   - HTTP (web)"
echo "  • 443  - HTTPS (secure web)"
echo "  • 5900 - RustDesk Display"
echo "  • 5901 - RustDesk Audio/Control"
echo "  • 21115-21119 - RustDesk Services"
echo ""
echo "🛠️ USEFUL COMMANDS:"
echo "  • Check Docker: docker ps -a"
echo "  • Check firewall: sudo ufw status"
echo "  • View RustDesk logs: journalctl -u rustdesk-hbbs -f"
echo "  • Restart RustDesk: sudo systemctl restart rustdesk-hbbs"
echo ""
echo "📚 HELPFUL LINKS:"
echo "  • Docker Docs: https://docs.docker.com"
echo "  • Node.js Docs: https://nodejs.org/docs"
echo "  • Python Docs: https://docs.python.org/3"
echo "  • RustDesk Docs: https://rustdesk.com/docs"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✨ Server is ready! Current time: $(date)"
echo "════════════════════════════════════════════════════════════════"
echo ""

log_success "Initialization completed successfully"
