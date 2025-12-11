#!/bin/bash

################################################################################
# 🚀 DigitalOcean Server Creation Script (v5.0 - Production Ready)
################################################################################
# 
# هدف: خودکار‌سازی کامل ایجاد سرور توسعه در DigitalOcean
# با KASM Workspace و RustDesk Server برای دسئترسی از راه دور
#
# دستگای: 
#   1. GitHub Actions workflow برای دکمه کاری
#   2. ریزمان لاین (Terminal) برای توسعه‌دهندگان مواردی
#
# نویسنده: Mahdi Bagheban
# تاریخ: دسامبر 2025
#
################################################################################

set -o pipefail  # خروج اگر هر دستور ناموفق باشد

# ════════════════════════════════════════════
# 🎎 رنگ‌بندی و ویرایشلزرف
# ════════════════════════════════════════════

# رنگ‌ها
005c=("\033[39m" "\033[92m" "\033[91m" "\033[33m" "\033[94m" "\033[36m" "\033[35m")
C_DEF="${005c[0]}"   # بدون رنگ

C_GRN="${005c[1]}"   # سبز - ناراحت و موفقیت
C_RED="${005c[2]}"   # قرمز - خطا
C_YEL="${005c[3]}"   # زرد - هشدار
C_BLU="${005c[4]}"   # آبی - اطلاعات
C_CYN="${005c[5]}"   # سبز مایه - مراحل
C_MAG="${005c[6]}"   # بنفش - ظرافت

# ════════════════════════════════════════════
# 📋 توابع چاپ پیام
# ════════════════════════════════════════════

print_success() {
    echo -e "${C_GRN}✅ $1${C_DEF}"
}

print_error() {
    echo -e "${C_RED}❌ $1${C_DEF}" >&2
}

print_info() {
    echo -e "${C_BLU}ℹ️  $1${C_DEF}"
}

print_warning() {
    echo -e "${C_YEL}⚠️  $1${C_DEF}"
}

print_step() {
    echo ""
    echo -e "${C_CYN}${1}${C_DEF}"
    echo -e "${C_CYN}───────────────────────────${C_DEF}"
}

print_highlight() {
    echo -e "${C_MAG}${1}${C_DEF}"
}

exit_error() {
    print_error "$1"
    exit 1
}

# ════════════════════════════════════════════
# 🔍 بررسی پرور
# ════════════════════════════════════════════

check_prerequisites() {
    print_step "🔍 بررسی پرور بندی (Prerequisites)"
    
    # بررسی وجود jq
    if ! command -v jq &> /dev/null; then
        print_error "jq برنامه نموجود است"
        print_info "لطفا برروی زیر را ارزیابی کنید:"
        echo -e "  Ubuntu/Debian: ${C_BLU}sudo apt-get install jq${C_DEF}"
        echo -e "  macOS: ${C_BLU}brew install jq${C_DEF}"
        echo -e "  Windows (Scoop): ${C_BLU}scoop install jq${C_DEF}"
        exit 1
    fi
    
    # بررسی curl
    if ! command -v curl &> /dev/null; then
        exit_error "curl برنامه نموجود است"
    fi
    
    # بررسی bc (برای محاسبات)
    if ! command -v bc &> /dev/null; then
        print_warning "bc برنامه نموجود است (برای محاسبه هزینه)"
    fi
    
    print_success "تمام پرور بندی‌ها بررسی شدند"
}

# ════════════════════════════════════════════
# ⚙️ بارگذاری متغیرها
# ════════════════════════════════════════════

