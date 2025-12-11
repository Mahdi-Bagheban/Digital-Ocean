#!/bin/bash

#######################################
# اسکریپت ایجاد سرور توسعه در DigitalOcean
# Memory-Optimized Premium Intel 64GB RAM (پیشفرض)
# با KASM Workspace و RustDesk Server
# توسط: Mahdi Bagheban
# تاریخ: دسامبر 2025
# نسخه: 4.0 (ورودیهای انعطافپذیر + Override support)
#######################################

set -o pipefail  # خروج از اسکریپت اگر هر دستور فشل شود

# رنگ‌ها برای نمایش بهتر
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # بدون رنگ

# تابع چاپ پیام‌ها
print_message() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_success() {
    echo -e "${PURPLE}[★]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[→]${NC} $1"
}

# تابع خروج با خطا
exit_error() {
    print_error "$1"
    exit 1
}

# تابع چک کردن پیش‌نیازها
check_prerequisites() {
    print_step "بررسی پیش‌نیازها..."
    
    # بررسی jq
    if ! command -v jq &> /dev/null; then
        exit_error "jq نصب نشده است. لطفا ابتدا jq را نصب کنید:
  Windows: scoop install jq
  Linux: sudo apt-get install jq
  Mac: brew install jq"
    fi
    
    # بررسی curl
    if ! command -v curl &> /dev/null; then
        exit_error "curl نصب نشده است"
    fi
    
    # بررسی bc برای محاسبات
    if ! command -v bc &> /dev/null; then
        exit_error "bc نصب نشده است"
    fi
    
    print_message "تمام پیش‌نیازها موجود هستند"
}

# بررسی وجود فایل تنظیمات
check_env_file() {
    CONFIG_FILE=".env"
    # در GitHub Actions از environment variables استفاده می‌شود        exit_error "فایل .env یافت نشد!
        if [ -f "$CONFIG_FILE" ]; then
        print_message ".env فایل یافت شد و بارگذاری می‌شود..."
    else
        print_warning "فایل .env یافت نشد. از environment variables استفاده می‌شود."
    fi
}

# بارگذاری و اعتبارسنجی متغیرها
load_and_validate_env() {
    # بارگذاری فایل .env اگر وجود داشته باشد
    [ -f ".env" ] && source ".env"    
    if [ -z "$DO_API_TOKEN" ]; then
        exit_error "DO_API_TOKEN در فایل .env تنظیم نشده است!"
    fi
    
    if [ -z "$SSH_KEY_NAME" ]; then
        print_warning "SSH_KEY_NAME تنظیم نشده، از MahdiArts استفاده می‌شود"
        SSH_KEY_NAME="MahdiArts"
    fi
    
    # ===== پیشفرض‌های جدید با نویسندگی (Override) =====
    # اگر از GitHub Actions فرستاده شده، استفاده کن؛ وگرنه پیشفرض‌ها
    DROPLET_NAME="${DO_DROPLET_NAME:-${DROPLET_NAME:-mahdi-dev-workspace-64gb}}"
    REGION="${DO_REGION:-${REGION:-fra1}}"
    SIZE="${DO_SIZE_SLUG:-${SIZE:-m-16vcpu-64gb}}"
    IMAGE="${DO_IMAGE:-${IMAGE:-ubuntu-24-04-x64}}"
    TAGS="${DO_TAGS:-${TAGS:-mahdiarts,kasm-workspace,rustdesk,development,high-performance}}"
    ENABLE_IPV6="${DO_ENABLE_IPV6:-${ENABLE_IPV6:-true}}"
    ENABLE_BACKUPS="${DO_ENABLE_BACKUPS:-${ENABLE_BACKUPS:-false}}"
    AUTO_SHUTDOWN_HOURS="${DO_AUTO_SHUTDOWN_HOURS:-${AUTO_SHUTDOWN_HOURS:-}}"
    
    # ارزیابی boolean
    if [ "$ENABLE_IPV6" = "true" ] || [ "$ENABLE_IPV6" = "1" ]; then
        ENABLE_IPV6=true
    else
        ENABLE_IPV6=false
    fi
    
    if [ "$ENABLE_BACKUPS" = "true" ] || [ "$ENABLE_BACKUPS" = "1" ]; then
        ENABLE_BACKUPS=true
    else
        ENABLE_BACKUPS=false
    fi
}

