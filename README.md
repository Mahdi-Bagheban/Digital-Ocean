# 🚀 DigitalOcean Automation Suite v5.0

<div dir="rtl" align="right">

> **برنامه‌برنامه خودکار‌سازی کامل ایجاد و مدیریت سرور‌های DigitalOcean برای محیط‌های قدرتمند و پرایک‌س انلاین**

[![🔧 Status: Active](https://img.shields.io/badge/Status-Active-brightgreen)]()
[![🔖 Version: 5.0](https://img.shields.io/badge/Version-5.0-blue)]()
[![📄 License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![🐚 Language: Bash](https://img.shields.io/badge/Language-Bash-ff69b4)]()
[![👤 Author: Mahdi Bagheban](https://img.shields.io/badge/Author-Mahdi%20Bagheban-orange)](https://github.com/Mahdi-Bagheban)

</div>

---

## 📖 تضمین سریع

### 🚀 محیط قدرتمند یک کلیک!
- **GitHub Actions**: کلیک سریع برای ایجاد سرور
- **یا Bash Script**: اجرای مستقیم روی Linux/macOS
- **KASM Workspace**: دسکتاپ الکترونیکی در مرورگر
- **RustDesk Server**: دسترسی میزوار
- **Docker + Node.js + Python**: محیط توسعه کامل

---

## ✨ ویژگی‌ها

### 🎯 اتوماسیون کامل
- ✅ ایجاد سرور یک کلیک با GitHub Actions
- ✅ Configuration پیش‌فرض معقول
- ✅ پشتیبانی اختیاری Backup و IPv6
- ✅ Error handling قوی و Retry mechanism
- ✅ Progress indicators و خروجی User-friendly

### 💡 Best Practices
- ✅ Environment variable بدون Hardcoding
- ✅ Validation کامل ورودی‌ها
- ✅ Health Check خودکار
- ✅ Artifacts برای اطلاعات سرور
- ✅ GitHub Actions best practices

### 🛠️ محیط قدرتمند
- ✅ KASM Workspace 1.15 (دسکتاپ در مرورگر)
- ✅ RustDesk Server (دسترسی از راه دور)
- ✅ Docker Pre-installed
- ✅ Node.js 20 LTS + Python 3
- ✅ Git, tmux, zsh + Oh My Zsh
- ✅ Ubuntu 24.04 LTS

### 🎨 منعطف و پیکربندی‌پذیر
- ✅ تعیین اندازه سرور (s-2vcpu-4gb تا m-32vcpu-256gb)
- ✅ انتخاب منطقه (fra1, ams3, lon1, nyc1, sfo3, sgp1)
- ✅ Custom tags و Monitoring

---

## 📋 نیازمندی‌ها

### GitHub Actions
```
✓ GitHub Account
✓ DigitalOcean Account (حساب فعال)
✓ DigitalOcean API Token
✓ SSH Key در DigitalOcean
```

### محلی (Local Script)
```bash
✓ Bash 4.0+
✓ curl
✓ jq (JSON processor)
✓ bc (Calculator - اختیاری)
✓ Linux/macOS (یا Windows Subsystem for Linux)
```

**نصب پیش‌نیازها:**

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y curl jq bc

# macOS
brew install curl jq bc

# Windows (Scoop)
scoop install jq curl bc
```

---

## 🚀 شروع سریع

### گام 1️⃣: تنظیم Secrets در GitHub

به مسیر زیر بروید:
```
Settings → Secrets and variables → Actions → New repository secret
```

**Secrets مورد نیاز:**

| نام | توضیح | مثال |
|------|----------|----------|
| `DO_API_TOKEN` | API Token از DigitalOcean | `dop_v1_abc123...` |
| `SSH_KEY_NAME` | نام SSH Key در DigitalOcean | `my-ssh-key` |

**راهنمای دریافت API Token:**
1. وارد [DigitalOcean Control Panel](https://cloud.digitalocean.com) شوید
2. **API → Tokens/Keys → Generate New Token**
3. Scopes: "Read" و "Write" را انتخاب کنید
4. کپی و در Secrets GitHub قرار دهید

**اضافه کردن SSH Key:**
1. **Settings → Security → SSH keys → Add SSH key**
2. کلید عمومی SSH خود را پیست کنید
3. نام آن را در `SSH_KEY_NAME` قرار دهید

---

### گام 2️⃣: اجرای GitHub Actions

1. بروید به تب **Actions**
2. **🚀 Create Development Server** را انتخاب کنید
3. **Run workflow** را کلیک کنید
4. پارامترها را تنظیم کنید:

```
📝 نام سرور: mahdi-dev-workspace-64gb
🌍 منطقه: fra1 (Frankfurt)
💻 اندازه: m-8vcpu-64gb (8 CPU, 64GB RAM)
🌐 IPv6: true
💾 Backups: false (default)
🏷️  Tags: github-actions,development
```

5. **Run workflow** را کلیک کنید
6. منتظر تکمیل بمانید (حدود 5-10 دقیقه)

---

### گام 3️⃣: اتصال به سرور

پس از اتمام موفق، دستورات اتصال را مشاهده کنید:

```bash
# SSH (ترمینال)
ssh root@YOUR_IP_ADDRESS

# مثال:
ssh root@165.232.123.45
```

---

## 🖥️ استفاده محلی (Local)

### مراحل اجرا:

```bash
# 1. Clone کردن repository
git clone https://github.com/YOUR_USERNAME/Digital-Ocean.git
cd Digital-Ocean

# 2. ایجاد فایل .env
cp .env.example .env

# 3. تنظیم متغیرها
nano .env  # یا ویرایشگر خود را استفاده کنید

# 4. اجرا
chmod +x create-server.sh
./create-server.sh
```

### محتوای فایل `.env`:

```bash
# ✓ الزامی
DO_API_TOKEN="dop_v1_your_token_here"
SSH_KEY_NAME="your-ssh-key-name"

# ✓ اختیاری (پیش‌فرض)
DO_DROPLET_NAME="mahdi-dev-workspace-64gb"
DO_REGION="fra1"
DO_SIZE_SLUG="m-8vcpu-64gb"
DO_ENABLE_IPV6="true"
DO_ENABLE_BACKUPS="false"
DO_TAGS="github-actions,development,kasm"
DO_IMAGE="ubuntu-24-04-x64"
```

---

## 🔧 تنظیمات و Options

### اندازه‌های دسترسی‌پذیر (Size Slug)

| پلن | CPU | RAM | SSD | هزینه (ماهانه) | مورد استفاده |
|-----|-----|-----|-----|-------|-------------|
| **s-2vcpu-4gb** | 2 | 4GB | 80GB | ~$26 | تست، دمو خیلی سبک |
| **s-4vcpu-8gb** | 4 | 8GB | 160GB | ~$52 | دمو سبک |
| **m-8vcpu-64gb** | 8 | 64GB | 200GB | ~$435 | **توصیه شده** - توسعه |
| **m-16vcpu-128gb** | 16 | 128GB | 400GB | ~$870 | پروژه‌های بزرگ |
| **m-24vcpu-192gb** | 24 | 192GB | 600GB | ~$1305 | داده‌های بزرگ |
| **m-32vcpu-256gb** | 32 | 256GB | 800GB | ~$1740 | درخواست‌های سنگین |

### منطقه‌ها (Regions)

| کد | نام | مکان | Latency | بهترین برای |
|----|------|------|---------|----------|
| **fra1** | Frankfurt | 🇩🇪 آلمان | ~10-15ms | **پیشفرض** - بهترین برای ایران |
| **ams3** | Amsterdam | 🇳🇱 هلند | ~12-18ms | اروپای شمالی |
| **lon1** | London | 🇬🇧 انگلیس | ~15-20ms | اروپا |
| **nyc1** | New York | 🇺🇸 آمریکا | ~60-80ms | آمریکای شمالی |
| **sfo3** | San Francisco | 🇺🇸 آمریکا | ~120-140ms | آمریکای غربی |
| **sgp1** | Singapore | 🇸🇬 سنگاپور | ~80-100ms | آسیا |

---

## 📊 معماری

```
┌──────────────────────────────────────────────────────────────┐
│         GitHub Actions Workflow or Local Script              │
│    (یا Bash Script شما از ترمینال)                       │
└──────────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │ Validation &        │
        │ Check SSH Key       │
        └──────────┬──────────┘
                   │
        ┌──────────┴──────────────────────┐
        │ Create Droplet on DigitalOcean   │
        │ (Ubuntu 24.04)                  │
        └──────────┬──────────────────────┘
                   │
        ┌──────────┴──────────┐
        │ Wait for Boot       │
        │ & IP Address        │
        └──────────┬──────────┘
                   │
        ┌──────────┴────────────────────────────────┐
        │ Auto-Install on Droplet:                 │
        │ ├─ Docker & Docker Compose               │
        │ ├─ KASM Workspace                        │
        │ ├─ RustDesk Server                       │
        │ ├─ Node.js 20 LTS                        │
        │ ├─ Python 3 + pip                        │
        │ ├─ Git, tmux, zsh                        │
        │ └─ Security (UFW, etc)                   │
        └──────────┬────────────────────────────────┘
                   │
        ┌──────────┴──────────────────┐
        │ Health Check & Display       │
        │ Summary                      │
        └──────────────────────────────┘
```

---

## 🔐 امنیت

### بهترین تمرین‌ها

✅ **API Token Management**
- فقط از GitHub Secrets استفاده کنید
- کلیدها را هرگز Commit نکنید
- Token‌ها را دوره‌ای Rotate کنید

✅ **SSH Security**
- SSH Key-based authentication تنها
- Password Authentication غیرفعال
- Default Port تغییر یافته

✅ **Firewall**
- UFW (Uncomplicated Firewall) فعال
- فقط پورت‌های ضروری باز
- All inbound denied by default

✅ **Monitoring**
- DigitalOcean Monitoring فعال
- Health checks خودکار
- Alerts برای مشاکل

---

## 🗑️ حذف سرور

### روش 1: GitHub Actions
1. بروید **Actions**
2. **🗑️ Delete Development Server** را انتخاب کنید
3. Server ID یا Name را وارد کنید
4. تأیید کنید

### روش 2: محلی
```bash
bash ./delete-server.sh
```

---

## 💰 هزینه

### مثال برای m-8vcpu-64gb (پیشفرض)

```
ساعتی:   $0.5952/hour
روزانه:   ~$14.28/day
ماهانه:   ~$435/month (بر اساس 730 ساعت)

Backup (اختیاری): +20% (~$87/month)
Data Transfer:     $0.20/GB (بعد از 8TB)
```

---

## 🐛 Troubleshooting

### مشکل: "API Token not found"

**راه حل:**
```bash
# Local script:
export DO_API_TOKEN="your-token"

# یا .env میں:
DO_API_TOKEN="dop_v1_..."

# GitHub Actions:
# Settings → Secrets → DO_API_TOKEN
```

### مشکل: "SSH Key not found"

**راه حل:**
```bash
# ابتدا کلید را بررسی کنید:
curl -s -X GET \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  https://api.digitalocean.com/v2/account/keys | jq '.ssh_keys[] | .name'

# نام دقیق را استفاده کنید
```

### مشکل: "Rate limit exceeded"

**راه حل:**
- اسکریپت خودکار Retry می‌کند (3 بار)
- منتظر 10 ثانیه بین تلاش‌ها
- محدودیت: 5000 requests/hour

### مشکل: Droplet بلند نمی‌شود

**راه حل:**
1. Quota DigitalOcean را بررسی کنید
2. منطقه قابل دسترس است؟
3. اندازه سرور در آن منطقه موجود است؟

---

## 📚 مستندات جزئی

| فایل | توضیح |
|------|-------|
| `.github/workflows/create-server.yml` | GitHub Actions Workflow |
| `create-server.sh` | اسکریپت ایجاد سرور (محلی) |
| `delete-server.sh` | اسکریپت حذف سرور |
| `.env.example` | نمونه فایل تنظیمات |
| `README.md` | این فایل |
| `CHANGELOG.md` | تاریخچه تغییرات |

### Output Files

پس از ایجاد سرور:

```bash
.droplet_id          # شناسه سرور
.droplet_ip          # آدرس IPv4
.droplet_ipv6        # آدرس IPv6 (if enabled)
.droplet_created_at  # زمان ایجاد
```

---

## 🤝 مشارکت

درخواست‌های Pull و Issues خوشامد!

```bash
# Fork → Clone → Create Branch → Commit → Push → PR
git clone https://github.com/YOUR_USERNAME/Digital-Ocean.git
git checkout -b feature/your-feature
# ... تغییرات شما ...
git push origin feature/your-feature
```

### قوانین:
- Bash و YAML syntax valid باشند
- کامنت‌ها به فارسی
- نام متغیرها به انگلیسی
- Test روی محیط خود

---

## 📄 لایسنس

MIT License - برای جزئیات بیشتر [LICENSE](LICENSE) را ببینید.

---

## 👤 درباره نویسنده

**Mahdi Bagheban**
- 🔗 GitHub: [@Mahdi-Bagheban](https://github.com/Mahdi-Bagheban)
- 🌐 Website: [در صورت وجود]

---

## 🙏 تشکر

- **DigitalOcean** - برای API و سرورهای قابل اعتماد
- **KASM Team** - برای KASM Workspace
- **RustDesk Project** - برای RustDesk Server
- **جامعه متن‌باز** - برای ابزارهای فوق‌العاده

---

## 🔗 منابع مفید

- [DigitalOcean API Documentation](https://docs.digitalocean.com/reference/api/)
- [DigitalOcean CLI (doctl)](https://docs.digitalocean.com/reference/doctl/)
- [KASM Workspace Docs](https://www.kasmweb.com/)
- [RustDesk Server Setup](https://github.com/rustdesk/rustdesk-server)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide)

---

<div dir="rtl" align="right">

## نسخه‌های قبلی

- **v5.0** (2025-12-12) - بازنویسی کامل، بهبود خطا، progress bars
- **v4.0** (2025-12-08) - اضافه کردن KASM Workspace
- **v3.0** (2025-12-05) - RustDesk Server integration
- **v2.0** (2025-12-01) - GitHub Actions Workflow
- **v1.0** (2025-11-25) - اولین نسخه

---

**بسم‌الله الرحمن الرحیم** 🌙

**آخرین به‌روزرسانی:** دسامبر 2025

</div>
