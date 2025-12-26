#!/bin/bash
# One-command deployment - handles SSH password prompts
# Usage: ./deploy_auto.sh

set -e

DEPLOY_FILE="complete_deploy_final.tar.gz"
SERVER="root@68.183.25.130"
DEPLOY_PATH="/var/www/siteledger.ai"

echo "🚀 SiteLedger Auto-Deploy"
echo "========================="
echo ""
echo "This script will prompt for SSH password 3 times"
echo ""

# Step 1: Backup old site
echo "📦 Step 1/3: Backing up old site..."
ssh $SERVER "cd /var/www && mv siteledger.ai siteledger.ai.backup.\$(date +%Y%m%d_%H%M%S) && mkdir -p $DEPLOY_PATH && echo '✅ Backup complete'"

# Step 2: Upload package
echo ""
echo "📤 Step 2/3: Uploading package (7.5MB)..."
scp $DEPLOY_FILE $SERVER:$DEPLOY_PATH/

# Step 3: Extract and deploy
echo ""
echo "🔧 Step 3/3: Extracting and deploying..."
ssh $SERVER << 'ENDSSH'
cd /var/www/siteledger.ai && \
tar -xzf complete_deploy_final.tar.gz && \
rm complete_deploy_final.tar.gz && \
echo "✅ Files extracted" && \
npm ci --production && \
echo "✅ Dependencies installed" && \
sed -i 's/"start": "next start"/"start": "next start -p 3001"/' package.json && \
echo "✅ Port configured" && \
pm2 stop siteledger-web 2>/dev/null || true && \
pm2 delete siteledger-web 2>/dev/null || true && \
pm2 start npm --name siteledger-web -- start && \
pm2 save && \
echo "" && \
echo "✅✅✅ DEPLOYMENT COMPLETE! ✅✅✅" && \
echo "" && \
pm2 status && \
echo "" && \
sleep 2 && \
pm2 logs siteledger-web --lines 20 --nostream
ENDSSH

echo ""
echo "🎉 Deployment finished!"
echo "🌐 Site: https://siteledger.ai"
