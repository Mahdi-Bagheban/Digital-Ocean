# 📋 راهنمای تنظیم پروژه Digital-Ocean

## 🔐 تنظیم GitHub Secrets (مرحله اول - **مهم**)

برای اینکه GitHub Actions بتونه سرور DigitalOcean رو بسازه، باید دو متغیر محرمانه رو در تنظیمات رپو ست کنی:

### مراحل تنظیم Secrets:

1. **برو به صفحه Settings رپو:**
   ```
   https://github.com/Mahdi-Bagheban/Digital-Ocean/settings/secrets/actions
   ```

2. **روی دکمه `New repository secret` کلیک کن**

3. **اضافه کردن DO_API_TOKEN:**
   - **Name:** `DO_API_TOKEN`
   - **Secret:** توکن API خودت رو از DigitalOcean بگیر
   - چطور توکن بگیری:
     1. برو به: https://cloud.digitalocean.com/account/api/tokens
     2. روی `Generate New Token` کلیک کن
     3. یک نام بهش بده (مثلاً: `GitHub-Actions-Token`)
     4. **Read و Write** رو فعال کن
     5. توکن رو کپی کن و در Secret وارد کن
   - روی `Add secret` کلیک کن

4. **اضافه کردن SSH_KEY_NAME:**
   - روی `New repository secret` دوباره کلیک کن
   - **Name:** `SSH_KEY_NAME`
   - **Secret:** نام SSH Key که در DigitalOcean داری (مثلاً: `MahdiArts`)
   - چطور SSH Key پیدا کنی:
     1. برو به: https://cloud.digitalocean.com/account/security
     2. لیست SSH Keys رو ببین
     3. نام کلید خودت رو پیدا کن و کپی کن
   - روی `Add secret` کلیک کن

---

## ✅ بررسی موفقیت‌آمیز بودن

بعد از تنظیم Secrets، می‌تونی بری به بخش Actions و workflow رو اجرا کنی:

```
https://github.com/Mahdi-Bagheban/Digital-Ocean/actions/workflows/create-server.yml
```

روی دکمه `Run workflow` کلیک کن و سرور رو بساز!

---

## 🔧 استفاده محلی (Local)

اگه می‌خوای اسکریپت رو **روی کامپیوتر خودت** اجرا کنی:

1. **فایل .env بساز:**
   ```bash
   cp .env.example .env
   ```

2. **ویرایش .env:**
   - فایل `.env` رو با یک Text Editor باز کن
   - مقادیر واقعی رو جایگزین کن:
     ```bash
     DO_API_TOKEN=dop_v1_YOUR_REAL_TOKEN_HERE
     SSH_KEY_NAME=MahdiArts
     ```

3. **اجرای اسکریپت:**
   ```bash
   chmod +x create-server.sh
   ./create-server.sh
   ```

---

## 📌 نکات مهم

- ⚠️ **هیچوقت فایل `.env` رو به GitHub پوش نکن!**
- فایل `.env` در `.gitignore` قرار داره تا اتفاقی پوش نشه
- فقط از `.env.example` به عنوان نمونه استفاده کن
- توکن API باید **Read و Write** دسترسی داشته باشه
- اسم SSH Key باید **دقیقاً** همون اسمی باشه که در DigitalOcean ثبت کردی

---

## 🚀 اجرای Workflow از GitHub Actions

1. برو به تب **Actions** در رپو
2. از سمت چپ، روی **"🚀 Create Development Server with KASM"** کلیک کن
3. روی **"Run workflow"** کلیک کن
4. پارامترها رو تنظیم کن (یا از پیش‌فرض استفاده کن):
   - **Server Name:** نام سرور (مثلاً: `mahdi-dev-workspace`)
   - **Region:** منطقه دیتاسنتر (پیش‌فرض: Frankfurt `fra1`)
5. روی دکمه سبز **"Run workflow"** کلیک کن
6. منتظر بمون تا Workflow اجرا بشه (حدود 2-5 دقیقه)
7. بعد از اتمام، IP سرور و اطلاعات دسترسی رو در Summary می‌بینی

---

## 🗑️ حذف سرور

برای حذف سرور و جلوگیری از هزینه‌های اضافی:

### از طریق GitHub Actions:
1. برو به تب **Actions**
2. روی **"🗑️ Delete Server"** کلیک کن
3. **Run workflow** رو بزن

### از طریق Terminal:
```bash
./delete-server.sh
```

---

## ❓ مشکلات رایج

### خطا: "DO_API_TOKEN در فایل .env تنظیم نشده است!"
**راه‌حل:** مطمئن شو که در GitHub Secrets مقدار `DO_API_TOKEN` رو درست تنظیم کردی.

### خطا: "کلید SSH با نام 'XXX' یافت نشد!"
**راه‌حل:** برو به [DigitalOcean Security](https://cloud.digitalocean.com/account/security) و نام دقیق SSH Key خودت رو پیدا کن و در Secret `SSH_KEY_NAME` قرار بده.

### خطا: "jq نصب نشده است"
**راه‌حل:** در GitHub Actions این مشکل نیست، اما برای اجرای محلی:
- **Windows:** `scoop install jq`
- **Linux:** `sudo apt-get install jq`
- **Mac:** `brew install jq`

---

## 💰 هزینه‌ها

سرور Memory-Optimized با 32GB RAM:
- **هزینه ساعتی:** $0.347/hour
- **هزینه ماهانه:** $250/month

**توصیه:** بعد از کار حتماً سرور رو حذف کن تا هزینه اضافی نپردازی!

---

## 📞 پشتیبانی

اگه مشکلی داشتی:
1. مستندات رو دوباره بخون
2. GitHub Issues رو چک کن
3. Issue جدید باز کن با توضیحات کامل

---

**توسط Mahdi Bagheban - دسامبر 2025** 🚀