# تابع API call با error handling
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        local response
        
        if [ -z "$data" ]; then
            response=$(curl -s -w "\n%{http_code}" \
              -X "$method" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer $DO_API_TOKEN" \
              "https://api.digitalocean.com/v2$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" \
              -X "$method" \
              -H "Content-Type: application/json" \
              -H "Authorization: Bearer $DO_API_TOKEN" \
              -d "$data" \
              "https://api.digitalocean.com/v2$endpoint")
        fi
        
        local http_code=$(echo "$response" | tail -n1)
        local body=$(echo "$response" | sed '$d')
        
        # بررسی موفقیت
        if [[ "$http_code" =~ ^(200|201|204)$ ]]; then
            echo "$body"
            return 0
        fi
        
        # Rate limiting - منتظر بمان
        if [ "$http_code" = "429" ]; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Rate limit - ${retry_count}/${max_retries} - منتظر 10 ثانیه..."
                sleep 10
                continue
            fi
        fi
        
        # خطای دیگر
        print_error "API Error (HTTP $http_code):"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    done
    
    return 1
}

# دریافت ID کلید SSH
get_ssh_key_id() {
    print_step "در حال دریافت اطلاعات SSH Key..."
    
    local response
    response=$(api_call GET "/account/keys") || return 1
    
    local ssh_key_id
    ssh_key_id=$(echo "$response" | jq -r ".ssh_keys[] | select(.name==\"$SSH_KEY_NAME\") | .id" 2>/dev/null)
    
    if [ -z "$ssh_key_id" ] || [ "$ssh_key_id" = "null" ]; then
        print_error "کلید SSH با نام '$SSH_KEY_NAME' یافت نشد!"
        print_info "لیست کلیدهای SSH موجود:"
        echo "$response" | jq -r '.ssh_keys[] | "  - \(.name) (ID: \(.id))"' 2>/dev/null
        return 1
    fi
    
    print_message "SSH Key پیدا شد: $SSH_KEY_NAME (ID: $ssh_key_id)"
    echo "$ssh_key_id"
}

# ایجاد اسکریپت نصب بهبود یافته با RustDesk
create_install_script() {
    cat << 'EOFSCRIPT'
#!/bin/bash
set -e

# Log کردن
LOG_FILE="/var/log/server-install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "========================================"
echo "🚀 شروع نصب سرور توسعه"
echo "📅 تاریخ: $(date)"
echo "========================================"

# تابع نمایش پیشرفت
print_step() {
    echo ""
    echo "[$(date +'%H:%M:%S')] ➜ $1"
    echo "----------------------------------------"
}

print_success() {
    echo "[$(date +'%H:%M:%S')] ✓ $1"
}

print_error() {
    echo "[$(date +'%H:%M:%S')] ✗ $1"
}

# 1. آپدیت سیستم
print_step "آپدیت و ارتقای سیستم"
apt-get update || { print_error "خطا در update"; exit 1; }
apt-get upgrade -y || { print_error "خطا در upgrade"; exit 1; }
print_success "سیستم آپدیت شد"

# 2. نصب پکیج‌های پایه
print_step "نصب پکیج‌های پایه"
apt-get install -y \
    curl wget git build-essential ca-certificates \
    htop tmux vim nano net-tools ufw \
    software-properties-common apt-transport-https || {
    print_error "خطا در نصب پکیج‌های پایه"
    exit 1
}
print_success "پکیج‌های پایه نصب شدند"

# 3. پیکربندی Firewall
print_step "پیکربندی Firewall (UFW)"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'HTTPS - KASM'
ufw allow 80/tcp comment 'HTTP'
ufw allow 21115:21119/tcp comment 'RustDesk Server'
print_success "Firewall پیکربندی شد"

# 4. نصب Docker
print_step "نصب Docker و Docker Compose"
curl -fsSL https://get.docker.com -o get-docker.sh || {
    print_error "خطا در دانلود Docker"
    exit 1
}
bash get-docker.sh || {
    print_error "خطا در نصب Docker"
    exit 1
}
usermod -aG docker root || true

