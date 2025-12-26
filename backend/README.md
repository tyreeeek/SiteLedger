# SiteLedger Backend - DigitalOcean

## Overview

SiteLedger backend running on DigitalOcean:
- **PostgreSQL** - Database for all app data
- **DigitalOcean Spaces** - File storage for receipts & documents
- **JWT Authentication** - Secure user authentication
- **Node.js/Express API** - RESTful API server

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Set Up Local PostgreSQL

```bash
brew install postgresql@15
brew services start postgresql@15
createdb siteledger
```

### 3. Configure Environment

```bash
cp .env.example .env
```

### 4. Run Migrations

```bash
npm run migrate
```

### 5. Start Server

```bash
npm run dev    # Development
npm start      # Production
```

## Deployment

1. Run `./deploy.sh` on your Droplet
2. Update `.env` with production credentials
3. Start with PM2: `pm2 start src/index.js --name siteledger-api`

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/signup | Create account |
| POST | /api/auth/login | Login |
| GET | /api/auth/me | Get current user |
| DELETE | /api/auth/account | Delete account |
| GET | /api/jobs | List jobs |
| POST | /api/jobs | Create job |
| GET | /api/receipts | List receipts |
| POST | /api/receipts | Create receipt |
| GET | /api/timesheets | List timesheets |
| GET | /api/workers | List workers |
| GET | /api/settings/permissions | Get permissions |
| PUT | /api/settings/permissions | Update permissions |

## Security

- Passwords hashed with bcrypt
- JWT tokens with 7-day expiration
- All queries filter by user ID
- Rate limiting enabled
