# SiteLedger - AI Agent Instructions

## Project Overview

SiteLedger is a **production-ready multi-platform contractor management system** with iOS (Swift/SwiftUI), Next.js web app, and Node.js/Express backend. Features include job tracking, receipts, timesheets, workers, financial calculations, role-based access control, and AI-powered insights.

**Tech Stack:**
- **iOS:** Swift 5.9, SwiftUI, iOS 17+, Actor-based networking, MVVM architecture
- **Web:** Next.js 14 App Router, TypeScript, React 18, TanStack Query v5, Tailwind CSS, Sentry monitoring
- **Backend:** Node.js 18+/Express, PostgreSQL (DigitalOcean), JWT auth, Winston logging, PM2 process manager
- **Infrastructure:** DigitalOcean (backend + Spaces S3), Vercel (web), Nginx reverse proxy, HTTPS/SSL

**All platforms share:** `https://api.siteledger.ai/api` backend - no Firebase, no local databases!

## Architecture Essentials

### Three-Tier Client-Server Model
```
iOS/Web Client → Express API → PostgreSQL Database
               ↓
          DigitalOcean Spaces (file storage)
```

**Critical Data Flow:**
1. All clients authenticate via JWT (`Authorization: Bearer <token>`)
2. Backend validates token, attaches `req.user` with role (`owner`/`worker`)
3. SQL queries filter by `owner_id` or `worker_id` - **never** return unfiltered data
4. Financial calculations (profit, labor cost) computed in SQL - never client-side
5. Workers see only assigned jobs via `worker_job_assignments` junction table

### Authentication & Authorization
- **Token Storage:** localStorage (web) / UserDefaults (iOS) - loaded on app init
- **Middleware Chain:** `authenticate` → `requireOwner`/role checks → validation → handler
- **Two Roles:**
  - `owner`: Full CRUD on all owned entities
  - `worker`: Read assigned jobs, CRUD own timesheets, permissions in `worker_permissions` JSONB
- **Apple Sign-In:** Supported via `apple-signin-auth` package (see `backend/src/routes/auth.js`)

## Development Patterns by Platform

### iOS (Swift/SwiftUI) - See `SiteLedger/`

**MVVM Structure:**
```
Models/ → Data structs (Codable, mirror backend snake_case)
ViewModels/ → ObservableObjects with @Published state
Views/ → SwiftUI views with @StateObject/@EnvironmentObject
Services/ → Singletons (APIService, AuthService)
```

**APIService Critical Pattern:**
```swift
// APIService is an actor - all calls must be async/await
actor APIService {
    static let shared = APIService()
    private let baseURL = "https://api.siteledger.ai/api"
    
    // Retry logic built-in (maxRetries = 3)
    // Health checks via checkHealth()
    // Token management: setAccessToken(), loadStoredToken()
}

// Usage in ViewModels:
@StateObject private var viewModel = JobsViewModel()

Task {
    await viewModel.fetchJobs() // Calls APIService.shared
}
```

**Key Conventions:**
- Use `@EnvironmentObject var authService: AuthService` for global auth state
- Models use camelCase in code, encode/decode to snake_case for API
- All network calls wrapped in `Task { await ... }` blocks
- App entry: `SiteLedgerApp.swift` starts health checks, initializes services

### Web (Next.js) - See `web/`

**App Router Structure:**
```
app/ → All pages (use 'use client' for interactivity)
components/ → Reusable React components
lib/ → Singletons (api.ts, auth.ts, sentry.ts)
types/models.ts → TypeScript interfaces (match backend)
```

**TanStack Query Pattern:**
```tsx
'use client';
import { useQuery, useMutation } from '@tanstack/react-query';
import APIService from '@/lib/api';

// Query with caching (5min staleTime, 10min gcTime)
const { data: jobs, isLoading } = useQuery({
  queryKey: ['jobs'],
  queryFn: () => APIService.fetchJobs(),
});

// Mutation with cache invalidation
const createMutation = useMutation({
  mutationFn: (data) => APIService.createJob(data),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['jobs'] });
  },
});
```