# نصب Docker Compose
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

if ! command -v docker &> /dev/null; then
    print_error "Docker نصب نشد!"
    exit 1
fi

print_success "Docker نصب شد: $(docker --version)"
print_success "Docker Compose نصب شد: $(docker-compose --version)"

# 5. نصب KASM Workspace
print_step "نصب KASM Workspace (محیط دسکتاپ در مرورگر)"
cd /tmp

for i in {1..3}; do
    if wget -q https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.5b7fb6.tar.gz; then
        break
    fi
    if [ $i -eq 3 ]; then
        print_error "خطا: دانلود KASM ناموفق بود"
        exit 1
    fi
    echo "تلاش مجدد دانلود KASM ($i/3)..."
    sleep 5
done

tar -xzf kasm_release_1.15.0.5b7fb6.tar.gz || {
    print_error "خطا در استخراج KASM"
    exit 1
}

cd kasm_release
bash install.sh -L -e -m 64 2>&1 | tee -a "$LOG_FILE" || {
    print_error "خطا در نصب KASM - بررسی لاگ:"
    tail -50 "$LOG_FILE"
    exit 1
}

print_success "KASM Workspace نصب شد"

# 6. نصب RustDesk Server
print_step "نصب RustDesk Server (دسترسی از راه دور)"

# ایجاد دایرکتوری
mkdir -p /opt/rustdesk
cd /opt/rustdesk

# ایجاد docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3'

networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r rustdesk.example.com:21117
    volumes:
      - ./data:/root
    networks:
      - rustdesk-net
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - ./data:/root
    networks:
      - rustdesk-net
    ports:
      - 21117:21117
      - 21119:21119
    restart: unless-stopped
EOF

print_success "فایل docker-compose.yml ایجاد شد"

# اجرای RustDesk Server
docker-compose up -d || {
    print_error "خطا در اجرای RustDesk Server"
    exit 1
}

print_success "RustDesk Server راه‌اندازی شد"

# صبر برای ایجاد کلید عمومی
sleep 5

# نمایش اطلاعات RustDesk
if [ -f ./data/id_ed25519.pub ]; then
    echo ""
    echo "========================================"
    echo "📋 اطلاعات RustDesk Server"
    echo "========================================"
    echo "🔑 کلید عمومی (Public Key):"
    cat ./data/id_ed25519.pub
    echo ""
    echo "این کلید را در کلاینت RustDesk وارد کنید"
    echo "========================================"
    
    # ذخیره در فایل جداگانه
    cat ./data/id_ed25519.pub > /root/rustdesk-public-key.txt
    print_success "کلید عمومی در /root/rustdesk-public-key.txt ذخیره شد"
fi

# 7. نصب Node.js
print_step "نصب Node.js 20 LTS"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || true
apt-get install -y nodejs || {
    print_error "خطا در نصب Node.js"
    exit 1
}
print_success "Node.js نصب شد: $(node --version)"
print_success "npm نصب شد: $(npm --version)"

# 8. نصب Python
print_step "نصب Python 3 و ابزارهای مرتبط"
apt-get install -y python3 python3-pip python3-venv python3-dev || {
    print_error "خطا در نصب Python"
    exit 1
}
pip3 install --upgrade pip setuptools wheel 2>&1 | tail -5 || true
print_success "Python نصب شد: $(python3 --version)"
print_success "pip نصب شد: $(pip3 --version)"

