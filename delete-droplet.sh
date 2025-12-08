#!/bin/bash

#######################################
# اسکریپت حذف Droplet از DigitalOcean
# با محاسبه هزینه استفاده
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
    print_info "لطفا فایل .env را با API Token ایجاد کنید"
    exit 1
fi

# بارگذاری متغیرها از فایل .env
source "$CONFIG_FILE"

# بررسی متغیر API Token
if [ -z "$DO_API_TOKEN" ]; then
    print_error "DO_API_TOKEN در فایل .env تنظیم نشده است!"
    exit 1
fi

# بررسی وجود فایل شناسه Droplet
if [ ! -f ".droplet_id" ]; then
    print_error "فایل .droplet_id یافت نشد!"
    print_info "احتمالاً Droplet قبلاً حذف شده یا ایجاد نشده است"
    exit 1
fi

DROPLET_ID=$(cat .droplet_id)

print_info "=== حذف Droplet از DigitalOcean ==="
echo ""
print_info "شناسه Droplet: $DROPLET_ID"

# دریافت اطلاعات Droplet قبل از حذف
print_message "در حال دریافت اطلاعات سرور..."
DROPLET_INFO=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID")

# بررسی وجود Droplet
if echo "$DROPLET_INFO" | jq -e '.message' > /dev/null 2>&1; then
    ERROR_MSG=$(echo "$DROPLET_INFO" | jq -r '.message')
    if [[ "$ERROR_MSG" == *"not found"* ]]; then
        print_warning "Droplet با این شناسه وجود ندارد یا قبلاً حذف شده است"
        print_message "پاک‌سازی فایل‌های محلی..."
        rm -f .droplet_id .droplet_ip .droplet_created_at
        print_message "فایل‌های محلی پاک شدند"
        exit 0
    else
        print_error "خطا در دریافت اطلاعات: $ERROR_MSG"
        exit 1
    fi
fi

# نمایش اطلاعات سرور
DROPLET_NAME=$(echo "$DROPLET_INFO" | jq -r '.droplet.name')
IPV4=$(echo "$DROPLET_INFO" | jq -r '.droplet.networks.v4[0].ip_address')
STATUS=$(echo "$DROPLET_INFO" | jq -r '.droplet.status')

echo ""
print_info "نام سرور: $DROPLET_NAME"
print_info "آی‌پی: $IPV4"
print_info "وضعیت: $STATUS"
echo ""

# محاسبه هزینه استفاده
if [ -f ".droplet_created_at" ]; then
    CREATED_AT=$(cat .droplet_created_at)
    CURRENT_TIME=$(date +%s)
    USAGE_SECONDS=$((CURRENT_TIME - CREATED_AT))
    
    USAGE_HOURS=$(echo "scale=2; $USAGE_SECONDS / 3600" | bc)
    USAGE_DAYS=$(echo "scale=2; $USAGE_HOURS / 24" | bc)
    
    # قیمت Memory-Optimized 32GB: $250/ماه (30 روز) = $8.33/روز = $0.347/ساعت
    HOURLY_RATE=0.347
    ESTIMATED_COST=$(echo "scale=2; $USAGE_HOURS * $HOURLY_RATE" | bc)
    
    echo "======================================"
    print_message "اطلاعات استفاده از سرور:"
    echo "======================================"
    print_info "مدت زمان استفاده: ${USAGE_HOURS} ساعت (${USAGE_DAYS} روز)"
    print_info "نرخ ساعتی: \$${HOURLY_RATE}"
    print_info "هزینه تقریبی: \$${ESTIMATED_COST}"
    echo "======================================"
    echo ""
else
    print_warning "فایل زمان ایجاد یافت نشد - محاسبه هزینه امکان‌پذیر نیست"
    echo ""
fi

# تأیید حذف
print_warning "آیا مطمئن هستید که می‌خواهید این Droplet را حذف کنید؟"
read -p "برای ادامه 'yes' تایپ کنید: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "عملیات حذف لغو شد"
    exit 0
fi

# حذف Droplet
print_message "در حال حذف Droplet..."
DELETE_RESPONSE=$(curl -s -w "%{http_code}" -X DELETE \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID")

HTTP_CODE="${DELETE_RESPONSE: -3}"

if [ "$HTTP_CODE" = "204" ]; then
    print_message "Droplet با موفقیت حذف شد!"
    
    # پاک‌سازی فایل‌های محلی
    print_message "پاک‌سازی فایل‌های محلی..."
    rm -f .droplet_id .droplet_ip .droplet_created_at
    
    print_message "تمام فایل‌های مربوط به Droplet پاک شدند"
    echo ""
    
    if [ ! -z "$ESTIMATED_COST" ]; then
        print_info "هزینه نهایی شما تقریباً \$${ESTIMATED_COST} خواهد بود"
        print_info "این مبلغ از اعتبار حساب DigitalOcean شما کسر می‌شود"
    fi
    
    echo ""
    print_message "عملیات حذف با موفقیت انجام شد!"
    
elif [ "$HTTP_CODE" = "404" ]; then
    print_warning "Droplet قبلاً حذف شده است"
    print_message "پاک‌سازی فایل‌های محلی..."
    rm -f .droplet_id .droplet_ip .droplet_created_at
    print_message "فایل‌های محلی پاک شدند"
    
else
    print_error "خطا در حذف Droplet (کد HTTP: $HTTP_CODE)"
    print_error "پاسخ سرور: ${DELETE_RESPONSE:0:-3}"
    exit 1
fi
