#!/bin/bash

#######################################
# اسکریپت ایجاد سرور توسعه در DigitalOcean
# Memory-Optimized 32GB RAM با KASM Workspace
# توسط: Mahdi Bagheban
# تاریخ: دسامبر 2025
#######################################

# رنگ‌ها برای نمایش بهتر
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# بررسی نصب بودن jq برای پردازش JSON
if ! command -v jq &> /dev/null; then
    print_error "jq نصب نشده است. لطفا ابتدا jq را نصب کنید:"
    print_info "Windows: scoop install jq"
    print_info "Linux: sudo apt-get install jq"
    print_info "Mac: brew install jq"
    exit 1
fi

# بررسی وجود فایل تنظیمات
CONFIG_FILE=".env"
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "فایل .env یافت نشد!"
    print_info "لطفا فایل .env را با مقادیر زیر ایجاد کنید:"
    echo ""
    echo "DO_API_TOKEN=your_api_token_here"
    echo "SSH_KEY_NAME=MahdiArts"
    exit 1
fi

# بارگذاری متغیرها از فایل .env
source "$CONFIG_FILE"

# بررسی متغیرهای محیطی
if [ -z "$DO_API_TOKEN" ]; then
    print_error "DO_API_TOKEN در فایل .env تنظیم نشده است!"
    exit 1
fi

if [ -z "$SSH_KEY_NAME" ]; then
    print_warning "SSH_KEY_NAME تنظیم نشده، از MahdiArts استفاده می‌شود"
    SSH_KEY_NAME="MahdiArts"
fi

# تنظیمات Droplet
DROPLET_NAME="${DROPLET_NAME:-mahdi-dev-workspace}"
REGION="${REGION:-fra1}"  # فرانکفورت - نزدیک‌ترین به ایران
SIZE="${SIZE:-m-2vcpu-32gb}"  # Memory-Optimized 32GB
IMAGE="${IMAGE:-ubuntu-22-04-x64}"  # Ubuntu 22.04 LTS
TAGS="${TAGS:-mahdiarts,kasm-workspace,development}"

print_info "=== ایجاد سرور توسعه در DigitalOcean ==="
echo ""
print_info "نام سرور: $DROPLET_NAME"
print_info "منطقه: $REGION"
print_info "حافظه: 32GB RAM"
print_info "سیستم‌عامل: Ubuntu 22.04 LTS"
print_info "نوع: Memory-Optimized"
print_info "محیط: KASM Workspace + نرم‌افزارهای توسعه"
echo ""

# دریافت ID کلید SSH
print_message "در حال دریافت اطلاعات SSH Key..."
SSH_KEY_ID=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/account/keys" | \
  jq -r ".ssh_keys[] | select(.name==\"$SSH_KEY_NAME\") | .id")

if [ -z "$SSH_KEY_ID" ]; then
    print_error "کلید SSH با نام '$SSH_KEY_NAME' یافت نشد!"
    print_info "لیست کلیدهای SSH موجود:"
    curl -s -X GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DO_API_TOKEN" \
      "https://api.digitalocean.com/v2/account/keys" | \
      jq -r '.ssh_keys[] | "  - \(.name) (ID: \(.id))"'
    exit 1
fi

print_message "SSH Key پیدا شد: $SSH_KEY_NAME (ID: $SSH_KEY_ID)"

# اسکریپت نصب نرم‌افزارها
INSTALL_SCRIPT=$(cat << 'EOF'
#!/bin/bash

# نصب پایه‌های سیستم
apt-get update
apt-get upgrade -y
apt-get install -y curl wget git build-essential

# نصب Docker (پیش‌نیاز KASM)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker root

# نصب KASM Workspace
cd /tmp
wget https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.5b7fb6.tar.gz
tar -xzf kasm_release_1.15.0.5b7fb6.tar.gz
cd kasm_release
sudo bash install.sh -L -e -m 32

# نصب Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# نصب Python و ابزارها
apt-get install -y python3 python3-pip python3-venv
pip3 install --upgrade pip setuptools

# نصب VS Code (اختیاری - از طریق Workspace)
# ممکن است در محیط KASM قبلاً موجود باشد

# نصب Git و ابزارهای توسعه
apt-get install -y git vim nano htop tmux

# نصب Android Studio (قابل نصب در KASM)
# این قسمت می‌تواند از طریق KASM GUI نصب شود

# نصب Perplexity و دیگر ابزارها (غیر خطی)
# این‌ها معمولاً از طریق مرورگر یا appimage نصب می‌شوند

echo "✓ نصب نرم‌افزارها انجام شد"
EOF
)

