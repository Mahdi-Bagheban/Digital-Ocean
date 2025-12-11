# 🚀 DigitalOcean Development Workspace

![Version](https://img.shields.io/badge/version-4.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-active-success)

ابزار خودکار برای ایجاد و مدیریت سرورهای قدرتمند توسعه در DigitalOcean با **KASM Workspace** و **RustDesk Server**.

## 🔛 ویژگی‌ها

- ✅ **خودکار کامل**: GitHub Actions برای ایجاد و حذف سرور
- 💻 **KASM Workspace**: دسکتاپ کامل در مرورگر (GUI دسکتاپ)
- 🔐 **RustDesk Server**: دسترسی از راه دور (Remote Desktop)
- 📦 **Docker**: تمام ابزارها برای containerization
- 🚀 **Node.js 20 LTS**: محیط JavaScript
- 🐍 **Python 3**: برای scripting و data science
- 📤 **انعطافپذیری کامل**: انتخاب پلن، منطقه، و تنظیمات
- 🤑 **هوشمند**: پیش‌فرض‌های معقول + امکان customize

## 📊 مشخصات سرور پیشفرض

### **پلن اصلی** (توصیه شده):
- **Memory-Optimized Premium Intel**: `m-16vcpu-64gb`
- **RAM**: 64GB DDR4
- **vCPU**: 16 (Dedicated)
- **SSD**: 400GB NVMe
- **Transfer**: 8TB
- **هزینه**: ~$0.595/ساعت ($428/ماه)

### **پلن‌های جایگزین** (در GitHub Actions قابل انتخاب):
- `m-24vcpu-192gb` - 24 vCPU, 192GB RAM
- `m-32vcpu-256gb` - 32 vCPU, 256GB RAM
- `c-16` / `c-32` - CPU-Optimized
- `r-16vcpu-128gb` / `r-32vcpu-256gb` - Memory-Optimized
- `s-2vcpu-4gb` / `s-4vcpu-8gb` - برای تست (کم‌هزینه)

## 🚀 شروع سریع

### **الف) تنظیم GitHub Secrets** 

1. به `Settings` → `Secrets and variables` → `Actions` رفتید
2. دو Secret اضافه کنید:

```bash
DO_API_TOKEN = "your_digitalocean_api_token"
SSH_KEY_NAME = "MahdiArts"  # نام SSH Key شما در DigitalOcean
```

### **ب) اجرای Workflow** 🎯

**روش 1: از طریق GitHub UI**

1. به `Actions` رفتید
2. `🚀 Create Development Server` را انتخاب کنید
3. `Run workflow` کلیک کنید
4. پارامترها را پر کنید:
   - **Server Name**: نام سرور (مثال: `mahdi-dev-workspace-64gb`)
   - **Region**: منطقه (مثال: `fra1` برای فرانکفورت)
   - **Size Slug**: پلن سرور (پیشفرض: `m-16vcpu-64gb`)
   - **Enable IPv6**: `true` یا `false`
   - **Enable Backups**: `true` یا `false` (هزینه دارد)
   - **Custom Tags** (اختیاری): برچسب‌های سفارشی

**روش 2: محلی (Local)**

```bash
# 1. فایل .env را ایجاد کنید
cat > .env << EOF
DO_API_TOKEN=your_token_here
SSH_KEY_NAME=MahdiArts
EOF

# 2. اسکریپت را اجرا کنید
bash ./create-server.sh
```

## 🔗 دستورات اتصال

بعد از ایجاد سرور:

### **1️⃣ SSH (ترمینال)**
```bash
ssh root@YOUR_SERVER_IP
```

### **2️⃣ KASM Workspace (GUI دسکتاپ)**
```
https://YOUR_SERVER_IP:443
Username: admin@kasm.local
Password: (از طریق SSH دریافت کنید)
```

### **3️⃣ RustDesk (Remote Desktop)**
```
Server Address: YOUR_SERVER_IP
Ports: 21115-21119
Public Key: ssh root@YOUR_SERVER_IP cat /root/rustdesk-public-key.txt
```

## 📊 مشاهده لاگ و اطلاعات

### **لاگ نصب (Live)**
```bash
ssh root@YOUR_SERVER_IP tail -f /var/log/server-install.log
```

### **اطلاعات کامل سرور**
```bash
ssh root@YOUR_SERVER_IP /root/server-info.sh
```

## 🗑️ حذف سرور

### **روش 1: GitHub Actions**
1. به `Actions` رفتید
2. `🗑️ Delete Development Server` را انتخاب کنید
3. Server ID یا Name وارد کنید
4. تأیید کنید

### **روش 2: محلی**
```bash
bash ./delete-server.sh
```

## 📋 فایل‌های پروژه

```
.
├── create-server.sh          # اسکریپت ایجاد سرور
├── delete-server.sh          # اسکریپت حذف سرور
├── lib.sh                    # توابع مشترک
├── .github/workflows/
│   ├── create-server.yml     # Workflow ایجاد
│   └── delete-server.yml     # Workflow حذف
├── README.md                 # این فایل
├── SETUP.md                  # راهنمای تنظیم
├── TROUBLESHOOTING.md        # حل مشکلات
├── RUSTDESK_GUIDE.md         # راهنمای RustDesk
└── .env.example              # نمونه متغیرهای محیط
```

## ⚠️ نکات مهم

### **هزینه‌ها** 💰
- پلن `m-16vcpu-64gb`: ~$0.595/ساعت
- پلن `m-24vcpu-192gb`: ~$1.785/ساعت
- پلن تست `s-2vcpu-4gb`: ~$0.036/ساعت

### **حفاظت** 🔒
- Firewall UFW فعال است
- تنها پورت‌های ضروری باز هستند
- SSH Key-based Authentication (رمز عبور غیرفعال)

### **نصب و نرم‌افزار** 📦
ابزارهای اتوماتیکی:
- Docker & Docker Compose
- KASM Workspace
- RustDesk Server
- Node.js 20 LTS
- Python 3 + pip
- Git, Curl, Wget, Htop, etc.

زمان نصب: **۵-۲۰ دقیقه** (بستگی به سرعت اینترنت)

### **⏰ مدیریت سرور**

- **موقت**: سرور برای کار تقلبی، توسعه، و تست است
- **خودکار حذف پیشنهاد**: بعد از اتمام کار، سرور را حذف کنید
- **Snapshots**: اختیاری (برای پشتیبان‌گیری)

## 🛠️ تخصیص و مدیریت

### **تغییر اندازه (Scale)**

برای تغییر اندازه سرور در GitHub Actions:
1. Workflow را اجرا کنید
2. `size_slug` را تغییر دهید:
   ```bash
   m-16vcpu-64gb  → m-32vcpu-256gb  (بزرگ‌تر)
   m-16vcpu-64gb  → s-4vcpu-8gb     (کوچک‌تر/تست)
   ```

### **تغییر منطقه (Region)**

پلن‌های مختلف در منطقه‌های مختلف دسترسی دارند:
- `fra1` - Frankfurt (بهترین برای اروپا)
- `ams3` - Amsterdam
- `nyc1` - New York
- `sgp1` - Singapore

## 📞 پشتیبانی و مشاهده وضعیت

### **ورودی‌های Environment** 🔧

تمام ورودی‌های ممکن که می‌توانید customize کنید:

```bash
DO_DROPLET_NAME="mahdi-dev-workspace-64gb"
DO_REGION="fra1"
DO_SIZE_SLUG="m-16vcpu-64gb"
DO_IMAGE="ubuntu-24-04-x64"
DO_TAGS="mahdiarts,kasm-workspace,rustdesk"
DO_ENABLE_IPV6="true"
DO_ENABLE_BACKUPS="false"
DO_AUTO_SHUTDOWN_HOURS=""  # خالی = غیرفعال
```

### **صحت‌سنجی Secrets**

```bash
# بررسی API Token
curl -X GET -H "Authorization: Bearer $DO_API_TOKEN" \
  https://api.digitalocean.com/v2/account

# لیست SSH Keys
curl -X GET -H "Authorization: Bearer $DO_API_TOKEN" \
  https://api.digitalocean.com/v2/account/keys
```

## 🎓 مثال‌های استفاده

### **سناریو 1: تست سریع**
```
Size: s-2vcpu-4gb (ارزان)
Region: fra1
Enable Backups: false
مدت: 1-2 ساعت
```

### **سناریو 2: توسعه سنگین**
```
Size: m-16vcpu-64gb (توصیه شده)
Region: fra1
Enable IPv6: true
Enable Backups: false
مدت: چند روز
```

### **سناریو 3: تولید (Production-like)**
```
Size: m-24vcpu-192gb یا بیشتر
Region: fra1
Enable Backups: true
Enable IPv6: true
مدت: طولانی
```

## 🔐 Security Considerations

- ✅ SSH Key-based authentication
- ✅ UFW Firewall enabled
- ✅ HTTP/HTTPS only exposed ports
- ✅ System updates on boot
- ✅ Regular log monitoring

## 📚 مستندات بیشتر

- [SETUP.md](SETUP.md) - تنظیم دقیق
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - حل مشکلات
- [RUSTDESK_GUIDE.md](RUSTDESK_GUIDE.md) - راهنمای RustDesk
- [FIXES.md](FIXES.md) - رفع‌های شناخته‌شده

## 📄 لیسانس

MIT License - آزاد برای استفاده و توزیع

---

**نسخه**: 4.0 | **آخرین به‌روزرسانی**: دسامبر 2025

**ساخت شده توسط**: [Mahdi Bagheban](https://github.com/Mahdi-Bagheban)

**بسم الله الرحمن الرحیم** ✨
