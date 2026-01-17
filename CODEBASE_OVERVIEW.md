# Codebase Overview

## Structure

This is a monorepo containing the following main components:

- **SiteLedger/**: iOS Application (Swift/Xcode)
- **backend/**: Backend API (Node.js/Express)
- **web/**: Web Frontend (Next.js/React)

## Backend (`backend/`)

A Node.js Express application serving as the API.

- **Stack**: Node.js, Express, PostgreSQL
- **Infrastructure**: DigitalOcean (PM2/Nginx)
- **Key Dependencies**:
    - `pg` (Database)
    - `apple-signin-auth`, `google-auth-library`, `jsonwebtoken` (Authentication)
    - `aws-sdk` (Cloud services)
    - `tesseract.js` (OCR)
    - `nodemailer` (Email)
- **Structure**:
    - `src/index.js`: Entry point
    - `src/routes/`: API Routes
    - `src/database/`: Database logic and migrations
    - `src/config/`: Configuration

## Web (`web/`)

A Next.js application for the frontend.

- **Stack**: Next.js 14 (App Router), TypeScript, Tailwind CSS
- **Infrastructure**: Vercel
- **Key Dependencies**:
    - `@tanstack/react-query` (Data Fetching)
    - `lucide-react` (Icons)
    - `recharts` (Charts)
    - `sentry` (Monitoring)
- **Structure**:
    - `app/`: Next.js App Router pages and layouts (organized by feature: `dashboard`, `jobs`, `receipts`, etc.)
    - `components/`: Shared React components
    - `lib/`: Utilities
    - `public/`: Static assets

## Other
- **SiteLedger/**: Contains the `.xcodeproj` and Swift source code for the iOS app.