# ایجاد Droplet با user_data برای نصب اتوماتیک
print_message "در حال ایجاد Droplet..."
echo ""

RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  -d "{
    \"name\": \"$DROPLET_NAME\",
    \"region\": \"$REGION\",
    \"size\": \"$SIZE\",
    \"image\": \"$IMAGE\",
    \"ssh_keys\": [$SSH_KEY_ID],
    \"backups\": false,
    \"ipv6\": true,
    \"monitoring\": true,
    \"tags\": [\"${TAGS//,/\",\"}\"],
    \"user_data\": \"$(echo "$INSTALL_SCRIPT" | base64 -w 0)\"
  }" \
  "https://api.digitalocean.com/v2/droplets")

# بررسی خطا
if echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1; then
    print_error "خطا در ایجاد Droplet:"
    echo "$RESPONSE" | jq -r '.message'
    exit 1
fi

# استخراج اطلاعات Droplet
DROPLET_ID=$(echo "$RESPONSE" | jq -r '.droplet.id')
print_message "Droplet با موفقیت ایجاد شد!"
print_info "شناسه Droplet: $DROPLET_ID"

# ذخیره اطلاعات Droplet
echo "$DROPLET_ID" > .droplet_id
print_message "شناسه Droplet در فایل .droplet_id ذخیره شد"

# انتظار برای آماده شدن سرور
print_message "در حال انتظار برای آماده شدن سرور..."
echo ""

STATUS="new"
COUNTER=0
MAX_WAIT=300  # حداکثر 5 دقیقه

while [ "$STATUS" != "active" ] && [ $COUNTER -lt $MAX_WAIT ]; do
    sleep 5
    COUNTER=$((COUNTER + 5))
    
    DROPLET_INFO=$(curl -s -X GET \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DO_API_TOKEN" \
      "https://api.digitalocean.com/v2/droplets/$DROPLET_ID")
    
    STATUS=$(echo "$DROPLET_INFO" | jq -r '.droplet.status')
    
    PROGRESS=$((COUNTER / 3))
    printf "${BLUE}[i]${NC} وضعیت: $STATUS (${PROGRESS}%%) \r"
done

if [ "$STATUS" = "active" ]; then
    print_message "سرور آماده شد!"
    echo ""
    
    # نمایش اطلاعات سرور
    IPV4=$(echo "$DROPLET_INFO" | jq -r '.droplet.networks.v4[0].ip_address')
    IPV6=$(echo "$DROPLET_INFO" | jq -r '.droplet.networks.v6[0].ip_address')
    
    echo "======================================"
    print_message "اطلاعات سرور شما:"
    echo "======================================"
    print_info "شناسه: $DROPLET_ID"
    print_info "نام: $DROPLET_NAME"
    print_info "آی‌پی IPv4: $IPV4"
    print_info "آی‌پی IPv6: $IPV6"
    print_info "منطقه: $REGION"
    print_info "حافظه RAM: 32GB"
    print_info "CPU: 2 vCPU"
    print_info "دیسک: 100GB SSD"
    echo "======================================"
    echo ""
    
    # ذخیره آی‌پی
    echo "$IPV4" > .droplet_ip
    print_message "آی‌پی سرور در فایل .droplet_ip ذخیره شد"
    
    echo ""
    print_info "🔌 دستورات اتصال:"
    echo ""
    echo -e "${GREEN}SSH:${NC}"
    echo "  ssh root@$IPV4"
    echo ""
    echo -e "${GREEN}KASM Workspace:${NC}"
    echo "  https://$IPV4:443"
    echo "  Port: 443 (HTTPS)"
    echo ""
    
    # ذخیره تاریخ ایجاد برای محاسبه هزینه
    date +%s > .droplet_created_at
    print_message "اطلاعات ایجاد سرور ثبت شد"
    
    echo ""
    print_warning "⏱️  نصب نرم‌افزارها 5-15 دقیقه طول می‌کشد"
    print_info "لطفا صبور باشید..."
    echo ""
    
else
    print_error "سرور در زمان مقرر آماده نشد!"
    print_warning "لطفا وضعیت سرور را در پنل DigitalOcean بررسی کنید"
    exit 1
fi

print_message "عملیات با موفقیت انجام شد!"
print_info "برای حذف سرور از دستور زیر استفاده کنید:"
echo ""
echo -e "${YELLOW}./delete-server.sh${NC}"
echo ""
