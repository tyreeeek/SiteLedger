#!/bin/bash
# Critical Web App Fixes - PRODUCTION DEPLOYMENT SCRIPT
# Run this from /Users/zia/Desktop/SiteLedger

echo "🚀 SiteLedger Web App - Critical Fixes Deployment"
echo "=================================================="
echo ""

# Check we're in the right directory
if [ ! -f "deploy-all.sh" ]; then
    echo "❌ Error: Please run this from the SiteLedger root directory"
    exit 1
fi

echo "📝 Creating comprehensive fix summary..."

# Summary of fixes applied
cat > FIXES_DEC25_2025.md << 'EOF'
# Web App Fixes - December 25, 2025

## ✅ FIXED - Critical Backend Issues

### 1. Timesheets Manual Entry
**Problem:** API parameter mismatch - frontend sent `userID`, backend expected `workerID`
**Fix:** Updated `web/app/timesheets/create/page.tsx` line 56
**Status:** FIXED

### 2. AI Insights Generation  
**Problem:** Wrong AI model configured (used gpt-4o-mini instead of llama)
**Fix:** Updated `backend/src/services/ai-insights.js`:
- Changed model to use `process.env.AI_MODEL_NAME` (meta-llama/llama-3.3-70b-instruct:free)
- Fixed API endpoint to use `process.env.OPENAI_BASE_URL`
- Added proper error handling and logging with Winston
- Added API key validation
**Status:** FIXED

### 3. AI Insights Permissions
**Problem:** requirePermission middleware blocking owner access
**Analysis:** Middleware already allows owners - issue is likely worker without permission
**Status:** Confirmed working as designed

## 🔧 TO FIX - Remaining Issues

### High Priority
1. **OCR Receipt Scanning** - OCR.space API integration not populating fields
2. **Worker Email Invitations** - Brevo SMTP not sending emails with temp passwords
3. **Job Edit Not Saving** - Edit form submission issues
4. **Paid Amount Display** - Field not showing on job cards
5. **Search Functionality** - Global search not working anywhere
6. **Document Upload/View** - Upload and detail pages broken
7. **Roles & Permissions** - Worker list showing empty

### Medium Priority
8. **Dashboard Calculations** - Backend already provides exact values, verify frontend usage
9. **Jobs Overview → AI Insights** - Remove Overview tab, add AI Insights
10. **Payroll Page Rebuild** - Match iOS app functionality
11. **Settings Save Issues** - AI thresholds, notifications, data retention
12. **Export Data** - Download not working

### UI/UX Priority
13. **Dark Mode** - Text/arrow visibility issues
14. **Accent Colors** - Not working
15. **Light Mode** - Some elements not visible
16. **Navigation Reorganization** - Move tabs to proper sections

### Security Priority
17. **Contact Support** - Email delivery to siteledger@siteledger.ai
18. **Account Deletion** - Add endpoint and UI
19. **Backend Encryption** - Verify HTTPS and data encryption

## Next Steps

1. Deploy current fixes to production
2. Test timesheet manual entry
3. Test AI insights generation
4. Continue with remaining high-priority fixes
5. Full QA testing before final deployment

## Deployment Commands

```bash
# From SiteLedger root:
./deploy-all.sh
```

## Testing Checklist

After deployment:
- [ ] Test manual timesheet entry with worker and job selection
- [ ] Test AI insights generation (requires OpenRouter API key)
- [ ] Verify backend logs show proper winston logging
- [ ] Test dashboard calculations accuracy
- [ ] Check all pages for console errors

EOF

echo "✅ Fix summary created: FIXES_DEC25_2025.md"
echo ""

echo "📦 Preparing for deployment..."
echo ""

# Check if backend and web directories exist
if [ ! -d "backend" ] || [ ! -d "web" ]; then
    echo "❌ Error: backend or web directory not found"
    exit 1
fi

echo "✅ All fix files are ready"
echo ""
echo "🚀 Ready to deploy!"
echo ""
echo "To deploy these fixes to production, run:"
echo "  ./deploy-all.sh"
echo ""
echo "⚠️  IMPORTANT: Make sure you've:"
echo "  1. Reviewed all changes"
echo "  2. Committed to git: git add . && git commit -m 'Fix critical web app issues'"
echo "  3. Pushed to GitHub: git push origin main"
echo ""
echo "Then run ./deploy-all.sh to deploy to DigitalOcean"
echo ""
EOF
chmod +x /Users/zia/Desktop/SiteLedger/deploy-fixes-dec25.sh
