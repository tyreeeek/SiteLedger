#!/bin/bash

set -e

echo "🚀 Deploying SiteLedger Critical Fixes to Production"
echo "====================================================="
echo ""
echo "🌐 Target: https://siteledger.ai"
echo "📅 Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Verify we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run from web directory."
    exit 1
fi

echo "✅ Located web directory"
echo ""

# Show what's being deployed
echo "📋 FIXES INCLUDED IN THIS DEPLOYMENT:"
echo "  ✅ Theme system - no white flash, proper colors"
echo "  ✅ Accent colors - Blue (#007AFF) & Orange (#FF8C42)"
echo "  ✅ Dark mode - fully functional across all pages"
echo "  ✅ BackButton component - consistent navigation"
echo "  ✅ Workers module - add workers, email invitations"
echo "  ✅ Jobs editing - amount paid field saves correctly"
echo "  ✅ Receipts - AI processing, file upload working"
echo "  ✅ Privacy policy - address removed, dark mode added"
echo ""

read -p "🤔 Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Build the app
echo ""
echo "📦 Building production bundle..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Fix errors before deploying."
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Create deployment package
echo "📁 Creating deployment package..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEPLOY_FILE="critical_fixes_${TIMESTAMP}.tar.gz"

tar -czf "$DEPLOY_FILE" \
  .next \
  public \
  package.json \
  package-lock.json \
  next.config.ts \
  next.config.mjs \
  tailwind.config.ts \
  postcss.config.mjs

echo "✅ Package created: $DEPLOY_FILE"
echo ""

# Upload to server
echo "📤 Uploading to siteledger.ai (68.183.25.130)..."
scp "$DEPLOY_FILE" root@68.183.25.130:/tmp/

if [ $? -ne 0 ]; then
    echo "❌ Upload failed! Check SSH connection."
    exit 1
fi

echo "✅ Upload complete!"
echo ""

# Deploy on server
echo "🔧 Deploying on server..."
ssh root@68.183.25.130 << 'ENDSSH'
  echo "📂 Navigating to web directory..."
  cd /var/www/siteledger.ai
  
  echo "💾 Creating backup..."
  if [ -d ".next" ]; then
    tar -czf "backup_$(date +%Y%m%d_%H%M%S).tar.gz" .next public 2>/dev/null || true
  fi
  
  echo "📦 Extracting new files..."
  tar -xzf /tmp/critical_fixes_*.tar.gz
  
  echo "📥 Installing dependencies..."
  npm ci --production
  
  echo "🔄 Restarting application..."
  pm2 stop siteledger-web || true
  pm2 delete siteledger-web || true
  PORT=3001 pm2 start npm --name "siteledger-web" -- start
  pm2 save
  
  echo "🧹 Cleaning up..."
  rm /tmp/critical_fixes_*.tar.gz
  
  echo "✅ Server deployment complete!"
ENDSSH

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed! Check server logs."
    exit 1
fi

echo ""
echo "=============================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "=============================================="
echo ""
echo "🌐 Live URL: https://siteledger.ai"
echo "🌐 Web URL: https://web.siteledger.ai"
echo ""
echo "📊 Verify deployment:"
echo "   ssh root@68.183.25.130 'pm2 status'"
echo ""
echo "📝 View logs:"
echo "   ssh root@68.183.25.130 'pm2 logs siteledger-web --lines 50'"
echo ""
echo "🔄 If issues occur, restore backup:"
echo "   ssh root@68.183.25.130 'cd /var/www/siteledger.ai && tar -xzf backup_*.tar.gz'"
echo ""
echo "🧪 TEST IMMEDIATELY:"
echo "   1. Visit https://siteledger.ai"
echo "   2. Refresh page - verify no white flash"
echo "   3. Test Workers → Add Worker"
echo "   4. Test Jobs → Edit Job → Update Amount Paid"
echo "   5. Test Receipts → Add Receipt → Upload Image"
echo "   6. Toggle dark mode - verify text visibility"
echo ""

# Clean up local deployment file
rm "$DEPLOY_FILE"

echo "🎉 All done! Your fixes are now live!"
