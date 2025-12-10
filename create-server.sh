#!/bin/bash

#######################################
# اسکریپت ایجاد سرور توسعه در DigitalOcean
# Memory-Optimized 32GB RAM با KASM Workspace
# توسط: Mahdi Bagheban
# تاریخ: دسامبر 2025
# نسخه: 2.0 (بهبود شده)
#######################################

set -o pipefail  # خروج از اسکریپت اگر هر دستور فشل شود

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

# تابع خروج با خطا
exit_error() {
    print_error "$1"
    exit 1
}

# تابع چک کردن پیش‌نیازها
check_prerequisites() {
    print_info "بررسی پیش‌نیازها..."
    
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
    if [ ! -f "$CONFIG_FILE" ]; then
        exit_error "فایل .env یافت نشد!
لطفا فایل .env را با مقادیر زیر ایجاد کنید:
DO_API_TOKEN=your_api_token_here
SSH_KEY_NAME=MahdiArts"
    fi
}

# بارگذاری و اعتبارسنجی متغیرها
load_and_validate_env() {
    source ".env"
    
    if [ -z "$DO_API_TOKEN" ]; then
        exit_error "DO_API_TOKEN در فایل .env تنظیم نشده است!"
    fi
    
    if [ -z "$SSH_KEY_NAME" ]; then
        print_warning "SSH_KEY_NAME تنظیم نشده، از MahdiArts استفاده می‌شود"
        SSH_KEY_NAME="MahdiArts"
    fi
    
    # تنظیمات پیش‌فرض Droplet
    DROPLET_NAME="${DROPLET_NAME:-mahdi-dev-workspace}"
    REGION="${REGION:-fra1}"
    SIZE="${SIZE:-m-2vcpu-32gb}"
    IMAGE="${IMAGE:-ubuntu-22-04-x64}"
    TAGS="${TAGS:-mahdiarts,kasm-workspace,development}"
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

# دریافت ID کلید SSH با بهتر خطا processing
get_ssh_key_id() {
    print_message "در حال دریافت اطلاعات SSH Key..."
    
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

# ایجاد اسکریپت نصب بهتر
create_install_script() {
    cat << 'EOFSCRIPT'
#!/bin/bash
set -e

# Log کردن
LOG_FILE="/var/log/kasm-install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== شروع نصب در $(date) ==="

# نصب پایه‌های سیستم
apt-get update || { echo "خطا در update"; exit 1; }
apt-get upgrade -y || { echo "خطا در upgrade"; exit 1; }
apt-get install -y curl wget git build-essential ca-certificates || { echo "خطا در نصب پایه‌ای"; exit 1; }

# نصب Docker (پیش‌نیاز KASM)
echo "درحال نصب Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh || { echo "خطا در دانلود Docker"; exit 1; }
bash get-docker.sh || { echo "خطا در نصب Docker"; exit 1; }
usermod -aG docker root || true

# بررسی موفقیت Docker
if ! command -v docker &> /dev/null; then
    echo "Docker نصب نشد!"
    exit 1
fi

echo "Docker نصب شد: $(docker --version)"

# نصب KASM Workspace
echo "درحال نصب KASM Workspace..."
cd /tmp

# دانلود با retry
for i in {1..3}; do
    if wget -q https://kasm-static-content.s3.amazonaws.com/kasm_release_1.15.0.5b7fb6.tar.gz; then
        break
    fi
    if [ $i -eq 3 ]; then
        echo "خطا: دانلود KASM ناموفق بود"
        exit 1
    fi
    echo "تلاش مجدد دانلود KASM ($i/3)..."
    sleep 5
done

# استخراج و نصب
tar -xzf kasm_release_1.15.0.5b7fb6.tar.gz || { echo "خطا در استخراج KASM"; exit 1; }
cd kasm_release

# نصب KASM (بدون interactive)
bash install.sh -L -e -m 32 2>&1 | tee -a "$LOG_FILE" || {
    echo "خطا در نصب KASM - بررسی لاگ:"
    tail -50 "$LOG_FILE"
    exit 1
}

# نصب Node.js
echo "درحال نصب Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || true
apt-get install -y nodejs || { echo "خطا در نصب Node.js"; exit 1; }
echo "Node.js نصب شد: $(node --version)"

# نصب Python
echo "درحال نصب Python..."
apt-get install -y python3 python3-pip python3-venv || { echo "خطا در نصب Python"; exit 1; }
pip3 install --upgrade pip setuptools 2>&1 | tail -5 || true
echo "Python نصب شد: $(python3 --version)"

# نصب ابزارهای توسعه
echo "درحال نصب ابزارهای توسعه..."
apt-get install -y git vim nano htop tmux curl wget net-tools || true

echo "=== نصب موفق در $(date) ==="
echo "تمام نرم‌افزارها با موفقیت نصب شدند"
EOFSCRIPT
}

# ایجاد Droplet
create_droplet() {
    print_message "در حال ایجاد Droplet..."
    
    # ایجاد install script
    local install_script
    install_script=$(create_install_script)
    
    # تبدیل به Base64 صحیح (بدون wrap کردن)
    local user_data_base64
    user_data_base64=$(echo "$install_script" | base64 -w 0)
    
    # ایجاد JSON payload
    local payload=$(cat <<EOF
{
    "name": "$DROPLET_NAME",
    "region": "$REGION",
    "size": "$SIZE",
    "image": "$IMAGE",
    "ssh_keys": [$SSH_KEY_ID],
    "backups": false,
    "ipv6": true,
    "monitoring": true,
    "tags": ["${TAGS//,/\",\""}"],
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
    
    print_message "در حال انتظار برای آماده شدن سرور..."
    
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
    
    print_message "در حال دریافت اطلاعات سرور..."
    
    local response
    response=$(api_call GET "/droplets/$droplet_id") || return 1
    
    local droplet_name=$(echo "$response" | jq -r '.droplet.name')
    local ipv4=$(echo "$response" | jq -r '.droplet.networks.v4[0].ip_address')
    local ipv6=$(echo "$response" | jq -r '.droplet.networks.v6[0].ip_address')
    local status=$(echo "$response" | jq -r '.droplet.status')
    
    if [ -z "$ipv4" ] || [ "$ipv4" = "null" ]; then
        print_error "خطا: IP Address دریافت نشد"
        return 1
    fi
    
    echo "$ipv4" > .droplet_ip
    date +%s > .droplet_created_at
    
    echo "$ipv4"
}

# نمایش خلاصه
show_summary() {
    local droplet_id=$1
    local droplet_name=$2
    local ipv4=$3
    local region=$4
    
    echo ""
    echo "======================================"
    print_message "اطلاعات سرور شما:"
    echo "======================================"
    print_info "شناسه: $droplet_id"
    print_info "نام: $droplet_name"
    print_info "آی‌پی: $ipv4"
    print_info "منطقه: $region"
    print_info "حافظه RAM: 32GB"
    print_info "CPU: 2 vCPU"
    print_info "دیسک: 100GB SSD"
    echo "======================================"
    echo ""
    
    print_info "🔌 دستورات اتصال:"
    echo ""
    echo -e "${GREEN}SSH:${NC}"
    echo "  ssh root@$ipv4"
    echo ""
    echo -e "${GREEN}KASM Workspace (دسکتاپ در مرورگر):${NC}"
    echo "  https://$ipv4:443"
    echo "  Username: admin@kasm.local"
    echo "  (رمز عبور خودکار تعیین می‌شود)"
    echo ""
    
    print_warning "⏱️  نصب نرم‌افزارها 5-15 دقیقه طول می‌کشد"
    print_info "آپ لاگ نصب را می‌توانید بررسی کنید:"
    echo "  ssh root@$ipv4 tail -f /var/log/kasm-install.log"
    echo ""
    
    print_message "عملیات با موفقیت انجام شد!"
}

# ===== MAIN EXECUTION =====
main() {
    print_info "=== شروع اسکریپت ایجاد سرور ==="
    echo ""
    
    # مراحل پیش‌نیاز
    check_prerequisites
    check_env_file
    load_and_validate_env
    
    echo ""
    print_info "تنظیمات Droplet:"
    print_info "  نام: $DROPLET_NAME"
    print_info "  منطقه: $REGION"
    print_info "  حافظه: 32GB"
    print_info "  سیستم‌عامل: Ubuntu 22.04 LTS"
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
    
    print_info "برای حذف سرور از دستور زیر استفاده کنید:"
    echo ""
    echo -e "${YELLOW}./delete-server.sh${NC}"
    echo ""
}

# اجرای main
main "$@"
