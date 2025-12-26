# 📧 Email Configuration - Quick Reference

## Current Setup

```
Service: Brevo SMTP
Host: smtp-relay.brevo.com:587
From: "SiteLedger" <siteledger@siteledger.ai>
Status: ✅ Active
```

## What Emails Show

All emails from SiteLedger now display:

```
From: SiteLedger <siteledger@siteledger.ai>
```

This includes:
- Worker invitations
- Password resets
- Notifications

## Quick Test

```bash
cd /Users/zia/Desktop/SiteLedger/backend
node test-email-config.js
```

Expected output:
```
📮 From: "SiteLedger" <siteledger@siteledger.ai>
✅ Correctly configured to use siteledger@siteledger.ai
```

## Verify in Brevo

1. Login: https://app.brevo.com/
2. Go to: **Senders & IP** → **Senders**
3. Check: `siteledger@siteledger.ai` shows **Verified ✓**

## If Not Working

1. Check sender is verified in Brevo
2. Restart backend: `pm2 restart siteledger-backend --update-env`
3. Check logs: `pm2 logs siteledger-backend`

---

✅ **All set!** Emails will now send from your professional domain.
