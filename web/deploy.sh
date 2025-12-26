#!/bin/bash

set -e

echo "🚀 Deploying SiteLedger Web App to Production"
echo "=============================================="

# Build the app
echo "📦 Building production bundle..."
npm run build

# Create deployment package
echo "📁 Creating deployment package..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_FILE="deploy_${TIMESTAMP}.tar.gz"

tar -czf "$DEPLOY_FILE" \
  .next \
  public \
  package.json \
  package-lock.json \
  next.config.ts

echo "✅ Package created: $DEPLOY_FILE"

# Upload to server
echo "📤 Uploading to server..."
scp "$DEPLOY_FILE" root@68.183.25.130:/tmp/

# Deploy on server
echo "🔧 Deploying on server..."
ssh root@68.183.25.130 << 'ENDSSH'
  cd /var/www/siteledger.ai
  tar -xzf /tmp/deploy_*.tar.gz
  npm ci --production
  pm2 stop siteledger-web || true
  pm2 delete siteledger-web || true
  PORT=3001 pm2 start npm --name "siteledger-web" -- start
  pm2 save
ENDSSH

echo "✅ Deployment complete!"
echo ""
echo "🌐 Your app is live at: https://siteledger.ai"
echo "📊 Check status: ssh root@68.183.25.130 'pm2 status'"
echo "📝 View logs: ssh root@68.183.25.130 'pm2 logs siteledger-web'"
