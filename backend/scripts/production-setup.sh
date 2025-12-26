#!/bin/bash

# ============================================================
# SiteLedger Production Setup Script
# Run this on the DigitalOcean server after setting up domain
# ============================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   SiteLedger Production Setup${NC}"
echo -e "${BLUE}============================================${NC}"

# Check if domain is provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: ./production-setup.sh yourdomain.com${NC}"
    echo -e "${YELLOW}Example: ./production-setup.sh siteledger.construction${NC}"
    exit 1
fi

DOMAIN=$1
API_DOMAIN="api.$DOMAIN"
APP_DIR="/var/www/siteledger"

echo -e "${GREEN}Setting up for domain: $DOMAIN${NC}"
echo -e "${GREEN}API will be at: https://$API_DOMAIN${NC}"
echo ""

# ============================================
# Step 1: Update system packages
# ============================================
echo -e "${YELLOW}Step 1: Updating system packages...${NC}"
apt update && apt upgrade -y

# ============================================
# Step 2: Install Nginx
# ============================================
echo -e "${YELLOW}Step 2: Installing Nginx...${NC}"
apt install -y nginx

# ============================================
# Step 3: Install Certbot for SSL
# ============================================
echo -e "${YELLOW}Step 3: Installing Certbot...${NC}"
apt install -y certbot python3-certbot-nginx

# ============================================
# Step 4: Configure Nginx for API
# ============================================
echo -e "${YELLOW}Step 4: Configuring Nginx...${NC}"

# Create Nginx config for API
cat > /etc/nginx/sites-available/$API_DOMAIN << EOF
server {
    listen 80;
    server_name $API_DOMAIN;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        
        # CORS headers for iOS app
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
    }
}
EOF

# Create Nginx config for main domain (for privacy policy, etc.)
cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root /var/www/$DOMAIN/public;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Enable sites
ln -sf /etc/nginx/sites-available/$API_DOMAIN /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Remove default site
rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
nginx -t

# Reload Nginx
systemctl reload nginx

echo -e "${GREEN}Nginx configured!${NC}"

# ============================================
# Step 5: Create web directory for static files
# ============================================
echo -e "${YELLOW}Step 5: Creating web directories...${NC}"
mkdir -p /var/www/$DOMAIN/public

echo -e "${GREEN}Created /var/www/$DOMAIN/public${NC}"
echo -e "${YELLOW}Upload your privacy-policy.html there later${NC}"

# ============================================
# Step 6: Get SSL Certificate
# ============================================
echo -e "${YELLOW}Step 6: Getting SSL certificate...${NC}"
echo -e "${YELLOW}Make sure your DNS is pointing to this server!${NC}"
echo ""
read -p "Is your DNS configured? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    certbot --nginx -d $API_DOMAIN -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
    echo -e "${GREEN}SSL certificates installed!${NC}"
else
    echo -e "${YELLOW}Skipping SSL for now. Run this later:${NC}"
    echo -e "certbot --nginx -d $API_DOMAIN -d $DOMAIN -d www.$DOMAIN"
fi

# ============================================
# Step 7: Update environment variables
# ============================================
echo -e "${YELLOW}Step 7: Updating environment variables...${NC}"

# Update .env file
if [ -f "$APP_DIR/.env" ]; then
    sed -i "s|API_URL=.*|API_URL=https://$API_DOMAIN|g" $APP_DIR/.env
    sed -i "s|CORS_ORIGIN=.*|CORS_ORIGIN=https://$DOMAIN|g" $APP_DIR/.env
    echo -e "${GREEN}Environment variables updated!${NC}"
else
    echo -e "${YELLOW}.env file not found at $APP_DIR/.env${NC}"
fi

# ============================================
# Step 8: Restart PM2
# ============================================
echo -e "${YELLOW}Step 8: Restarting application...${NC}"
pm2 restart siteledger-api || pm2 start $APP_DIR/src/index.js --name siteledger-api
pm2 save

echo -e "${GREEN}Application restarted!${NC}"

# ============================================
# Step 9: Set up auto-renewal for SSL
# ============================================
echo -e "${YELLOW}Step 9: Setting up SSL auto-renewal...${NC}"
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
echo -e "${GREEN}SSL auto-renewal configured!${NC}"

# ============================================
# Summary
# ============================================
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}   Production Setup Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "API URL: ${GREEN}https://$API_DOMAIN${NC}"
echo -e "Website: ${GREEN}https://$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Upload privacy-policy.html to /var/www/$DOMAIN/public/"
echo -e "2. Update iOS app APIService.swift baseURL to:"
echo -e "   ${GREEN}https://$API_DOMAIN/api${NC}"
echo -e "3. Test the API: curl https://$API_DOMAIN/health"
echo ""
