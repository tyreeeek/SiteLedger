# ☁️ Cloudflare Email Routing Setup Guide

## Current Situation
- Domain: siteledger.ai
- Current DNS: DigitalOcean
- Goal: Set up support@siteledger.ai email forwarding

## Prerequisites
- Cloudflare account (free): https://dash.cloudflare.com/sign-up
- Access to DigitalOcean account

---

## Step 1: Move DNS to Cloudflare (One-time setup)

### 1.1 Add Domain to Cloudflare
1. Login to Cloudflare: https://dash.cloudflare.com/
2. Click **Add a Site**
3. Enter: `siteledger.ai`
4. Select **Free plan**
5. Click **Continue**

### 1.2 Import DNS Records
Cloudflare will scan your current DNS records and import them automatically.

**Verify these records are present:**
```
Type: A
Name: @ (or siteledger.ai)
Value: 68.183.25.130
Proxied: Yes (orange cloud)

Type: A
Name: api
Value: 68.183.25.130
Proxied: No (gray cloud) ⚠️ Important: API must be DNS-only

Type: CNAME
Name: www
Value: siteledger.ai
Proxied: Yes
```

### 1.3 Update Nameservers at DigitalOcean
1. Go to DigitalOcean Dashboard: https://cloud.digitalocean.com/networking/domains
2. Click on `siteledger.ai`
3. Go to **Settings** → **Edit Nameservers**
4. Replace with Cloudflare nameservers (Cloudflare will show you these):
   ```
   Example (yours will be different):
   alice.ns.cloudflare.com
   bob.ns.cloudflare.com
   ```
5. Save changes

**⏱️ Wait 5-30 minutes for DNS propagation**

### 1.4 Verify DNS is Active
```bash
dig NS siteledger.ai +short
```
Should show Cloudflare nameservers (ends with `.cloudflare.com`)

---

## Step 2: Enable Email Routing in Cloudflare

### 2.1 Navigate to Email Routing
1. In Cloudflare dashboard, select `siteledger.ai`
2. Go to **Email** → **Email Routing** (in left sidebar)
3. Click **Get started** or **Enable Email Routing**

### 2.2 Add Destination Email
1. Click **Destination addresses**
2. Click **Add destination address**
3. Enter your personal email (e.g., `your-email@gmail.com`)
4. Check your email for verification code
5. Enter code to verify

### 2.3 Create Routing Rule
1. Go to **Routing rules** tab
2. Click **Create address** or **Create rule**
3. Configure:
   ```
   Custom address: support
   Action: Send to an email
   Destination: your-email@gmail.com (select from dropdown)
   ```
4. Click **Save**

### 2.4 Enable Email Routing
1. Toggle the switch to **Enabled** (top of page)
2. Cloudflare will automatically add MX records

**MX Records added (automatic):**
```
Type: MX
Name: siteledger.ai
Priority: 1
Value: route1.mx.cloudflare.net

Type: MX
Name: siteledger.ai
Priority: 2
Value: route2.mx.cloudflare.net

Type: MX
Name: siteledger.ai
Priority: 3
Value: route3.mx.cloudflare.net

Type: TXT
Name: siteledger.ai
Value: v=spf1 include:_spf.mx.cloudflare.net ~all
```

---

## Step 3: Test Email Forwarding

### 3.1 Wait for DNS Propagation
Wait 5-10 minutes after enabling, then check:
```bash
dig MX siteledger.ai +short
```

Should show:
```
1 route1.mx.cloudflare.net.
2 route2.mx.cloudflare.net.
3 route3.mx.cloudflare.net.
```

### 3.2 Send Test Email
1. Use your personal email or another email service
2. Send email to: `support@siteledger.ai`
3. Check your destination email inbox
4. Should arrive within 1-2 minutes

### 3.3 Verify in Cloudflare
1. Go to **Email** → **Email Routing** → **Activity**
2. Should see the test email in the log

---

## Step 4: Configure Reply-As (Optional but Recommended)

This lets you reply AS support@siteledger.ai instead of your personal email.

### Gmail:
1. Go to Gmail Settings → **Accounts and Import**
2. Click **Add another email address** (in "Send mail as" section)
3. Enter:
   - Name: `SiteLedger Support`
   - Email: `support@siteledger.ai`
4. Choose **Send through Gmail** (easier)
5. Gmail will send verification email to support@siteledger.ai
6. Check your inbox (forwarded from Cloudflare)
7. Click verification link
8. Now you can reply as support@siteledger.ai!

---

## Troubleshooting

### Email not being received?
1. Check MX records: `dig MX siteledger.ai +short`
2. Check Cloudflare Email Routing is **Enabled**
3. Verify destination email is verified in Cloudflare
4. Check spam folder
5. Check Cloudflare Activity log for errors

### DNS not updating?
1. Wait up to 24 hours for full propagation
2. Clear DNS cache: `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
3. Check current nameservers: `dig NS siteledger.ai +short`

### Website stops working after DNS change?
1. Verify A records in Cloudflare point to: 68.183.25.130
2. Check SSL/TLS mode in Cloudflare is set to **Full** or **Full (strict)**
3. api.siteledger.ai must be **DNS-only (gray cloud)** not proxied

---

## Summary

✅ **After completion you'll have:**
- Free email forwarding for support@siteledger.ai
- Emails forward to your personal inbox
- Ability to reply as support@siteledger.ai
- Cloudflare CDN and DDoS protection (bonus!)
- Professional email appearance for your app

⏱️ **Total Time:** 30-45 minutes (including DNS propagation wait)

💰 **Cost:** $0 (completely free)

---

## Quick Reference

**Test MX Records:**
```bash
dig MX siteledger.ai +short
```

**Test Email:**
```bash
echo "Test email body" | mail -s "Test Subject" support@siteledger.ai
```

**Check DNS Propagation:**
- https://dnschecker.org/#MX/siteledger.ai

---

Need help? The setup is straightforward but let me know if you hit any issues!
