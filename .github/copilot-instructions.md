# SiteLedger AI Coding Instructions

## Project Overview
SiteLedger is a **multi-platform contractor management system** with three distinct client applications sharing a unified PostgreSQL backend:
- **iOS native app** (Swift/SwiftUI) - Full-featured mobile client
- **Next.js web app** (TypeScript/React) - Browser-based dashboard
- **Node.js/Express backend** - REST API with PostgreSQL on DigitalOcean

## ⚠️ Production-First Development Philosophy
**Critical:** All code committed to this repository must be production-ready. This is not a development/staging environment - every commit can be deployed immediately to live users.

- **No placeholder code** - All features must be fully functional
- **Security by default** - Input validation, error handling, and logging are mandatory
- **User-facing errors** - All error messages must be clear and actionable for users
- **No debug artifacts** - No `console.log()` in backend, no `alert()` in web, controlled `#if DEBUG` in iOS
- **Test before commit** - Manually verify all user flows affected by your changes

See `PRODUCTION_READINESS_COMPLETE.md` for the complete checklist.

## Critical Architecture Patterns

### Backend API Structure
- **Base URL:** `https://api.siteledger.ai/api` (production DigitalOcean server)
- **Auth:** JWT tokens via `Authorization: Bearer <token>` header
- **Database:** PostgreSQL with SQL helper functions for profit calculations
  - Key functions: `calculate_job_profit()`, `calculate_job_labor_cost()`, `calculate_effective_hours()`
  - Located in `backend/src/database/schema.sql`
- **Migrations:** Use numbered SQL files in `backend/migrations/` (e.g., `007_update_ai_insights_structure.sql`)
- **Routes:** Modular Express routers in `backend/src/routes/` with middleware layering:
  ```javascript
  router.post('/endpoint', authenticate, requirePermission('canDoThing'), validationMiddleware, handler);
  ```

### iOS App (Swift/SwiftUI)
- **Service Layer:** All API calls go through `APIService.shared` (actor-based for thread safety)
- **Architecture:** MVVM with `@StateObject` ViewModels and `@EnvironmentObject` for AuthService
- **State Management:** ViewModels use `@Published` properties, cleared on sign-out via NotificationCenter
- **Auth Flow:** JWT tokens stored in UserDefaults at key `api_access_token`
- **Health Checks:** Background task every 30 seconds in `SiteLedgerApp.swift`

### Web App (Next.js 14)
- **Data Fetching:** TanStack Query (React Query) with 5-minute cache, retry-once policy in `components/providers.tsx`
- **API Client:** Singleton `APIService.shared` in `lib/api.ts` mirrors iOS structure exactly
- **Auth:** `AuthService` in `lib/auth.ts` manages localStorage tokens
- **Toast System:** Use `toast` from `lib/toast.ts` (react-hot-toast wrapper) - **NEVER use `alert()`**
  - Success: `toast.success('Message')` (green, 3s)
  - Error: `toast.error('Message')` (red, 4s)
- **Page Auth:** Check `AuthService.isAuthenticated()` in `useEffect` before rendering protected content

## Role-Based Access Control (RBAC)
- **Roles:** `owner` (full access) and `worker` (limited by permissions)
- **Worker Permissions:** JSONB column `worker_permissions` in `users` table controls:
  - `canViewFinancials`, `canUploadReceipts`, `canApproveTimesheets`, `canSeeAIInsights`, `canViewAllJobs`
- **Middleware:** Use `requirePermission('permissionName')` in backend routes
- **Frontend:** Check `user.workerPermissions` before rendering UI elements

## Key Business Logic
- **Profit Calculation:** `projectValue - laborCost - receiptExpenses`
  - Labor cost: Sum of `timesheet.hours * worker.hourlyRate`
  - Receipt expenses: Sum of all receipt amounts for job
  - Calculated real-time in frontend OR via PostgreSQL functions in backend
- **Job Status:** `active`, `completed`, `on_hold` (enum type)
- **Timesheet Status:** `working` (clocked in), `completed`, `flagged`

