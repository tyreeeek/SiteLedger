# Comprehensive Web App Fixes

## Critical Issues to Fix:

### 1. Jobs Page
- ✅ Backend already supports amountPaid updates
- ❌ Profile icon (Users icon) should navigate to `/jobs/${jobId}/edit`, currently does
- ❌ Need to verify edit functionality works

### 2. Receipts
- ❌ AI OCR not working - need to integrate OpenRouter AI
- ❌ Date format incorrect
- ❌ Can't view receipt details - need detail page

### 3. Workers
- ❌ Remove password field from create worker form (auto-generate)
- ❌ Email sending failing - check backend email service
- ✅ Backend already auto-generates password if not provided

### 4. Documents
- ❌ Upload failing with 400 error - need to debug endpoint

### 5. Settings
- ❌ Password change not working
- ❌ AI automations don't save
- ❌ AI insights don't generate
- ❌ Roles/permissions don't work
- ❌ Notifications don't work
- ❌ Appearance theme doesn't work
- ❌ Export features don't work
- ❌ Data retention doesn't work

### 6. Branding & UX
- ❌ Add SiteLedger logo to sidebar
- ❌ Make "SiteLedger" text color adaptive (black/white based on theme)
- ❌ Add favicon
- ❌ Fix ALL input fields to have text-gray-900 bg-white
- ❌ Add back navigation buttons
- ❌ Remove address from privacy policy

### 7. Company Profile
- ❌ Make editable and useful throughout app
