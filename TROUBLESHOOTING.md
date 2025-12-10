# 🚿 Troubleshooting Guide - Digital Ocean KASM Server

## 👋 Quick Reference

If your workflow is failing, follow this quick checklist:

### ❌ **Workflow Failed Immediately**
1. ✅ Check **DO_API_TOKEN** is set in Secrets
2. ✅ Check **SSH_KEY_NAME** is set in Secrets  
3. ✅ Verify SSH key exists in DigitalOcean
4. ✅ Check API token has correct permissions

### ❌ **Workflow Hung/Timed Out**
1. ✅ Check if Droplet was created (DigitalOcean Console)
2. ✅ If exists, check server logs: `ssh root@IP tail -f /var/log/kasm-install.log`
3. ✅ If not created, delete manually and retry

### ❌ **Server Created But Software Won't Install**
1. ✅ SSH to server
2. ✅ Check logs: `tail -f /var/log/kasm-install.log`
3. ✅ Check Docker: `docker --version`
4. ✅ Check disk space: `df -h`

---

## 🔐 Secret Configuration Issues

### Problem: `DO_API_TOKEN is not set`

**Cause:** Secret not configured in GitHub repository

**Solution:**
```
1. Go to: https://github.com/Mahdi-Bagheban/Digital-Ocean
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: DO_API_TOKEN
5. Value: Your DigitalOcean API token
   (Get from: https://cloud.digitalocean.com/account/api/tokens)
6. Click "Add secret"
```

**Verify:**
```bash
# List your DigitalOcean API tokens
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.digitalocean.com/v2/account/keys"
```

---

### Problem: `SSH_KEY_NAME is not set` OR `SSH key not found`

**Cause:** SSH key secret not configured or name doesn't match

**Solution:**
```
1. Go to: https://cloud.digitalocean.com/account/security/keys
2. Note the exact SSH key name (case-sensitive!)
3. Go to: Settings → Secrets and variables → Actions
4. Click "New repository secret"
5. Name: SSH_KEY_NAME
6. Value: <Exact SSH key name from DigitalOcean>
7. Click "Add secret"
```

**Example:**
If your SSH key in DigitalOcean is named `MahdiArts`:
```yaml
SSH_KEY_NAME=MahdiArts  # Case-sensitive!
```

**List your SSH keys:**
```bash
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.digitalocean.com/v2/account/keys" | jq '.ssh_keys[] | "\(.name) (ID: \(.id))"'
```

---

## 🛰 API Token Permission Issues

### Problem: `Unauthorized` or `Permission denied`

**Cause:** API token lacks required scopes

**Solution:**
Your token needs these permissions:
- ✅ `create_droplets` - Create servers
- ✅ `read_account` - Read account info
- ✅ `read_ssh_keys` - Read SSH keys
- ✅ `read_droplets` - Check server status
- ✅ `write_droplets` - Delete servers

**How to check token permissions:**
1. Go to: https://cloud.digitalocean.com/account/api/tokens
2. Click on your token
3. Scroll to "Scopes" section
4. Verify all required permissions are checked
5. If not, recreate token with full permissions

---

### Problem: `Invalid API token`

**Cause:** Token is malformed, expired, or revoked

**Solution:**
1. Go to: https://cloud.digitalocean.com/account/api/tokens
2. Look for your token
3. If not visible:
   - Token may have been revoked
   - Click "Generate New Token"
   - Name it: `github-actions`
   - Enable all scopes
   - Copy the NEW token
4. Update secret: Settings → Secrets → DO_API_TOKEN
5. Paste the new token
6. Try workflow again

---

## ⚠️ Droplet Creation Issues

### Problem: `Droplet creation failed`

**Possible Causes:**

#### 1. Insufficient Account Quota
```
❌ Error: "You have reached your quota for droplets"
```
**Solution:**
- Delete unused droplets
- Or request quota increase from DigitalOcean
- Go to: https://cloud.digitalocean.com/account/team/limits

