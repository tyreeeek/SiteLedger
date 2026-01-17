#!/bin/bash
# Direct deployment to production server (no GitHub needed)
# Deploy SiteLedger backend and migrations

set -e

echo "🚀 Direct Deployment to Production"
echo "===================================="

SERVER="root@api.siteledger.ai"
REMOTE_DIR="/var/www/siteledger"
LOCAL_BACKEND="/Users/zia/Desktop/SiteLedger/backend"

echo ""
echo "📦 Step 1: Uploading backend files..."
rsync -avz --progress \
  --exclude 'node_modules' \
  --exclude '.env' \
  --exclude 'uploads' \
  --exclude '*.log' \
  --exclude '*.tar.gz' \
  "$LOCAL_BACKEND/" \
  "$SERVER:$REMOTE_DIR/"

echo ""
echo "✅ Backend files uploaded"
echo ""
echo "🔧 Step 2: Installing dependencies and applying migrations on server..."

ssh "$SERVER" << 'ENDSSH'
cd /var/www/siteledger

echo "📦 Installing dependencies..."
npm install --production --silent

echo ""
echo "🗄️  Applying database migrations..."
echo "Migration 015: Geofence fields..."
node apply_manual_migration.js 015_add_geofence_to_jobs.sql

echo ""
echo "Migration 016: Company info fields..."
node apply_manual_migration.js 016_add_company_info_to_users.sql

echo ""
echo "Migration 017: Notifications table..."
node apply_manual_migration.js 017_add_notifications_table.sql

echo ""
echo "🔄 Restarting backend..."
pm2 restart siteledger-backend

echo ""
echo "💾 Saving PM2 config..."
pm2 save

echo ""
echo "✅ Backend deployment complete!"
echo ""
echo "📊 Server status:"
pm2 list

ENDSSH

echo ""
echo "===================================="
echo "✅ Deployment Complete!"
echo "===================================="
echo ""
echo "Backend API: https://api.siteledger.ai"
echo ""
echo "Test: curl https://api.siteledger.ai/health"
echo ""