load_environment() {
    print_step "🌙 بارگذاری فایل .env"
    
    # حح نظرات: همگام GitHub Actions با environment variables كار می‌کند
    if [ -f ".env" ]; then
        print_info ".env فایل یافت شد"
        source ".env" || print_warning "خطا در خواندن .env"
    fi
    
    # اعتبارسنجی متغیرهای الزامی
    if [ -z "$DO_API_TOKEN" ]; then
        exit_error "DO_API_TOKEN تعریف نشده است"
    fi
    
    if [ -z "$SSH_KEY_NAME" ]; then
        print_warning "SSH_KEY_NAME تعریف نشده، از مقدار پیشفرض استفاده می‌شود"
        SSH_KEY_NAME="MahdiArts"
    fi
    
    # تعيين مقادير پيشفرض
    DROPLET_NAME="${DO_DROPLET_NAME:-${DROPLET_NAME:-mahdi-dev-workspace-64gb}}"
    REGION="${DO_REGION:-${REGION:-fra1}}"
    SIZE="${DO_SIZE_SLUG:-${SIZE:-s-4vcpu-8gb}}"
    IMAGE="${DO_IMAGE:-${IMAGE:-ubuntu-24-04-x64}}"
    TAGS="${DO_TAGS:-${TAGS:-github-actions,development,kasm,rustdesk}}"
    
    # تبديل string به boolean
    ENABLE_IPV6="${DO_ENABLE_IPV6:-true}"
    ENABLE_BACKUPS="${DO_ENABLE_BACKUPS:-false}"
    
    if [ "$ENABLE_IPV6" = "false" ] || [ "$ENABLE_IPV6" = "0" ]; then
        ENABLE_IPV6="false"
    else
        ENABLE_IPV6="true"
    fi
    
    if [ "$ENABLE_BACKUPS" = "true" ] || [ "$ENABLE_BACKUPS" = "1" ]; then
        ENABLE_BACKUPS="true"
    else
        ENABLE_BACKUPS="false"
    fi
    
    print_success "متغیرها بارگذار شدند"
}

# ════════════════════════════════════════════
# 🔌 API Calls با Retry مکانیزم
# ════════════════════════════════════════════

api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
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
        if [[ "$http_code" =~ ^(200|201|202)$ ]]; then
            echo "$body"
            return 0
        fi
        
        # Rate limiting - منتظر بمان
        if [ "$http_code" = "429" ]; then
            retry=$((retry + 1))
            if [ $retry -lt $max_retries ]; then
                print_warning "رایـِزفركت ریتـِز ال عی بی‌جا - تلاش $retry/$max_retries - منتظر 10 ثانیه..."
                sleep 10
                continue
            fi
        fi
        
        # خطای ديگر
        print_error "خطا API (HTTP $http_code):"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    done
    
    return 1
}

# ════════════════════════════════════════════
# 🔑 دریافت SSH Key ID
# ════════════════════════════════════════════

get_ssh_key_id() {
    print_step "🔑 دریافت ID کلید SSH"
    
    local response
    response=$(api_call GET "/account/keys") || return 1
    
    local ssh_key_id
    ssh_key_id=$(echo "$response" | jq -r ".ssh_keys[] | select(.name==\"$SSH_KEY_NAME\") | .id" 2>/dev/null)
    
    if [ -z "$ssh_key_id" ] || [ "$ssh_key_id" = "null" ]; then
        print_error "کلید SSH با نام '$SSH_KEY_NAME' یافت نشد!"
        print_info "لایست کلیدهای موجود:"
        echo "$response" | jq -r '.ssh_keys[] | "  • \\(.name) (ID: \\(.id))"' 2>/dev/null
        return 1
    fi
    
    print_success "کلید SSH پیدا شد: $SSH_KEY_NAME (ID: $ssh_key_id)"
    echo "$ssh_key_id"
}

# ════════════════════════════════════════════
# 🚄 ایجاد Droplet
# ════════════════════════════════════════════

create_droplet() {
    print_step "🏗️ ایجاد Droplet (Size: $SIZE | Region: $REGION)"
    
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
  "user_data": null
}
EOF
)
    
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
        return 1
    fi
    
    print_success "🚄 Droplet با موفقیت ایجاد شد"
    print_info "شناسه: $droplet_id"
    
    echo "$droplet_id" > .droplet_id
    echo "$droplet_id"
}

# ════════════════════════════════════════════
# ⏳ انتظار برای آماده شدن Droplet
# ════════════════════════════════════════════