**Critical Files:**
- `lib/api.ts` - Axios singleton, matches iOS `APIService.swift` exactly
- `lib/auth.ts` - Session management, mirrors iOS `AuthService.swift`
- `lib/sentry.ts` - Error logging wrapper: `logError()`, `logWarning()`, `logInfo()`
- `components/providers.tsx` - TanStack Query config (retry: 1, no refetch on focus)
- `app/layout.tsx` - Theme provider, toast notifications (`react-hot-toast`)

**Key Conventions:**
- Every page: `'use client'` directive at top if uses state/effects
- Auth guard: Check `AuthService.shared.isAuthenticated()` in useEffect, redirect to `/`
- Toasts not alerts: `import toast from 'react-hot-toast'; toast.success('...')`
- Dark mode: Use `dark:` Tailwind classes, theme from `ThemeProvider`

### Backend (Express) - See `backend/`

**Directory Structure:**
```
src/
  index.js → App entry, route registration, middleware setup
  routes/ → Feature routes (jobs.js, auth.js, timesheets.js...)
  middleware/ → auth.js, requestLogger.js
  database/ → schema.sql, migrate.js, db.js (pg pool)
  services/ → spaces.js (DigitalOcean S3)
  config/ → logger.js (Winston)
migrations/ → Numbered SQL files (001_*.sql, 002_*.sql...)
```

**Route Pattern (Critical!):**
```javascript
const { authenticate, requireOwner } = require('../middleware/auth');
const { body, validationResult } = require('express-validator');

router.post('/', authenticate, requireOwner, [
  body('jobName').notEmpty(),
  body('clientName').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  // ALWAYS filter by req.user.id (owner_id)
  const result = await pool.query(
    'INSERT INTO jobs (owner_id, job_name, client_name) VALUES ($1, $2, $3) RETURNING *',
    [req.user.id, req.body.jobName, req.body.clientName]
  );
  
  res.json(result.rows[0]);
});
```

**Financial Calculations (Server-Side Only!):**
```sql
-- Example from backend/src/routes/jobs.js
SELECT 
  j.*,
  COALESCE(
    (SELECT SUM(t.hours * COALESCE(w.hourly_rate, 0))
     FROM timesheets t
     LEFT JOIN users w ON t.worker_id = w.id
     WHERE t.job_id = j.id), 0
  ) as labor_cost,
  COALESCE(
    (SELECT SUM(r.amount) FROM receipts r WHERE r.job_id = j.id), 0
  ) as receipt_expenses
FROM jobs j
WHERE j.owner_id = $1
```

**Logging:**
```javascript
const logger = require('./config/logger');
logger.info('User action', { userId: req.user.id, action: 'created_job' });
logger.error('Database error', { error: err.message, query: 'SELECT...' });
```

## Database & Migrations

**Schema Philosophy:**
- UUIDs for all primary keys (`uuid_generate_v4()`)
- ENUM types for status fields (`job_status`, `user_role`, `alert_severity`)
- JSONB for flexible data (`worker_permissions`, `ai_insights`)
- Timestamps: `created_at`, `updated_at` (both `TIMESTAMP WITH TIME ZONE`)
- Foreign keys with `ON DELETE CASCADE` or `SET NULL`

**Migration Workflow:**
```bash
# Create migration in backend/migrations/
# Format: 003_add_new_feature.sql

# Test locally first
cd backend
psql siteledger < migrations/003_add_new_feature.sql

# Deploy to production
node src/database/migrate.js  # Or npm run migrate
```

**Key Tables:**
- `users` - Both owners and workers, `role` ENUM, `worker_permissions` JSONB
- `jobs` - Owned by users, many-to-many workers via `worker_job_assignments`
- `receipts`, `timesheets`, `documents` - All have `job_id` foreign key
- `worker_payments` - Track payments to workers
- `alerts` - Auto-generated notifications

## Common Development Workflows

### Adding a New API Endpoint
1. **Backend:** Create route in `backend/src/routes/feature.js`
2. **Register:** Add to `backend/src/index.js`: `app.use('/api/feature', featureRoutes)`
3. **iOS:** Add method to `APIService.swift`, create Model if needed
4. **Web:** Add method to `lib/api.ts`, add type to `types/models.ts`
5. **Test:** Use curl/Postman, then integrate into UI

