# SiteLedger Web App - Production Ready Implementation

## ✅ COMPLETED
1. Next.js 14 + TypeScript setup
2. APIService - matches iOS APIService.swift exactly
3. AuthService - matches iOS AuthService.swift exactly
4. Data Models - all types match iOS models exactly
5. Dependencies installed: React Query, Axios, Lucide Icons, Recharts

## 🔨 NEXT STEPS - Build Pages Matching iOS

### Page Structure (matches iOS Views/)
```
app/
├── (auth)/
│   ├── signin/page.tsx          → Views/Auth/SignInView.swift
│   ├── signup/page.tsx          → Views/Auth/SignUpView.swift
│   └── layout.tsx               → Auth wrapper
├── dashboard/page.tsx           → Views/Dashboard/DashboardView.swift
├── jobs/
│   ├── page.tsx                 → Views/Jobs/JobsListView.swift
│   └── [id]/page.tsx            → Views/Jobs/JobDetailView.swift
├── receipts/page.tsx            → Views/Receipts/ReceiptsView.swift
├── timesheets/page.tsx          → Views/Timesheets/TimesheetsView.swift
├── documents/page.tsx           → Views/Documents/DocumentsView.swift
├── workers/page.tsx             → Views/Worker/WorkerManagementView.swift
├── settings/page.tsx            → Views/Settings/SettingsView.swift
├── layout.tsx                   → Main layout with navigation
└── page.tsx                     → Landing page

```

## Key Features to Implement

1. **Dashboard** - Stats cards, active jobs, alerts, AI insights
2. **Jobs** - CRUD, profit calculation, worker assignment
3. **Receipts** - Upload, categorize, link to jobs
4. **Timesheets** - Clock in/out, labor cost calculation
5. **Documents** - File upload, job linking
6. **Workers** - Manage team, hourly rates
7. **Settings** - User profile, password change

## Profit Calculation Logic
```typescript
profit = projectValue - laborCost - receiptExpenses
remainingBalance = projectValue - amountPaid
```

Deploy with: `npm run build && ./deploy.sh`
