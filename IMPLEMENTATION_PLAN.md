# SiteLedger Implementation Plan - January 15, 2026

## Status Legend
- ✅ **COMPLETED** - Fully implemented and tested
- 🔄 **IN PROGRESS** - Currently being worked on
- ⏳ **PENDING** - Requires database migration or deployment
- 📋 **TODO** - Not started yet

---

## 1. Profile Information Doesn't Save (Website) - ✅ COMPLETED

**Changes Made:**
- Updated `web/app/settings/account/page.tsx` to properly upload avatar images
- Added 'profile' upload type to `web/lib/api.ts`
- Profile data now saves to backend via `/api/auth/profile`
- Page reloads after save to refresh all components with new data

**Files Modified:**
- `/Users/zia/Desktop/SiteLedger/web/app/settings/account/page.tsx`
- `/Users/zia/Desktop/SiteLedger/web/lib/api.ts`

---

## 2. Profile Picture Doesn't Appear in Settings (Website) - ✅ COMPLETED

**Changes Made:**
- Updated `web/components/dashboard-layout.tsx` sidebar to display user profile picture
- Shows profile image if `user.photoURL` exists
- Falls back to initials in colored circle if no photo

**Files Modified:**
- `/Users/zia/Desktop/SiteLedger/web/components/dashboard-layout.tsx`

---

## 3. Addresses Don't Save (Both Platforms) - ⏳ PENDING DATABASE MIGRATION

**Required Changes:**
1. **Database Migration (Created)**:
   - File: `/Users/zia/Desktop/SiteLedger/backend/migrations/009_add_company_info_to_users.sql`
   - Adds fields to `users` table:
     - `company_name`, `company_logo`
     - `address_street`, `address_city`, `address_state`, `address_zip`
     - `company_phone`, `company_email`, `company_website`, `company_tax_id`
   - **STATUS**: Migration file created, needs to be run on production database

2. **Backend API Updates Needed**:
   - Update `/api/auth/profile` endpoint to accept new address fields
   - Update `/api/auth/register` to accept company info on signup

3. **Website Updates Needed**:
   - Update `web/app/settings/company/page.tsx` to use separate address fields
   - Update `web/app/auth/signup/page.tsx` to collect company info
   - Replace single "address" textarea with:
     - Street Address (input)
     - City (input)
     - State (select dropdown)
     - ZIP Code (input)

4. **iOS Updates Needed**:
   - Update company profile view to use separate address fields
   - Update signup flow to collect company info
   - Update User model to include address components

**Deployment Steps**:
```bash
# On production server:
cd /Users/zia/Desktop/SiteLedger/backend
psql $DATABASE_URL < migrations/009_add_company_info_to_users.sql
pm2 restart siteledger-backend
```

---

## 4. Workers Seeing Money in Permissions (Both Platforms) - 🔄 IN PROGRESS

**Changes Made (Website)**:
- ✅ Updated `web/app/jobs/[id]/page.tsx` to check `canViewFinancials` permission
- ✅ Financial cards (Project Value, Payments, Cost, Profit) now hidden for workers without permission
- ✅ Payment progress bar now hidden for workers without permission

**Still Needed (Website)**:
- Dashboard financial widgets
- Payroll page (entire page should be owner-only)
- Job list page (hide amount columns)
- Receipt amounts (hide from workers without permission)

**Still Needed (iOS)**:
- JobDetailView: Hide financial sections
- DashboardView: Hide financial widgets
- PayrollView: Owner-only access
- Check all views that display money amounts

**Backend**:
- Already has `canViewFinancials` in `worker_permissions` JSONB
- No backend changes needed

---

## 5. Approve Timesheets Functionality Missing (Both Platforms) - 📋 TODO

**Problem**: No UI for owners to approve/deny/edit timesheets

**Website Changes Needed**:
1. Create `/web/app/timesheets/review/page.tsx` - Timesheet review page for owners
2. Add backend endpoint: `PUT /api/timesheets/:id/approve`
3. Add backend endpoint: `PUT /api/timesheets/:id/deny`
4. Update timesheet list to show approval status
5. Add approve/deny/edit buttons for each timesheet