### Deploying Changes
```bash
# Backend (on DigitalOcean droplet)
cd /root/siteledger/backend
git pull
npm install
npm run migrate  # If schema changed
pm2 restart siteledger-backend
pm2 logs siteledger-backend --lines 50

# Web (Vercel auto-deploys on push to main)
git push origin main

# iOS (Xcode)
Archive → Distribute → TestFlight/App Store
```

### Running Tests
```bash
# iOS (Xcode)
Cmd+U or Test Navigator → Run tests
See: SiteLedger Tests/JobsLifecycleTests.swift

# Backend (manual - no test suite yet)
curl -X POST https://api.siteledger.ai/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Web (no test suite - add Vitest if needed)
```

### Debugging Production Issues
```bash
# Check backend logs (Winston + PM2)
pm2 logs siteledger-backend
tail -f backend/logs/error-*.log

# Check Sentry (web errors)
# Dashboard: sentry.io/organizations/.../projects/siteledger-web

# Database queries (DigitalOcean console or psql)
psql $DATABASE_URL
SELECT * FROM jobs WHERE owner_id = '...';
```

## Production Readiness Checklist

**Security:**
- ✅ JWT tokens validated on every request
- ✅ Helmet.js security headers
- ✅ Rate limiting (5000 req/15min)
- ✅ HTTPS/SSL via Nginx
- ✅ CORS restricted to `siteledger.ai` domains
- ✅ SQL injection prevented (parameterized queries)

**Performance:**
- ✅ TanStack Query caching (5min stale, 10min gc)
- ✅ Compression middleware (gzip, level 6)
- ✅ Database indexes on foreign keys
- ✅ Actor-based networking (iOS) prevents race conditions

**Monitoring:**
- ✅ Sentry error tracking (web)
- ✅ Winston logging (backend) - daily rotate, JSON format
- ✅ PM2 process monitoring - auto-restart on crash
- ✅ Health checks: `GET https://api.siteledger.ai/health`

**Accessibility:**
- ✅ Web app WCAG compliant (see `PRODUCTION_READINESS_REPORT.md`)
- ✅ All inputs have labels, buttons have aria-labels
- ✅ Keyboard navigation supported

## Anti-Patterns & Common Mistakes

❌ **Don't filter data client-side** - Always use SQL `WHERE owner_id = $1`
❌ **Don't calculate profit client-side** - Use subqueries in SELECT
❌ **Don't use `alert()`** - Use `toast.error()` (web) or native alerts (iOS)
❌ **Don't bypass authentication** - Every protected route needs `authenticate` middleware
❌ **Don't commit `.env` files** - Use `.env.example` templates
❌ **Don't use Firebase APIs** - Fully migrated to DigitalOcean backend
❌ **Don't hardcode API URLs** - Use `baseURL` constants in APIService
❌ **Don't ignore validation errors** - Check `validationResult(req)` before DB queries

## Key Files for Reference

**Critical Entry Points:**
- `backend/src/index.js` - Express app setup, all routes registered
- `SiteLedger/SiteLedgerApp.swift` - iOS app entry, health checks
- `web/app/layout.tsx` - Next.js root layout, providers

**Data Models:**
- `backend/src/database/schema.sql` - Single source of truth
- `SiteLedger/Models/` - Swift structs (Codable)
- `web/types/models.ts` - TypeScript interfaces

**Authentication:**
- `backend/src/middleware/auth.js` - JWT verification, role checks
- `SiteLedger/Services/AuthService.swift` - iOS session management
- `web/lib/auth.ts` - Web session management

**API Services:**
- `SiteLedger/Services/APIService.swift` - Actor-based, 1209 lines
- `web/lib/api.ts` - Axios singleton, 274 lines

**Deployment:**
- `backend/deploy.sh` - Automated DigitalOcean setup (356 lines)
- `backend/ecosystem.config.js` - PM2 configuration

---

**Updated:** December 25, 2025  
**For questions:** Check `backend/README.md`, `PRODUCTION_READINESS_REPORT.md`, `ERROR_HANDLING_STRATEGY.md`
