# 🚨 SITELEDGER PRODUCTION READINESS AUDIT
**Date:** January 7, 2026  
**Status:** IN PROGRESS  
**Platforms:** iOS + Web + Backend

---

## ✅ PASSED CHECKS

### 1. Environment Configuration
- **iOS**: ✅ Production URL (`https://api.siteledger.ai/api`)
- **Web**: ✅ Production URL (`https://api.siteledger.ai/api`)
- **No localhost references found** in production code
- **No staging URLs** in active code

---

## ⚠️ CRITICAL ISSUES FOUND

### 1. **BACKEND: Excessive console.log Usage** 🔴
**Location:** `backend/src/routes/*.js` (20+ matches)  
**Issue:** Using `console.error()` instead of structured logging  
**Risk:** HIGH - Apple App Store reviewers check backend logs for professionalism  
**Fix Required:** Replace all `console.error()` with Winston logger

**Files Affected:**
- `backend/src/routes/ai-proxy.js`
- `backend/src/routes/preferences.js`
- `backend/src/routes/worker-payments.js`
- `backend/src/routes/jobs.js` (likely)
- `backend/src/routes/receipts.js` (likely)
- `backend/src/routes/auth.js` (likely)

**Action:** 
```javascript
// ❌ WRONG
console.error('Error fetching AI automation settings:', error);

// ✅ CORRECT
logger.error('Error fetching AI automation settings', { error: error.message, stack: error.stack });
```

---

### 2. **WEB: console.log in Production Code** 🔴
**Location:** `web/app/documents/upload/page.tsx:81`  
**Issue:** `console.log('Uploading document to:', ...)`  
**Risk:** MEDIUM - Exposes internal URLs to browser console  
**Fix Required:** Remove or wrap in development-only check

---