wait_for_droplet() {
    local droplet_id=$1
    
    print_step "⏳ منتظر آماده شدن سرور..."
    
    local status="new"
    local counter=0
    local max_wait=600  # 10 دقیقه
    local interval=10
    
    # صبر بدون چک برای راه‌اندازی اولیه
    sleep 30
    
    while [ "$status" != "active" ] && [ $counter -lt $max_wait ]; do
        sleep $interval
        counter=$((counter + interval))
        
        local response
        response=$(api_call GET "/droplets/$droplet_id") || {
            print_warning "خطا در دریافت وضعیت، تلاش مجدد..."
            continue
        }
        
        status=$(echo "$response" | jq -r '.droplet.status' 2>/dev/null)
        
        if [ -z "$status" ] || [ "$status" = "null" ]; then
            print_warning "خطا: وضعیت Droplet دریافت نشد"
            continue
        fi
        
        local progress=$((counter * 100 / max_wait))
        local bar_length=30
        local filled=$((progress * bar_length / 100))
        local empty=$((bar_length - filled))
        
        # ایجاد progress bar
        local bar="["
        for i in $(seq 1 $filled); do bar="${bar}="; done
        for i in $(seq 1 $empty); do bar="${bar}-"; done
        bar="${bar}]"
        
        printf "\r${C_BLU}[i]${C_DEF} وضعیت: %-8s | $bar %3d%% | صبر %ds\\   " "$status" "$progress" "$((max_wait - counter))"
    done
    
    echo ""  # newline after progress bar
    
    if [ "$status" = "active" ]; then
        print_success "🎉 Droplet آماده شد! (در $((counter))s ثانیه)"
        return 0
    else
        print_error "😿 Droplet به موقع آماده نشد (وضعیت: $status)"
        return 1
    fi
}

# ════════════════════════════════════════════
# 📋 دریافت اطلاعات Droplet
# ════════════════════════════════════════════

get_droplet_info() {
    local droplet_id=$1
    
    print_step "📋 دریافت اطلاعات سرور"
    
    local response
    response=$(api_call GET "/droplets/$droplet_id") || return 1
    
    local ipv4=$(echo "$response" | jq -r '.droplet.networks.v4[] | select(.type=="public") | .ip_address' | head -1)
    local ipv6=$(echo "$response" | jq -r '.droplet.networks.v6[] | select(.type=="public") | .ip_address' | head -1)
    local memory=$(echo "$response" | jq -r '.droplet.memory')
    local vcpus=$(echo "$response" | jq -r '.droplet.vcpus')
    local disk=$(echo "$response" | jq -r '.droplet.disk')
    
    if [ -z "$ipv4" ] || [ "$ipv4" = "null" ]; then
        print_error "خطا: IPv4 دریافت نشد"
        return 1
    fi
    
    # ذخیره در فایل و متغیرهای global
    echo "$ipv4" > .droplet_ip
    echo "$ipv6" > .droplet_ipv6
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .droplet_created_at
    
    DROPLET_IPV4="$ipv4"
    DROPLET_IPV6="$ipv6"
    DROPLET_MEMORY="$memory"
    DROPLET_VCPUS="$vcpus"
    DROPLET_DISK="$disk"
    
    print_success "اطلاعات دریافت شد"
    echo "$ipv4"
}

# ════════════════════════════════════════════
# 📊 محاسبه هزینه تقریبی
# ════════════════════════════════════════════

calculate_hourly_cost() {
    local size=$1
    
    # نرخ‌های DigitalOcean (دلار آمریکا در ساعت)
    case $size in
        "s-2vcpu-4gb")     echo "0.0357" ;;
        "s-4vcpu-8gb")     echo "0.0714" ;;
        "s-4vcpu-8gb")    echo "0.5952" ;;
        "m-16vcpu-128gb")  echo "1.1904" ;;
        "m-24vcpu-192gb")  echo "1.7857" ;;
        "m-32vcpu-256gb")  echo "2.3809" ;;
        "c-16")            echo "0.4762" ;;
        "c-32")            echo "0.9524" ;;
        "r-2vcpu-16gb")    echo "0.1191" ;;
        "r-4vcpu-32gb")    echo "0.2381" ;;
        *) echo "0" ;;
    esac
}

