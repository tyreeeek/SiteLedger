# Comprehensive Web App Fixes - December 25, 2025

## Critical Issues to Fix

### 1. Dashboard - Exact Calculations
**Problem:** Using abbreviated numbers (1.5M, 50K) and recalculating client-side  
**Solution:**
- Remove `formatCurrency()` rounding - use exact dollar amounts
- Use backend-provided `profit`, `totalCost`, `remainingBalance` instead of recalculating
- Display: `$1,234,567.89` instead of `$1.2M`

**Files to Fix:**
- `web/app/dashboard/page.tsx` - lines 90-100 (remove client calculations)

---

### 2. Jobs - Edit & Paid Amount Issues  
**Problem:** Edit doesn't save, paid amount doesn't display, Overview tab should be AI Insights  
**Solution:**
- Fix job edit mutation to properly call API
- Add `amountPaid` field display binding
- Replace "Overview" tab with "AI Insights" tab showing AI-generated insights

**Files to Fix:**
- `web/app/jobs/[id]/page.tsx` - Fix overview tab, add paid amount display
- `web/app/jobs/[id]/edit/page.tsx` - Fix edit mutation

---

### 3. Receipts - AI OCR Not Working
**Problem:** AI OCR returns empty fields  
**Solution:**
- Debug `/api/receipts/ai-extract` endpoint
- Ensure OpenAI API key is configured
- Test with actual receipt images

**Files to Fix:**
- `backend/src/routes/receipts.js` - AI extraction endpoint
- `web/app/receipts/create/page.tsx` - OCR integration

---

### 4. Global Search Not Working
**Problem:** Search doesn't work on any page  
**Solution:**
- Implement backend search endpoints for each entity
- Add frontend search UI that filters results
- Enable search on: jobs, receipts, timesheets, documents, workers

**Files to Create/Fix:**
- Add search params to all GET endpoints
- Update all list pages with working search

---

### 5. Timesheets - Manual Entry Error
**Problem:** Manual timesheet creation fails  
**Solution:**
- Debug validation errors
- Check required fields match backend schema
- Test endpoint directly

**Files to Fix:**
- `web/app/timesheets/create/page.tsx`
- `backend/src/routes/timesheets.js` - POST endpoint validation

---

### 6. Documents - Upload & Detail View Broken
**Problem:** Can't upload documents, detail view 404s  
**Solution:**
- Fix file upload endpoint integration
- Fix document detail page routing
- Ensure DigitalOcean Spaces configured

**Files to Fix:**
- `web/app/documents/upload/page.tsx` - Upload form
- `web/app/documents/[id]/page.tsx` - Detail view (create if missing)
- `backend/src/routes/upload.js` - File upload endpoint

---

### 7. Workers - Email Invitations Not Sending
**Problem:** Workers don't receive invitation emails  
**Solution:**
- Configure nodemailer with actual SMTP credentials
- Test email delivery
- Ensure template includes temporary password

**Files to Fix:**
- `backend/src/routes/workers.js` - Send invite endpoint
- Create email service if missing
- Add SMTP configuration to `.env`

---

### 8. Payroll - Not Matching iOS App
**Problem:** Payroll page incomplete/non-functional  
**Solution:**
- Rebuild payroll page to match iOS functionality:
  - List of all worker payments
  - Payment history per worker
  - Total paid/unpaid amounts
  - Create new payment UI

**Files to Fix:**
- `web/app/payroll/page.tsx` - Complete rebuild

---

### 9. AI Automations - Settings Don't Save
**Problem:** Gets error "Failed to save settings"  
**Solution:**
- Debug `/api/settings/ai` PUT endpoint
- Check validation requirements
- Ensure AI automation jobs configured

**Files to Fix:**
- `backend/src/routes/settings.js` - AI settings endpoint
- `web/app/settings/ai-automation/page.tsx` - Form submission

---

### 10. AI Insights - Generation Fails
**Problem:** Gets error "Failed to generate insights"  
**Solution:**
- Debug `/api/ai-insights` POST endpoint
- Verify OpenAI API key
- Check rate limits

