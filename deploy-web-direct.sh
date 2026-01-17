#!/bin/bash
# Deploy Web App Directly (no GitHub/Vercel)

set -e

echo "🌐 Direct Web Deployment"
echo "========================"

SERVER="root@api.siteledger.ai"
REMOTE_WEB_DIR="/var/www/siteledger-web"
LOCAL_WEB="/Users/zia/Desktop/SiteLedger/web"

echo ""
echo "🏗️  Step 1: Building web app locally..."
cd "$LOCAL_WEB"
npm run build

echo ""
echo "📦 Step 2: Uploading web files..."
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.env' \
  --exclude '.next/cache' \
  "$LOCAL_WEB/" \
  "$SERVER:$REMOTE_WEB_DIR/"

echo ""
echo "🔧 Step 3: Installing dependencies on server..."

ssh "$SERVER" << 'ENDSSH'
cd /var/www/siteledger-web

echo "📦 Installing dependencies..."
npm install --production --silent

echo ""
echo "🔄 Restarting web app..."
pm2 restart siteledger-web || pm2 start npm --name "siteledger-web" -- start

echo ""
echo "💾 Saving PM2 config..."
pm2 save

echo ""
echo "✅ Web deployment complete!"
echo ""
echo "📊 Server status:"
pm2 list

ENDSSH

echo ""
echo "===================================="
echo "✅ Web Deployment Complete!"
echo "===================================="
echo ""
echo "Website: https://siteledger.ai"
echo ""
