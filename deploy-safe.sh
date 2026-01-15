#!/bin/bash

# Safe deployment script that preserves production .env files
# Usage: ./deploy-safe.sh [backend|web|all]

set -e

PASSWORD="Dk7!vP9#Qm4\$Xe2@Hs8Zt"
SERVER="root@68.183.25.130"
DEPLOY_TYPE="${1:-all}"

echo "🚀 SiteLedger Safe Deployment"
echo "================================"

deploy_backend() {
    echo ""
    echo "📦 Deploying Backend..."
    echo "- Backing up production .env..."
    
    # Backup production .env
    sshpass -p "$PASSWORD" ssh "$SERVER" "cp /root/siteledger/backend/.env /root/siteledger/backend/.env.backup"
    
    # Deploy backend files (excluding .env)
    sshpass -p "$PASSWORD" rsync -avz \
        --exclude 'node_modules' \
        --exclude '.env' \
        --exclude '.env.backup' \
        --exclude 'logs/*' \
        backend/ "$SERVER":/root/siteledger/backend/
    
    # Restore production .env
    sshpass -p "$PASSWORD" ssh "$SERVER" "mv /root/siteledger/backend/.env.backup /root/siteledger/backend/.env"
    
    # Restart backend
    echo "- Restarting backend..."
    sshpass -p "$PASSWORD" ssh "$SERVER" "pm2 restart siteledger-backend --update-env"
    
    echo "✅ Backend deployed successfully!"
}

deploy_web() {
    echo ""
    echo "🌐 Deploying Web..."
    
    # Deploy web files
    cd web
    sshpass -p "$PASSWORD" rsync -avz \
        --exclude 'node_modules' \
        --exclude '.next' \
        --exclude '.git' \
        . "$SERVER":/root/siteledger/web/
    
    # Build and restart
    echo "- Building Next.js..."
    sshpass -p "$PASSWORD" ssh "$SERVER" "cd /root/siteledger/web && npm run build"
    
    echo "- Restarting web..."
    sshpass -p "$PASSWORD" ssh "$SERVER" "pm2 restart siteledger-web"
    
    cd ..
    echo "✅ Web deployed successfully!"
}

# Main deployment logic
case "$DEPLOY_TYPE" in
    backend)
        deploy_backend
        ;;
    web)
        deploy_web
        ;;
    all)
        deploy_backend
        deploy_web
        ;;
    *)
        echo "❌ Invalid deployment type: $DEPLOY_TYPE"
        echo "Usage: $0 [backend|web|all]"
        exit 1
        ;;
esac

echo ""
echo "🎉 Deployment Complete!"
echo "================================"
echo "📊 Check status: ssh $SERVER 'pm2 status'"
echo "📋 View logs: ssh $SERVER 'pm2 logs siteledger-backend --lines 50'"
