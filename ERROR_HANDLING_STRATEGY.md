# Error Handling & User Feedback Strategy
**Date:** December 25, 2025  
**Status:** In Progress  

---

## Current State Analysis

### What We Have ✅
1. **Basic Error Catching** - Try/catch blocks in all async operations
2. **User Notifications** - `alert()` for errors (functional but basic)
3. **Form Validation** - Client-side validation with error states
4. **HTTP Error Handling** - Axios interceptors catch API errors
5. **Silent Failures** - Graceful degradation when optional features fail

### What's Missing 🟡
1. **Toast Notifications** - Professional, non-blocking notifications
2. **Error Tracking** - No Sentry or error monitoring service
3. **Structured Logging** - No centralized logging on backend
4. **Error Boundaries** - No React error boundaries for catastrophic failures
5. **User-Friendly Messages** - Some technical errors exposed to users

---

## Implementation Plan

### Phase 1: Toast Notifications (Quick Win) ✅
**Goal:** Replace alert() with professional toast notifications  
**Tool:** react-hot-toast (lightweight, 3KB)  
**Timeline:** 30 minutes

**Benefits:**
- ✅ Non-blocking (users can dismiss or ignore)
- ✅ Multiple toasts can stack
- ✅ Styled to match app theme
- ✅ Auto-dismiss after timeout
- ✅ Position customizable

**Implementation:**
```bash
cd web && npm install react-hot-toast
```

**Usage:**
```typescript
import toast from 'react-hot-toast';

// Success
toast.success('Job created successfully!');

// Error
toast.error('Failed to create job. Please try again.');

// Loading with promise
toast.promise(
  APIService.createJob(data),
  {
    loading: 'Creating job...',
    success: 'Job created!',
    error: 'Failed to create job'
  }
);
```

---

### Phase 2: Error Tracking with Sentry (Recommended)
**Goal:** Track production errors automatically  
**Tool:** Sentry (@sentry/nextjs, @sentry/react-native)  
**Timeline:** 1-2 hours setup  
**Cost:** Free tier (5K events/month)

**Benefits:**
- ✅ Automatic error capture
- ✅ Stack traces and breadcrumbs
- ✅ User context (email, ID)
- ✅ Performance monitoring
- ✅ Release tracking
- ✅ Email alerts on errors

**Setup:**
```bash
# Web
npm install @sentry/nextjs --save

# Initialize
npx @sentry/wizard -i nextjs

# iOS (if needed)
# Add Sentry to Swift Package Manager
```

**Configuration:**
```typescript
// sentry.client.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
  beforeSend(event, hint) {
    // Filter out sensitive data
    return event;
  }
});
```

---

### Phase 3: Error Boundaries (Safety Net)
**Goal:** Catch React rendering errors gracefully  
**Implementation:** Next.js error.tsx files  
**Timeline:** 30 minutes

**Files to Create:**
1. `app/error.tsx` - Global error boundary
2. `app/jobs/error.tsx` - Jobs section error boundary
3. `app/receipts/error.tsx` - Receipts section error boundary

**Example:**
```typescript
// app/error.tsx
'use client';

import { useEffect } from 'react';
import * as Sentry from '@sentry/nextjs';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <div className="text-center">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
          Something went wrong!
        </h2>
        <p className="text-gray-600 dark:text-gray-400 mb-6">
          We've been notified and are working on a fix.
        </p>
        <button
          onClick={reset}
          className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          Try again
        </button>
      </div>
    </div>
  );
}
```

---

### Phase 4: Structured Backend Logging
**Goal:** Centralized logging for debugging  
**Tool:** Winston or Pino  
**Timeline:** 1-2 hours

**Example (Winston):**
```javascript
// backend/src/utils/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple(),
  }));
}

module.exports = logger;
```

**Usage:**
```javascript
const logger = require('./utils/logger');

app.post('/api/jobs', async (req, res) => {
  try {
    // ...
    logger.info('Job created', { userId: req.user.id, jobId: job.id });
  } catch (error) {
    logger.error('Failed to create job', { 
      error: error.message, 
      stack: error.stack,
      userId: req.user.id 
    });
    res.status(500).json({ error: 'Failed to create job' });
  }
});
```

---

### Phase 5: Form Validation Improvements
**Goal:** Better inline validation feedback  
**Current:** Basic validation, setErrors state  
**Enhancement:** Real-time validation with debouncing

**Example:**
```typescript
// Custom validation hook
import { useState, useEffect } from 'react';
import { useDebouncedValue } from './useDebounce';

export function useFormValidation(formData, rules) {
  const [errors, setErrors] = useState({});
  const debouncedData = useDebouncedValue(formData, 300);

  useEffect(() => {
    const newErrors = {};
    Object.keys(rules).forEach(field => {
      const error = rules[field](debouncedData[field]);
      if (error) newErrors[field] = error;
    });
    setErrors(newErrors);
  }, [debouncedData]);

  return errors;
}
```

---

## Priority Ranking

### High Priority (Must Have) 🔴
1. ✅ **Toast Notifications** - Replace alert() immediately
2. 🟡 **Error Boundaries** - Safety net for production
3. 🟡 **Basic Error Tracking** - At minimum, log to backend

### Medium Priority (Should Have) 🟡
4. **Sentry Integration** - Professional error tracking
5. **Structured Logging** - Backend Winston/Pino setup
6. **User-Friendly Error Messages** - Review all error text

### Low Priority (Nice to Have) 🟢
7. **Advanced Form Validation** - Real-time with debouncing
8. **Retry Logic** - Auto-retry failed requests
9. **Offline Mode** - Service worker for PWA

---

## Error Message Guidelines

### DO ✅
- **User-Friendly:** "Failed to create job. Please try again."
- **Actionable:** "Unable to upload file. Check your internet connection."
- **Specific:** "Email address is already registered."
- **Positive:** "Job saved as draft" (instead of "Failed to publish")

### DON'T ❌
- **Technical Jargon:** "500 Internal Server Error"
- **Stack Traces:** "TypeError: Cannot read property 'id' of undefined"
- **Vague:** "Something went wrong"
- **Blame User:** "You entered invalid data"

### Examples

**Bad:** `alert('Error: 401 Unauthorized')`  
**Good:** `toast.error('Your session has expired. Please sign in again.')`

**Bad:** `alert(error.message)` (shows raw error)  
**Good:** `toast.error('Unable to load jobs. Please refresh the page.')`

**Bad:** `alert('Success')`  
**Good:** `toast.success('Job created successfully!', { icon: '✅' })`

---

## Implementation Status

### Completed ✅
- Basic try/catch error handling
- Form validation with error states
- Silent graceful degradation
- HTTP error catching with axios

### In Progress 🟡
- Toast notifications (this document)
- Error tracking setup guide
- Error boundary templates

### Not Started ⏸️
- Sentry integration
- Backend structured logging
- Advanced form validation

---

## Next Steps

1. **Install react-hot-toast** (5 min)
2. **Create toast utility wrapper** (10 min)
3. **Replace alert() calls throughout app** (30 min)
4. **Test toast notifications** (15 min)
5. **Document Sentry setup** (for later)
6. **Create error boundary templates** (30 min)

**Total Estimated Time:** 2-3 hours for full implementation

---

**Status:** Ready to implement toast notifications  
**Blocker:** None - all dependencies available  
**Risk:** Low - react-hot-toast is stable and well-tested
