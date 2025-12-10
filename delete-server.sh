#!/bin/bash

#######################################
# اسکریپت حذف سرور از DigitalOcean
# با محاسبه هزینه استفاده
# توسط: Mahdi Bagheban
# تاریخ: دسامبر 2025
# نسخه: 2.0 (بهبود شده)
#######################################

set -o pipefail

# رنگ‌ها برای نمایش بهتر
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

exit_error() {
    print_error "$1"
    exit 1
}

# تابع API call با retry logic
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
        
        # Rate limiting
        if [ "$http_code" = "429" ]; then
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warning "Rate limit - ${retry_count}/${max_retries} - منتظر 10 ثانیه..."
                sleep 10
                continue
            fi
        fi
        
        print_error "API Error (HTTP $http_code): $body"
        return 1
    done
    
    return 1
}

# بررسی پیش‌نیازها
check_prerequisites() {
    print_info "بررسی پیش‌نیازها..."
    
    if ! command -v jq &> /dev/null; then
        exit_error "jq نصب نشده است"
    fi
    
    if ! command -v curl &> /dev/null; then
        exit_error "curl نصب نشده است"
    fi
    
    if ! command -v bc &> /dev/null; then
        exit_error "bc نصب نشده است"
    fi
    
    print_message "تمام پیش‌نیازها موجود هستند"
}

# بررسی فایل .env
check_env_file() {
    CONFIG_FILE=".env"
    if [ ! -f "$CONFIG_FILE" ]; then
        exit_error "فایل .env یافت نشد"
    fi
}

# بارگذاری متغیرها
load_env() {
    source ".env"
    
    if [ -z "$DO_API_TOKEN" ]; then
        exit_error "DO_API_TOKEN در فایل .env تنظیم نشده است"
    fi
}

# بررسی droplet_id
check_droplet_id() {
    if [ ! -f ".droplet_id" ]; then
        exit_error "فایل .droplet_id یافت نشد!
احتمالاً سرور قبلاً حذف شده یا ایجاد نشده است"
    fi
}

# دریافت اطلاعات Droplet
get_droplet_info() {
    local droplet_id=$1
    
    print_message "در حال دریافت اطلاعات سرور..."
    
    local response
    response=$(api_call GET "/droplets/$droplet_id") || return 1
    
    # بررسی 404
    if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
        ERROR_MSG=$(echo "$response" | jq -r '.message')
        if [[ "$ERROR_MSG" == *"not found"* ]]; then
            print_warning "سرور با این شناسه وجود ندارد یا قبلاً حذف شده است"
            return 2  # صورت خاصی نبود
        else
            return 1
        fi
    fi
    
    echo "$response"
}

# حذف Droplet
delete_droplet() {
    local droplet_id=$1
    
    print_message "درحال حذف سرور..."
    
    # بررسی قبلی تایید
    read -p "آیا بطور مطمئن هستید می‌خواهید این سرور را حذف کنید? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        print_info "عملیات حذف لغو شد"
        return 0
    fi
    
    # حذف ایجاد کرد
    local response
    response=$(curl -s -w "\n%{http_code}" -X DELETE \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $DO_API_TOKEN" \
      "https://api.digitalocean.com/v2/droplets/$droplet_id")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "204" ]; then
        print_message "سرور با موفقیت حذف شد!"
        return 0
    elif [ "$http_code" = "404" ]; then
        print_warning "سرور قبلاً حذف شده است"
        return 2
    else
        print_error "خطا در حذف سرور (HTTP $http_code)"
        local body=$(echo "$response" | sed '$d')
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

# محاسبه هزینه
calculate_cost() {
    if [ ! -f ".droplet_created_at" ]; then
        print_warning "فایل زمان ایجاد نشد - محاسبه هزینه امکان‌پذیر نیست"
        return
    fi
    
    CREATED_AT=$(cat .droplet_created_at)
    CURRENT_TIME=$(date +%s)
    USAGE_SECONDS=$((CURRENT_TIME - CREATED_AT))
    
    USAGE_HOURS=$(echo "scale=2; $USAGE_SECONDS / 3600" | bc)
    USAGE_DAYS=$(echo "scale=2; $USAGE_HOURS / 24" | bc)
    
    # Memory-Optimized 32GB: $250/month = $0.347/hour
    HOURLY_RATE=0.347
    ESTIMATED_COST=$(echo "scale=2; $USAGE_HOURS * $HOURLY_RATE" | bc)
    
    echo ""
    echo "======================================"
    print_message "اطلاعات استفاده از سرور:"
    echo "======================================"
    print_info "مدت زمان استفاده: ${USAGE_HOURS} ساعت (${USAGE_DAYS} روز)"
    print_info "نرخ ساعتی: \$${HOURLY_RATE}"
    print_info "هزینه تقریبی: \$${ESTIMATED_COST}"
    echo "======================================"
    echo ""
}

# پاك‌سازی فایل‌ها
cleanup_files() {
    print_message "پاك‌سازی فایل‌های محلی..."
    rm -f .droplet_id .droplet_ip .droplet_created_at
    print_message "فایل‌های محلی پاك شدند"
}

# ===== MAIN EXECUTION =====
main() {
    print_info "=== شروع اسکریپت حذف سرور ==="
    echo ""
    
    # مراحل شروعی
    check_prerequisites
    check_env_file
    load_env
    check_droplet_id
    
    DROPLET_ID=$(cat .droplet_id)
    print_info "شناسه سرور: $DROPLET_ID"
    echo ""
    
    # دریافت اطلاعات
    DROPLET_INFO=$(get_droplet_info "$DROPLET_ID")
    RESULT=$?
    
    if [ $RESULT -eq 1 ]; then
        exit_error "خطا در دریافت اطلاعات Droplet"
    fi
    
    if [ $RESULT -eq 2 ]; then
        print_warning "سرور قبلاً حذف شده است"
        cleanup_files
        exit 0
    fi
    
    # نمایش اطلاعات
    DROPLET_NAME=$(echo "$DROPLET_INFO" | jq -r '.droplet.name')
    IPV4=$(echo "$DROPLET_INFO" | jq -r '.droplet.networks.v4[0].ip_address')
    STATUS=$(echo "$DROPLET_INFO" | jq -r '.droplet.status')
    
    echo ""
    print_info "نام سرور: $DROPLET_NAME"
    print_info "آی‌پی: $IPV4"
    print_info "وضعیت: $STATUS"
    echo ""
    
    # محاسبه هزینه
    calculate_cost
    
    # حذف
    delete_droplet "$DROPLET_ID"
    DELETE_RESULT=$?
    
    if [ $DELETE_RESULT -ne 0 ] && [ $DELETE_RESULT -ne 2 ]; then
        exit_error "خطا در حذف سرور"
    fi
    
    # پاك‌سازی
    cleanup_files
    
    echo ""
    print_message "عملیات ایجاد شام انجام شد"
    echo ""
}

main "$@"
