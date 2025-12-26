# Performance Optimization Audit 🚀

**Date:** December 25, 2024  
**Status:** 🔄 IN PROGRESS  
**Goal:** Optimize SiteLedger for production performance  

---

## Current Performance Baseline

### Web App (Next.js)
- **Bundle Size:** 87.3 kB First Load JS (good!)
- **Routes:** 39 static routes compiled
- **Build Time:** ~30 seconds
- **Dependencies:** 685 packages

### Backend (Node.js)
- **Dependencies:** 228 packages
- **Server:** Node.js with PM2
- **Database:** PostgreSQL (DigitalOcean)
- **Storage:** DigitalOcean Spaces (S3)

### iOS App (Swift/SwiftUI)
- **Architecture:** MVVM with Actor-based networking
- **Minimum iOS:** 17.0+
- **Image handling:** Direct loading (no compression)

---

## Performance Optimization Areas

### 🎯 Priority 1: Quick Wins (1-2 hours)

#### 1. Image Optimization (Web)
**Current State:**
- Using standard `<img>` tags
- No lazy loading
- No compression
- No next/image optimization

**Optimization:**
- Replace `<img>` with Next.js `<Image>` component
- Enable automatic WebP conversion
- Add lazy loading for off-screen images
- Implement blur placeholder for better UX

**Files to Check:**
- `web/app/jobs/[id]/page.tsx` - Job images
- `web/app/receipts/[id]/page.tsx` - Receipt images
- `web/app/documents/page.tsx` - Document thumbnails
- `web/components/dashboard-layout.tsx` - User avatar

**Expected Impact:** 30-50% reduction in image size

---

#### 2. Code Splitting (Web)
**Current State:**
- All components loaded upfront
- Large AI/OCR libraries loaded even if not used

**Optimization:**
- Dynamic imports for heavy components
- Lazy load AI service
- Lazy load chart libraries (if any)
- Route-based code splitting (already done by Next.js)

**Target Files:**
- `web/lib/ai.ts` - AI service (should be lazy)
- `web/app/receipts/create/page.tsx` - OCR heavy
- `web/app/settings/ai-*` pages - AI features

**Expected Impact:** Faster initial page load

---

#### 3. API Response Caching (Web)
**Current State:**
- TanStack Query enabled (good!)
- Default cache times may be short

**Optimization:**
- Increase staleTime for rarely-changing data (workers, settings)
- Add cache headers on backend
- Implement stale-while-revalidate strategy

**Expected Impact:** Fewer API calls, faster navigation

---

### 🎯 Priority 2: Backend Optimization (2-3 hours)

#### 4. Database Query Optimization
**Current State:**
- No explicit indexes documented
- Complex JOIN queries for financial calculations
- Multiple queries per request

**Optimization:**
- Add indexes on frequently queried columns
- Optimize job profit calculation queries
- Implement query result caching for dashboards

**Target Queries:**
- Job list with labor costs (timesheets JOIN)
- Receipt expenses by job
- Financial dashboard aggregations

**Expected Impact:** 50-70% faster queries

---

#### 5. API Response Compression
**Current State:**
- Unknown if gzip/brotli enabled

**Optimization:**
- Enable compression middleware in Express
- Reduce payload sizes for large lists

**Expected Impact:** 60-80% smaller response sizes

---

#### 6. Backend Caching Layer
**Current State:**
- No caching (every request hits database)

**Optimization:**
- Add Redis for frequently accessed data
- Cache user sessions
- Cache job lists with TTL
- Invalidate on updates

**Expected Impact:** 90% reduction in database load

---

### 🎯 Priority 3: Advanced Optimization (3-4 hours)

#### 7. iOS Image Compression
**Current State:**
- Full-resolution images uploaded
- No client-side compression

**Optimization:**
- Add UIImage compression before upload
- Resize to max 1920px width
- Compress to 80% quality for JPEG

**Expected Impact:** Faster uploads, reduced storage

---

#### 8. API Request Batching
**Current State:**
- Individual requests for related data

**Optimization:**
- Batch job + timesheets + receipts in single request
- GraphQL-style data fetching
- Add `/api/dashboard/summary` endpoint

**Expected Impact:** Fewer round trips

---

#### 9. Service Worker & PWA
**Current State:**
- No offline support
- No PWA manifest

**Optimization:**
- Add service worker for offline mode
- Cache static assets
- Add PWA manifest for "Add to Home Screen"

**Expected Impact:** Better mobile experience

---

## Performance Metrics to Track

### Web Vitals (Target)
- **LCP (Largest Contentful Paint):** < 2.5s ✅
- **FID (First Input Delay):** < 100ms ✅
- **CLS (Cumulative Layout Shift):** < 0.1 ✅

### Custom Metrics
- **API Response Time:** < 200ms (95th percentile)
- **Database Query Time:** < 50ms average
- **Image Load Time:** < 1s per image
- **Bundle Size:** Keep under 100KB First Load JS

---

## Implementation Plan

### Phase 1: Quick Wins (2 hours) ⏳
1. ✅ Audit current performance
2. 🔄 Image optimization with next/image
3. 🔄 Code splitting for AI features
4. 🔄 Optimize TanStack Query cache times

### Phase 2: Backend (2 hours) ⏳
5. 🔄 Add database indexes
6. 🔄 Enable compression middleware
7. 🔄 Optimize complex queries

### Phase 3: Advanced (Optional) ⏸️
8. ⏸️ iOS image compression
9. ⏸️ API request batching
10. ⏸️ Service worker & PWA

---

## Tools & Testing

### Performance Testing Tools
- **Lighthouse:** Run on production URL
- **WebPageTest:** Detailed waterfall analysis
- **Next.js Bundle Analyzer:** Visualize bundle size
- **PostgreSQL EXPLAIN ANALYZE:** Query performance

### Commands
```bash
# Analyze Next.js bundle
cd web && npm run build -- --analyze

# Test backend queries
psql -h db_host -U db_user -d db_name
EXPLAIN ANALYZE SELECT ...;

# Lighthouse CLI
npx lighthouse https://siteledger.ai --view
```

---

## Success Criteria

### Must Have ✅
- [ ] Image optimization implemented
- [ ] Code splitting for heavy features
- [ ] Database indexes added
- [ ] API compression enabled
- [ ] Bundle size < 100KB First Load JS

### Nice to Have 🎯
- [ ] Redis caching layer
- [ ] iOS image compression
- [ ] PWA manifest
- [ ] Service worker

---

**Next Step:** Start with image optimization (highest impact, lowest effort)