# ════════════════════════════════════════════
# 🌟 نمایش خلاصه نهایی
# ════════════════════════════════════════════

show_summary() {
    local droplet_id=$1
    local ipv4=$2
    
    local hourly_cost=$(calculate_hourly_cost "$SIZE")
    local daily_cost=$(echo "$hourly_cost * 24" | bc -l 2>/dev/null || echo "0")
    local monthly_cost=$(echo "$hourly_cost * 730" | bc -l 2>/dev/null || echo "0")
    
    echo ""
    echo "========================================="
    print_highlight "✨ سرور شما با موفقیت ایجاد شد!"
    echo "========================================="
    echo ""
    
    print_info "📋 مشخصات سرور:"
    echo "  🆔 شناسه: $droplet_id"
    echo "  📝 نام: $DROPLET_NAME"
    echo "  🌐 IPv4: $ipv4"
    if [ -n "$DROPLET_IPV6" ] && [ "$DROPLET_IPV6" != "null" ]; then
        echo "  🌍 IPv6: $DROPLET_IPV6"
    fi
    echo "  📍 منطقه: $REGION"
    echo ""
    
    print_info "💪 قدرت پردازشی:"
    echo "  🧠 RAM: $DROPLET_MEMORY MB"
    echo "  🔥 CPU: $DROPLET_VCPUS vCPUs"
    echo "  ⚡ SSD: $DROPLET_DISK GB"
    echo ""
    
    print_info "🔗 دستورات اتصال:"
    echo ""
    echo -e "  ${C_GRN}SSH (ترمینال):${C_DEF}"
    echo -e "    ${C_BLU}ssh root@$ipv4${C_DEF}"
    echo ""
    
    print_info "💰 هزینه تقریبی:"
    if [ "$hourly_cost" != "0" ]; then
        echo "  ساعتی: \$$hourly_cost/hour"
        if command -v bc &> /dev/null && [ "$daily_cost" != "0" ]; then
            printf "  روزانه: \$%.2f/day\n" "$daily_cost"
            printf "  ماهانه: \$%.2f/month\n" "$monthly_cost"
        fi
    fi
    echo ""
    
    print_warning "⚠️  بعد از استفاده، حتماً سرور را حذف کنید!"
    echo ""
    echo "========================================="
    print_highlight "🚀 موفق باشید!"
    echo "========================================="
    echo ""
}

# ════════════════════════════════════════════
# 🚀 اجرای اصلی (Main)
# ════════════════════════════════════════════

main() {
    echo ""
    print_highlight "========================================="
    print_highlight "🚀 اسکریپت ایجاد سرور DigitalOcean v5.0"
    print_highlight "========================================="
    echo ""
    
    # مراحل پیش‌نیاز
    check_prerequisites || exit 1
    load_environment || exit 1
    
    print_info "⚙️  تنظیمات Droplet:"
    echo "  📝 نام: $DROPLET_NAME"
    echo "  🌍 منطقه: $REGION"
    echo "  💾 اندازه: $SIZE"
    echo "  🐧 سیستم‌عامل: $IMAGE"
    echo "  🏷️  برچسب‌ها: $TAGS"
    echo ""
    
    # دریافت SSH Key
    SSH_KEY_ID=$(get_ssh_key_id) || exit 1
    echo ""
    
    # ایجاد Droplet
    DROPLET_ID=$(create_droplet) || exit 1
    echo ""
    
    # انتظار برای آماده شدن
    wait_for_droplet "$DROPLET_ID" || exit 1
    echo ""
    
    # دریافت اطلاعات
    DROPLET_IP=$(get_droplet_info "$DROPLET_ID") || exit 1
    echo ""
    
    # نمایش خلاصه
    show_summary "$DROPLET_ID" "$DROPLET_IP"
}

# اجرای برنامه
main "$@"
