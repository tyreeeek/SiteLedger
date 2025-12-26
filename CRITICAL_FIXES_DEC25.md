# Critical Web App Fixes - December 25, 2025

## Priority 1: Backend API Fixes (Blocking Issues)

### 1. Timesheet Manual Entry - API Mismatch
**Issue:** Frontend sends `userID`, backend expects `workerID`
**File:** `web/app/timesheets/create/page.tsx` line 56
**Fix:** Change `userID` to `workerID` in API call

### 2. AI Insights Generation - OpenRouter API
**Issue:** Failed to generate insights error
**Files to check:**
- `backend/src/routes/ai-insights.js`
- `backend/src/services/ai-insights.js`
**Fix:** Verify OpenRouter API key and request format

### 3. OCR Receipt Scanning
**Issue:** OCR doesn't populate form fields
**File:** `backend/src/services/ocr-service.js`
**Fix:** Verify OCR.space API integration and response parsing

### 4. Worker Email Invitations
**Issue:** Workers don't receive email with temp password
**File:** `backend/src/routes/workers.js`
**Fix:** Implement Brevo SMTP email sending on worker creation

### 5. Settings Save Endpoints
**Issue:** AI thresholds, notifications, data retention don't save
**Files:**
- `backend/src/routes/preferences.js`
- `backend/src/routes/settings.js`
**Fix:** Add missing PUT/POST endpoints for each setting type

## Priority 2: Frontend Calculation Fixes

### 6. Dashboard - Use Exact Backend Calculations
**File:** `web/app/dashboard/page.tsx`
**Issue:** Frontend doing client-side estimates instead of using backend totals
**Fix:** Backend already provides `totalCost`, `profit`, `remainingBalance` - use them directly

### 7. Jobs Page - Calculations
**File:** `web/app/jobs/page.tsx`
**Issue:** Client-side calculation of metrics instead of backend values
**Fix:** Use job.totalCost, job.profit from backend API response

## Priority 3: UI/UX Fixes

### 8. Job Edit Not Working
**Issue:** Edit form doesn't save changes
**Check:** Job update endpoint and form submission

### 9. Paid Amount Display
**Issue:** amountPaid not showing on job cards
**Fix:** Verify field mapping in job display components

### 10. Jobs - Replace Overview with AI Insights Tab
**File:** `web/app/jobs/[id]/page.tsx`
**Action:** Remove Overview tab, add AI Insights tab

### 11. Search Functionality
**Issue:** Search doesn't work anywhere
**Fix:** Implement client-side filtering for receipts, jobs, documents, etc.

### 12. Document Upload & Detail View
**Files:**
- `web/app/documents/upload/page.tsx`
- `web/app/documents/[id]/page.tsx`
**Fix:** Check multer upload endpoint and detail page data fetching

### 13. Roles & Permissions - No Workers Showing
**File:** `web/app/settings/roles-permissions/page.tsx`
**Fix:** Check workers API call and data mapping

### 14. Dark Mode Visibility Issues
**File:** `web/app/globals.css` or theme provider
**Fix:** Add proper text/icon colors for dark mode
- Text should be `text-gray-100` or `text-white` in dark mode
- Icons need `dark:text-gray-100` classes
- Arrows/chevrons need proper contrast

### 15. Accent Colors Not Working
**File:** Theme system
**Fix:** Implement CSS custom properties for accent colors

## Priority 4: Navigation Reorganization

### 16. Move Tabs to Settings
**Action:**
- Move "Company Profile" → Settings
- Move "Account Settings" → Settings  
- Move "FAQ" → Settings

### 17. Group Worker Management Tabs
**Action:**
- Keep "Workers", "Timesheets", "Payroll" together in nav

## Priority 5: New Features

### 18. Rebuild Payroll Page
**File:** `web/app/payroll/page.tsx`
**Action:** Match iOS app functionality:
- Worker payment history
- Payment tracking
- Export capabilities

### 19. Export Data Functionality
**File:** `backend/src/routes/export.js`
**Fix:** Implement full data export (jobs, receipts, timesheets, workers)

### 20. Contact Support Email
**File:** `backend/src/routes/support.js`
**Fix:** Send emails via Brevo to siteledger@siteledger.ai

### 21. Account Deletion
**Files:**
- `backend/src/routes/auth.js` - Add DELETE /api/auth/account endpoint
- `web/app/settings/account/page.tsx` - Add deletion UI with confirmation

## Priority 6: Security & Production Readiness

### 22. Backend Security Review
**Actions:**
- Verify all endpoints use `authenticate` middleware
- Check rate limiting is active
- Ensure HTTPS in production
- Add request validation to all endpoints

### 23. Error Handling Audit
**Actions:**
- Replace any remaining `console.log` in backend with `logger`
- Ensure all API errors return user-friendly messages
- Add error boundaries to critical web pages

## Testing Checklist

After fixes:
- [ ] Test all dashboard calculations with real data
- [ ] Test job create/edit/delete flow
- [ ] Test receipt upload with OCR
- [ ] Test manual timesheet entry
- [ ] Test document upload and viewing
- [ ] Test worker invitation email
- [ ] Test all settings save correctly
- [ ] Test dark mode on all pages
- [ ] Test search on receipts, jobs, documents
- [ ] Test payroll page functionality
- [ ] Test AI insights generation
- [ ] Test AI automations
- [ ] Test data export download
- [ ] Test contact support email delivery
- [ ] Test account deletion with confirmation

## Implementation Order

1. Fix backend API endpoints (1-5) - CRITICAL BLOCKERS
2. Fix frontend calculations (6-7) - DATA ACCURACY
3. Fix UI functionality (8-13) - USER EXPERIENCE
4. Fix theming issues (14-15) - VISUAL
5. Reorganize navigation (16-17) - UX IMPROVEMENT
6. Add new features (18-21) - FEATURE PARITY
7. Security audit (22-23) - PRODUCTION READY
8. Full testing (Testing Checklist) - QUALITY ASSURANCE
