# SiteLedger Production Readiness Audit
**Date:** December 25, 2025  
**Status:** In Progress

---

## 🔍 Audit Summary

### Web App Issues Found
1. **Accessibility Issues** (Critical for production)
   - Missing labels on form inputs (multiple pages)
   - Missing aria-labels on buttons and selects
   - Inline styles in production code

2. **Debug Code** (Should be removed)
   - Console.log/error statements throughout codebase
   - Should be replaced with proper error tracking

3. **Browser Compatibility**
   - `text-wrap: balance` not supported in Chrome < 114

### iOS App Issues Found
1. **Debug Statements**
   - Numerous print() statements throughout codebase
   - Should be removed or wrapped in conditional compilation

2. **TODO/FIXME Items**
   - Receipt deletion verification (TODO in ReceiptOperationsTests.swift)

### Backend Issues Found
1. **Error Handling**
   - Some routes have generic error messages
   - Need more specific user-facing error messages

---

## 📋 Detailed Findings

### WEB APP

#### Accessibility Violations (Critical)
**Impact:** Fails WCAG standards, app store rejection risk

**Files Affected:**
- `/web/app/jobs/page.tsx:150` - Select missing accessible name
- `/web/app/jobs/create/page.tsx` - Multiple issues:
  - Line 66: Button missing title
  - Line 177: Input missing label
  - Line 188: Input missing label
  - Line 145: Select missing name
- `/web/app/timesheets/create/page.tsx` - Multiple issues:
  - Line 91: Button missing title
  - Line 149: Input missing label
  - Lines 109, 129: Selects missing names
- `/web/app/documents/upload/page.tsx` - Multiple issues
- `/web/app/jobs/[id]/page.tsx` - Buttons and inline styles
- `/web/app/settings/ai-thresholds/page.tsx` - Form inputs missing labels
- `/web/app/settings/roles/page.tsx:155` - Button missing title
- `/web/app/settings/export/page.tsx` - Inputs missing labels
- `/web/app/receipts/[id]/page.tsx:118` - Button missing title
- `/web/app/timesheets/clock/page.tsx:250` - Select missing name

#### Debug Code (Should Remove)
All `console.log` and `console.error` statements should be removed or replaced with proper error tracking service.

**Files with console statements:**
- Multiple files in `/web/app/**/*.tsx`

#### CSS Compatibility
- `/web/app/globals.css:50` - `text-wrap: balance` not supported in Chrome < 114

---

### iOS APP

#### Debug Statements (Should Remove)
All `print()` statements should be removed or wrapped in `#if DEBUG` blocks.

**Files with print statements:**
- `SiteLedger/Services/APIKeyManager.swift` - Multiple debug prints
- `SiteLedger/Services/AuthService.swift` - Apple Sign-In debug prints
- `SiteLedger/Models/Job.swift` - Decoding debug print
- Many other files throughout the app

#### Incomplete Features
- Receipt deletion verification (noted in tests)

---

### BACKEND

#### Error Messages
Some error messages are too generic. Need to review all routes for user-friendly error messages.

---

## ✅ Recommended Fixes

### Priority 1: Critical (Must Fix)
1. **Fix all accessibility violations in web app**
2. **Remove all debug print/console statements**
3. **Test all features end-to-end on both platforms**

### Priority 2: Important (Should Fix)
1. **Add error tracking service (e.g., Sentry)**
2. **Implement proper logging instead of print/console**
3. **Fix CSS compatibility issues**
4. **Complete any TODO items**

### Priority 3: Nice to Have
1. **Add automated accessibility testing**
2. **Add unit tests for critical paths**
3. **Performance optimization**

---

## 🎯 Action Plan

1. ✅ Complete audit (this document)
2. ⏳ Fix web accessibility issues
3. ⏳ Remove debug code from both platforms
4. ⏳ Add proper error tracking
5. ⏳ Test all features
6. ⏳ Final production check

---

## 📊 Progress Tracking

- [ ] Web accessibility fixes
- [ ] iOS debug code cleanup
- [ ] Web debug code cleanup  
- [ ] Error tracking setup
- [ ] Cross-platform feature parity check
- [ ] Performance testing
- [ ] Security audit
- [ ] Final QA pass