## Development Workflows

### Backend Development
```bash
cd backend
npm run dev              # Start with nodemon (auto-reload)
npm run migrate          # Run database schema/migrations
npm run seed             # Seed demo data (if available)
```

### Web Development
```bash
cd web
npm run dev              # Start Next.js dev server on port 3000
npm run build            # Production build (requires 4GB RAM)
npm start                # Start production server on port 3001
```

### iOS Development
- Open `SiteLedger.xcodeproj` in Xcode
- Requires iOS 17+ (set in `Package.swift`)
- **API Key Setup:** Configure via `APIKeyManager.shared.configure()` on app launch

### Production Deployment
Use deployment scripts from project root:
```bash
./deploy-all.sh         # Deploy both backend + web (3-4 min)
./deploy-backend.sh     # Backend only (1 min)
./deploy-web.sh         # Web only (2-3 min)
```
- **Infrastructure:** DigitalOcean droplet (4GB RAM required for Next.js builds)
- **Process Manager:** PM2 manages both backend and web processes
- **Logs:** `ssh root@68.183.25.130 "pm2 logs <service-name> --lines 50"`

## Code Conventions

### Logging
- **Backend:** Use Winston logger from `config/logger.js`
  ```javascript
  logger.info('Operation succeeded', { userId, jobId });
  logger.error('Operation failed', { error: err.message });
  ```
- **iOS:** Use `#if DEBUG` print statements for development
- **Web:** Console logs acceptable (no production logging infrastructure yet)

### Error Handling
- **Backend:** Return JSON errors with appropriate HTTP status codes
  ```javascript
  res.status(400).json({ error: 'User-friendly message' });
  ```
- **Web:** Use try-catch with toast notifications:
  ```typescript
  try {
    await APIService.someAction();
    toast.success('Action completed');
  } catch (error) {
    toast.error(error.message || 'Something went wrong');
  }
  ```
- **iOS:** Use Swift's native error handling with user-facing error messages

### API Response Formats
All backend responses follow consistent patterns:
- **Success (single):** `{ user: {...}, jobs: [...] }` (snake_case in DB, camelCase in API)
- **Success (list):** `{ jobs: [...], total: 42 }`
- **Error:** `{ error: "Message" }` or `{ errors: [{msg, param}] }` (express-validator)

### File Uploads
- **Storage:** DigitalOcean Spaces (S3-compatible) at `SPACES_ENDPOINT`
- **Multer:** Used in backend for multipart/form-data handling
- **Routes:** `/api/upload` handles file uploads, returns CDN URLs

## Testing & Quality

### Production Readiness Requirements
**ALL code must be production-ready before committing.** Reference `PRODUCTION_READINESS_COMPLETE.md` for checklist:
- ✅ Error handling with user-friendly messages
- ✅ Input validation (express-validator on backend, client-side validation on frontend)
- ✅ Security headers (Helmet.js configured in backend)
- ✅ Rate limiting on API endpoints
- ✅ Logging with Winston (structured JSON logs)
- ✅ No `console.log` in production code (use `logger` in backend)
- ✅ No `alert()` in web app (use `toast.success()` or `toast.error()`)
- ✅ Proper loading states and error boundaries in React
- ✅ Database queries use parameterized statements (SQL injection protection)
- ✅ JWT tokens validated with algorithm whitelist
- ✅ File uploads validated (type, size, malware scanning)

### Testing Strategy
- **Unit Tests:** Limited coverage - see `SiteLedger Tests/` for iOS examples
- **E2E Testing:** Plan exists in `E2E_TESTING_PLAN.md` but not fully implemented
- **Manual Testing:** Primary QA method - test all user flows before deployment
- **Production Monitoring:** Winston logs + PM2 process monitoring

### Code Review Standards
- All changes must be deployable to production immediately
- No WIP commits - features should be complete and tested
- Follow existing patterns (MVVM for iOS, React Query for web, Express middleware for backend)
- Security-first: validate inputs, sanitize outputs, check permissions

