# 🚀 Deploy Fixes to siteledger.ai

## Quick Deploy

```bash
cd /Users/zia/Desktop/SiteLedger/web
./deploy-fixes.sh
```

This will:
1. ✅ Build the production bundle
2. ✅ Create deployment package
3. ✅ Upload to siteledger.ai (68.183.25.130)
4. ✅ Backup existing files
5. ✅ Deploy and restart PM2
6. ✅ Your fixes go live!

---

## What Gets Fixed

### ✅ Theme & Colors
- No more white flash on refresh
- Proper accent colors (Blue: #007AFF, Orange: #FF8C42)
- Dark mode works perfectly

### ✅ Navigation
- Back buttons work everywhere
- Consistent hover states

### ✅ Workers
- ✅ Add workers works
- ✅ Email invitations sent
- ✅ Password auto-generated

### ✅ Jobs
- ✅ Edit jobs works
- ✅ Amount Paid saves correctly

### ✅ Receipts
- ✅ AI image processing
- ✅ File upload works
- ✅ Data persists

---

## After Deployment - TEST THESE

Visit **https://siteledger.ai** and verify:

1. **Theme Test**
   - Refresh page multiple times
   - ✅ No white flash
   - ✅ Text is readable (not white on white)

2. **Workers Test**
   - Go to Workers → Add Worker
   - Fill in: Name, Email, Hourly Rate
   - Submit
   - ✅ Check worker's email for invitation

3. **Jobs Test**
   - Edit any job
   - Change "Amount Paid"
   - Save
   - ✅ Verify it persists after refresh

4. **Receipts Test**
   - Add Receipt → Upload image
   - ✅ AI should extract vendor/amount
   - Save receipt
   - ✅ Should appear in receipts list

5. **Dark Mode Test**
   - Toggle dark/light mode
   - ✅ All text should be visible
   - ✅ Colors should look good

---

## Troubleshooting

### If deployment fails:

```bash
# Check PM2 status
ssh root@68.183.25.130 'pm2 status'

# View logs
ssh root@68.183.25.130 'pm2 logs siteledger-web --lines 100'

# Restart manually
ssh root@68.183.25.130 'pm2 restart siteledger-web'
```

### If site is broken after deploy:

```bash
# Restore backup
ssh root@68.183.25.130
cd /var/www/siteledger.ai
ls -lt backup_*.tar.gz | head -1  # Find latest backup
tar -xzf backup_YYYYMMDD_HHMMSS.tar.gz
pm2 restart siteledger-web
```

### Check backend is running:

```bash
ssh root@68.183.25.130 'pm2 list | grep backend'
```

Backend should be running on port 3000
Frontend (web) runs on port 3001

---

## Server Info

- **Domain**: siteledger.ai
- **IP**: 68.183.25.130
- **Web Directory**: `/var/www/siteledger.ai`
- **Web Port**: 3001
- **Backend Port**: 3000
- **PM2 Process**: `siteledger-web`

---

## Alternative: Manual Deploy

If script doesn't work:

```bash
# 1. Build locally
npm run build

# 2. Create package
tar -czf fixes.tar.gz .next public package.json next.config.ts tailwind.config.ts

# 3. Upload
scp fixes.tar.gz root@68.183.25.130:/tmp/

# 4. Deploy on server
ssh root@68.183.25.130
cd /var/www/siteledger.ai
tar -xzf /tmp/fixes.tar.gz
npm ci --production
pm2 restart siteledger-web
```

---

## Need Help?

1. Check logs: `ssh root@68.183.25.130 'pm2 logs siteledger-web'`
2. Check status: `ssh root@68.183.25.130 'pm2 status'`
3. Test backend: `curl https://api.siteledger.ai/health`
4. Test frontend: `curl https://siteledger.ai`

---

**Ready to deploy?**

```bash
./deploy-fixes.sh
```

🎉 Your fixes will be live in ~2 minutes!
