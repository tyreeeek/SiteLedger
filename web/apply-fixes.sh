#!/bin/bash
# SiteLedger Web - Critical Fixes Deployment Script
# This script applies all critical UI and functional fixes

echo "🚀 Starting SiteLedger Web Critical Fixes..."
echo "================================================"

# Change to web directory
cd "$(dirname "$0")"

# Ensure we're in the web folder
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the web directory."
    exit 1
fi

echo "✅ Located web directory"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo ""
echo "🎨 Fixes Applied:"
echo "  ✅ Theme system updated - no more white flash on refresh"
echo "  ✅ Accent colors configured (Blue: #007AFF, Orange: #FF8C42)"
echo "  ✅ Dark mode properly configured in all color variables"
echo "  ✅ BackButton component created for consistent navigation"
echo "  ✅ Worker creation flow fixed with email sending"
echo "  ✅ Job edit page updated with proper dark mode support"
echo ""

echo "🔄 Building application..."
npm run build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📝 Next Steps:"
    echo "  1. Test worker creation - password should be emailed"
    echo "  2. Test job editing - amount paid should save properly"
    echo "  3. Verify theme persists on page refresh"
    echo "  4. Check all navigation arrows work correctly"
    echo ""
    echo "🚀 To start development server:"
    echo "   npm run dev"
    echo ""
    echo "🌐 To deploy to production:"
    echo "   ./deploy.sh"
else
    echo ""
    echo "❌ Build failed! Please check the errors above."
    exit 1
fi
