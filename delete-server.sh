#!/bin/bash

#######################################
# اسکریپت حذف سرور از DigitalOcean
# با محاسبه هزینه دقیق برای 64GB RAM
# توسط: Mahdi Bagheban
# تاریخ: دسامبر 2025
# نسخه: 3.0 (ارتقاء برای 64GB)
#######################################

set -o pipefail

# رنگ‌ها برای نمایش بهتر
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_success() {
    echo -e "${PURPLE}[★]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[→]${NC} $1"
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
    print_step "بررسی پیش‌نیازها..."
    
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
    
    print_step "در حال دریافت اطلاعات سرور..."
    
    local response
    response=$(api_call GET "/droplets/$droplet_id") || return 1
    
    # بررسی 404
    if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
        ERROR_MSG=$(echo "$response" | jq -r '.message')
        if [[ "$ERROR_MSG" == *"not found"* ]]; then
            print_warning "سرور با این شناسه وجود ندارد یا قبلاً حذف شده است"
            return 2  # حالت خاص: سرور پیدا نشد
        else
            return 1
        fi
    fi
    
    echo "$response"
}

# حذف Droplet
delete_droplet() {
    local droplet_id=$1
    
    print_step "آماده‌سازی برای حذف سرور..."
    echo ""
    
    # تایید قبل از حذف
    print_warning "⚠️  شما در حال حذف سرور هستید!"
    echo ""
    read -p "آیا مطمئن هستید که می‌خواهید این سرور را حذف کنید? (yes/no): " CONFIRM
    echo ""
    
    if [ "$CONFIRM" != "yes" ]; then
        print_info "عملیات حذف لغو شد"
        return 0
    fi
    
    print_step "درحال حذف سرور..."
    
    # حذف سرور
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

# محاسبه هزینه دقیق برای 64GB RAM
calculate_cost() {
    if [ ! -f ".droplet_created_at" ]; then
        print_warning "فایل زمان ایجاد یافت نشد - محاسبه هزینه امکان‌پذیر نیست"
        return
    fi
    
    CREATED_AT=$(cat .droplet_created_at)
    CURRENT_TIME=$(date +%s)
    USAGE_SECONDS=$((CURRENT_TIME - CREATED_AT))
    
    # محاسبه زمان استفاده
    USAGE_HOURS=$(echo "scale=2; $USAGE_SECONDS / 3600" | bc)
    USAGE_DAYS=$(echo "scale=2; $USAGE_HOURS / 24" | bc)
    USAGE_MINUTES=$(echo "scale=0; $USAGE_SECONDS / 60" | bc)
    
    # Memory-Optimized Premium Intel 64GB: $428/month = $0.595/hour
    HOURLY_RATE=0.595
    ESTIMATED_COST=$(echo "scale=2; $USAGE_HOURS * $HOURLY_RATE" | bc)
    
    # محاسبه هزینه ماهانه در صورت ادامه
    MONTHLY_COST=428
    
    echo ""
    echo "=========================================="
    print_info "📊 خلاصه استفاده از سرور"
    echo "=========================================="
    echo ""
    print_info "⏱️  مدت زمان استفاده:"
    echo "   ${USAGE_MINUTES} دقیقه"
    echo "   ${USAGE_HOURS} ساعت"
    echo "   ${USAGE_DAYS} روز"
    echo ""
    print_info "💰 اطلاعات هزینه:"
    echo "   نرخ ساعتی: \$${HOURLY_RATE}"
    echo "   نرخ ماهانه: \$${MONTHLY_COST}"
    echo ""
    print_success "💵 هزینه تقریبی این دوره: \$${ESTIMATED_COST}"
    echo ""
    
    # نکته مفید
    if (( $(echo "$USAGE_HOURS < 1" | bc -l) )); then
        print_info "💡 نکته: استفاده کمتر از ۱ ساعت - هزینه کم!"
    elif (( $(echo "$USAGE_DAYS > 1" | bc -l) )); then
        print_warning "⚠️  توجه: استفاده بیش از ۱ روز - هزینه قابل توجه!"
    fi
    
    echo "=========================================="
    echo ""
}

# پاک‌سازی فایل‌ها
cleanup_files() {
    print_step "پاک‌سازی فایل‌های محلی..."
    
    local files_to_remove=(".droplet_id" ".droplet_ip" ".droplet_created_at")
    local removed_count=0
    
    for file in "${files_to_remove[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            removed_count=$((removed_count + 1))
        fi
    done
    
    if [ $removed_count -gt 0 ]; then
        print_message "${removed_count} فایل محلی پاک شد"
    else
        print_info "فایلی برای پاک‌سازی یافت نشد"
    fi
}

# نمایش خلاصه نهایی
show_final_summary() {
    echo ""
    echo "=========================================="
    print_success "✨ عملیات حذف سرور با موفقیت انجام شد"
    echo "=========================================="
    echo ""
    print_info "📝 خلاصه عملیات:"
    echo "   ✓ سرور از DigitalOcean حذف شد"
    echo "   ✓ فایل‌های محلی پاک شدند"
    echo "   ✓ هزینه محاسبه شد"
    echo ""
    print_info "🔄 برای ایجاد سرور جدید:"
    echo -e "${CYAN}   ./create-server.sh${NC}"
    echo ""
    print_message "🎉 با تشکر از استفاده شما!"
    echo "=========================================="
    echo ""
}

# ===== MAIN EXECUTION =====
main() {
    echo ""
    echo "=========================================="
    echo "🗑️  اسکریپت حذف سرور DigitalOcean"
    echo "📦 نسخه 3.0 - 64GB RAM Server"
    echo "=========================================="
    echo ""
    
    # مراحل شروعی
    check_prerequisites
    check_env_file
    load_env
    check_droplet_id
    
    DROPLET_ID=$(cat .droplet_id)
    print_info "🆔 شناسه سرور: $DROPLET_ID"
    echo ""
    
    # دریافت اطلاعات
    DROPLET_INFO=$(get_droplet_info "$DROPLET_ID")
    RESULT=$?
    
    if [ $RESULT -eq 1 ]; then
        exit_error "خطا در دریافت اطلاعات سرور"
    fi
    
    if [ $RESULT -eq 2 ]; then
        print_warning "سرور قبلاً حذف شده است"
        cleanup_files
        echo ""
        print_message "✅ عملیات با موفقیت انجام شد"
        echo ""
        exit 0
    fi
    
    # نمایش اطلاعات سرور
    DROPLET_NAME=$(echo "$DROPLET_INFO" | jq -r '.droplet.name')
    IPV4=$(echo "$DROPLET_INFO" | jq -r '.droplet.networks.v4[0].ip_address')
    STATUS=$(echo "$DROPLET_INFO" | jq -r '.droplet.status')
    SIZE=$(echo "$DROPLET_INFO" | jq -r '.droplet.size.slug')
    REGION=$(echo "$DROPLET_INFO" | jq -r '.droplet.region.slug')
    
    echo ""
    echo "=========================================="
    print_info "📋 اطلاعات سرور مورد نظر برای حذف"
    echo "=========================================="
    echo ""
    echo "  📝 نام: $DROPLET_NAME"
    echo "  🌐 آی‌پی: $IPV4"
    echo "  📊 وضعیت: $STATUS"
    echo "  💪 مشخصات: $SIZE"
    echo "  📍 منطقه: $REGION"
    echo ""
    echo "=========================================="
    echo ""
    
    # محاسبه هزینه
    calculate_cost
    
    # حذف سرور
    delete_droplet "$DROPLET_ID"
    DELETE_RESULT=$?
    
    if [ $DELETE_RESULT -ne 0 ] && [ $DELETE_RESULT -ne 2 ]; then
        exit_error "خطا در حذف سرور"
    fi
    
    # پاک‌سازی
    cleanup_files
    
    # نمایش خلاصه نهایی
    show_final_summary
}

main "$@"