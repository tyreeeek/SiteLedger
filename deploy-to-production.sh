#!/bin/bash
# Quick deployment script for SiteLedger production
# Run this and enter the server password when prompted

echo "🚀 Deploying to production..."
echo "You'll be prompted for the server password"
echo ""

# SSH to server and deploy
ssh root@api.siteledger.ai << 'ENDSSH'
cd /var/www/siteledger
echo "📥 Pulling latest code..."
git pull origin main

echo "📦 Installing dependencies..."
npm install --production

echo "🔄 Restarting backend..."
pm2 restart siteledger-backend

echo "💾 Saving PM2 config..."
pm2 save

echo "✅ Backend deployment complete!"
exit
ENDSSH

echo ""
echo "✅ Backend deployed! Now deploying web..."

# Deploy web (Vercel auto-deploys from GitHub)
echo "📱 Web will auto-deploy from GitHub to Vercel"
echo "✅ All done! Check https://siteledger.ai in a few minutes"
