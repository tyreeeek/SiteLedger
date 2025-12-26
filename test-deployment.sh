#!/bin/bash
# Quick Test Script for Deployed Fixes
# Run this AFTER deployment to verify fixes are working

echo "🧪 Testing Deployed Fixes - SiteLedger Web App"
echo "================================================"
echo ""

API_URL="https://api.siteledger.ai"

echo "1️⃣ Testing Backend Health..."
health_response=$(curl -s "${API_URL}/health")
if [[ $health_response == *"healthy"* ]]; then
    echo "   ✅ Backend is healthy"
else
    echo "   ❌ Backend health check failed"
    echo "   Response: $health_response"
fi
echo ""

echo "2️⃣ Testing Backend API Endpoints..."
echo "   Testing /api/jobs endpoint (requires auth)..."
jobs_response=$(curl -s -w "\n%{http_code}" "${API_URL}/api/jobs")
http_code=$(echo "$jobs_response" | tail -n1)
if [ "$http_code" == "401" ]; then
    echo "   ✅ Jobs endpoint responding (401 = needs auth, expected)"
else
    echo "   ⚠️  Jobs endpoint returned: $http_code"
fi
echo ""

echo "3️⃣ Checking AI Insights Service..."
echo "   Verifying OpenRouter API configuration..."
if ssh root@68.183.25.130 "cd /root/siteledger/backend && grep -q 'OPENROUTER_API_KEY' .env"; then
    echo "   ✅ OpenRouter API key is configured"
else
    echo "   ❌ OpenRouter API key not found in .env"
fi
echo ""

echo "4️⃣ Checking OCR Service..."
echo "   Verifying OCR.space API configuration..."
if ssh root@68.183.25.130 "cd /root/siteledger/backend && grep -q 'OCR_SPACE_API_KEY' .env"; then
    echo "   ✅ OCR API key is configured"
else
    echo "   ❌ OCR API key not found in .env"
fi
echo ""

echo "5️⃣ Checking PM2 Process Status..."
ssh root@68.183.25.130 "pm2 status" | grep -E "siteledger|online|errored"
echo ""

echo "6️⃣ Checking Recent Backend Logs..."
echo "   Last 20 lines from backend:"
ssh root@68.183.25.130 "pm2 logs siteledger-api --lines 20 --nostream" | tail -20
echo ""

echo "7️⃣ Checking Recent Web Logs..."
echo "   Last 20 lines from web:"
ssh root@68.183.25.130 "pm2 logs siteledger-web --lines 20 --nostream" | tail -20
echo ""

echo "================================================"
echo "✅ Automated tests complete!"
echo ""
echo "📋 MANUAL TESTING CHECKLIST:"
echo ""
echo "Open https://siteledger.ai and test:"
echo "  [ ] Sign in successfully"
echo "  [ ] Dashboard loads with exact numbers (not estimates)"
echo "  [ ] Navigate to Timesheets → Create"
echo "  [ ] Select a worker and job from dropdowns"
echo "  [ ] Enter clock in/out times or hours"
echo "  [ ] Submit - should succeed (no error)"
echo "  [ ] Navigate to Receipts → Create"
echo "  [ ] Upload a receipt image"
echo "  [ ] OCR should auto-fill vendor, amount, date"
echo "  [ ] Navigate to AI Insights"
echo "  [ ] Click 'Generate Insights'"
echo "  [ ] Should see insights (not error)"
echo "  [ ] Check browser console for errors (F12)"
echo ""
echo "If any test fails, check logs with:"
echo "  ssh root@68.183.25.130 \"pm2 logs siteledger-api --lines 100\""
echo ""
