# SSH ACCESS TROUBLESHOOTING GUIDE
## DigitalOcean Server: 68.183.25.130

## Current Status
- ✅ Server is ONLINE (ping responds)
- ✅ Backend API is WORKING (https://api.siteledger.ai/health returns 200)
- ✅ Web app is WORKING (https://siteledger.ai is accessible)
- ❌ SSH port 22 is CLOSED (Connection refused)

## Historical Info
- Server WAS accessible via SSH before (found in ~/.ssh/known_hosts)
- SSH keys: ed25519, RSA, ECDSA present in known_hosts
- This means SSH was working previously at port 22

## Possible Causes
1. **SSH service stopped** - Someone/something stopped sshd
2. **Firewall rule changed** - UFW or iptables blocking port 22
3. **DigitalOcean firewall** - Cloud firewall blocking your IP
4. **SSH config changed** - Moved to different port or disabled

## How to Fix

### Option 1: DigitalOcean Console (RECOMMENDED - No SSH needed)
1. Log into https://cloud.digitalocean.com
2. Go to your droplet (68.183.25.130)
3. Click "Access" → "Launch Droplet Console"
4. This gives you direct console access (bypasses SSH)
5. Once in console, run:
   ```bash
   # Check SSH status
   systemctl status sshd
   
   # If stopped, start it
   systemctl start sshd
   systemctl enable sshd
   
   # Check firewall
   ufw status
   
   # If SSH is blocked, allow it
   ufw allow 22/tcp
   
   # Check if SSH is listening
   netstat -tlnp | grep :22
   ```

### Option 2: DigitalOcean Recovery Console
1. In DigitalOcean dashboard
2. Power → Recovery Console
3. Boot into recovery mode
4. Mount filesystem and check SSH config

### Option 3: DigitalOcean Support
1. Open support ticket
2. They can reset SSH access for you

## Once SSH is Fixed

### Test Connection
```bash
ssh root@68.183.25.130 "echo 'SSH is working!'"
```

### Deploy the Fixes
```bash
cd /Users/zia/Desktop/SiteLedger
./deploy-direct.sh
```

### Or Use GitHub Method
```bash
# The original way (requires GitHub push first)
git push origin main
./deploy-all.sh
```

## Files Ready to Deploy
Once SSH access is restored, these fixed files are ready:

**Backend:**
- `backend/src/services/ai-insights.js` - Fixed OpenRouter API
- `backend/src/services/ocr-service.js` - Fixed OCR.space API  
- `backend/src/routes/ai-insights.js` - Fixed permissions

**Web:**
- `web/app/timesheets/create/page.tsx` - Fixed manual entry
- `web/app/receipts/create/page.tsx` - Fixed OCR integration
- `web/lib/api.ts` - Added OCR method

**Documentation:**
- `CRITICAL_FIXES_DEC25.md` - Fix tracking
- `FIXES_PROGRESS_DEC25_2025.md` - Detailed report
- `test-deployment.sh` - Testing script

## Temporary Workaround
Since the backend is currently running and accessible:
- Current production site has the OLD code
- New fixes are committed to GitHub
- Can't deploy until SSH is fixed
- Users will have to wait for:
  - Manual timesheet entry fix
  - AI insights generation fix
  - Receipt OCR fix

## Alternative: Manual File Update (if desperate)
If you have database access or can use DigitalOcean Spaces:
1. Access server files via DigitalOcean's file browser (if available)
2. Manually copy-paste file contents
3. Restart PM2 processes via DigitalOcean console

---

**BOTTOM LINE:** You need to use DigitalOcean's web console to access the server and restart SSH. Then you can deploy normally.
