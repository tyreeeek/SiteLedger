#!/bin/bash

# ============================================================================
# SiteLedger Backend - Automated Deployment Script for DigitalOcean
# ============================================================================
# Run this script on your DigitalOcean droplet with sudo
# Usage: sudo bash deploy.sh

set -e  # Exit on error

echo "🚀 SiteLedger Backend Deployment Script"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ This script must be run with sudo${NC}"
    exit 1
fi

# ============================================================================
# Step 1: System Dependencies
# ============================================================================
echo -e "${BLUE}📦 Step 1: Installing System Dependencies...${NC}"

apt-get update -qq
apt-get upgrade -y -qq

# Install Node.js 18+
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18+"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y -qq nodejs
else
    echo "✅ Node.js already installed: $(node -v)"
fi

# Install PostgreSQL
if ! command -v psql &> /dev/null; then
    echo "Installing PostgreSQL"
    apt-get install -y -qq postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
else
    echo "✅ PostgreSQL already installed"
fi

# Install PM2 globally
npm install -g pm2 -q

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx"
    apt-get install -y -qq nginx
    systemctl enable nginx
else
    echo "✅ Nginx already installed"
fi

# Install Certbot for SSL
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot"
    apt-get install -y -qq certbot python3-certbot-nginx
else
    echo "✅ Certbot already installed"
fi

echo -e "${GREEN}✅ System dependencies installed${NC}\n"

# ============================================================================
# Step 2: PostgreSQL Database Setup
# ============================================================================
echo -e "${BLUE}🗄️  Step 2: Setting Up PostgreSQL Database...${NC}"

# Generate random password if not set
DB_PASSWORD=${DB_PASSWORD:-$(openssl rand -base64 32)}

# Create database and user
sudo -u postgres psql << EOF
-- Drop existing if needed (uncomment if redoing)
-- DROP DATABASE IF EXISTS siteledger;
-- DROP ROLE IF EXISTS siteledger_user;

-- Create new database and user
CREATE DATABASE IF NOT EXISTS siteledger;
CREATE USER IF NOT EXISTS siteledger_user WITH PASSWORD '$DB_PASSWORD';

-- Set user permissions
ALTER ROLE siteledger_user SET client_encoding TO 'utf8';
ALTER ROLE siteledger_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE siteledger_user SET default_transaction_deferrable TO on;
ALTER ROLE siteledger_user SET timezone TO 'UTC';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE siteledger TO siteledger_user;

-- For tables and sequences
\c siteledger
GRANT ALL ON SCHEMA public TO siteledger_user;
GRANT ALL ON ALL TABLES IN SCHEMA public TO siteledger_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO siteledger_user;
EOF

echo -e "${GREEN}✅ Database created${NC}"
echo -e "${YELLOW}💾 Database credentials:${NC}"
echo "   Username: siteledger_user"
echo "   Password: $DB_PASSWORD"
echo "   Database: siteledger"
echo "   Host: localhost"
echo ""

# ============================================================================
# Step 3: Deploy Backend Code
# ============================================================================
echo -e "${BLUE}📂 Step 3: Deploying Backend Code...${NC}"

APP_DIR="/var/www/siteledger"

if [ ! -d "$APP_DIR" ]; then
    mkdir -p "$APP_DIR"
    echo "Created $APP_DIR"
else
    echo "✅ Directory exists: $APP_DIR"
fi

# Note: You need to upload files separately via SCP or Git
echo -e "${YELLOW}⚠️  Please upload backend files to $APP_DIR${NC}"
echo "   Use: scp -r backend/* root@YOUR_IP:$APP_DIR/"
echo ""

# ============================================================================
# Step 4: Install Dependencies
# ============================================================================
echo -e "${BLUE}📦 Step 4: Installing Node Dependencies...${NC}"

cd "$APP_DIR"

if [ -f "package.json" ]; then
    npm install -q
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ package.json not found in $APP_DIR${NC}"
    exit 1
fi

# ============================================================================
# Step 5: Configure Environment
# ============================================================================
echo -e "${BLUE}⚙️  Step 5: Configuring Environment...${NC}"