# 9. نصب ابزارهای توسعه اضافی
print_step "نصب ابزارهای توسعه اضافی"
apt-get install -y \
    zsh \
    ripgrep \
    fd-find \
    bat \
    tree \
    jq \
    httpie || true

print_success "ابزارهای توسعه نصب شدند"

# 10. نصب Oh My Zsh (اختیاری)
print_step "نصب Oh My Zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
print_success "Oh My Zsh نصب شد"

# 11. ایجاد اسکریپت اطلاعات سرور
cat > /root/server-info.sh << 'INFOEOF'
#!/bin/bash
echo "========================================"
echo "🖥️  اطلاعات سرور"
echo "========================================"
echo ""
echo "📊 مشخصات سخت‌افزاری:"
echo "  CPU: $(nproc) cores"
echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}') (Total)"
echo "  Disk: $(df -h / | awk 'NR==2 {print $2}') (Total)"
echo ""
echo "🌐 اطلاعات شبکه:"
echo "  IPv4: $(curl -s ifconfig.me)"
echo "  Hostname: $(hostname)"
echo ""
echo "🐳 Docker:"
docker --version
docker-compose --version
echo ""
echo "📦 نرم‌افزارها:"
echo "  Node.js: $(node --version 2>/dev/null || echo 'نصب نشده')"
echo "  Python: $(python3 --version 2>/dev/null || echo 'نصب نشده')"
echo "  Git: $(git --version 2>/dev/null || echo 'نصب نشده')"
echo ""
echo "🔐 RustDesk Server:"
echo "  Status: $(docker ps --filter name=hbbs --format '{{.Status}}' 2>/dev/null || echo 'خاموش')"
if [ -f /opt/rustdesk/data/id_ed25519.pub ]; then
    echo "  Public Key:"
    cat /opt/rustdesk/data/id_ed25519.pub
fi
echo ""
echo "========================================"
INFOEOF

chmod +x /root/server-info.sh
print_success "اسکریپت اطلاعات سرور ایجاد شد: /root/server-info.sh"

