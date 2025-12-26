#!/bin/bash

# SiteLedger Full Stack Deployment Script
# Deploys both backend and frontend
# Usage: ./deploy-all.sh

set -e  # Exit on any error

echo "🚀 Starting Full Stack Deployment..."
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Deploy backend first
echo "📦 Deploying Backend..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/deploy-backend.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
sleep 2

# Deploy frontend
echo "🌐 Deploying Frontend..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"$SCRIPT_DIR/deploy-web.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Full Stack Deployment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Backend API: https://api.siteledger.ai"
echo "✅ Frontend: https://siteledger.ai"
echo ""
echo "Total deployment time: ~3-4 minutes"
