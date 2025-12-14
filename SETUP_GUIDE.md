# 🚀 Digital Ocean RustDesk Server - Complete Setup Guide v12.0

**بسم الله الرحمن الرحیم - یا علی!** 🌟

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [SSH Key Setup](#ssh-key-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Create Server Workflow](#create-server-workflow)
5. [Delete Server Workflow](#delete-server-workflow)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### ✅ Required Accounts
- **GitHub Account** - For repository and Actions
- **DigitalOcean Account** - For server hosting
- **SSH Key Pair** - For secure authentication

### ✅ System Requirements
- SSH client (built-in on macOS/Linux)
- Windows users: Use Git Bash or WSL
- Internet connection

---

## SSH Key Setup

### Step 1: Generate SSH Key Pair (If You Don't Have One)

**On your local machine:**

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "MahdiArts" -f ~/.ssh/id_rsa

# When prompted for passphrase, press Enter (or add passphrase for extra security)
# Don't set a passphrase for GitHub Actions usage
```

**Output:** Two files will be created:
- `~/.ssh/id_rsa` - **Private Key** (keep secret!)
- `~/.ssh/id_rsa.pub` - **Public Key** (share with DigitalOcean)

### Step 2: Add Public Key to DigitalOcean

1. **Get your public key:**
```bash
cat ~/.ssh/id_rsa.pub
```

2. **Add to DigitalOcean:**
   - Go to [DigitalOcean Account Settings](https://cloud.digitalocean.com/account/security)
   - Click "SSH Keys"
   - Click "Add SSH Key"
   - Paste the public key
   - **Name it exactly: `MahdiArts`** (case-sensitive)
   - Click "Add SSH Key"

### Step 3: Verify Key in DigitalOcean

1. Go to [DigitalOcean SSH Keys](https://cloud.digitalocean.com/account/security)
2. You should see "MahdiArts" in the list
3. Copy the fingerprint (will look like: `b7:0b:a9:32:b6:b6:1a:8e:71:1e`)

---

## GitHub Secrets Configuration

### Step 1: Create GitHub Secrets

Go to your GitHub repository → Settings → Secrets and Variables → Actions

### Step 2: Add SSH Private Key Secret

**Name:** `SSH_PRIVATE_KEY`

**Value:** Get your private key:
```bash
cat ~/.ssh/id_rsa
```

**Copy the ENTIRE output** (including the lines):
```
-----BEGIN OPENSSH PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQD...
...
-----END OPENSSH PRIVATE KEY-----
```

✅ **Paste this exact content into the GitHub secret**

### Step 3: Add DigitalOcean API Token Secret

**Name:** `DO_API_TOKEN`

**Value:** 
1. Go to [DigitalOcean API Tokens](https://cloud.digitalocean.com/account/api/tokens)
2. Click "Generate New Token"
3. Name it: `GitHub-Actions`
4. Give it **Read & Write** permissions
5. Copy the token
6. Paste into GitHub secret

✅ **Keep this token secret!**

### Step 4: Verify Secrets

Your GitHub Actions secrets should now have:
```
✅ SSH_PRIVATE_KEY - Your SSH private key
✅ DO_API_TOKEN    - Your DigitalOcean API token
```

---

## Create Server Workflow

### How to Use

1. **Go to GitHub Actions**
   - Navigate to your repository
   - Click "Actions" tab
   - Select "🚀 Create DigitalOcean Server with RustDesk"

2. **Click "Run workflow"**
   - Fill in the parameters:
     - **Server Name**: Any name (e.g., "rustdesk-1", "testserver")
     - **Region**: Frankfurt recommended for Iran
     - **Server Plan**: Small ($26/mo) recommended for production

3. **Click "Run workflow"**

### What Happens

The workflow will:
1. ✅ Validate SSH keys
2. ✅ Create a new Droplet in DigitalOcean
3. ✅ Wait for server activation
4. ✅ Configure SSH access
5. ✅ Install Docker, Node.js, Python
6. ✅ Install RustDesk Server OSS
7. ✅ Configure UFW Firewall
8. ✅ Generate connection guides
9. ✅ Create GitHub Release with QR codes

### Expected Duration
- **Nano** (s-1vcpu-512mb): ~30-35 minutes
- **Small** (s-2vcpu-4gb): ~25-30 minutes
- **Standard** (s-4vcpu-8gb): ~20-25 minutes
- **High Memory** (m-2vcpu-16gb): ~20-25 minutes
- **XL** (m-8vcpu-64gb): ~20-25 minutes

### After Workflow Completes

1. **Check GitHub Release**
   - Click "Releases" on repository
   - Download:
     - `rustdesk-connection-guide.md` - Full instructions
     - `rustdesk-qr-ipv4.png` - QR code for mobile

2. **Connect via RustDesk**
   - Download RustDesk from [rustdesk.com](https://rustdesk.com)
   - Enter server IP from workflow output
   - Click Connect

3. **SSH Access**
   ```bash
   ssh root@<server_ip>
   ```

---

## Delete Server Workflow

### ⚠️ Important: Always Delete When Done!

Servers cost money while running. Delete when not in use.

### How to Delete

1. **Go to GitHub Actions**
   - Select "🗑️ Delete DigitalOcean Server"
   - Click "Run workflow"

2. **Fill in parameters**
   - **Server Name to Delete**: Exact name used during creation
   - **Confirm**: Select "DELETE" from dropdown

3. **Click "Run workflow"**

### Workflow Will
1. ✅ Find server by name
2. ✅ Request confirmation
3. ✅ Delete Droplet
4. ✅ Wait for deletion confirmation
5. ✅ Generate summary

### Deletion Time
- Usually completes in **30-45 seconds**
- Charges stop immediately

---

## Workflow Features

### 🔐 Security
- ✅ SSH key authentication (no passwords)
- ✅ Private key stored in GitHub Secrets
- ✅ Firewall automatically configured
- ✅ Double confirmation for deletion

### 🔄 Reliability
- ✅ Retry logic for API calls
- ✅ Health checks before operations
- ✅ Clear error messages
- ✅ Fallback mechanisms

### 📊 Monitoring
- ✅ Step-by-step logging
- ✅ Real-time progress updates
- ✅ Detailed error reporting
- ✅ GitHub Release with documentation

### 💾 Setup Includes
- ✅ Ubuntu 24.04 LTS
- ✅ Docker & Docker Compose
- ✅ RustDesk Server OSS
- ✅ Node.js LTS
- ✅ Python 3 with pip
- ✅ UFW Firewall
- ✅ Development tools

---

## Troubleshooting

### SSH Connection Fails

**Problem:** `ssh: connect to host X.X.X.X port 22: Connection refused`

**Solution:**
```bash
# 1. Wait 2-3 minutes after server creation
# 2. Verify SSH port is open
telnet <server_ip> 22

# 3. Check SSH key is correct
ssh -i ~/.ssh/id_rsa root@<server_ip> echo "test"

# 4. Check firewall
sudo ufw status
```

### RustDesk Connection Issues

**Problem:** Cannot connect to RustDesk

**Solution:**
```bash
# 1. Wait 1-2 minutes after server creation
# 2. Check if RustDesk is running
ssh root@<server_ip> systemctl status rustdesk-hbbs

# 3. Check ports are open
ssh root@<server_ip> sudo ufw status

# 4. Verify services started
ssh root@<server_ip> ps aux | grep rust
```

### Workflow Fails with SSH Error

**Problem:** `ssh_key_setup failed`

**Checks:**
1. ✅ SSH_PRIVATE_KEY secret is set
2. ✅ Key contains full private key (-----BEGIN...-----END-----)
3. ✅ No extra whitespace or line breaks
4. ✅ Key format is correct (ed25519 or rsa)

**Fix:**
```bash
# Re-add the secret:
cat ~/.ssh/id_rsa
# Copy entire output to GitHub Secret
```

### DigitalOcean API Errors

**Problem:** `401 Unauthorized` or `403 Forbidden`

**Solution:**
1. Check DO_API_TOKEN is correct
2. Verify token has Read & Write permissions
3. Check token hasn't expired (tokens expire after 30 days)
4. Generate a new token if needed

### Public Key Not Found

**Problem:** `Error: SSH Key 'MahdiArts' not found`

**Solution:**
1. Go to DigitalOcean Settings → SSH Keys
2. Verify "MahdiArts" key exists
3. If not, add your public key:
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```
4. Create new SSH key in DigitalOcean with name "MahdiArts"

---

## Common Commands

### SSH into Server
```bash
ssh root@<server_ip>
```

### Check RustDesk Status
```bash
ssh root@<server_ip> systemctl status rustdesk-hbbs
```

### View Firewall Rules
```bash
ssh root@<server_ip> sudo ufw status verbose
```

### Check Disk Usage
```bash
ssh root@<server_ip> df -h
```

### Check Memory
```bash
ssh root@<server_ip> free -h
```

### View RustDesk Logs
```bash
ssh root@<server_ip> journalctl -u rustdesk-hbbs -f
```

---

## Performance Benchmarks

### Server Creation Times (Frankfurt)
| Plan | Install Time | Total Time |
|------|--------------|------------|
| Nano | 30-35 min | 35-40 min |
| Small | 25-30 min | 30-35 min |
| Standard | 20-25 min | 25-30 min |
| High Memory | 20-25 min | 25-30 min |
| XL | 20-25 min | 25-30 min |

### Cost Breakdown (Monthly)
| Plan | vCPU | RAM | Storage | Cost |
|------|------|-----|---------|------|
| Nano | 1 | 0.5GB | 10GB | $4 |
| Small | 2 | 4GB | 80GB | $26 |
| Standard | 4 | 8GB | 160GB | $52 |
| High Memory | 2 | 16GB | 320GB | $98 |
| XL | 8 | 64GB | 1.6TB | $435 |

---

## Best Practices

### Security
- ✅ Never share SSH private key
- ✅ Keep API tokens secret
- ✅ Use strong passphrases for keys
- ✅ Rotate API tokens regularly
- ✅ Use firewall rules appropriately

### Cost Management
- ✅ Always delete servers when not in use
- ✅ Use appropriate plan size
- ✅ Monitor server usage
- ✅ Set up billing alerts

### Maintenance
- ✅ Keep systems updated
- ✅ Monitor RustDesk logs
- ✅ Check firewall rules
- ✅ Regular backups if needed

---

## Support & Help

### Resources
- 📚 [DigitalOcean Documentation](https://docs.digitalocean.com/)
- 🦀 [RustDesk Documentation](https://rustdesk.com/docs/)
- 🐙 [GitHub Actions Documentation](https://docs.github.com/en/actions)
- 🔐 [SSH Key Setup Guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)

### Issues
If you encounter issues:
1. Check the troubleshooting section
2. Review GitHub Actions logs
3. Verify all secrets are configured
4. Check DigitalOcean dashboard

---

## Changelog

### v12.0 (Current)
- ✅ SSH Private Key in secrets
- ✅ Direct public key name reference
- ✅ Improved error messages
- ✅ Better documentation
- ✅ 60-second health check timeout
- ✅ accept-new SSH behavior

### v11.0
- ✅ Critical fixes for SSH handling
- ✅ RustDesk retry logic
- ✅ Semantic versioning for releases

### v10.0+
- ✅ RustDesk Server OSS integration
- ✅ Docker & development tools
- ✅ Firewall configuration
- ✅ QR code generation

---

## Testing

### Before Production

1. **Test with Nano plan**
   - Create server with Nano ($4/mo)
   - Verify all components work
   - Test SSH connection
   - Delete server

2. **Test with Small plan**
   - Create server with Small ($26/mo)
   - Test production workload
   - Monitor performance
   - Delete when done

3. **Test in different region**
   - Try Amsterdam, London, etc.
   - Verify latency is acceptable
   - Check performance metrics

---

## License

MIT License - Feel free to use and modify

---

**بسم الله الرحمن الرحیم - یا علی!** 🌟

**Happy deploying!** 🚀

*Last Updated: December 14, 2025*
*Version: 12.0*