# 12. پاکسازی
print_step "پاکسازی فایل‌های موقت"
apt-get autoremove -y
apt-get clean
rm -rf /tmp/*
print_success "پاکسازی انجام شد"

# پایان
echo ""
echo "========================================"
echo "✅ نصب با موفقیت کامل شد!"
echo "📅 زمان پایان: $(date)"
echo "========================================"
echo ""
echo "📝 برای مشاهده اطلاعات کامل سرور:"
echo "   /root/server-info.sh"
echo ""
echo "🌐 دسترسی به KASM Workspace:"
echo "   https://$(curl -s ifconfig.me):443"
echo ""
echo "🔐 دسترسی به RustDesk:"
echo "   Server: $(curl -s ifconfig.me)"
echo "   Ports: 21115-21119"
if [ -f /opt/rustdesk/data/id_ed25519.pub ]; then
    echo "   Public Key: $(cat /opt/rustdesk/data/id_ed25519.pub)"
fi
echo ""
echo "========================================"
EOFSCRIPT
}

# ایجاد Droplet
create_droplet() {
    print_step "در حال ایجاد Droplet (Size: $SIZE, Region: $REGION)..."
    
    # ایجاد install script
    local install_script
    install_script=$(create_install_script)
    
    # تبدیل به Base64 صحیح (بدون wrap کردن)
    local user_data_base64
    user_data_base64=$(echo "$install_script" | base64 -w 0 2>/dev/null || echo "$install_script" | base64)
    
    # ایجاد JSON payload
    local payload=$(cat <<EOF
{
    "name": "$DROPLET_NAME",
    "region": "$REGION",
    "size": "$SIZE",
    "image": "$IMAGE",
    "ssh_keys": [$SSH_KEY_ID],
    "backups": $ENABLE_BACKUPS,
    "ipv6": $ENABLE_IPV6,
    "monitoring": true,
    "tags": ["${TAGS//,/\",\"}"],
    "user_data": "$user_data_base64"
}
EOF
)
    
    # ارسال درخواست
    local response
    response=$(api_call POST "/droplets" "$payload") || return 1
    
    # بررسی خطا در response
    if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
        print_error "خطا در ایجاد Droplet:"
        echo "$response" | jq -r '.message'
        return 1
    fi
    
    # استخراج Droplet ID
    local droplet_id
    droplet_id=$(echo "$response" | jq -r '.droplet.id' 2>/dev/null)
    
    if [ -z "$droplet_id" ] || [ "$droplet_id" = "null" ]; then
        print_error "خطا: Droplet ID دریافت نشد"
        echo "$response"
        return 1
    fi
    
    print_message "Droplet با موفقیت ایجاد شد!"
    print_info "شناسه Droplet: $droplet_id"
    
    echo "$droplet_id" > .droplet_id
    echo "$droplet_id"
}

# انتظار برای Droplet به آماده شدن
wait_for_droplet() {
    local droplet_id=$1
    
    print_step "در حال انتظار برای آماده شدن سرور..."
    
    local status="new"
    local counter=0
    local max_wait=600  # 10 دقیقه
    local check_interval=10
    
    # صبر کنید 30 ثانیه قبل از اولین چک
    sleep 30
    
    while [ "$status" != "active" ] && [ $counter -lt $max_wait ]; do
        sleep $check_interval
        counter=$((counter + check_interval))
        
        local response
        response=$(api_call GET "/droplets/$droplet_id") || {
            print_warning "خطا در دریافت وضعیت - تلاش مجدد..."
            continue
        }
        
        status=$(echo "$response" | jq -r '.droplet.status' 2>/dev/null)
        
        if [ -z "$status" ] || [ "$status" = "null" ]; then
            print_warning "خطا: وضعیت Droplet دریافت نشد"
            continue
        fi
        
        local progress=$((counter * 100 / max_wait))
        printf "${BLUE}[i]${NC} وضعیت: $status ($progress%%) - صبر $((max_wait - counter))s ثانیه\r"
    done
    
    echo ""  # نیولاین بعد از progress bar
    
    if [ "$status" = "active" ]; then
        print_message "سرور آماده شد!"
        return 0
    else
        print_error "سرور در زمان مقرر ($((max_wait / 60)) دقیقه) آماده نشد"
        print_info "وضعیت فعلی: $status"
        return 1
    fi
}

# استخراج اطلاعات سرور
get_droplet_info() {
    local droplet_id=$1
    
    print_step "در حال دریافت اطلاعات سرور..."
    
    local response
    response=$(api_call GET "/droplets/$droplet_id") || return 1
    
    local droplet_name=$(echo "$response" | jq -r '.droplet.name')
    local ipv4=$(echo "$response" | jq -r '.droplet.networks.v4[0].ip_address')
    local ipv6=$(echo "$response" | jq -r '.droplet.networks.v6[0].ip_address')
    local status=$(echo "$response" | jq -r '.droplet.status')
    local size_slug=$(echo "$response" | jq -r '.droplet.size_slug')
    local memory=$(echo "$response" | jq -r '.droplet.memory')
    local vcpus=$(echo "$response" | jq -r '.droplet.vcpus')
    local disk=$(echo "$response" | jq -r '.droplet.disk')
    
    if [ -z "$ipv4" ] || [ "$ipv4" = "null" ]; then
        print_error "خطا: IP Address دریافت نشد"
        return 1
    fi
    
    echo "$ipv4" > .droplet_ip
    echo "$ipv6" > .droplet_ipv6
    echo "$size_slug" > .droplet_size
    date +%s > .droplet_created_at
    
    # ذخیره اطلاعات به متغیرهای global برای استفاده در show_summary
    DROPLET_IPV6="$ipv6"
    DROPLET_SIZE_SLUG="$size_slug"
    DROPLET_MEMORY="$memory"
    DROPLET_VCPUS="$vcpus"
    DROPLET_DISK="$disk"
    
    echo "$ipv4"
}

# محاسبه هزینه تقریبی
calculate_hourly_cost() {
    local size=$1
    
    case $size in
        "s-1vcpu-512mb") echo "0.0044" ;;
        "s-1vcpu-1gb") echo "0.0089" ;;
        "s-2vcpu-2gb") echo "0.0179" ;;
        "s-2vcpu-4gb") echo "0.0357" ;;
        "s-4vcpu-8gb") echo "0.0714" ;;
        "s-6vcpu-16gb") echo "0.1428" ;;
        "s-8vcpu-32gb") echo "0.2857" ;;
        "m-16vcpu-64gb") echo "0.5952" ;;
        "m-24vcpu-192gb") echo "1.7857" ;;
        "m-32vcpu-256gb") echo "2.3809" ;;
        "c-2") echo "0.0595" ;;
        "c-4") echo "0.1190" ;;
        "c-8") echo "0.2381" ;;
        "c-16") echo "0.4762" ;;
        "c-32") echo "0.9524" ;;
        "r-2vcpu-16gb") echo "0.1191" ;;
        "r-4vcpu-32gb") echo "0.2381" ;;
        "r-8vcpu-64gb") echo "0.4762" ;;
        "r-16vcpu-128gb") echo "0.9524" ;;
        "r-32vcpu-256gb") echo "1.9048" ;;
        *) echo "N/A" ;;
    esac
}

# نمایش خلاصه با RustDesk
show_summary() {
    local droplet_id=$1
    local droplet_name=$2
    local ipv4=$3
    local region=$4
    
    local hourly_cost=$(calculate_hourly_cost "$SIZE")
    local daily_cost=$(echo "$hourly_cost * 24" | bc -l 2>/dev/null || echo "N/A")
    local monthly_cost=$(echo "$hourly_cost * 730" | bc -l 2>/dev/null || echo "N/A")
    
    echo ""
    echo "=========================================="
    print_success "🎉 سرور شما با موفقیت ایجاد شد!"
    echo "=========================================="
    echo ""
    
    print_info "📋 مشخصات سرور:"
    echo "  🆔 شناسه: $droplet_id"
    echo "  📝 نام: $droplet_name"
    echo "  🌍 آی‌پی: $ipv4"
    if [ "$DROPLET_IPV6" != "null" ] && [ -n "$DROPLET_IPV6" ]; then
        echo "  🌐 IPv6: $DROPLET_IPV6"
    fi
    echo "  📍 منطقه: $region"
    echo ""
    
    print_info "💪 قدرت پردازشی:"
    echo "  🧠 RAM: ${DROPLET_MEMORY}MB"
    echo "  🔥 CPU: $DROPLET_VCPUS vCPUs"
    echo "  ⚡ SSD: ${DROPLET_DISK}GB NVMe"
    echo "  🌐 Transfer: 8TB"
    echo "  🚀 Network: تا 10 Gbps"
    echo ""
    
    print_info "🔌 دستورات اتصال:"
    echo ""
    echo -e "${GREEN}1️⃣  SSH (دسترسی ترمینال):${NC}"
    echo -e "${CYAN}   ssh root@$ipv4${NC}"
    echo ""
    echo -e "${GREEN}2️⃣  KASM Workspace (دسکتاپ در مرورگر):${NC}"
    echo -e "${CYAN}   https://$ipv4:443${NC}"
    echo "   Username: admin@kasm.local"
    echo "   (رمز عبور را از SSH دریافت کنید)"
    echo ""
    echo -e "${GREEN}3️⃣  RustDesk Server (دسترسی از راه دور):${NC}"
    echo -e "${CYAN}   Server Address: $ipv4${NC}"
    echo "   Ports: 21115-21119"
    echo "   برای دریافت کلید عمومی:"
    echo -e "${CYAN}   ssh root@$ipv4 cat /root/rustdesk-public-key.txt${NC}"
    echo ""
    
    print_warning "⏱️  نصب نرم‌افزارها ۵-۲۰ دقیقه طول می‌کشد"
    echo ""
    print_info "📊 مشاهده لاگ نصب:"
    echo -e "${CYAN}   ssh root@$ipv4 tail -f /var/log/server-install.log${NC}"
    echo ""
    print_info "📋 مشاهده اطلاعات کامل سرور:"
    echo -e "${CYAN}   ssh root@$ipv4 /root/server-info.sh${NC}"
    echo ""
    
    print_info "💰 هزینه تقریبی:"
    if [ "$hourly_cost" != "N/A" ]; then
        echo "  ساعتی: \$$hourly_cost/hour"
        if [ "$daily_cost" != "N/A" ]; then
            printf "  روزانه: \$%.2f/day\n" "$daily_cost"
        fi
        if [ "$monthly_cost" != "N/A" ]; then
            printf "  ماهانه: \$%.2f/month\n" "$monthly_cost"
        fi
    else
        echo "  (لطفا هزینه را از پنل DigitalOcean بررسی کنید)"
    fi
    echo ""
    
    print_warning "⚠️  یادآوری: حتماً بعد از اتمام کار، سرور را حذف کنید!"
    echo ""
    print_info "🗑️  حذف سرور:"
    echo -e "${YELLOW}   ./delete-server.sh${NC}"
    echo ""
    echo "=========================================="
    print_success "✨ از سرور قدرتمند خود لذت ببرید!"
    echo "=========================================="
    echo ""
}

# ===== MAIN EXECUTION =====
main() {
    echo ""
    echo "=========================================="
    echo "🚀 اسکریپت ایجاد سرور DigitalOcean"
    echo "📦 نسخه 4.0 - ورودیهای انعطافپذیر"
    echo "=========================================="
    echo ""
    
    # مراحل پیش‌نیاز
    check_prerequisites
    check_env_file
    load_and_validate_env
    
    echo ""
    print_info "⚙️  تنظیمات Droplet:"
    echo "  📝 نام: $DROPLET_NAME"
    echo "  📍 منطقه: $REGION"
    echo "  💾 Size Slug: $SIZE"
    echo "  🐧 سیستم‌عامل: $IMAGE"
    echo "  🏷️  Tags: $TAGS"
    echo "  🌐 IPv6: $ENABLE_IPV6"
    echo "  💾 Backups: $ENABLE_BACKUPS"
    if [ -n "$AUTO_SHUTDOWN_HOURS" ]; then
        echo "  ⏱️  Auto-Shutdown: پس از $AUTO_SHUTDOWN_HOURS ساعت"
    fi
    echo ""
    
    # دریافت SSH Key
    SSH_KEY_ID=$(get_ssh_key_id) || exit_error "ناموفق در دریافت SSH Key"
    
    # ایجاد Droplet
    DROPLET_ID=$(create_droplet) || exit_error "ناموفق در ایجاد Droplet"
    
    # انتظار برای Droplet
    wait_for_droplet "$DROPLET_ID" || exit_error "Droplet به موقع آماده نشد"
    
    # دریافت اطلاعات
    DROPLET_IP=$(get_droplet_info "$DROPLET_ID") || exit_error "ناموفق در دریافت اطلاعات Droplet"
    
    # نمایش خلاصه
    show_summary "$DROPLET_ID" "$DROPLET_NAME" "$DROPLET_IP" "$REGION"
}

# اجرای main
main "$@"
