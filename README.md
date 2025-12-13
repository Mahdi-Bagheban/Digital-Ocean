# 🚀 DigitalOcean Automation Suite v10.0

<div dir="rtl" align="right">

> **اتوماسیون کامل ایجاد سرورهای قدرتمند با RustDesk Server OSS، Node.js، و Python برای توسعه و دسترسی از راه دور**

[![🔧 Status: Active](https://img.shields.io/badge/Status-Active-brightgreen)]()
[![💾 Version: 10.0](https://img.shields.io/badge/Version-10.0-blue)]()
[![📄 License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![📈 RustDesk: OSS](https://img.shields.io/badge/RustDesk-OSS-orange)]()
[![👤 Author: Mahdi Bagheban](https://img.shields.io/badge/Author-Mahdi%20Bagheban-orange)](https://github.com/Mahdi-Bagheban)

</div>

---

## 📈 What's New in v10.0?

### ✨ Major Changes

| Feature | v5.0 | **v10.0** | Status |
|---------|------|----------|--------|
| RustDesk Server | ❌ | ✅ **OSS Self-Hosted** | 🌟 NEW |
| Node.js | ❌ | ✅ **LTS 20** | 🌟 NEW |
| Python 3 | ❌ | ✅ **Complete** | 🌟 NEW |
| KASM Workspace | ✅ | ❌ **Removed** | 🗑️ Removed |
| IPv4 + IPv6 | ✅ | ✅ **Both** | ✅ Improved |
| Auto Guides | ✅ | ✅ **Enhanced** | ✅ Better |

### Why These Changes?

```
🚀 RustDesk Server OSS
   • Lightweight remote access
   • Self-hosted = Full privacy
   • Works on Android + Windows
   • Perfect for development

📦 Node.js + Python
   • Web development tools
   • Script automation
   • Data processing
   • Machine learning ready

🗑️ No KASM Workspace
   • Too heavy (memory intensive)
   • Expensive to run hourly
   • Replaced by lighter RustDesk
   • Better cost efficiency
```

---

## 🚀 Quick Start (30 Seconds)

### Method 1: GitHub Actions (Easiest)

```
1. Go to: Actions tab
2. Click: "🚀 Create DigitalOcean Server with RustDesk"
3. Fill in: Server name, Region, Size
4. Click: "Run workflow"
5. Wait: 3-5 minutes
6. Get: IP address from GitHub Release
7. Connect: Open RustDesk, enter IP
8. Done! 🎉
```

### Method 2: Linux/macOS Terminal

```bash
# Clone & Setup
git clone https://github.com/Mahdi-Bagheban/Digital-Ocean.git
cd Digital-Ocean
cp .env.example .env

# Edit .env with your API token
nano .env

# Run
chmod +x scripts/init-server.sh
bash scripts/init-server.sh
```

---

## 💰 Complete Pricing Breakdown

### Server Sizes & Costs

| Size | Specs | /Hour | /Day | /Month | Best For |
|------|-------|-------|------|--------|----------|
| **Nano** | 1 CPU, 512MB | $0.006 | $0.14 | $4 | Testing only |
| **Small** ⭐ | 2 CPU, 4GB | $0.035 | $0.84 | **$26** | Recommended |
| **Standard** | 4 CPU, 8GB | $0.071 | $1.70 | **$52** | Light Dev |
| **High Memory** | 2 CPU, 16GB | $0.149 | $3.57 | **$98** | Heavy Workload |
| **Extra Large** | 8 CPU, 64GB | $0.595 | $14.28 | **$435** | Production |

### Example: Small (2 CPU, 4GB RAM)

- **1 Hour**: $0.035 = cheapest trial
- **1 Day (24h)**: $0.84 = short project
- **1 Week**: $5.88 = test environment
- **1 Month**: $26 = develop & test

✅ **Pro Tip:** Use smaller sizes for testing, upgrade to "Standard" for real dev work.

---

## 🌟 Recommended Setup

### For Most Users (Best Value)

```yaml
Server Name: my-rustdesk-server
Region: fra1          # Frankfurt (best latency to Iran)
Size: s-2vcpu-4gb     # 2 vCPU, 4GB RAM
Cost: $26/month (~$0.035/hour)
Suitable for: 1-3 concurrent users
```

### For Development

```yaml
Server Name: dev-workspace
Region: fra1
Size: s-4vcpu-8gb     # 4 vCPU, 8GB RAM
Cost: $52/month (~$0.071/hour)
Suitable for: Active development, Docker containers
```

### For Production

```yaml
Server Name: prod-rustdesk
Region: fra1
Size: m-8vcpu-64gb    # 8 vCPU, 64GB RAM
Cost: $435/month (~$0.595/hour)
Suitable for: Heavy workloads, multiple users
```

---

## 💱 What's Installed?

### System
- ✅ **Ubuntu 24.04 LTS** - Latest stable
- ✅ **Docker** - Container platform
- ✅ **Docker Compose** - Multi-container
- ✅ **UFW Firewall** - Security (IPv4 + IPv6)

### RustDesk
- ✅ **RustDesk Server OSS v1.41.9** - Self-hosted
- ✅ **hbbs** - Signal Server
- ✅ **hbbr** - Relay Server
- ✅ **systemd services** - Auto-start

### Development
- ✅ **Node.js 20 LTS** - JavaScript runtime
- ✅ **npm** - Package manager
- ✅ **Python 3** - Programming language
- ✅ **pip3** - Package manager
- ✅ **Git** - Version control

### Tools
- ✅ **tmux** - Terminal multiplexer
- ✅ **nano/vim** - Text editors
- ✅ **curl/wget** - Download tools
- ✅ **jq** - JSON processor
- ✅ **htop** - System monitor

---

## 📱 Mobile Connection (Android)

### 5-Minute Setup

1. **Download App**
   - Google Play Store: Search "RustDesk"
   - Or download APK from [rustdesk.com](https://rustdesk.com)

2. **Open App & Connect**
   - Tap "+" button
   - Select "IP Address"
   - Enter server IP: `165.232.123.45` (example)
   - Tap "Connect"

3. **First Connection**
   - App connects to your server
   - Server shows permission dialog
   - Accept connection
   - Done! 🎉

4. **Access Remote Desktop**
   - See server desktop in app
   - Touch to move mouse
   - Use keyboard to type
   - Touch & hold for right-click

### Tips
- 📱 Works on **WiFi or mobile data**
- 🔄 Landscape mode for better view
- 📊 Adjust quality in settings for slower networks
- 💾 Bookmarks connection for quick access

---

## 💻 Windows Connection

### 5-Minute Setup

1. **Download RustDesk**
   - Go to [rustdesk.com](https://rustdesk.com/downloads/)
   - Download "RustDesk.exe"

2. **Install**
   - Double-click `RustDesk.exe`
   - If Smart Screen appears: Click "More info" → "Run anyway"
   - Click "Install"
   - Wait 1-2 minutes

3. **Connect**
   - RustDesk launches automatically
   - Enter server IP in "ID/IP" field
   - Example: `165.232.123.45`
   - Click "Connect" or press Enter

4. **First Connection**
   - A dialog appears on server
   - Click "Accept" to allow access
   - Server desktop appears in RustDesk window
   - You can now control the server!

### Keyboard Shortcuts
- **Ctrl+Alt+Home** - Release mouse capture
- **Win+R** - Open Run on remote
- **Alt+Tab** - Switch remote windows
- **Ctrl+C/V** - Copy-paste works!

---

## 🗑️ Delete Server When Done

### ⚠️ IMPORTANT: Don't Forget This!

**Server costs money while running!**

### GitHub Actions Method

1. Go to **Actions** tab
2. Click **"🗑️ Delete DigitalOcean Server"**
3. Enter server name: `my-rustdesk-server`
4. Select confirm: **"DELETE"** (exact match)
5. Click "Run workflow"
6. ✅ Server deleted - no more charges!

### Terminal Method

```bash
# SSH to server first
ssh root@YOUR_IP

# Or use deletion script
bash scripts/cleanup.sh
```

---

## 📝a Complete Guides

### 📖 Full Documentation

- **[RUSTDESK_SETUP.md](./RUSTDESK_SETUP.md)** ⭐ START HERE
  - Complete setup guide
  - Android connection steps
  - Windows connection steps
  - Troubleshooting section
  - Advanced configuration

- **[Workflows Documentation](./.github/workflows/)**
  - `create-server.yml` - Create workflow
  - `delete-server.yml` - Delete workflow
  - `cleanup-old-workflows.yml` - Maintenance

---

## 🔧 GitHub Actions Setup

### Step 1: Add Secrets

Go to: `Settings → Secrets and variables → Actions`

Add these secrets:

| Name | Where to Get | Example |
|------|-------------|----------|
| `DO_API_TOKEN` | DigitalOcean → Settings → API → Tokens | `dop_v1_abc123...` |
| `SSH_KEY_NAME` | DigitalOcean → Settings → SSH Keys | `github-action-key` |

### Step 2: Get DigitalOcean API Token

1. Login to [DigitalOcean Dashboard](https://cloud.digitalocean.com)
2. Go to **API** menu
3. Click **Tokens/Keys**
4. Click **Generate New Token**
5. Select both "Read" and "Write" scopes
6. Copy the token (shown only once!)
7. Paste in GitHub Secrets as `DO_API_TOKEN`

### Step 3: Add SSH Key to DigitalOcean

1. In DigitalOcean Dashboard: **Settings → SSH Keys**
2. Click **Add SSH Key**
3. Paste your public SSH key
4. Name it: `github-action-key`
5. Save name in GitHub Secrets as `SSH_KEY_NAME`

### Step 4: Run Workflow

1. Go to **GitHub Actions** tab
2. Select **"🚀 Create DigitalOcean Server with RustDesk"**
3. Click **"Run workflow"** button
4. Fill in parameters
5. Click **"Run workflow"** again
6. Watch progress in logs
7. Get IP from Release section when done

---

## 🌐 Region Selection Guide

### Best Latency Map

```
🇮🇷 Iran Users:
  fra1 (Frankfurt) ............... ⭐⭐⭐⭐⭐ BEST (~100ms)
  ams3 (Amsterdam) ............... ⭐⭐⭐⭐ Good (~150ms)
  lon1 (London) .................. ⭐⭐⭐ OK (~200ms)
  sgp1 (Singapore) ............... ⭐⭐ Fair (~250ms)
  nyc1 (New York) ................ ⭐ Poor (~300ms)

🇺🇸 US Users:
  nyc1 (New York) ................ ⭐⭐⭐⭐⭐ BEST (~10ms)
  sfo3 (San Francisco) ........... ⭐⭐⭐⭐ Good (~60ms)
  fra1 (Frankfurt) ............... ⭐⭐ OK (~100ms)

🇪🇺 Europe Users:
  fra1 (Frankfurt) ............... ⭐⭐⭐⭐⭐ BEST (~10ms)
  ams3 (Amsterdam) ............... ⭐⭐⭐⭐⭐ BEST (~20ms)
  lon1 (London) .................. ⭐⭐⭐⭐ Good (~30ms)
```

---

## 🐛 Troubleshooting

### Android Issues

**Cannot connect?**
- ⏳ Wait 2-3 minutes after server creation
- 🔍 Check IP address is correct
- 🔄 Restart RustDesk app
- 📡 Try WiFi instead of mobile data
- 🔗 Check internet connection

**Black screen?**
- 📱 Tap screen to activate
- ⚙️ Check settings for input permissions
- 🔄 Try reconnecting

---

### Windows Issues

**Connection refused?**
- ⏳ Server may still initializing (wait 2 minutes)
- 🔍 Double-check IP address
- 🔐 Check Windows Firewall settings
- 📡 Ping: `ping 165.232.123.45`

**RustDesk blocked by antivirus?**
- ✅ RustDesk is open-source and safe
- 🛡️ Add RustDesk to antivirus whitelist
- 🔄 Restart and try again

**Very slow connection?**
- 📊 Check internet speed (needs 5+ Mbps)
- ⚙️ Reduce quality in RustDesk settings
- 📉 Try lower resolution
- 🔄 Close other apps using network

---

## 💰 Understanding Costs

### How Billing Works

```
💰 Billing = Hourly Rate × Hours Running

Example - Small (2 CPU, 4GB):
  1 hour running    = $0.035
  24 hours running  = $0.84
  730 hours/month   = $26.00

⚠️ Important: Stopped servers still cost money!
   Always DELETE when done.
```

### Monthly Cost Examples

| Scenario | Cost |
|----------|------|
| Leave running 1 month | ~$26 |
| 1 week testing | ~$5 |
| 1 day workshop | ~$0.84 |
| 1 hour test | $0.035 |
| **Not charged** | **After deletion** ✅ |

### Save Money
✅ Use smaller sizes for testing
✅ Delete server immediately after use
✅ Set reminders to avoid forgetting
✅ Use Frankfurt region for best performance

---

## 📚 Resources

### Official Docs
- [RustDesk Documentation](https://rustdesk.com/docs/)
- [DigitalOcean API Docs](https://docs.digitalocean.com/reference/api/)
- [Node.js Docs](https://nodejs.org/en/docs/)
- [Python Docs](https://docs.python.org/3/)

### GitHub
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [RustDesk Server GitHub](https://github.com/rustdesk/rustdesk-server)

---

## 🔄 Changelog

### v10.0 (December 2025) - Current
- ✨ Added RustDesk Server OSS
- ✨ Added Node.js LTS 20
- ✨ Added Python 3 complete
- 🗑️ Removed KASM Workspace (too heavy)
- ✅ Enhanced IPv4 + IPv6 support
- ✅ Improved workflow automation
- 📖 Complete connection guides
- 🎨 Better GitHub Release output

### v5.0 (Previous)
- KASM Workspace included
- Basic automation
- Manual RustDesk setup

---

## 👤 Author

**Mahdi Bagheban (MahdiArts)**
- GitHub: [@Mahdi-Bagheban](https://github.com/Mahdi-Bagheban)
- Website: [MahdiArts.ir](https://mahdiarts.ir)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

<div dir="rtl" align="right">

## سلام! 👋

اگر این پروژه برای شما مفید بود، لطفا یک ⭐ Star بدهید.

هرگونه سوال یا مشکل؟ یک Issue بسازید!

---

**آخرین به‌روزرسانی:** دسامبر 13، 2025

**نسخه:** 10.0 ✨

**وضعیت:** فعال و در حال توسعه ✅

</div>