#### 2. Invalid Region
```
❌ Error: "The region 'xyz' is invalid"
```
**Solution:**
Valid regions are:
- `fra1` - Frankfurt
- `ams3` - Amsterdam
- `lon1` - London
- `nyc1` - New York

When running workflow, select from dropdown or check REGION variable

#### 3. Billing Issue
```
❌ Error: "Billing problem" or "Account suspended"
```
**Solution:**
- Go to: https://cloud.digitalocean.com/account/billing/overview
- Check balance and payment method
- Update payment if needed

---

## ⏱️ Workflow Timeout Issues

### Problem: `Workflow timed out after 30 minutes`

**Cause:** Droplet took too long to become active or installation failed

**Solution:**

1. **Check if Droplet exists:**
   ```bash
   # SSH to server and check logs
   ssh root@SERVER_IP tail -f /var/log/kasm-install.log
   
   # If this works, installation is ongoing
   # Wait 5-15 more minutes
   ```

2. **If Droplet doesn't exist:**
   ```bash
   # Check DigitalOcean Console
   # Or use API:
   curl -X GET \
     -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.digitalocean.com/v2/droplets?tag_name=mahdiarts" |\
     jq '.droplets[] | "\(.id) - \(.name) - \(.status)"'
   ```

3. **If Droplet is stuck:**
   ```bash
   # Delete it manually
   ./delete-server.sh
   
   # Or via API:
   DROPLET_ID=123456
   curl -X DELETE \
     -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.digitalocean.com/v2/droplets/$DROPLET_ID"
   ```

4. **Retry workflow:**
   - Check logs for actual error
   - Fix the issue
   - Run workflow again

---

## 💻 Server Connection Issues

### Problem: `Connection refused` or `SSH timeout`

**Cause:** Server not ready or firewall blocking

**Solution:**

1. **Wait for server to boot:**
   ```bash
   # Initial boot takes 30-60 seconds
   sleep 60
   ssh root@SERVER_IP
   ```

2. **Check server status:**
   ```bash
   # From DigitalOcean console
   # Or via API:
   curl -X GET \
     -H "Authorization: Bearer YOUR_TOKEN" \
     "https://api.digitalocean.com/v2/droplets/DROPLET_ID" |\
     jq '.droplet | "Status: \(.status), IP: \(.networks.v4[0].ip_address)"'
   ```

3. **Check SSH key permissions (local):**
   ```bash
   # Your SSH key should be readable only by you
   chmod 600 ~/.ssh/id_rsa
   
   # Try connecting with explicit key
   ssh -i ~/.ssh/id_rsa -v root@SERVER_IP
   ```

4. **Check firewall (DigitalOcean):**
   - Go to: https://cloud.digitalocean.com/networking/firewalls
   - Check if port 22 (SSH) is open
   - Create firewall rule if needed

---

## 📚 Installation Verification

### Problem: `KASM not accessible at https://IP:443`

**Cause:** Installation still in progress or failed

**Solution:**

1. **Check installation status:**
   ```bash
   ssh root@SERVER_IP
   tail -f /var/log/kasm-install.log
   ```

2. **Wait for completion:**
   ```
   Expected time: 5-15 minutes
   Watch for: "=== نصب موفق ==="
   ```

3. **If Docker failed:**
   ```bash
   ssh root@SERVER_IP
   docker --version
   
   # If command not found, reinstall:
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo bash get-docker.sh
   ```

4. **If KASM failed:**
   ```bash
   ssh root@SERVER_IP
   
   # Check Docker containers
   docker ps -a
   
   # Check KASM service
   systemctl status kasm-core || true
   
   # View full installation log
   cat /var/log/kasm-install.log | tail -100
   ```

---

## 💥 Common Error Messages

### `"No such file or directory: .env"`

**Cause:** Environment file not created

**Solution:**
```bash
cp .env.example .env
# Edit .env with your values
vim .env
```

### `"jq: command not found"`

**Cause:** `jq` not installed

