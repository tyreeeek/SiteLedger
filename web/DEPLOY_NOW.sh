#!/bin/bash

# Complete Clean Deployment Script
# This will replace the old server files with the new clean version

echo "🚀 Creating complete deployment package..."

# Create complete deployment archive
tar -czf complete_deploy.tar.gz \
  .next \
  app \
  components \
  lib \
  types \
  public \
  package.json \
  package-lock.json \
  next.config.ts \
  tsconfig.json \
  tailwind.config.ts \
  postcss.config.mjs

echo "✅ Package created: complete_deploy.tar.gz"
echo ""
echo "📋 Now run these commands on the server:"
echo ""
echo "============================================"
echo "ssh root@68.183.25.130"
echo ""
echo "# Backup old deployment"
echo "cd /var/www && mv siteledger.ai siteledger.ai.old.$(date +%Y%m%d_%H%M%S)"
echo ""
echo "# Create fresh directory"
echo "mkdir -p /var/www/siteledger.ai"
echo ""
echo "# Exit SSH and upload from your Mac:"
echo "exit"
echo ""
echo "# Upload the package"
echo "scp complete_deploy.tar.gz root@68.183.25.130:/var/www/siteledger.ai/"
echo ""
echo "# SSH back in"
echo "ssh root@68.183.25.130"
echo ""
echo "# Extract and setup"
echo "cd /var/www/siteledger.ai"
echo "tar -xzf complete_deploy.tar.gz"
echo "rm complete_deploy.tar.gz"
echo ""
echo "# Install dependencies"
echo "npm ci --production"
echo ""
echo "# Update package.json to use port 3001"
echo "sed -i 's/\"start\": \"next start\"/\"start\": \"next start -p 3001\"/' package.json"
echo ""
echo "# Restart PM2"
echo "pm2 stop siteledger-web || true"
echo "pm2 delete siteledger-web || true"
echo "pm2 start npm --name siteledger-web -- start"
echo "pm2 save"
echo ""
echo "# Check status"
echo "pm2 status"
echo "pm2 logs siteledger-web --lines 20"
echo "============================================"
