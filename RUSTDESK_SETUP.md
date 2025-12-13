# 🚀 RustDesk Server Setup & Connection Guide

> **Complete guide for creating, configuring, and connecting to your self-hosted RustDesk server on DigitalOcean**

---

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [Server Creation](#-server-creation)
3. [Android Connection](#-android-connection)
4. [Windows Connection](#-windows-connection)
5. [Troubleshooting](#-troubleshooting)
6. [Advanced Configuration](#-advanced-configuration)
7. [Cost & Billing](#-cost--billing)

---

## 🚀 Quick Start

### 30-Second Overview

```
1. Go to GitHub Actions
2. Run "🚀 Create DigitalOcean Server with RustDesk" workflow
3. Fill in: Server name, Region, Server size
4. Wait 3-5 minutes
5. Get IP address from GitHub Release
6. Open RustDesk app
7. Enter IP address
8. Click Connect!
9. Accept connection on server
10. Done! 🎉
```

---

## 📦 Server Creation

### Step 1: Access GitHub Actions

1. Go to your repository: [Digital-Ocean](https://github.com/Mahdi-Bagheban/Digital-Ocean)
2. Click **"Actions"** tab at the top
3. Look for **"🚀 Create DigitalOcean Server with RustDesk"**
4. Click **"Run workflow"**

### Step 2: Configure Server Settings

**Server Name** (Required)
- Enter a descriptive name: `rustdesk-server`, `my-remote-desktop`, etc.
- Must be unique
- Only use letters, numbers, and hyphens

**Region** (Required) - Choose based on your location:

| Region | Location | Best For | Latency to Iran |
|--------|----------|----------|------------------|
| **fra1** 🌟 | Frankfurt, Germany | Iran & Middle East | **BEST** ~100ms |
| **ams3** | Amsterdam, Netherlands | Europe | ~150ms |
| **lon1** | London, UK | Europe | ~200ms |
| **nyc1** | New York, USA | North America | ~300ms |
| **sfo3** | San Francisco, USA | North America West | ~350ms |
| **sgp1** | Singapore, Asia | Southeast Asia | ~250ms |

**Server Size** (Required) - Choose based on your needs:

| Size | Specs | Cost/Month | Best For | Notes |
|------|-------|-----------|----------|-------|
| **Nano** | 1 vCPU, 512MB RAM | $4 | **Testing only** | Limited |
| **Small** 🌟 | 2 vCPU, 4GB RAM | $26 | **Most Users** | RECOMMENDED |
| **Standard** | 4 vCPU, 8GB RAM | $52 | Light Development | Good for multiple users |
| **High Memory** | 2 vCPU, 16GB RAM | $98 | Heavy Workloads | RAM intensive |
| **Extra Large** | 8 vCPU, 64GB RAM | $435 | Heavy Development | Production |

### Step 3: Create Server

1. Fill in all three fields
2. Click **"Run workflow"** button (green)
3. **Wait 3-5 minutes** for completion
4. Watch the logs in real-time (optional)

### Step 4: Get Connection Details

After completion:

1. Look for the **GitHub Release** with your server ID
2. Download **`rustdesk-connection-guide.md`**
3. Or find **IPv4 address** in the Workflow Output
4. Example: `165.232.123.45`

---

## 📱 Android Connection

### Download RustDesk

**Method 1: Google Play Store** (Official)
1. Open **Google Play Store**
2. Search: **"RustDesk"**
3. Click "Install"
4. Wait for download to complete

**Method 2: Direct APK** (If Play Store unavailable)
1. Visit [rustdesk.com](https://rustdesk.com)
2. Click "Downloads"
3. Select "Android APK"
4. Download and install (may need to enable "Unknown Sources")

### Connect to Server

#### **Option A: Using Server IP (Easiest)**

1. **Open RustDesk app**
2. **Tap the "+" button** (Add new connection) OR **Tap "Connect" button**
3. **Select "IP Address" mode**
4. **Enter server IP**: `165.232.123.45` (your actual IP)
5. **Tap "Connect"**
6. **Wait for connection** (2-10 seconds)
7. **Server will show a permission dialog** - Tap "Accept"
8. **Your remote desktop appears!** 🎉

#### **Option B: Using QR Code (Faster)**

1. **Get QR code** from Release artifacts (`rustdesk-qr-ipv4.png`)
2. **Open RustDesk app**
3. **Tap the scan icon** (QR code icon)
4. **Point camera at QR code**
5. **Auto-connects!**

### Tips for Android

- 📱 Keep your phone in **landscape mode** for better desktop view
- 🔊 Use headphones for better audio experience
- 🔑 Tap the **settings icon** (⚙️) for quality/performance adjustment
- 📍 Bookmark the connection for quick access
- 🌐 Works on **WiFi** and **Mobile Data**

**Supported Android Versions:**
- Android 5.0+
- Recommended: Android 8.0+

---

## 💻 Windows Connection

### Download RustDesk

1. Go to [rustdesk.com](https://rustdesk.com)
2. Click **"Downloads"** menu
3. Download **"RustDesk.exe"** (Windows installer)
4. Or download **"RustDesk.msi"** (Windows package)

### Install RustDesk

**Option 1: EXE Installer** (Recommended)
1. **Double-click** `RustDesk.exe`
2. **Windows Smart Screen might appear** → Click "More info" → "Run anyway"
3. **Click "Install"** in the installer window
4. **Wait for installation** (1-2 minutes)
5. **RustDesk launches automatically** after installation

**Option 2: MSI Installer**
1. **Right-click** `RustDesk.msi`
2. **Select "Install"**
3. **Follow wizard**

**Option 3: Portable Version**
1. Download `RustDesk-portable.exe`
2. Just run it - **no installation needed!**
3. Great for testing or USB drives

### Connect to Server

1. **Launch RustDesk**
   - Look for the RustDesk window
   - Or open from Start menu

2. **Enter Connection Details**
   - Find the **"ID/IP"** field (upper left area)
   - Enter your server IP: `165.232.123.45`
   - Leave **ID** field empty (IP connection mode)

3. **Click "Connect" button** (or press Enter)
   - Window says "Connecting..."
   - Wait 2-10 seconds

4. **Server Confirmation**
   - A dialog appears on **server desktop**
   - Shows your device name
   - Click "Accept" to allow connection

5. **Remote Desktop View**
   - Server desktop appears in RustDesk window
   - Move mouse, click, type normally
   - Like sitting at the server!

### Windows Interface Guide

```
┌─────────────────────────────────────────────┐
│ RustDesk                              🔄 ⚙️  │
├─────────────────────────────────────────────┤
│ ID/IP: [165.232.123.45        ]  [Connect] │
│                                             │
│ Quality:     [High ▼]                       │
│ Resolution:  [Full ▼]                       │
│                                             │
│ Advanced options...                         │
├─────────────────────────────────────────────┤
│ 🎥 Display (Server View)                    │
│                                             │
│ (Remote desktop content shows here)        │
│                                             │
│                                             │
│                                             │
│                                             │
│ [⌨️ Keyboard] [🖱️ Mouse] [📋 Clipboard]    │
└─────────────────────────────────────────────┘
```

### Quality Settings

- **High**: Best clarity (higher bandwidth)
- **Medium**: Balanced (recommended)
- **Low**: Fast response (lower bandwidth)
- **Best Compression**: Lowest bandwidth

### Keyboard Shortcuts

- **Ctrl+Alt+Home**: Release mouse capture
- **Win+R**: Open Run dialog on remote
- **Alt+Tab**: Switch remote windows
- **Ctrl+C/V**: Copy-paste works!

---

## 🔧 Troubleshooting

### Android Issues

**Problem: "Cannot connect to server"**
- ✓ Wait 1-2 minutes after server creation
- ✓ Check if IP address is correct
- ✓ Try with IPv6 if IPv4 doesn't work
- ✓ Ensure both WiFi and server are on same network (or use IPv4)
- ✓ Restart RustDesk app

**Problem: "Connection timeout"**
- ✓ Server firewall may be initializing
- ✓ Try again after 2 minutes
- ✓ Check internet connection
- ✓ Try a different network (WiFi vs mobile data)

**Problem: "Black screen or no input"**
- ✓ Tap the screen to activate
- ✓ Check if remote keyboard is enabled
- ✓ Try "Control" button options

---

### Windows Issues

**Problem: "Connection refused"**
- ✓ Server may still be initializing (wait 2-3 minutes)
- ✓ Double-check IP address
- ✓ Try ping from Command Prompt:
  ```cmd
  ping 165.232.123.45
  ```
- ✓ If ping fails, network is unreachable

**Problem: "Windows Smart Screen blocked"**
- ✓ Click "More info"
- ✓ Click "Run anyway"
- ✓ RustDesk is safe - it's open source

**Problem: "Firewall blocked RustDesk"**
- ✓ Windows Firewall may block connection
- ✓ Open Windows Defender Firewall
- ✓ Click "Allow an app through firewall"
- ✓ Check RustDesk in both Private and Public
- ✓ Click "OK"

**Problem: "Very slow connection"**
- ✓ Reduce quality in settings
- ✓ Check your internet speed (needs 5+ Mbps)
- ✓ Close other apps using network
- ✓ Try lower resolution

---

## 🔐 Advanced Configuration

### Custom RustDesk Port

Default ports are:
- `5900` - Display
- `5901` - Audio/Control  
- `21115-21119` - Services

To change ports (advanced):
1. SSH to server:
   ```bash
   ssh root@165.232.123.45
   ```
2. Edit RustDesk config:
   ```bash
   nano /opt/rustdesk/config.toml
   ```
3. Change port numbers
4. Restart service:
   ```bash
   sudo systemctl restart rustdesk-hbbs
   ```

### View RustDesk Logs

```bash
# SSH to server
ssh root@165.232.123.45

# View signal server logs
journalctl -u rustdesk-hbbs -f

# View relay server logs
journalctl -u rustdesk-hbbr -f
```

### Server Uptime Check

```bash
# SSH to server
ssh root@165.232.123.45

# Check services
sudo systemctl status rustdesk-hbbs
sudo systemctl status rustdesk-hbbr

# Check open ports
sudo netstat -tlnp | grep rustdesk
```

---

## 💰 Cost & Billing

### How Billing Works

- **Hourly Billing**: Server costs money **every hour it runs**
- **No Shutdown Discount**: Even if idle, you pay
- **Auto-charging**: Card charged automatically
- **Minimum $0.0099/hour** (Nano size)

### Example Costs

| Plan | Hourly | Daily | Weekly | Monthly |
|------|--------|-------|--------|----------|
| Nano | $0.006 | $0.14 | $1.00 | $4.00 |
| Small | $0.035 | $0.84 | $5.88 | $26.00 |
| Standard | $0.071 | $1.70 | $11.90 | $52.00 |

### How to Avoid Unexpected Charges

✅ **DO THIS:**
- ✓ Delete server immediately after use
- ✓ Set calendar reminder if using for fixed period
- ✓ Check your servers regularly
- ✓ Enable billing alerts in DigitalOcean

❌ **DON'T DO THIS:**
- ✗ Leave server running indefinitely
- ✗ Create multiple servers and forget them
- ✗ Ignore billing notifications

### Delete Server When Done

**IMPORTANT: DO NOT FORGET THIS STEP!**

1. Go to GitHub Actions
2. Click **"🗑️ Delete DigitalOcean Server"** workflow
3. Enter your server name
4. Select confirm: **"DELETE"** (exact match!)
5. Click **"Run workflow"**
6. Wait for completion
7. ✅ Server is deleted - no more charges!

---

## 📞 Support & Resources

### Official Resources

- **RustDesk Docs**: https://rustdesk.com/docs/
- **DigitalOcean Help**: https://docs.digitalocean.com/
- **GitHub Issues**: Create issue in this repo

### Common Questions

**Q: Why Frankfurt region?**
A: Lowest latency from Iran (~100ms). Other regions work but slower.

**Q: Can I run multiple servers?**
A: Yes! Create another server with different name.

**Q: Can I change server location later?**
A: No. Delete and create new in different region.

**Q: What if my IP changes?**
A: RustDesk reconnects automatically.

**Q: Is my data safe?**
A: RustDesk is open-source and self-hosted. Only you control server.

---

## 🎯 Quick Reference

### Server Creation Workflow
```
GitHub Actions → Run "Create Server" → Configure → Wait 5 min → Get IP
```

### Android Connection
```
Google Play Store → Install RustDesk → Enter IP → Connect → Accept
```

### Windows Connection
```
Download RustDesk → Install → Enter IP → Connect → Accept
```

### Delete Server
```
GitHub Actions → Run "Delete Server" → Confirm → Done
```

---

## 📝 Changelog

### Version 10.0 (Current) - December 2025
- ✨ Added RustDesk Server OSS
- ✨ Added Node.js LTS
- ✨ Added Python 3 support
- ✨ Removed KASM Workspace (too heavy)
- ✨ Enhanced IPv4 + IPv6 support
- ✨ Improved guide generation

---

**Last Updated:** December 13, 2025  
**Version:** 1.0  
**Author:** Mahdi Bagheban (MahdiArts)  
**License:** MIT

---

**Happy Remote Access! 🚀**
