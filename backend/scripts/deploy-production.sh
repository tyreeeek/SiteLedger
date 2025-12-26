#!/bin/bash
# ===========================================
# SiteLedger Production Deployment Script
# Run on DigitalOcean Droplet
# ===========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  SiteLedger Production Deployment${NC}"
echo -e "${GREEN}=========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

DOMAIN=${1:-api.siteledger.ai}
APP_DIR="/var/www/siteledger"
EMAIL=${2:-admin@siteledger.ai}

echo -e "${YELLOW}Domain: $DOMAIN${NC}"
echo -e "${YELLOW}App Directory: $APP_DIR${NC}"

# ===========================================
# Step 1: System Updates
# ===========================================
echo -e "\n${GREEN}[1/8] Updating system...${NC}"
apt update && apt upgrade -y

# ===========================================
# Step 2: Install Dependencies
# ===========================================
echo -e "\n${GREEN}[2/8] Installing dependencies...${NC}"

# Node.js 20 LTS
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
fi
echo "Node: $(node -v)"

# Nginx
apt install -y nginx

# Certbot for SSL
apt install -y certbot python3-certbot-nginx

# PM2
npm install -g pm2

# PostgreSQL (if not using managed DB)
# apt install -y postgresql postgresql-contrib

# ===========================================
# Step 3: Setup Application Directory
# ===========================================
echo -e "\n${GREEN}[3/8] Setting up application...${NC}"

mkdir -p $APP_DIR
cd $APP_DIR

# If files not uploaded yet
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}Please upload application files to $APP_DIR${NC}"
    echo "Use: scp -r backend/* root@YOUR_DROPLET_IP:$APP_DIR/"
    exit 1
fi

# Install dependencies
npm ci --only=production

# ===========================================
# Step 4: Setup Environment
# ===========================================
echo -e "\n${GREEN}[4/8] Configuring environment...${NC}"

if [ ! -f ".env" ]; then
    if [ -f ".env.production" ]; then
        cp .env.production .env
        echo -e "${GREEN}Copied .env.production to .env${NC}"
    else
        echo -e "${RED}No .env.production found!${NC}"
        exit 1
    fi
fi

# ===========================================
# Step 5: Setup Database
# ===========================================
echo -e "\n${GREEN}[5/8] Setting up database...${NC}"

# Create database user and database (uncomment if using local PostgreSQL)
# sudo -u postgres psql << EOF
# CREATE USER siteledger_user WITH PASSWORD 'YOUR_SECURE_PASSWORD';
# CREATE DATABASE siteledger OWNER siteledger_user;
# GRANT ALL PRIVILEGES ON DATABASE siteledger TO siteledger_user;
# EOF

# Run migrations
npm run migrate || echo "Migration failed or already run"

# ===========================================
# Step 6: Configure Nginx
# ===========================================
echo -e "\n${GREEN}[6/8] Configuring Nginx...${NC}"

# Copy Nginx config
cp nginx/siteledger.conf /etc/nginx/sites-available/siteledger

# Update domain in config
sed -i "s/api.siteledger.ai/$DOMAIN/g" /etc/nginx/sites-available/siteledger

# Enable site
ln -sf /etc/nginx/sites-available/siteledger /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test config
nginx -t

# ===========================================
# Step 7: Setup SSL with Let's Encrypt
# ===========================================
echo -e "\n${GREEN}[7/8] Setting up SSL...${NC}"

# Create certbot webroot
mkdir -p /var/www/certbot

# Temporarily allow HTTP for certbot
cat > /etc/nginx/sites-available/siteledger-temp << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 'OK';
    }
}
EOF

ln -sf /etc/nginx/sites-available/siteledger-temp /etc/nginx/sites-enabled/siteledger
systemctl reload nginx

# Get SSL certificate
certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --email $EMAIL --agree-tos --non-interactive

# Restore full config
ln -sf /etc/nginx/sites-available/siteledger /etc/nginx/sites-enabled/siteledger
rm /etc/nginx/sites-available/siteledger-temp

# Setup auto-renewal
systemctl enable certbot.timer
systemctl start certbot.timer

# Reload Nginx with SSL
systemctl reload nginx

# ===========================================
# Step 8: Start Application with PM2
# ===========================================
echo -e "\n${GREEN}[8/8] Starting application...${NC}"

cd $APP_DIR

# Stop existing if running
pm2 delete siteledger-api 2>/dev/null || true

# Start with PM2
pm2 start src/index.js --name siteledger-api --env production

# Save PM2 config
pm2 save

# Setup PM2 to start on boot
pm2 startup systemd -u root --hp /root

# ===========================================
# Done!
# ===========================================
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "API URL: ${GREEN}https://$DOMAIN${NC}"
echo -e "Health:  ${GREEN}https://$DOMAIN/health${NC}"
echo ""
echo "Useful commands:"
echo "  pm2 status          - Check app status"
echo "  pm2 logs            - View logs"
echo "  pm2 restart all     - Restart app"
echo "  certbot renew       - Renew SSL"
echo ""
