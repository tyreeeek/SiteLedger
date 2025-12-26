# 📧 Email Setup Guide - Production Ready

## 🌊 DigitalOcean Managed Email (Recommended for DO Hosting)

### Benefits:
- ✅ Integrated with your DO account
- ✅ No external service needed
- ✅ Reliable delivery
- ✅ Simple setup
- ✅ Scales with your infrastructure

### Setup:
1. Go to https://cloud.digitalocean.com/account/api/tokens
2. Create a new Personal Access Token with "Email" scope
3. Or use DigitalOcean's SMTP service

### Option A: DigitalOcean Email API (Simplest)
```bash
# Install DO SDK
npm install @digitalocean/sdk

# Update .env:
DO_EMAIL_API_KEY=your-do-api-token
SMTP_FROM="SiteLedger" <noreply@yourdomain.com>
```

### Option B: DigitalOcean Managed Email with SMTP
1. Go to DigitalOcean Dashboard → Email
2. Create a new email domain
3. Verify domain with DNS records
4. Get SMTP credentials
5. Update .env:
```bash
SMTP_HOST=smtp.digitalocean.com
SMTP_PORT=587
SMTP_USER=your-do-email-user
SMTP_PASS=your-do-email-password
SMTP_FROM="SiteLedger" <noreply@yourdomain.com>
```

---

## Gmail SMTP Setup (Quick & Easy for Testing)

### Step 1: Enable 2-Factor Authentication
1. Go to https://myaccount.google.com/security
2. Enable 2-Step Verification if not already enabled

### Step 2: Generate App Password
1. Go to https://myaccount.google.com/apppasswords
2. Select app: "Mail"
3. Select device: "Other (Custom name)" → Enter "SiteLedger"
4. Click "Generate"
5. Copy the 16-character password (no spaces)

### Step 3: Update .env File
```bash
SMTP_USER=azgharjawazkhan@gmail.com
SMTP_PASS=xxxx xxxx xxxx xxxx  # Your 16-character app password (remove spaces)
```

### Step 4: Test
Restart the server and invite a worker - the email will be sent to their email address!

---

## 📮 Mailgun (Best Free Alternative - Recommended!)

### Benefits:
- ✅ **5,000 emails/month FREE** (vs Gmail's 500/day limit)
- ✅ Perfect for DigitalOcean deployments
- ✅ Easy integration
- ✅ Excellent deliverability
- ✅ Email analytics included

### Setup (5 minutes):
1. Go to https://signup.mailgun.com/new/signup
2. Sign up (credit card required but won't be charged)
3. Verify your email
4. Go to Dashboard → Sending → Domains → Add New Domain
5. Use your domain or sandbox domain for testing
6. Get SMTP credentials from "Domain Settings"

### Update .env:
```bash
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@sandboxXXXXXXXX.mailgun.org  # From Mailgun dashboard
SMTP_PASS=your-mailgun-smtp-password
SMTP_FROM="SiteLedger" <noreply@sandboxXXXXXXXX.mailgun.org>
```

### Why Mailgun?
- Free tier: 5,000 emails/month
- No daily limits (unlike Gmail's 500/day)
- Better deliverability than Gmail
- Easy DNS setup
- Great for production

---

## Alternative: SendGrid (Recommended for Large Production)

### Benefits:
- Higher sending limits (100 emails/day free, scalable)
- Better deliverability
- Email analytics
- No Gmail account needed

### Setup:
1. Sign up at https://sendgrid.com
2. Create API key in Settings → API Keys
3. Update .env:
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
SMTP_FROM="SiteLedger" <noreply@yourdomain.com>
```

---

## Alternative: AWS SES (Recommended for Enterprise)

### Benefits:
- Very low cost ($0.10 per 1000 emails)
- High deliverability
- Scales infinitely
- Part of AWS ecosystem

### Setup:
1. Go to AWS SES Console
2. Verify your domain or email
3. Create SMTP credentials
4. Update .env:
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USER=your-ses-access-key
SMTP_PASS=your-ses-secret-key
SMTP_FROM="SiteLedger" <noreply@yourdomain.com>
```

---

## Testing

### Development Mode (No SMTP configured):
- Emails logged to console
- Credentials returned in API response
- Perfect for testing

### Production Mode (SMTP configured):
- Real emails sent
- Check spam folder first time
- Monitor server.log for errors

### Test Command:
```bash
# Watch server logs
cd backend
tail -f server.log | grep "EMAIL\|✅"
```

---

## Email Sending Limits

| Provider | Free Tier | Best For | Setup Time |
|----------|-----------|----------|------------|
| **Mailgun** ⭐ | 5,000/month | Production | 5 min |
| Gmail | 500/day (15k/month) | Quick testing | 2 min |
| SendGrid | 100/day | Scale | 10 min |
| AWS SES | 62,000/month | Enterprise | 30 min |
| DigitalOcean | Varies | DO infrastructure | 15 min |

**Recommendation:** Start with **Mailgun** (free, reliable, perfect for DO)

---

## Troubleshooting

### "Authentication failed"
- Check app password (not regular password)
- Remove spaces from app password
- Verify 2FA is enabled

### "Connection refused"
- Check port (587 for TLS, 465 for SSL)
- Verify firewall not blocking SMTP

### Emails going to spam
- Use proper "From" address
- Add SPF/DKIM records to domain
- Consider using SendGrid/SES

### "Rate limit exceeded"
- Gmail: 500/day max
- Wait 24 hours or upgrade to SendGrid/SES

---

## Security Best Practices

✅ Never commit SMTP credentials to git
✅ Use app passwords, not account passwords
✅ Rotate credentials regularly
✅ Monitor failed login attempts
✅ Use environment variables
✅ Enable 2FA on email accounts

---

## Next Steps

1. Generate Gmail App Password (5 minutes)
2. Update `.env` with credentials
3. Restart server: `npm run dev` or `node src/index.js`
4. Test by inviting a worker
5. Check your email inbox!

**Current Status:** Development mode (emails logged to console)
**After Setup:** Production mode (real emails sent)
