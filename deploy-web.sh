#!/bin/bash

# SiteLedger Web Deployment Script
# Usage: ./deploy-web.sh

set -e  # Exit on any error

echo "🚀 Starting SiteLedger Web Deployment..."
echo "========================================"

# SSH credentials
SSH_USER="root"
SSH_HOST="68.183.25.130"
export SSHPASS='Dk7!vP9#Qm4$Xe2@Hs8Zt'
WEB_PATH="/var/www/siteledger.ai"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1:${NC} Copying source files to server..."
cd /Users/zia/Desktop/SiteLedger/web
tar czf - \
  --exclude 'node_modules' \
  --exclude '.next' \
  --exclude '.git' \
  . | sshpass -e ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST "cd $WEB_PATH && tar xzf -"
echo "✓ Code copied"

echo ""
echo -e "${YELLOW}Step 2:${NC} Installing dependencies ON SERVER..."
sshpass -e ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST << 'EOF'
cd /var/www/siteledger.ai
npm install --production=false
echo "✓ Dependencies installed"
EOF

echo ""
echo -e "${YELLOW}Step 3:${NC} Building Next.js app (this takes 2-3 minutes)..."
sshpass -e ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST << 'EOF'
cd /var/www/siteledger.ai
npm run build 2>&1 | tail -20
echo "✓ Build completed"
EOF

echo ""
echo -e "${YELLOW}Step 4:${NC} Restarting web server..."
sshpass -e ssh -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST << 'EOF'
pm2 restart siteledger-web
sleep 3
pm2 list | grep siteledger-web
echo "✓ Server restarted"
EOF

echo ""
echo -e "${GREEN}========================================"
echo -e "✅ Deployment Complete!"
echo -e "======================================${NC}"
echo ""
echo "Your website is live at: https://siteledger.ai"
echo ""
echo "To check logs: ssh root@68.183.25.130 'pm2 logs siteledger-web'"
echo "To check status: ssh root@68.183.25.130 'pm2 status'"
