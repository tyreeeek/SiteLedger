# 🔍 Debug: Jobs Date Issue

## Current Status

I've added debug logging to identify why Job dates are still showing "Jan 7".

## What I Added

### Debug Logging in APIService.fetchJobs()
```swift
print("📅 Job '\(apiJob.jobName)': startDate='\(apiJob.startDate)', createdAt='\(apiJob.createdAt)'")
```

This will show:
- **What the backend is sending** for each job's startDate
- **Whether parsing is failing** (if you see ⚠️ warnings)

### Debug Logging in APIService.fetchReceipts()
Similar logging to see what date format the backend sends for receipts.

---

## How to Debug

### 1. Run the App with Console Open

In Xcode:
1. Press **Cmd+R** to run
2. Open **Console** (Cmd+Shift+Y or View → Debug Area → Show Debug Area)
3. Navigate to **Jobs** tab
4. Look for log output like:

```
📅 Job 'Kitchen Renovation': startDate='2026-01-07', createdAt='2026-01-07T19:30:00.000Z'
⚠️ Failed to parse startDate for job 'bobby': '2026-01-07'
```

### 2. What to Look For

**If you see:**
```
📅 Job 'bobby': startDate='2026-01-07', createdAt='2026-01-07T...'
```

This means:
- ✅ Backend is sending dates in `YYYY-MM-DD` format
- ❓ Parser should handle this (we added `dateOnly` formatter)
- 🔍 Need to check if the parser is working

**If you see:**
```
⚠️ Failed to parse startDate for job 'bobby': '2026-01-07'
```

This means:
- ❌ The `DateFormatters.parseAPIDate()` is failing
- 🐛 Bug in the date parser logic
- 🔧 Need to fix the parser

---

## Possible Issues

### Issue 1: PostgreSQL Returns Dates as Objects, Not Strings

The backend might be returning dates like:
```json
{
  "startDate": "2026-01-07T00:00:00.000Z"  // Full ISO8601
}
```

Or:
```json
{
  "startDate": "2026-01-07"  // Date only
}
```

**Solution**: The parser handles both formats now.

### Issue 2: Timezone Conversion

PostgreSQL DATE fields don't have timezone info. When converting to ISO8601, the backend might be adding UTC timezone (`Z`), which could cause the date to shift by a day depending on local timezone.

**Example:**
- **Database**: `2026-01-07` (no time)
- **Backend sends**: `2026-01-07T00:00:00.000Z` (UTC midnight)
- **iOS parses**: `2026-01-06 16:00:00` (PST, 8 hours behind)
- **iOS displays**: `Jan 6` (wrong!)

**Solution**: The `dateOnly` formatter uses UTC timezone to prevent shifts.

### Issue 3: Fallback to Date()

If parsing fails, the code falls back to `Date()` (today):
```swift
startDate: parsedStartDate ?? Date()  // ← Falls back to TODAY
```

This is intentional to prevent crashes, but it means failures are silent.

**Solution**: Added logging to catch failures.

---

## Next Steps

1. **Run the app** and check console output
2. **Share the log output** showing:
   - What `startDate` values the backend is sending
   - Any ⚠️ warnings about parsing failures
3. **I'll fix the parser** based on the actual format

---

## Quick Fix Option

If the issue is just the `?? Date()` fallback, we can make the date optional and handle nil in the UI:

```swift
// Option 1: Make date optional
startDate: parsedStartDate  // Could be nil

// Option 2: Use a placeholder date
startDate: parsedStartDate ?? Date.distantPast
```

Then in the UI:
```swift
if let startDate = job.startDate {
    Text(startDate.formatted(...))
} else {
    Text("No date set")
}
```

But first, let's see what the backend is actually sending! 📊