**iOS Changes Needed**:
1. Create `TimesheetReviewView.swift` - Swipe actions for approve/deny
2. Add approval status badge to TimesheetRowView
3. Add edit functionality for timesheet hours/notes

**Database**:
- Add `approval_status` enum to timesheets table: `pending`, `approved`, `denied`
- Add `approved_by` UUID field (references users.id)
- Add `approved_at` TIMESTAMP field

---

## 6. Image Preview Doesn't Work (Both Platforms) - 📋 TODO

**Problem**: Image previews not displaying after upload

**Areas Affected**:
- Receipt image preview in create/edit forms
- Document image preview
- Profile photo preview (✅ FIXED in item #1)

**Website Fixes Needed**:
- `web/app/receipts/create/page.tsx` - Preview component
- `web/app/documents/create/page.tsx` - Preview component

**iOS Fixes Needed**:
- Receipt image preview in AddReceiptView
- Document preview in DocumentsView

---

## 7. Upload Documents Feature Doesn't Work (Both Platforms) - 📋 TODO

**Problem**: Document upload functionality broken

**Investigation Needed**:
- Check if backend `/api/upload/document` endpoint is working
- Test file upload flow
- Check if documents are saving to database

**Website**: `/web/app/documents/create/page.tsx`
**iOS**: `DocumentsView.swift`

---

## 8. Direct Deposits Feature Doesn't Work (Both Platforms) - 📋 TODO

**Problem**: Direct deposit functionality not implemented

**Scope Question**: What should direct deposits do?
- Store worker bank account info?
- Integrate with payment processor (Stripe, Plaid)?
- Just track direct deposit records?

**Needs Clarification Before Implementation**

---

## 9. Geofence Time Tracking (Both Platforms) - 📋 TODO

**Features Needed**:
1. Set geofence radius for each job (e.g., 100 meters from job address)
2. When worker clocks in, verify they're within geofence
3. Alert if worker clocks in from outside geofence
4. Store GPS coordinates with each clock-in/out event

**Database Changes**:
- Add `geofence_radius` to jobs table (DECIMAL, meters)
- Add `geofence_lat`, `geofence_lng` to jobs table
- Timesheets already have `clock_in_location`, `clock_out_location`

**Backend**:
- Add geofence validation logic to clock-in endpoint
- Calculate distance between worker location and job location
- Return error if outside geofence

**Website**:
- Add geofence settings to job create/edit forms
- Show geofence status in timesheet list
- Map view showing geofence boundary

**iOS**:
- Request location permission on clock-in
- Use CoreLocation to get GPS coordinates
- Show map with geofence boundary
- Alert user if outside geofence

---

## 10. Company Branding on Signup (Both Platforms) - ⏳ PENDING DATABASE MIGRATION

**Depends On**: Item #3 (database migration)

**Website Changes**:
- Update `/web/app/auth/signup/page.tsx` to include:
  - Company Name (required)
  - Company Logo upload
  - Address fields (street, city, state, zip)

**iOS Changes**:
- Update SignUpView.swift to include same fields
- Add image picker for logo upload

---

## 11. Remove SiteLedger Branding, Use Company Logo (Both Platforms) - ⏳ PENDING ITEM #10

**Website**:
- Replace SiteLedger logo in `dashboard-layout.tsx` with company logo
- Update page titles to use company name
- Keep "Powered by Z & N Global" in footer

**iOS**:
- Replace app logo with company logo (if provided)
- Update navigation title to company name
- Update Settings screen

---

## 12. Worker Assignment Notifications (Both Platforms) - 📋 TODO

**Features**:
- Send push notification when worker assigned to job
- Email notification (optional)
- In-app notification badge

**Backend**:
- Integrate push notification service (Firebase Cloud Messaging or APNs)
- Create notifications table to track sent notifications
- Add endpoint: `POST /api/notifications/send`

**Website**:
- Implement Web Push API
- Add notification permission request

**iOS**:
- Request notification permissions
- Handle remote notifications
- Show notification badge

---

## 13. Separate Address Fields (Both Platforms) - ⏳ PENDING ITEM #3

Covered in Item #3

---

## 14. Long Receipt Scanner (Camera Feature - Both Platforms) - 📋 TODO

**Feature**: Ability to scan long receipts like document scanner apps

**Website**:
- Implement multi-page image capture
- Stitch images together
- Or: Accept multiple images for single receipt

**iOS**:
- Use VNDocumentCameraViewController for scanning
- Automatic edge detection
- Multi-page capture support

---

## 15. Landing Page: "GPS" → "Geofence Time Tracking" - 📋 TODO

**Simple Text Change**:
- File: `/web/app/page.tsx`
- Find "GPS Time Tracking"
- Replace with "Geofence Time Tracking"

---

## 16. Terms: Add "Powered by Z & N Global" + Liability Disclaimer - 📋 TODO

**Files to Update**:
- `/web/app/legal/terms/page.tsx`
- iOS: `TermsView.swift` or similar

**Text to Add**:
```
SiteLedger is powered by Z & N Global.

LIMITATION OF LIABILITY:
Z & N Global and SiteLedger shall not be liable for any loss, corruption, or 
unauthorized access to user data. Users are responsible for maintaining their 
own backups. By using this service, you acknowledge and accept that data loss 
may occur and the service providers bear no liability for such incidents.
```

---

## 17. Fix Payment Screen on Website - 📋 TODO

**Needs Clarification**: What specifically is broken on the payment screen?
- Is it the UI layout?
- Payment recording functionality?
- Payment history display?

---

## 18. Move Quick Actions to Top Under Name (Website) - 📋 TODO

**Location**: Dashboard page (`/web/app/dashboard/page.tsx`)
**Change**: Move quick action buttons to appear directly under user name in header

---

## DIGITAL OCEAN IMAGE ACCESS QUESTION

**Answer**: Yes, as the DigitalOcean Spaces owner, you can access all uploaded images.

**Access Methods**:
1. **DigitalOcean Console**: Browse Spaces bucket directly
2. **AWS S3 CLI**: Use credentials to list/download files
   ```bash
   s3cmd ls s3://siteledger-bucket/uploads/
   s3cmd get s3://siteledger-bucket/uploads/receipts/...
   ```
3. **Direct URL**: All uploads have public URLs (if ACL is public-read)
   - Format: `https://your-cdn-endpoint.com/uploads/receipts/{userId}/{filename}`

**File Structure**:
```
/uploads/
  /receipts/{userId}/
  /documents/{userId}/
  /profile/{userId}/
```

---

## DEPLOYMENT CHECKLIST

### Phase 1: Critical Fixes (Can Deploy Immediately)
- [x] Profile save functionality (Items #1, #2)
- [x] Hide financials from workers (Item #4, partial)
- [ ] Landing page text change (Item #15)
- [ ] Terms update (Item #16)

### Phase 2: Database Migration Required
- [ ] Run migration 009_add_company_info_to_users.sql
- [ ] Update backend profile endpoint
- [ ] Implement company settings page (Item #3)
- [ ] Company branding on signup (Item #10)
- [ ] Use company logo everywhere (Item #11)

### Phase 3: New Features
- [ ] Geofence time tracking (Item #9)
- [ ] Timesheet approval system (Item #5)
- [ ] Worker notifications (Item #12)
- [ ] Long receipt scanner (Item #14)

### Phase 4: Bug Fixes & Polish
- [ ] Image preview fixes (Item #6)
- [ ] Document upload fixes (Item #7)
- [ ] Direct deposits (Item #8)
- [ ] Payment screen fix (Item #17)
- [ ] Quick actions UI (Item #18)

---

## ESTIMATED TIME

- ✅ Completed: Items #1, #2 (2 hours)
- 🔄 In Progress: Item #4 (1 hour remaining)
- Phase 1 remaining: 1 hour
- Phase 2: 6-8 hours
- Phase 3: 16-20 hours
- Phase 4: 8-10 hours

**Total Remaining**: ~30-40 hours of development work
