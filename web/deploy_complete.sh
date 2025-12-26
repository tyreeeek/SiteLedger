#!/bin/bash
set -e

echo "🚀 Complete SiteLedger Deployment"
echo "=================================="
echo ""

# Step 1: Fresh build
echo "📦 Building fresh production bundle..."
npm run build

# Step 2: Create complete package with ALL files
echo "📁 Creating deployment package..."
tar -czf complete_deploy_final.tar.gz \
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

echo "✅ Package created: complete_deploy_final.tar.gz"
echo ""
echo "📊 Package size: $(ls -lh complete_deploy_final.tar.gz | awk '{print $5}')"
echo ""
echo "=================================="
echo "🔧 DEPLOYMENT INSTRUCTIONS"
echo "=================================="
echo ""
echo "Run these commands step-by-step:"
echo ""
echo "# 1. SSH into server"
echo "ssh root@68.183.25.130"
echo ""
echo "# 2. Backup and prepare (paste this entire block):"
cat << 'SSHCMD1'
cd /var/www && \
mv siteledger.ai siteledger.ai.backup.$(date +%Y%m%d_%H%M%S) && \
mkdir -p /var/www/siteledger.ai && \
echo "✅ Old site backed up, ready for upload"
SSHCMD1
echo ""
echo "# 3. Exit SSH (type: exit)"
echo ""
echo "# 4. Upload from Mac terminal:"
echo "scp complete_deploy_final.tar.gz root@68.183.25.130:/var/www/siteledger.ai/"
echo ""
echo "# 5. SSH back in:"
echo "ssh root@68.183.25.130"
echo ""
echo "# 6. Extract and deploy (paste this entire block):"
cat << 'SSHCMD2'
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
echo "📝 Checking logs..." && \
sleep 3 && \
pm2 logs siteledger-web --lines 30 --nostream
SSHCMD2
echo ""
echo "=================================="
echo "✅ Script ready! Follow steps above."
echo "=================================="