### Known Migration/Fix Documents
Reference these for understanding recent changes:
- `ALERT_TO_TOAST_MIGRATION.md` - Toast notification system migration (completed)
- `ERROR_HANDLING_COMPLETE.md` - Error handling strategy
- `PRODUCTION_READINESS_COMPLETE.md` - Production hardening checklist
- `WEB_ACCESSIBILITY_FIXES_COMPLETE.md` - Accessibility improvements

## External Dependencies

### Backend Services
- **Infrastructure:** DigitalOcean droplet with 4GB RAM (required for Next.js builds)
- **Database:** DigitalOcean Managed PostgreSQL (connection via `DATABASE_URL`)
- **Storage:** DigitalOcean Spaces (S3-compatible, credentials in `.env`)
- **AI/ML:** OpenRouter API with `meta-llama/llama-3.3-70b-instruct:free` model
  - Used for AI insights generation in `backend/src/services/ai-insights.js`
  - Base URL: `https://openrouter.ai/api/v1`
  - API key in `OPENROUTER_API_KEY` env var
- **OCR Service:** OCR.space API for receipt scanning/parsing
  - Used in `backend/src/services/ocr-service.js`
  - API key in `OCR_SPACE_API_KEY` env var
- **Email:** Brevo (formerly Sendinblue) for transactional emails
  - SMTP relay for system emails (password resets, notifications)
  - Credentials: `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS` in `.env`
  - Verified sender: `siteledger@siteledger.ai`
  - See `backend/EMAIL_SETUP.md` for configuration details
- **Apple Sign-In:** `apple-signin-auth` package (private key in `apple-private-key.p8`)
  - Team ID, Key ID, Client ID configured in `.env`

### Key NPM Packages
- **Backend:** express, pg (PostgreSQL), bcryptjs, jsonwebtoken, winston, multer, aws-sdk (for Spaces), nodemailer (Brevo)
- **Web:** next@14, @tanstack/react-query, axios, react-hot-toast, lucide-react (icons)

## Common Pitfalls

1. **Don't use `alert()` in web app** - Always use `toast.success()` or `toast.error()` (see `ALERT_TO_TOAST_MIGRATION.md`)
2. **Don't use `console.log` in backend** - Use `logger.info()`, `logger.error()`, etc. from Winston
3. **Remember API URL differences** - Backend uses `/api` prefix, iOS/web clients include it in base URL
4. **Worker permissions checks** - Always verify RBAC before allowing sensitive operations
5. **Database migrations** - Create numbered migration files, don't modify `schema.sql` directly after initial setup
6. **JWT token lifecycle** - Tokens stored in UserDefaults (iOS) and localStorage (web), cleared on logout
7. **Real-time calculations** - Profit/cost calculations happen in frontend OR via PostgreSQL functions, keep them consistent
8. **File paths in production** - Use environment variables for file storage paths, never hardcode
9. **Production readiness** - All code must be production-ready: error handling, validation, logging, security
10. **Rate limiting** - API endpoints have rate limits configured - design for graceful degradation
11. **Email verification** - All email senders must be verified in Brevo before sending
12. **4GB RAM requirement** - DigitalOcean droplet needs 4GB RAM for Next.js builds to succeed

## Quick Reference

### Add New Route
1. Create file in `backend/src/routes/your-feature.js`
2. Import and mount in `backend/src/index.js`: `app.use('/api/your-feature', yourFeatureRoutes);`
3. Add auth middleware: `router.get('/', authenticate, handler);`
4. Update iOS `APIService.swift` and web `lib/api.ts` with new method

### Add New Database Table
1. Add table definition to `backend/migrations/00X_description.sql`
2. Run migration: `cd backend && npm run migrate`
3. Update TypeScript types in `web/types/` if needed
4. Add corresponding Swift model in `SiteLedger/Models/` if needed

### Debug Connection Issues
- Backend health: `curl https://api.siteledger.ai/health`
- Check PM2 status: `ssh root@68.183.25.130 "pm2 status"`
- View logs: `ssh root@68.183.25.130 "pm2 logs siteledger-api --lines 100"`