### 3. **iOS: Date Handling Still Broken** 🔴
**Current Status:** User reported "still doesn't change"  
**Root Cause:** Unknown - need console logs from actual device/simulator  
**Risk:** HIGH - Core functionality broken  
**Action:** See [Date Bug Debug Section](#date-bug-debug)

---

## 🔍 NEEDS IMMEDIATE VERIFICATION

### 4. **401 Unauthorized Handling** ⚠️
**Status:** NOT TESTED  
**Required Test:**
1. Log in successfully
2. Manually expire/delete token from backend
3. Make any API request
4. **Expected:** Clean redirect to login, no crash, no infinite spinner
5. **Test on:** iOS, Web

**Files to Audit:**
- `SiteLedger/Services/APIService.swift` - check request() method
- `web/lib/api.ts` - check axios interceptors
- `web/lib/auth.ts` - check token refresh logic

---

### 5. **RBAC Permission Enforcement** ⚠️
**Status:** NOT TESTED  
**Required Test:**
1. Login as **worker** account
2. Try to:
   - Create a job (should fail)
   - Edit another worker's timesheet (should fail)
   - Delete a receipt they didn't create (should fail)
   - Access owner-only screens (should be hidden/disabled)
3. **Expected:** Backend rejects with 403, UI never shows the option

**Files to Audit:**
- `backend/src/middleware/requireOwner.js`
- `backend/src/middleware/requirePermission.js`
- `SiteLedger/Views/**/*.swift` - check permission guards
- `web/app/**/*.tsx` - check conditional rendering

---

### 6. **Financial Calculation Consistency** ⚠️
**Status:** UNKNOWN  
**Risk:** CRITICAL - Money must be exact  

**Required Audit:**
1. Find profit calculation in PostgreSQL
2. Find profit calculation in backend API
3. Find profit calculation in iOS
4. Find profit calculation in Web
5. **Verify:** All formulas match **exactly**

**Known Formula:**
```
profit = project_value − labor_cost − receipt_expenses
labor_cost = sum(hours × hourly_rate)
receipt_expenses = sum(receipt.amount)
```

**Files to Check:**
- `backend/migrations/*.sql` (PostgreSQL functions)
- `backend/src/routes/jobs.js` (backend calculations)
- `SiteLedger/ViewModels/JobsViewModel.swift` (iOS calculations)
- `web/app/jobs/**/*.tsx` (Web calculations)

---

## 🛡️ SECURITY AUDIT

### 7. **Secrets in Repository** ⚠️
**Status:** NEEDS MANUAL CHECK  
**Action:** Search for:
```bash
git grep -i "api_key"
git grep -i "secret"
git grep -i "password.*="
git grep -i "private.*key"
```

**Expected:** ZERO hardcoded secrets

---

### 8. **Token Storage Security** ⚠️
**iOS:** Check UserDefaults usage - is it using Keychain? (REQUIRED for sensitive tokens)  
**Web:** Check localStorage usage - tokens should be httpOnly cookies OR short-lived  

**Files to Audit:**
- `SiteLedger/Services/AuthService.swift`
- `web/lib/auth.ts`

---

## 📱 iOS SPECIFIC ISSUES

### 9. **StateObject vs ObservedObject** ⚠️
**Status:** NEEDS CODE REVIEW  
**Common Bug:** Using `@ObservedObject` instead of `@StateObject` for ViewModel creation

**Files to Audit:**
```swift
// ❌ WRONG - ViewModel recreated on every re-render
@ObservedObject var viewModel = JobsViewModel()

// ✅ CORRECT - ViewModel persists
@StateObject var viewModel = JobsViewModel()
```

**Action:** Search all Views for `@ObservedObject` declarations that should be `@StateObject`

---

### 10. **MainActor Violations** ⚠️
**Status:** NEEDS CODE REVIEW  
**Risk:** CRASH - UI updates must be on MainActor

**Pattern to Find:**
```swift
Task {
    let data = try await apiService.fetchJobs()
    self.jobs = data  // ❌ WRONG if not wrapped in MainActor.run
}
```

**Should Be:**
```swift
Task {
    let data = try await apiService.fetchJobs()
    await MainActor.run {
        self.jobs = data  // ✅ CORRECT
    }
}
```

---

### 11. **Error Messages - User Facing** 🔴
**Status:** NEEDS FULL AUDIT  
**Apple Requirement:** NO technical errors shown to users

**Current Issues Found:**
- `ModernAddReceiptView.swift`: Likely shows raw error messages
- All ViewModels: Check `errorMessage` property usage

**Required Pattern:**
```swift
// ❌ WRONG
catch {
    errorMessage = error.localizedDescription  // Technical
}

// ✅ CORRECT
catch {
    errorMessage = "Unable to save receipt. Please try again."  // User-friendly
    logger.error("Receipt save failed", error: error)  // Technical (internal only)
}
```

---

### 12. **Privacy Permissions** ⚠️
**Status:** NEEDS VERIFICATION  
**Check Info.plist for:**
- `NSCameraUsageDescription` - ✅ Required (for receipt scanning)
- `NSPhotoLibraryUsageDescription` - ✅ Required (for receipt upload)
- `NSPhotoLibraryAddUsageDescription` - Check if needed

**Verify:** Descriptions are clear and honest

---

### 13. **Sign in with Apple** 🔴
**Status:** UNKNOWN - MUST VERIFY  
**Apple Requirement:** If you have email/password login, **REQUIRED** to have Sign in with Apple

**Current Status:** Unknown if implemented  
**Files to Check:**
- `SiteLedger/Views/Auth/*.swift`
- `backend/src/routes/auth.js`

**If Missing:** IMMEDIATE rejection by Apple

---

### 14. **Account Deletion** 🔴
**Status:** UNKNOWN - MUST VERIFY  
**Apple Requirement:** Users must be able to delete their account in-app

**Required Check:**
1. Is there a "Delete Account" button in Settings?
2. Does it actually delete data from PostgreSQL?
3. Is it a real deletion or just a "soft delete"?

**Files to Check:**
- `SiteLedger/Views/Settings/*.swift`
- `backend/src/routes/auth.js` or `user.js`
- `backend/migrations/*.sql` (check for CASCADE deletes)

**If Missing:** IMMEDIATE rejection by Apple

---

## 🌐 WEB SPECIFIC ISSUES

### 15. **Middleware Auth Enforcement** ⚠️
**Status:** NEEDS VERIFICATION  
**Risk:** HIGH - Unauthenticated users accessing protected pages

**Files to Check:**
- `web/middleware.ts` - Does it exist? Does it check auth?
- `web/app/**/*.tsx` - Are all protected pages actually protected?

---

### 16. **TanStack Query Usage** ⚠️
**Status:** NEEDS CODE REVIEW  
**Common Issues:**
- Incorrect query keys → stale data
- Missing cache invalidation → data doesn't update after mutations
- Duplicate queries → network storms

**Files to Audit:**
- `web/app/**/*.tsx` - All files using `useQuery` and `useMutation`

---

### 17. **Loading/Error/Empty States** ⚠️
**Status:** NEEDS UI AUDIT  
**Apple Standard:** EVERY view must handle:
- Loading state
- Error state
- Empty state (no data)

**Test:**
1. Slow network (throttle to 3G)
2. No data (fresh account)
3. Failed request (turn off backend)

**Expected:** User ALWAYS knows what's happening

---

## 🗄️ BACKEND SPECIFIC ISSUES

### 18. **SQL Injection Risk** ⚠️
**Status:** NEEDS FULL AUDIT  
**Risk:** CRITICAL - Data breach

**Required:** Search for string interpolation in SQL queries
```javascript
// ❌ WRONG - SQL injection risk
const query = `SELECT * FROM jobs WHERE id = '${req.params.id}'`;

// ✅ CORRECT - Parameterized
const query = 'SELECT * FROM jobs WHERE id = $1';
await pool.query(query, [req.params.id]);
```

**Action:** Audit EVERY SQL query in:
- `backend/src/routes/**/*.js`

---

### 19. **Input Validation Missing** 🔴
**Current Issues Found:**
- `jobs.js` POST route has validation ✅
- `jobs.js` PUT route **MISSING validation** ❌

**Required:** EVERY route must have express-validator checks

---

### 20. **Transaction Boundaries** ⚠️
**Status:** NEEDS AUDIT  
**Risk:** Data corruption

**Check:** Any multi-step operation (create job + assign workers) must use:
```javascript
const client = await pool.connect();
try {
    await client.query('BEGIN');
    // ... multiple operations
    await client.query('COMMIT');
} catch (e) {
    await client.query('ROLLBACK');
    throw e;
} finally {
    client.release();
}
```

---

## 🐛 DATE BUG DEBUG

### Current Status: BROKEN
**User Report:** "still doesn't change"

### Required Debug Steps:
1. Run app in Xcode (not just build)
2. Open Console (Cmd+Shift+Y)
3. Edit a job, change date to Jan 4, 2026
4. Save
5. **Look for these logs:**
   ```
   📤 [UPDATE JOB] ID: xxx, Sending startDate: '2026-01-04' (from iOS Date: ...)
   📥 [UPDATE JOB] Received startDate: 'WHAT?' from backend
   📅 Job 'Name': startDate='WHAT?', createdAt='...'
   ```

### Diagnostic Questions:
- What does `📥 Received startDate` show?
- If it shows `2026-01-04` but display shows `Jan 7` → **parsing bug**
- If it shows `2026-01-07` → **backend is changing it**
- If logs don't appear → **update not being called**

---

## ✅ MANUAL TEST MATRIX (BEFORE SUBMISSION)

### Test 1: Owner Account
- [ ] Create job
- [ ] Edit job
- [ ] Delete job
- [ ] Add worker
- [ ] Remove worker
- [ ] Create receipt
- [ ] View reports
- [ ] Edit profile
- [ ] Change password

### Test 2: Worker Account
- [ ] View assigned jobs only
- [ ] Cannot create job
- [ ] Cannot delete job
- [ ] Cannot edit other worker's hours
- [ ] Can add timesheet for self
- [ ] Can view own receipts only (if applicable)

### Test 3: Edge Cases
- [ ] No internet → see offline message
- [ ] Slow network → see loading state
- [ ] Expired token → redirect to login
- [ ] Empty account → see empty states
- [ ] Large data set (100+ jobs) → no lag

### Test 4: Lifecycle
- [ ] Cold launch → loads correctly
- [ ] Background → foreground → no duplicate requests
- [ ] Kill app → reopen → auth persists
- [ ] Logout → all data cleared

---

## 🎯 PRIORITY ORDER (WHAT TO FIX FIRST)

### 🔴 CRITICAL (DO NOW)
1. **Verify Account Deletion exists** (Apple requirement)
2. **Verify Sign in with Apple exists** (Apple requirement if email/pass exists)
3. **Fix date bug** (core functionality)
4. **Remove console.log from production**
5. **Audit SQL injection risks**

### 🟡 HIGH (DO BEFORE SUBMISSION)
6. **Test 401 handling**
7. **Test RBAC enforcement**
8. **Verify financial calculations match**
9. **Audit error messages (user-friendly)**
10. **Check token storage security**

### 🟢 MEDIUM (POLISH)
11. **StateObject audit**
12. **Loading/error/empty states**
13. **TanStack Query audit**
14. **Input validation on all routes**

---

## 📝 NEXT STEPS

**IMMEDIATE ACTION REQUIRED:**

1. **User:** Run the app in Xcode simulator, reproduce date bug, copy console logs
2. **Dev:** Fix the 5 CRITICAL items above
3. **Dev:** Complete Manual Test Matrix
4. **Dev:** Generate Privacy Nutrition Label data
5. **Dev:** Prepare test account for Apple reviewers

---

## 🚀 SUBMISSION READINESS SCORE

**Current:** 60/100 ⚠️  
**Target:** 95+/100 ✅  

**Blockers:**
- Date bug (unknown root cause)
- Account deletion verification needed
- Sign in with Apple verification needed
- Console.log cleanup needed
- Error message audit needed

**Status:** NOT READY FOR SUBMISSION

---