**Files to Fix:**
- `backend/src/routes/ai-insights.js`
- Verify API key in `.env`

---

### 11. Navigation Reorganization
**Problem:** Tabs in wrong sections  
**Solution:**
- Move Company Profile → Settings
- Move Account Settings → Settings
- Move FAQ → Payroll/Workers section
- Move Timesheets → Payroll/Workers section

**Files to Fix:**
- `components/dashboard-layout.tsx` - Navigation structure

---

### 12. Settings - All Subsections Broken
**Problems:**
- AI Thresholds don't save
- Smart Notifications don't save  
- Roles & Permissions shows "No workers" when 3 exist
- Data Retention doesn't save
- Export Data fails

**Solution:**
- Debug each settings endpoint
- Fix worker fetching in roles page
- Implement export functionality
- Ensure all PUT endpoints work

**Files to Fix:**
- `backend/src/routes/settings.js` - All settings endpoints
- `web/app/settings/*/page.tsx` - All settings pages

---

### 13. Appearance - Dark Mode & Light Mode Issues
**Problem:** 
- Dark mode: text/arrows invisible (white on white)
- Light mode: some text/arrows invisible  
- Accent colors don't work

**Solution:**
- Audit all Tailwind classes for proper dark: variants
- Fix contrast issues
- Implement accent color theming system
- Test both modes thoroughly

**Files to Fix:**
- `app/globals.css` - Dark mode CSS variables
- All component files - Add proper dark: classes
- Implement accent color system

---

### 14. Contact Support - Email Not Sending
**Problem:** Support form doesn't send to siteledger@siteledger.ai  
**Solution:**
- Configure email service
- Test email delivery
- Add confirmation message

**Files to Fix:**
- `backend/src/routes/support.js` (create if missing)
- `web/app/support/page.tsx`

---

### 15. Account Deletion Missing
**Problem:** No delete account button  
**Solution:**
- Add delete account UI in account settings
- Implement backend endpoint with confirmation
- Hard delete user and all owned data

**Files to Create:**
- `backend/src/routes/auth.js` - DELETE /account endpoint
- `web/app/settings/account/page.tsx` - Add delete button

---

### 16. Backend Security Audit
**Problem:** Backend needs protection and encryption  
**Solution:**
- Verify all routes have authentication middleware
- Add encryption for sensitive fields (passwords already bcrypt)
- Audit for SQL injection (already using parameterized queries)
- Add rate limiting to sensitive endpoints
- Enable HTTPS only (already configured)

**Files to Check:**
- All route files - Verify `authenticate` middleware
- `backend/src/middleware/auth.js` - Security settings
- `backend/src/index.js` - Global security config

---

## Implementation Priority

### Phase 1 (Critical - Do First)
1. Dashboard exact calculations
2. Jobs edit & paid amount
3. Global search implementation
4. Dark/Light mode visibility fixes

### Phase 2 (High Priority)
5. Receipts AI OCR
6. Timesheets manual entry
7. Documents upload/detail
8. Settings endpoints (all subsections)

### Phase 3 (Important)
9. Worker email invitations
10. Payroll page rebuild
11. AI systems (automation & insights)
12. Navigation reorganization

### Phase 4 (Polish)
13. Accent color theming
14. Contact support email
15. Account deletion
16. Backend security audit

---

## Testing Checklist

After each fix, test:
- ✅ Functionality works as expected
- ✅ No console errors
- ✅ Works in both dark and light mode
- ✅ Mobile responsive
- ✅ Proper error messages (no generic "Failed to...")
- ✅ Loading states work
- ✅ Data persists after refresh

---

## Success Criteria

- All calculations show exact dollar amounts with cents
- All edit/create forms save successfully
- All search bars filter results
- Dark mode has proper contrast (all text visible)
- Light mode has proper contrast (all text visible)
- Accent colors apply to UI elements
- AI features work (OCR, insights, automation)
- Emails send successfully (invitations, support)
- Account can be deleted with confirmation
- No console errors anywhere
- Backend fully secured and encrypted