if [ ! -f ".env" ]; then
    # Create .env from .env.production template
    cp .env.production .env 2>/dev/null || {
        echo "Creating default .env"
        cat > .env << EOF
PORT=3000
NODE_ENV=production
DATABASE_URL=postgresql://siteledger_user:$DB_PASSWORD@localhost:5432/siteledger
JWT_SECRET=$(openssl rand -base64 32)
JWT_EXPIRES_IN=7d
API_URL=https://api.yourdomain.com
EOF
    }
    
    # Update database credentials
    sed -i "s|siteledger_user:.*@|siteledger_user:$DB_PASSWORD@|g" .env
    
    echo -e "${GREEN}✅ .env created${NC}"
    echo -e "${YELLOW}⚠️  IMPORTANT: Edit .env and update:${NC}"
    echo "   - JWT_SECRET (auto-generated, but verify)"
    echo "   - API_URL (set your domain)"
    echo "   - SPACES credentials (if using file uploads)"
    echo ""
else
    echo "✅ .env already exists"
fi

# ============================================================================
# Step 6: Apply Database Schema
# ============================================================================
echo -e "${BLUE}🗄️  Step 6: Applying Database Schema...${NC}"

if [ -f "src/database/schema.sql" ]; then
    source .env
    psql "$DATABASE_URL" < src/database/schema.sql
    echo -e "${GREEN}✅ Database schema applied${NC}"
else
    echo -e "${YELLOW}⚠️  schema.sql not found${NC}"
fi

# ============================================================================
# Step 7: Start with PM2
# ============================================================================
echo -e "${BLUE}🚀 Step 7: Starting Backend with PM2...${NC}"

# Kill existing process if running
pm2 delete siteledger-api 2>/dev/null || true

# Start the app
pm2 start src/index.js --name "siteledger-api" --interpreter node

# Setup startup on boot
pm2 startup systemd -u root --hp /root
pm2 save

sleep 2
pm2 list

echo -e "${GREEN}✅ Backend started with PM2${NC}"
echo ""

# ============================================================================
# Step 8: Configure Nginx
# ============================================================================
echo -e "${BLUE}🌐 Step 8: Configuring Nginx Reverse Proxy...${NC}"

# Create Nginx config
cat > /etc/nginx/sites-available/siteledger << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.yourdomain.com;  # UPDATE THIS

    # SSL certificates (add after certbot setup)
    # ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/siteledger_access.log;
    error_log /var/log/nginx/siteledger_error.log;

    # Reverse proxy to Node.js backend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/siteledger /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test config
nginx -t

# Restart Nginx
systemctl restart nginx
echo -e "${GREEN}✅ Nginx configured${NC}"
echo ""

# ============================================================================
# Step 9: Setup SSL (Optional)
# ============================================================================
echo -e "${BLUE}🔐 Step 9: SSL Certificate Setup (Optional)${NC}"
echo -e "${YELLOW}To setup SSL:${NC}"
echo "   sudo certbot --nginx -d api.yourdomain.com"
echo "   Then verify: certbot renew --dry-run"
echo ""

# ============================================================================
# Step 10: Test API
# ============================================================================
echo -e "${BLUE}✅ Step 10: Testing API...${NC}"

sleep 3

if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API is responding${NC}"
else
    echo -e "${RED}❌ API not responding - Check PM2 logs${NC}"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo "========================================="
echo "📋 NEXT STEPS:"
echo "========================================="
echo ""
echo "1️⃣  Update Nginx configuration:"
echo "   - Edit /etc/nginx/sites-available/siteledger"
echo "   - Replace 'api.yourdomain.com' with your domain"
echo "   - Run: sudo systemctl restart nginx"
echo ""
echo "2️⃣  Setup SSL Certificate:"
echo "   - Run: sudo certbot --nginx -d api.yourdomain.com"
echo ""
echo "3️⃣  Update .env with production values:"
echo "   - Edit: /var/www/siteledger/.env"
echo "   - Update API_URL, SPACES credentials, etc."
echo "   - Run: pm2 restart siteledger-api"
echo ""
echo "4️⃣  Monitor the application:"
echo "   - Check status: pm2 status"
echo "   - View logs: pm2 logs siteledger-api"
echo "   - Monitor: pm2 monit"
echo ""
echo "5️⃣  Update iOS app:"
echo "   - Change API base URL to: https://api.yourdomain.com"
echo "   - Build and deploy to TestFlight"
echo ""
echo "========================================="
echo ""
echo "Database Credentials (save in secure location):"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: siteledger"
echo "   Username: siteledger_user"
echo "   Password: (shown above, also in .env)"
echo ""
echo "========================================="

