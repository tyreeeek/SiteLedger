#!/bin/bash
# DIRECT DEPLOYMENT TO DIGITALOCEAN (No GitHub)
# Uploads changed files directly via SCP

echo "🚀 Direct Deployment to DigitalOcean"
echo "====================================="
echo ""

SERVER="root@68.183.25.130"
REMOTE_PATH="/root/siteledger"
Dk7!vP9#Qm4$Xe2@Hs8Zt="Dk7!vP9#Qm4$Xe2@Hs8Zt"

echo "📦 Step 1: Uploading Backend Files..."
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no backend/src/services/ai-insights.js "${SERVER}:${REMOTE_PATH}/backend/src/services/"
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no backend/src/services/ocr-service.js "${SERVER}:${REMOTE_PATH}/backend/src/services/"
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no backend/src/routes/ai-insights.js "${SERVER}:${REMOTE_PATH}/backend/src/routes/"
echo "   ✅ Backend files uploaded"
echo ""

echo "📦 Step 2: Uploading Web Files..."
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no web/app/timesheets/create/page.tsx "${SERVER}:${REMOTE_PATH}/web/app/timesheets/create/"
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no web/app/receipts/create/page.tsx "${SERVER}:${REMOTE_PATH}/web/app/receipts/create/"
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" scp -o StrictHostKeyChecking=no web/lib/api.ts "${SERVER}:${REMOTE_PATH}/web/lib/"
echo "   ✅ Web files uploaded"
echo ""

echo "🔄 Step 3: Restarting Backend Service..."
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" ssh -o StrictHostKeyChecking=no "${SERVER}" "cd ${REMOTE_PATH}/backend && pm2 restart siteledger-api"
echo "   ✅ Backend restarted"
echo ""

echo "🏗️  Step 4: Rebuilding Web App..."
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" ssh -o StrictHostKeyChecking=no "${SERVER}" "cd ${REMOTE_PATH}/web && npm run build"
echo "   ✅ Web rebuilt"
echo ""

echo "🔄 Step 5: Restarting Web Service..."
sshpass -p "${Dk7!vP9#Qm4$Xe2@Hs8Zt}" ssh -o StrictHostKeyChecking=no "${SERVER}" "cd ${REMOTE_PATH}/web && pm2 restart siteledger-web"
echo "   ✅ Web restarted"
echo ""

echo "✅ Deployment Complete!"
echo ""
echo "🧪 Run tests:"
echo "   ./test-deployment.sh"
echo ""
