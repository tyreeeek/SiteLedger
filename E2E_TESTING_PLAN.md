# End-to-End Testing Plan
**Date:** December 25, 2025  
**Status:** In Progress  

## Test Coverage Overview

### 1. Authentication Flow ✅
- [x] Backend health check
- [ ] User signup (email/password)
- [ ] User login (email/password)
- [ ] Apple Sign-In integration
- [ ] Token persistence
- [ ] Logout functionality
- [ ] Account deletion

### 2. Job Management 🔄
- [ ] Create new job
- [ ] List all jobs
- [ ] View job details
- [ ] Edit job details
- [ ] Assign workers to job
- [ ] Calculate job profit
- [ ] Archive/delete job

### 3. Receipt Management
- [ ] Upload receipt image
- [ ] AI OCR extraction
- [ ] Manual receipt entry
- [ ] Edit receipt
- [ ] Associate receipt with job
- [ ] Delete receipt

### 4. Timesheet Tracking
- [ ] Clock in/out functionality
- [ ] Manual timesheet entry
- [ ] Approve/reject timesheets
- [ ] Calculate worker hours
- [ ] Export timesheet data

### 5. Worker Management
- [ ] Create worker account
- [ ] Email password to worker
- [ ] Assign worker to job
- [ ] Update worker permissions
- [ ] View worker hours
- [ ] Deactivate worker

### 6. Financial Calculations
- [ ] Job profit calculation
- [ ] Labor cost calculation
- [ ] Receipt expense totals
- [ ] Payroll calculations
- [ ] Export financial data

---

## Test Execution Log

### Backend Health ✅
```bash
curl https://api.siteledger.ai/health
Response: {"status":"ok","timestamp":"2025-12-25T21:16:50.483Z","version":"1.0.0"}
Status: PASS ✅
```

---

## Next Steps
1. Test authentication endpoints
2. Test job CRUD operations
3. Test receipt upload flow
4. Verify financial calculations
5. Test worker permissions