**Solution:**
```bash
# On Ubuntu/Debian
sudo apt-get install jq

# On macOS
brew install jq

# On Windows (WSL)
sudo apt-get install jq
```

### `"SSH key 'xyz' not found"`

**Cause:** Key name doesn't match DigitalOcean

**Solution:**
```bash
# Get exact key name
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.digitalocean.com/v2/account/keys" |\
  jq '.ssh_keys[] | .name'

# Update SSH_KEY_NAME secret with exact name
```

### `"Droplet already exists"`

**Cause:** Previous Droplet not deleted

**Solution:**
```bash
# Delete existing Droplet
./delete-server.sh

# Or manually via DigitalOcean console
# Or via API:
DROPLET_ID=123456
curl -X DELETE \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID"
```

---

## 📄 Checking Logs

### GitHub Actions Workflow Logs

```
1. Go to: https://github.com/Mahdi-Bagheban/Digital-Ocean
2. Click "Actions" tab
3. Select the failed workflow run
4. Click "create-server" job
5. Expand the failed step
6. Read the error message
```

### Server Installation Logs

```bash
# SSH to server
ssh root@SERVER_IP

# Watch installation in real-time
tail -f /var/log/kasm-install.log

# View entire log
cat /var/log/kasm-install.log

# Check for errors
grep -i error /var/log/kasm-install.log
```

### DigitalOcean API Logs

```bash
# Check Droplet creation events
DROPLET_ID=123456
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.digitalocean.com/v2/droplets/$DROPLET_ID/droplet_snapshots"

# Check account events
curl -X GET \
  -H "Authorization: Bearer YOUR_TOKEN" \
  "https://api.digitalocean.com/v2/account/events?per_page=20" |\
  jq '.events[] | "\(.id) - \(.type) - \(.status)"'
```

---

## 🔙 Recovery Steps

### If Everything Failed

**Step 1: Clean up**
```bash
# Delete any leftover Droplets
./delete-server.sh

# Or manually from DigitalOcean console
```

**Step 2: Verify secrets**
```
Settings → Secrets and variables → Actions
- Confirm DO_API_TOKEN is set
- Confirm SSH_KEY_NAME is set
```

**Step 3: Test API token locally**
```bash
# Export your token
export DO_API_TOKEN="your_token_here"

# Test connectivity
curl -X GET \
  -H "Authorization: Bearer $DO_API_TOKEN" \
  "https://api.digitalocean.com/v2/account"

# Should return your account info
```

**Step 4: Run script locally (optional)**
```bash
# If you want to test before GitHub Actions
cp .env.example .env
# Edit .env with your values
vim .env

# Run local script
./create-server.sh
```

**Step 5: Retry in GitHub Actions**
```
1. Go to Actions tab
2. Select "Create Development Server with KASM"
3. Click "Run workflow"
4. Enter parameters if needed
5. Click "Run workflow" button
```

---

## 📕 Getting Help

If you still can't resolve the issue:

1. **Check the logs** (most important!)
2. **Look up the error message** in this guide
3. **Check DigitalOcean console** for Droplet status
4. **Check GitHub Actions** for workflow logs
5. **Contact DigitalOcean support** if API issue
6. **Contact GitHub support** if workflow issue

---

## 👻 FAQ

**Q: How long does server creation take?**
A: Usually 8-15 minutes including software installation

**Q: Can I use a different Droplet size?**
A: Yes, edit SIZE in `.env` or `create-server.sh`

**Q: How much does it cost?**
A: $250/month ($0.347/hour) for 32GB memory-optimized

**Q: Can I create multiple servers?**
A: Yes, but each needs a unique name (DROPLET_NAME)

**Q: Will my data persist?**
A: Only while Droplet exists. Delete script removes everything.

**Q: Can I add more software after creation?**
A: Yes, SSH to server and install via apt/npm/pip

---

**Last Updated:** December 10, 2025  
**Status:** All Issues Fixed ✅
